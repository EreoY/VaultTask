import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../services/auth_service.dart';
import '../../models/chat_model.dart';
import '../../models/task_model.dart';
import '../memory/context_builder.dart';
import '../skills/persona.dart';
import '../skills/skill_task_manager.dart';
import '../skills/skill_vision.dart';
import '../tools/registry.dart';
import '../tools/handlers/query_handlers.dart';
import '../tools/handlers/team_handlers.dart';
import '../tools/handlers/personal_handlers.dart';
import '../tools/handlers/vision_handlers.dart';
import '../tools/handlers/ui_handlers.dart';
import 'response_parser.dart';
import '../utils/draft_builder.dart';
import '../../config/env_config.dart';

class MistyAgent {
  static const String cfModelId = 'google/gemma-4-26b-a4b-it';
  final List<Map<String, dynamic>> _history = [];
  
  final Future<Map<String, String>?> Function(String name, String? url)? onGetImageB64;
  final Future<void> Function(String name, String? url, String newDesc)? onUpdateImageDescription;

  MistyAgent({
    this.onGetImageB64,
    this.onUpdateImageDescription,
  });

  void resetSession() => _history.clear();

  void setHistory(List<Map<String, dynamic>> history) {
    _history.clear();
    _history.addAll(history);
  }

  Map<String, String> _buildSystemMessage(String context) {
    return {
      'role': 'system',
      'content': '${Persona.coreMandates}\n\n'
                 '${SkillTaskManager.rules}\n\n'
                 '${SkillVision.rules}\n\n'
                 '$context'
    };
  }

  Map<String, dynamic> _convertSchema(Schema? s) {
    if (s == null) return {'type': 'object', 'properties': {}};
    final Map<String, dynamic> json = {'type': s.type.name.toLowerCase()};
    if (s.description != null) json['description'] = s.description;
    if (s.properties != null) json['properties'] = s.properties!.map((k, v) => MapEntry(k, _convertSchema(v)));
    if (s.requiredProperties != null && s.requiredProperties!.isNotEmpty) json['required'] = s.requiredProperties;
    if (s.items != null) json['items'] = _convertSchema(s.items);
    if (s.enumValues != null) json['enum'] = s.enumValues;
    return json;
  }

  Map<String, dynamic> _convertTool(FunctionDeclaration fd) => {
    'type': 'function',
    'function': {
      'name': fd.name, 
      'description': fd.description, 
      'parameters': _convertSchema(fd.parameters)
    },
  };

