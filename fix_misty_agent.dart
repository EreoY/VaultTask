import 'dart:io';

void main() {
  var file = File('my_ai_assistant/lib/ai_agent/core/misty_agent.dart');
  file.writeAsStringSync(r'''
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../services/auth_service.dart';
import '../../models/chat_model.dart';
import '../tools/registry.dart';
import '../tools/handlers/team_handlers.dart';
import '../tools/handlers/personal_handlers.dart';
import '../tools/handlers/query_handlers.dart';
import '../tools/handlers/vision_handlers.dart';
import '../tools/handlers/ui_handlers.dart';
import '../memory/context_builder.dart';
import '../utils/draft_builder.dart';
import 'response_parser.dart';

class MistyAgent {
  final String apiKey;
  final String cfModelId = '@cf/google/gemini-1.5-flash';
  final List<Map<String, dynamic>> _history = [];

  MistyAgent({required this.apiKey});

  Map<String, dynamic> _convertTool(FunctionDeclaration fd) {
    return {
      'name': fd.name,
      'description': fd.description,
      'parameters': fd.parameters?.toJson(),
    };
  }

  Map<String, String> _buildSystemMessage(String liveContext) {
    return {
      'role': 'system',
      'content': '''You are Aether Assistant, a high-fidelity AI executive planner. 
Current Strategic Context:
$liveContext

Protocol:
1. Use ID-First approach.
2. If multiple actions are needed, call tools sequentially.
3. Be professional and concise.''',
    };
  }

  Future<Map<String, dynamic>> _callCfApi(Map<String, String> systemMsg, {bool stream = false}) async {
    final body = {
      'uid': AuthService().currentUser?.uid ?? '', 
      'model': cfModelId,
      'messages': [systemMsg, ..._history],
      'tools': allAiTools.map((fd) => _convertTool(fd)).toList(),
      'max_tokens': 1500,
      'stream': stream,
    };
    final resp = await http.post(Uri.parse('https://calenda-api-worker.jitkhon1979.workers.dev/api/ai/chat'), 
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
    if (resp.statusCode != 200) throw Exception('Server error: ${resp.body}');
    return jsonDecode(resp.body);
  }

  Future<AiReply> processMessageStream(String message, {List<Map<String, String>>? attachments}) async {
    return await processMessage(message, attachments: attachments);
  }

  Future<AiReply> processMessage(String message, {List<Map<String, String>>? attachments}) async {
    final List<ToolCallInfo> allToolNames = []; // PERSISTENT TOOL LOGS
    
    final liveContext = await ContextBuilder.buildLiveContext();
    final systemMessage = _buildSystemMessage(liveContext);

    final imageAttachments = attachments?.where((a) => a['mime']?.startsWith('image/') == true && (a['b64'] ?? '').isNotEmpty).toList();
    if (imageAttachments != null && imageAttachments.isNotEmpty) {
      final content = <Map<String, dynamic>>[{'type': 'text', 'text': message}];
      for (final img in imageAttachments) {
        content.add({'type': 'image_url', 'image_url': {'url': 'data:${img['mime']};base64,${img['b64']}'}});
      }
      _history.add({'role': 'user', 'content': content});
    } else {
      _history.add({'role': 'user', 'content': message});
    }

    try {
      final response = await _callCfApi(systemMessage);
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

      final assistantEntry = <String, dynamic>{'role': 'assistant', 'content': responseText};
      if (rawToolCalls != null && (rawToolCalls as List).isNotEmpty) {
        assistantEntry['tool_calls'] = rawToolCalls;
      }
      _history.add(assistantEntry);

      if (rawToolCalls == null || (rawToolCalls as List).isEmpty) {
        return AiReply(text: responseText, reasoning: null, toolCalls: allToolNames);
      }

      final List<FunctionCall> actionCalls = [];
      final List<Map<String, dynamic>> turnToolHistory = [];

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
            functionName == 'show_ui_content') {
          
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
          else toolOutput = 'OK';

          turnToolHistory.add({'role': 'tool', 'tool_call_id': toolCall['id'] ?? 'call_${DateTime.now().millisecondsSinceEpoch}', 'content': toolOutput});
        } else {
          actionCalls.add(fCall);
        }
      }

      for (final th in turnToolHistory) _history.add(th);

      if (actionCalls.isNotEmpty) {
        final compositeReply = DraftBuilder.tryBuildComposite(actionCalls: actionCalls, responseText: responseText, allToolNames: allToolNames);
        if (compositeReply != null) return compositeReply;
      }

      if (turnToolHistory.isNotEmpty) {
        final secRes = await _callCfApi(systemMessage);
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
        _history.add({'role': 'assistant', 'content': secText});
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
''');
}