  Future<Map<String, dynamic>> _callCfApi(
    Map<String, String> systemMsg, {
    bool stream = false,
    String? sessionId,
    String? assistantMessageId,
  }) async {
    final body = {
      'uid': AuthService().currentUser?.uid ?? '', 
      'model': cfModelId,
      'messages': [systemMsg, ..._history],
      'tools': allAiTools.map((fd) => _convertTool(fd)).toList(),
      'max_tokens': 1500,
      'stream': stream,
      if (sessionId != null) 'session_id': sessionId,
      if (assistantMessageId != null) 'assistant_message_id': assistantMessageId,
    };
    final resp = await http.post(Uri.parse('${EnvConfig.backendUrl}/api/ai/chat'), 
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
    if (resp.statusCode != 200) throw Exception('Server error: ${resp.body}');
    return jsonDecode(resp.body);
  }

  Future<AiReply> processMessageStream(
    String message, {
    List<Map<String, String>>? attachments,
    TaskModel? activeTask,
    String? sessionId,
    String? assistantMessageId,
  }) async {
    return await processMessage(
      message,
      attachments: attachments,
      activeTask: activeTask,
      sessionId: sessionId,
      assistantMessageId: assistantMessageId,
    );
  }

  Future<AiReply> processMessage(
    String message, {
    List<Map<String, String>>? attachments,
    TaskModel? activeTask,
    String? sessionId,
    String? assistantMessageId,
  }) async {
    final List<ToolCallInfo> allToolNames = []; // PERSISTENT TOOL LOGS
    final liveContext = await ContextBuilder.buildLiveContext(activeTask: activeTask);
    final systemMessage = _buildSystemMessage(liveContext);

    final hasAttachments = attachments != null && attachments.isNotEmpty;
    if (hasAttachments) {
      String enrichedText = message;
      for (final att in attachments) {
        final name = att['name'] ?? 'image';
        final url = att['url'] ?? '';
        enrichedText += '\n[Attached Image Name: "$name", URL: "$url"]';
      }
      final content = <Map<String, dynamic>>[{'type': 'text', 'text': enrichedText}];
      
      // Send ALL file types (image, audio, video, pdf) as inline data URIs
      // Gemini's OpenAI-compatible endpoint supports multimodal input via image_url with data URI
      for (final att in attachments) {
        final mime = att['mime'] ?? 'application/octet-stream';
        final b64 = att['b64'] ?? '';
        if (b64.isNotEmpty) {
          content.add({'type': 'image_url', 'image_url': {'url': 'data:$mime;base64,$b64'}});
        }
      }
      _history.add({'role': 'user', 'content': content});
    } else {
      _history.add({'role': 'user', 'content': message});
    }

    try {
      final response = await _callCfApi(
        systemMessage,
        sessionId: sessionId,
        assistantMessageId: assistantMessageId,
      );
      final result = response['result'];
      if (result == null) return AiReply(text: 'The AI service is not responding. Please try again.');
      
      String responseText = '';
      dynamic rawToolCalls;
      
      allToolNames.add(ToolCallInfo(name: 'system_sync_live_context', arguments: {'status': 'success', 'time': DateTime.now().toIso8601String()}));

      if (result['choices'] != null && (result['choices'] as List).isNotEmpty) {
        final messageObj = result['choices'][0]['message'];
        final parts = messageObj['content'] is List ? messageObj['content'] as List : null;
        if (parts != null) {
          responseText = ResponseParser.extractTextFromParts(parts);
        } else {
          responseText = messageObj['content'] ?? '';
        }
        rawToolCalls = messageObj['tool_calls'];
      } else {
        responseText = result['response'] ?? result['text'] ?? '';
        rawToolCalls = result['tool_calls'];
      }

      responseText = ResponseParser.cleanText(responseText);

       final assistantEntry = <String, dynamic>{
         'role': 'assistant',
         'content': responseText.isNotEmpty ? responseText : null,
       };
       if (rawToolCalls != null && (rawToolCalls as List).isNotEmpty) {
         assistantEntry['tool_calls'] = rawToolCalls;
       }
       _history.add(assistantEntry);

      if (rawToolCalls == null || (rawToolCalls as List).isEmpty) {
        return AiReply(text: responseText, reasoning: null, toolCalls: allToolNames);
      }

      final List<FunctionCall> actionCalls = [];
      final List<Map<String, dynamic>> turnToolHistory = [];
      final List<Map<String, dynamic>> extraUserMessagesToInject = [];

      for (var toolCall in (rawToolCalls as List)) {
        final function = toolCall['function'];
        if (function == null) continue;
        final functionName = function['name'];
        var args = function['arguments'];
        if (args is String) args = jsonDecode(args);
        final cleanArgs = ResponseParser.recursiveStripThink(Map<String, dynamic>.from(args as Map));
        
        allToolNames.add(ToolCallInfo(name: functionName, arguments: cleanArgs));
        final fCall = FunctionCall(functionName, cleanArgs);

        if (functionName.startsWith('query_') || functionName.startsWith('list_') || 
            functionName.startsWith('check_') || functionName == 'analyze_uploaded_image' ||
            functionName == 'show_ui_content' || functionName == 'get_actual_image' ||
            functionName == 'update_image_description') {
          
          String toolOutput = '';
          if (functionName == 'list_team_boards') toolOutput = await QueryHandlers.handleListBoards(cleanArgs);
          else if (functionName == 'query_team_tasks') toolOutput = await QueryHandlers.handleQueryTeamTasks(cleanArgs);
          else if (functionName == 'query_board_members') toolOutput = await QueryHandlers.handleQueryBoardMembers(cleanArgs);
          else if (functionName == 'check_board_updates') toolOutput = await QueryHandlers.handleCheckUpdates(cleanArgs);
          else if (functionName == 'check_member_roles') toolOutput = await QueryHandlers.handleCheckRoles(cleanArgs);
          else if (functionName == 'check_conflict') toolOutput = 'OK';
          else if (functionName == 'analyze_uploaded_image') toolOutput = await VisionHandlers.handleAnalyzeImage(cleanArgs);
          else if (functionName == 'list_personal_tasks') toolOutput = await PersonalHandlers.handleList(cleanArgs);
          else if (functionName == 'show_ui_content') toolOutput = await UIHandlers.handleShowUI(cleanArgs);
          else if (functionName == 'join_team_board') toolOutput = await TeamHandlers.handleJoin(cleanArgs);
          else if (functionName == 'get_actual_image') {
            final name = cleanArgs['name']?.toString() ?? '';
            final url = cleanArgs['url']?.toString();
            if (onGetImageB64 != null) {
              final res = await onGetImageB64!(name, url);
              if (res != null) {
                final b64 = res['b64'] ?? '';
                final mime = res['mime'] ?? 'image/jpeg';
                toolOutput = 'SUCCESS: Loaded visual content for "$name". The image has been injected as a user message immediately following this tool response.';
                extraUserMessagesToInject.add({
                  'role': 'user',
                  'content': [
                    {'type': 'text', 'text': 'This is the actual visual content of image "$name" for you to analyze:'},
                    {'type': 'image_url', 'image_url': {'url': 'data:$mime;base64,$b64'}}
                  ]
                });
              } else {
                toolOutput = 'ERROR: Could not retrieve image data for "$name". Check if name/url is correct.';
              }
            } else {
              toolOutput = 'ERROR: onGetImageB64 callback is not registered.';
            }
          } else if (functionName == 'update_image_description') {
            final name = cleanArgs['name']?.toString() ?? '';
            final url = cleanArgs['url']?.toString();
            final description = cleanArgs['description']?.toString() ?? '';
            if (onUpdateImageDescription != null) {
              await onUpdateImageDescription!(name, url, description);
              toolOutput = 'SUCCESS: Updated description for "$name" to: $description';
            } else {
              toolOutput = 'ERROR: onUpdateImageDescription callback is not registered.';
            }
          }
          else toolOutput = 'OK';

          turnToolHistory.add({'role': 'tool', 'tool_call_id': toolCall['id'] ?? 'call_${DateTime.now().millisecondsSinceEpoch}', 'content': toolOutput});
        } else {
          actionCalls.add(fCall);
        }
      }

      for (final th in turnToolHistory) _history.add(th);
      for (final msg in extraUserMessagesToInject) _history.add(msg);

      if (actionCalls.isNotEmpty) {
        final compositeReply = DraftBuilder.tryBuildComposite(actionCalls: actionCalls, responseText: responseText, allToolNames: allToolNames);
        if (compositeReply != null) return compositeReply;
      }

      bool canSkipSecondCall = responseText.trim().isNotEmpty;
      if (canSkipSecondCall) {
        for (var toolCall in (rawToolCalls as List)) {
          final function = toolCall['function'];
          if (function == null) continue;
          final name = function['name']?.toString() ?? '';
          if (name.startsWith('query_') || name.startsWith('list_') || name.startsWith('check_') ||
              name.startsWith('create_') || name.startsWith('update_') || name.startsWith('delete_') ||
              name.startsWith('move_') || name == 'join_team_board') {
            if (name != 'update_image_description') {
              canSkipSecondCall = false;
              break;
            }
          }
        }
      }

      if (canSkipSecondCall) {
        return AiReply(text: responseText, reasoning: null, toolCalls: allToolNames);
      }

      if (turnToolHistory.isNotEmpty) {
        final secRes = await _callCfApi(
          systemMessage,
          sessionId: sessionId,
          assistantMessageId: assistantMessageId,
        );
        final secResult = secRes['result'];
        String secText = '';
        if (secResult?['choices'] != null && (secResult['choices'] as List).isNotEmpty) {
          final secMessageObj = secResult['choices'][0]['message'];
          final secParts = secMessageObj['content'] is List ? secMessageObj['content'] as List : null;
          if (secParts != null) secText = ResponseParser.extractTextFromParts(secParts);
          else secText = secMessageObj['content']?.toString() ?? '';
        } else {
          secText = secResult?['response']?.toString() ?? secResult?['text']?.toString() ?? '';
        }
        
        secText = ResponseParser.cleanText(secText);
        _history.add({'role': 'assistant', 'content': secText.isNotEmpty ? secText : null});
        return AiReply(text: secText.trim(), reasoning: null, toolCalls: allToolNames);
      }

      return AiReply(text: responseText.trim(), reasoning: null, toolCalls: allToolNames);
    } catch (e) {
      return AiReply(text: 'An error occurred: $e', toolCalls: const []);
    }
  }

  Future<String> executePending(FunctionCall fc) async {
    final name = fc.name;
    final args = Map<String, dynamic>.from(fc.args);
    if (name == 'create_team_task') return await TeamHandlers.handleCreate(args);
    if (name == 'update_team_task') return await TeamHandlers.handleUpdate(args);
    if (name == 'delete_team_task') return await TeamHandlers.handleDelete(args);
    if (name == 'move_team_task') return await TeamHandlers.handleMove(args);
    if (name == 'create_personal_task') return await PersonalHandlers.handleCreate(args);
    return 'Unknown action';
  }
}
