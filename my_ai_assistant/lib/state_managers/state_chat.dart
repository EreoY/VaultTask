import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../models/chat_model.dart';
import '../models/board_model.dart';
import '../models/task_model.dart';
import '../ai_agent/core/misty_agent.dart';
import '../services/auth_service.dart';
import '../databases/api_cloudflare.dart';
import '../databases/db_personal_sqlite.dart';
import 'package:google_generative_ai/google_generative_ai.dart' hide ChatSession;

// ─── StateChat ──────────────────────────────────────────────────────────────
class StateChat extends ChangeNotifier {
  static final onImageDescriptionRegenerated = StreamController<Map<String, dynamic>>.broadcast();
  static final onUploadError = StreamController<String>.broadcast();
  static final onUploadSuccess = StreamController<String>.broadcast();

  // Dual-Context State Variables
  final List<ChatMessage> _globalMessages = [];
  final List<ChatMessage> _taskMessages = [];
  
  late MistyAgent _globalAgent;
  late MistyAgent _taskAgent;

  final String _provider = 'cf'; // Kept for compatibility if UI needs it
  final String _cfModel = MistyAgent.cfModelId;

  bool _globalIsTyping = false;
  bool _taskIsTyping = false;

  ProposalDraft? _globalDraft;
  ProposalDraft? _taskDraft;

  final List<PlatformFile> _globalPendingFiles = [];
  final List<PlatformFile> _taskPendingFiles = [];

  List<ChatSession> _globalSessions = [];
  List<ChatSession> _taskSessions = [];
  ChatSession? _currentGlobalSession;
  String? _activeTaskId;
  final Map<String, String> _activeTaskSessionId = {};
  bool _isLoadingGlobalContext = false;

  // Getters that dynamically route to the active context (Global vs Task-specific)
  List<ChatMessage> get _messages => _activeTaskId != null ? _taskMessages : _globalMessages;
  MistyAgent get _agent => _activeTaskId != null ? _taskAgent : _globalAgent;
  
  bool get _isTyping => _activeTaskId != null ? _taskIsTyping : _globalIsTyping;
  set _isTyping(bool val) {
    if (_activeTaskId != null) {
      _taskIsTyping = val;
    } else {
      _globalIsTyping = val;
    }
  }

  ProposalDraft? get _draft => _activeTaskId != null ? _taskDraft : _globalDraft;
  set _draft(ProposalDraft? val) {
    if (_activeTaskId != null) {
      _taskDraft = val;
    } else {
      _globalDraft = val;
    }
  }

  List<PlatformFile> get _pendingFiles => _activeTaskId != null ? _taskPendingFiles : _globalPendingFiles;

  // Public Getters (Global Context)
  List<ChatMessage> get messages => _globalMessages;
  bool get isTyping => _globalIsTyping;
  ProposalDraft? get draft => _globalDraft;
  List<PlatformFile> get pendingFiles => _globalPendingFiles;

  // Public Getters (Task Context)
  List<ChatMessage> get taskMessages => _taskMessages;
  bool get isTaskTyping => _taskIsTyping;
  ProposalDraft? get taskDraft => _taskDraft;
  List<PlatformFile> get taskPendingFiles => _taskPendingFiles;

  List<ChatSession> get globalSessions => _globalSessions;
  List<ChatSession> get taskSessions => _taskSessions;
  ChatSession? get currentGlobalSession => _currentGlobalSession;
  String? get activeTaskId => _activeTaskId;
  
  String? get activeSessionId {
    if (_activeTaskId != null) {
      return _activeTaskSessionId[_activeTaskId];
    }
    return _currentGlobalSession?.id;
  }

  StateChat() {
    _initRouter();
    _initImageDescriptionListener();
    ensureInitialized();
  }

  Future<void> _initRouter() async {
    _globalAgent = MistyAgent(
      onGetImageB64: _getImageB64,
      onUpdateImageDescription: _updateImageDescription,
    );
    _taskAgent = MistyAgent(
      onGetImageB64: _getImageB64,
      onUpdateImageDescription: _updateImageDescription,
    );
  }

  void _initImageDescriptionListener() {
    onImageDescriptionRegenerated.stream.listen((event) {
      final url = event['url'] as String?;
      final name = event['name'] as String?;
      final description = event['aiDescription'] as String?;
      if (description == null || (url == null && name == null)) return;

      bool changed = false;

      // Update global messages in memory
      for (int i = 0; i < _globalMessages.length; i++) {
        final msg = _globalMessages[i];
        final hasMatch = msg.attachments.any((att) => 
            (url != null && att['url'] == url) || (name != null && att['name'] == name));
        if (hasMatch) {
          final updatedAtt = msg.attachments.map((att) {
            if ((url != null && att['url'] == url) || (name != null && att['name'] == name)) {
              return Map<String, String>.from(att)..['description'] = description;
            }
            return att;
          }).toList();
          final updatedMsg = msg.copyWith(attachments: updatedAtt);
          _globalMessages[i] = updatedMsg;
          final sessId = _currentGlobalSession?.id;
          if (sessId != null) {
            _saveChatMessageToDb(updatedMsg, sessId);
          }
          changed = true;
        }
      }

      // Update task messages in memory
      for (int i = 0; i < _taskMessages.length; i++) {
        final msg = _taskMessages[i];
        final hasMatch = msg.attachments.any((att) => 
            (url != null && att['url'] == url) || (name != null && att['name'] == name));
        if (hasMatch) {
          final updatedAtt = msg.attachments.map((att) {
            if ((url != null && att['url'] == url) || (name != null && att['name'] == name)) {
              return Map<String, String>.from(att)..['description'] = description;
            }
            return att;
          }).toList();
          final updatedMsg = msg.copyWith(attachments: updatedAtt);
          _taskMessages[i] = updatedMsg;
          final sessId = _activeTaskId != null ? _activeTaskSessionId[_activeTaskId] : null;
          if (sessId != null) {
            _saveChatMessageToDb(updatedMsg, sessId);
          }
          changed = true;
        }
      }

      if (changed) {
        _globalAgent.setHistory(_convertMessagesToAgentHistory(_globalMessages));
        _taskAgent.setHistory(_convertMessagesToAgentHistory(_taskMessages));
        notifyListeners();
      }
    });
  }

  void _generateDescriptionInBg(Uint8List bytes, String filename, String url, String mime) {
    ApiCloudflare.generateAiDescription(bytes, mime).then((desc) {
      if (desc.isNotEmpty) {
        onImageDescriptionRegenerated.add({
          'name': filename,
          'url': url,
          'aiDescription': desc,
        });
      }
    }).catchError((e) {
      debugPrint('Background AI description generation failed: $e');
    });
  }

  Future<void> _saveChatMessageToDb(ChatMessage updatedMsg, String sessionId) async {
    try {
      await DbPersonalSqlite.instance.insertChatMessage(updatedMsg, sessionId);
      await ApiCloudflare.insertChatMessage(updatedMsg, sessionId);
    } catch (e) {
      debugPrint('Error saving chat message update: $e');
    }
  }

  Future<Map<String, String>?> _getImageB64(String name, String? url) async {
    // 1. Search in global messages attachments
    for (final msg in _globalMessages) {
      for (final att in msg.attachments) {
        if (att['name'] == name || (url != null && att['url'] == url)) {
          final b64 = att['b64'] ?? '';
          final mime = att['mime'] ?? 'image/jpeg';
          if (b64.isNotEmpty) {
            return {'b64': b64, 'mime': mime};
          }
        }
      }
    }
    // 2. Search in task messages attachments
    for (final msg in _taskMessages) {
      for (final att in msg.attachments) {
        if (att['name'] == name || (url != null && att['url'] == url)) {
          final b64 = att['b64'] ?? '';
          final mime = att['mime'] ?? 'image/jpeg';
          if (b64.isNotEmpty) {
            return {'b64': b64, 'mime': mime};
          }
        }
      }
    }
    // 3. Download from URL
    final targetUrl = url ?? '';
    if (targetUrl.isNotEmpty && targetUrl.startsWith('http')) {
      try {
        final uri = Uri.parse(targetUrl);
        final resp = await http.get(uri);
        if (resp.statusCode == 200) {
          final b64 = base64Encode(resp.bodyBytes);
          final ext = targetUrl.split('.').last.split('?').first.toLowerCase();
          String mime = 'image/jpeg';
          if (ext == 'png') {
            mime = 'image/png';
          } else if (ext == 'gif') mime = 'image/gif';
          else if (ext == 'webp') mime = 'image/webp';
          return {'b64': b64, 'mime': mime};
        }
      } catch (e) {
        debugPrint('Error getting image from url: $e');
      }
    }
    return null;
  }

  Future<void> _updateImageDescription(String name, String? url, String newDesc) async {
    // Publish event for all listeners to update
    onImageDescriptionRegenerated.add({
      'name': name,
      'url': url,
      'aiDescription': newDesc,
    });
  }

  Future<void> switchProvider(String provider) async {
    // Deprecated in new unified router
    notifyListeners();
  }

  Future<void> updateCfModel(String modelId) async {
    // Deprecated in new unified router
    notifyListeners();
  }

  String get aiProvider => _provider;
  String get cfModelId => _cfModel;
  List<Map<String, String>> get availableCfModels => [{'id': _cfModel, 'name': 'Gemini 3.1 Flash Lite', 'description': 'Unified Model'}];

  String get currentModelName => 'Gemini 3.1 Flash Lite';

  Future<void> updateApiKey(String key) async {
    await AuthService().saveUserApiKey(key);
    _agent.resetSession();
    notifyListeners();
  }

  Future<void> clearApiKey() async {
    await AuthService().clearUserApiKey();
    _agent.resetSession();
    notifyListeners();
  }

  String? get currentApiKey => null; // Deprecated locally, uses backend proxy key

  List<PlatformFile> get pendingFileMaps => _pendingFiles;

  /// Receives already-picked files from the UI layer.
  /// Called AFTER FilePicker.pickFiles() completes in the gesture callback.
  void addPendingFiles(List<PlatformFile> files) {
    if (files.isEmpty) return;
    _pendingFiles.addAll(files);
    notifyListeners();
  }

  void removeFile(int index) {
    if (index >= 0 && index < _pendingFiles.length) {
      _pendingFiles.removeAt(index);
      notifyListeners();
    }
  }

  void clearPendingFiles() {
    _pendingFiles.clear();
    notifyListeners();
  }

  String _guessMimeType(String? filename) {
    final ext = filename?.split('.').last.toLowerCase() ?? '';
    final map = <String, String>{
      'jpg': 'image/jpeg', 'jpeg': 'image/jpeg', 'png': 'image/png',
      'gif': 'image/gif', 'webp': 'image/webp', 'bmp': 'image/bmp',
      'svg': 'image/svg+xml',
      'pdf': 'application/pdf',
      'mp3': 'audio/mpeg', 'wav': 'audio/wav', 'ogg': 'audio/ogg',
      'm4a': 'audio/mp4', 'flac': 'audio/flac',
      'mp4': 'video/mp4', 'mov': 'video/quicktime', 'avi': 'video/x-msvideo',
      'mkv': 'video/x-matroska',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'txt': 'text/plain', 'csv': 'text/csv', 'json': 'application/json',
      'zip': 'application/zip', 'rar': 'application/x-rar-compressed',
    };
    return map[ext] ?? 'application/octet-stream';
  }



  void addMessage(ChatMessage message) {
    _messages.insert(0, message);
    notifyListeners();
  }

  void resetFullChat() async {
    final sessId = activeSessionId;
    if (sessId != null) {
      await ApiCloudflare.deleteChatSession(sessId);
      if (_activeTaskId != null) {
        await startNewTaskSession(_activeTaskId!);
      } else {
        _globalSessions.removeWhere((s) => s.id == sessId);
        if (_globalSessions.isNotEmpty) {
          await selectGlobalSession(_globalSessions.first);
        } else {
          await startNewGlobalSession();
        }
      }
    } else {
      _messages.clear();
      _draft = null;
      _agent.resetSession();
      notifyListeners();
    }
  }

  // ─── Send message ──────────────────────────────────────────────────────────
  Future<void> sendMessageToAI(String text, {String? boardId}) async {
    if (text.trim().isEmpty && _globalPendingFiles.isEmpty) return;
    if (_globalIsTyping) return;

    final sessId = _currentGlobalSession?.id;
    if (sessId == null) return;

    // Auto-rename session on first message
    if (_currentGlobalSession!.name == 'New Session') {
      final words = text.trim().split(RegExp(r'\s+'));
      final newName = words.take(5).join(' ');
      if (newName.isNotEmpty) await renameSession(_currentGlobalSession!.id, newName);
    }

    _globalIsTyping = true;
    notifyListeners();

    // ─── Step 1: Upload files to R2 (blocking) ─────────────────────────
    final List<Map<String, String>> attachments = [];
    final List<PlatformFile> filesToUpload = List.from(_globalPendingFiles);
    final List<Uint8List> uploadedBytesList = [];
    clearPendingFiles();

    for (final file in filesToUpload) {
      try {
        Uint8List? bytes = file.bytes;
        if (bytes == null && !kIsWeb && file.path != null) {
          bytes = await io.File(file.path!).readAsBytes();
        }
        if (bytes == null) {
          onUploadError.add('ไม่สามารถอ่านไฟล์ "${file.name}"');
          continue;
        }

        final res = await ApiCloudflare.uploadImage(bytes, file.name, path: 'chats');
        if (res['url'] == null) {
          onUploadError.add('อัปโหลด "${file.name}" ล้มเหลว: ไม่ได้ URL');
          continue;
        }

        final mime = _guessMimeType(file.name);
        final imageUrl = res['url'].toString();
        attachments.add({
          'name': file.name,
          'url': imageUrl,
          'mime': mime,
          'b64': base64Encode(bytes),
          'description': '', // empty initially, loaded in bg
        });
        uploadedBytesList.add(bytes);
        onUploadSuccess.add('อัปโหลด "${file.name}" สำเร็จ');

        if (mime.startsWith('image/')) {
          _generateDescriptionInBg(bytes, file.name, imageUrl, mime);
        }
      } catch (e) {
        debugPrint('Upload failed for ${file.name}: $e');
        onUploadError.add('อัปโหลด "${file.name}" ล้มเหลว: $e');
      }
    }

    // ─── Step 2: Create & persist user message ─────────────────────────
    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      attachments: attachments,
    );
    _globalMessages.insert(0, userMsg);
    notifyListeners();
    await ApiCloudflare.insertChatMessage(userMsg, sessId);

    // Sync agent history (excluding the new userMsg) to strip base64 from historical messages
    final historyMsgs = _globalMessages.skip(1).toList();
    final agentHistory = _convertMessagesToAgentHistory(historyMsgs);
    _globalAgent.setHistory(agentHistory);

    // ─── Step 3: Send to AI agent ──────────────────────────────────────
    final aiMessageId = DateTime.now().millisecondsSinceEpoch.toString();
    final reply = await _globalAgent.processMessageStream(
      text, 
      attachments: attachments,
      sessionId: sessId,
      assistantMessageId: aiMessageId,
    );
    _globalIsTyping = false;

    // ─── Step 4: Handle AI response ────────────────────────────────────
    final aiMessage = ChatMessage(
      id: aiMessageId,
      text: reply.text,
      reasoning: reply.reasoning,
      isUser: false,
      hasDraft: reply.pendingCall != null,
      pendingCall: reply.pendingCall,
      toolCalls: reply.toolCalls,
    );
    _globalMessages.insert(0, aiMessage);
    await ApiCloudflare.insertChatMessage(aiMessage, sessId);

    if (reply.stream != null) {
      String fullText = reply.text;
      reply.stream!.listen((chunk) {
        fullText += chunk;
        final index = _globalMessages.indexWhere((m) => m.id == aiMessageId);
        if (index != -1) {
          _globalMessages[index] = aiMessage.copyWith(text: fullText);
          notifyListeners();
        }
      }, onDone: () async {
        await ApiCloudflare.insertChatMessage(aiMessage.copyWith(text: fullText), sessId);
        if (reply.pendingCall != null) _buildDraft(reply.pendingCall!);
      });
    } else {
      if (reply.pendingCall != null) {
        await _buildDraft(reply.pendingCall!);
      } else {
        _globalDraft = null;
      }
    }

    notifyListeners();
  }

  Future<void> sendTaskMessageToAI(String text, TaskModel activeTask) async {
    if (text.trim().isEmpty) return;
    if (_taskIsTyping) return;

    final sessId = _activeTaskSessionId[activeTask.id];
    if (sessId == null) return;

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
    );

    _taskMessages.insert(0, userMsg);
    await ApiCloudflare.insertChatMessage(userMsg, sessId);

    _taskIsTyping = true;
    notifyListeners();

    // Sync agent history (excluding the new userMsg) to strip base64 from historical messages
    final historyMsgs = _taskMessages.skip(1).toList();
    final agentHistory = _convertMessagesToAgentHistory(historyMsgs);
    _taskAgent.setHistory(agentHistory);

    // Route to unified provider using the task agent
    final aiMessageId = DateTime.now().millisecondsSinceEpoch.toString();
    final reply = await _taskAgent.processMessageStream(
      text,
      attachments: [],
      activeTask: activeTask,
      sessionId: sessId,
      assistantMessageId: aiMessageId,
    );

    _taskIsTyping = false;

    // Create the message object
    final aiMessage = ChatMessage(
      id: aiMessageId,
      text: reply.text, // Could be empty if streaming
      reasoning: reply.reasoning,
      isUser: false,
    );

    _taskMessages.insert(0, aiMessage);
    await ApiCloudflare.insertChatMessage(aiMessage, sessId);

    if (reply.stream != null) {
      // Handle streaming updates
      String fullText = reply.text;
      reply.stream!.listen((chunk) {
        fullText += chunk;
        final index = _taskMessages.indexWhere((m) => m.id == aiMessageId);
        if (index != -1) {
          _taskMessages[index] = ChatMessage(
            id: aiMessageId,
            text: fullText,
            reasoning: aiMessage.reasoning,
            isUser: false,
            timestamp: aiMessage.timestamp,
          );
          notifyListeners();
        }
      }, onDone: () async {
        final finalAiMsg = ChatMessage(
          id: aiMessageId,
          text: fullText,
          reasoning: aiMessage.reasoning,
          isUser: false,
          timestamp: aiMessage.timestamp,
        );
        await ApiCloudflare.insertChatMessage(finalAiMsg, sessId);
      });
    }

    notifyListeners();
  }

  // ─── Chat Session Handlers ──────────────────────────────────────────────────

  Future<void> ensureInitialized() async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;
    if (_globalSessions.isEmpty) {
      await loadGlobalSessions();
    }
  }

  Future<void> loadGlobalSessions() async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;
    final sessions = await ApiCloudflare.getChatSessions(uid, taskId: '');
    _globalSessions = sessions;
    if (_globalSessions.isNotEmpty) {
      await selectGlobalSession(_globalSessions.first);
    } else {
      await startNewGlobalSession();
    }
  }

  Future<void> startNewGlobalSession() async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;
    final id = 'session_global_${DateTime.now().millisecondsSinceEpoch}';
    final newSession = ChatSession(
      id: id,
      uid: uid,
      taskId: '',
      name: 'New Session',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await ApiCloudflare.insertChatSession(id, uid, 'New Session', taskId: '');
    _globalSessions.insert(0, newSession);
    await selectGlobalSession(newSession);
  }

  Future<void> selectGlobalSession(ChatSession session) async {
    _currentGlobalSession = session;
    _activeTaskId = null;
    _globalDraft = null;
    _globalAgent.resetSession();
    final msgs = await ApiCloudflare.getChatMessages(session.id);
    final sanitizedMsgs = _sanitizeLoadedMessages(msgs);
    _globalMessages.clear();
    _globalMessages.addAll(sanitizedMsgs);
    final agentHistory = _convertMessagesToAgentHistory(sanitizedMsgs);
    _globalAgent.setHistory(agentHistory);
    notifyListeners();
  }

  Future<void> selectTaskSession(String taskId, {String? taskTitle}) async {
    _activeTaskId = taskId;
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;

    final title = (taskTitle != null && taskTitle.isNotEmpty) ? taskTitle : 'Task Discussion';

    String sessionId = _activeTaskSessionId[taskId] ?? '';
    final sessions = await ApiCloudflare.getChatSessions(uid, taskId: taskId);
    _taskSessions = sessions;
    
    if (sessionId.isEmpty) {
      if (sessions.isNotEmpty) {
        sessionId = sessions.first.id;
        // Update session name if it has changed
        if (taskTitle != null && sessions.first.name != taskTitle) {
          await ApiCloudflare.insertChatSession(sessionId, uid, title, taskId: taskId);
          final idx = _taskSessions.indexWhere((s) => s.id == sessionId);
          if (idx != -1) {
            final old = _taskSessions[idx];
            _taskSessions[idx] = ChatSession(
              id: old.id,
              uid: old.uid,
              taskId: old.taskId,
              name: title,
              createdAt: old.createdAt,
              updatedAt: DateTime.now().millisecondsSinceEpoch,
            );
          }
        }
      } else {
        sessionId = 'session_task_${taskId}_${DateTime.now().millisecondsSinceEpoch}';
        await ApiCloudflare.insertChatSession(sessionId, uid, title, taskId: taskId);
        final newSess = ChatSession(
          id: sessionId,
          uid: uid,
          taskId: taskId,
          name: title,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
        _taskSessions = [newSess];
      }
      _activeTaskSessionId[taskId] = sessionId;
    } else {
      if (taskTitle != null && taskTitle.isNotEmpty) {
        await ApiCloudflare.insertChatSession(sessionId, uid, title, taskId: taskId);
        final idx = _taskSessions.indexWhere((s) => s.id == sessionId);
        if (idx != -1) {
          final old = _taskSessions[idx];
          _taskSessions[idx] = ChatSession(
            id: old.id,
            uid: old.uid,
            taskId: old.taskId,
            name: title,
            createdAt: old.createdAt,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          );
        }
      }
    }

    _taskDraft = null;
    _taskAgent.resetSession();
    final msgs = await ApiCloudflare.getChatMessages(sessionId);
    final sanitizedMsgs = _sanitizeLoadedMessages(msgs);
    _taskMessages.clear();
    _taskMessages.addAll(sanitizedMsgs);
    final agentHistory = _convertMessagesToAgentHistory(sanitizedMsgs);
    _taskAgent.setHistory(agentHistory);
    notifyListeners();
  }

  Future<void> startNewTaskSession(String taskId, {String? taskTitle}) async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;
    final title = (taskTitle != null && taskTitle.isNotEmpty) ? taskTitle : 'Task Discussion';
    final sessionId = 'session_task_${taskId}_${DateTime.now().millisecondsSinceEpoch}';
    
    final newSessionName = '$title (เสสชัน ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')})';
    await ApiCloudflare.insertChatSession(sessionId, uid, newSessionName, taskId: taskId);
    _activeTaskSessionId[taskId] = sessionId;
    
    final newSess = ChatSession(
      id: sessionId,
      uid: uid,
      taskId: taskId,
      name: newSessionName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    _taskSessions.insert(0, newSess);
    
    _taskMessages.clear();
    _taskDraft = null;
    _taskAgent.resetSession();
    notifyListeners();
  }

  Future<void> switchTaskSession(String taskId, String sessionId) async {
    _activeTaskId = taskId;
    _activeTaskSessionId[taskId] = sessionId;
    
    _taskMessages.clear();
    _taskDraft = null;
    _taskAgent.resetSession();
    final msgs = await ApiCloudflare.getChatMessages(sessionId);
    final sanitizedMsgs = _sanitizeLoadedMessages(msgs);
    _taskMessages.addAll(sanitizedMsgs);
    final agentHistory = _convertMessagesToAgentHistory(sanitizedMsgs);
    _taskAgent.setHistory(agentHistory);
    notifyListeners();
  }

  Future<void> renameSession(String sessionId, String newName) async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;
    final idx = _globalSessions.indexWhere((s) => s.id == sessionId);
    String taskId = '';
    if (idx != -1) {
      taskId = _globalSessions[idx].taskId;
    }
    await ApiCloudflare.insertChatSession(sessionId, uid, newName, taskId: taskId);
    if (idx != -1) {
      final old = _globalSessions[idx];
      _globalSessions[idx] = ChatSession(
        id: old.id,
        uid: old.uid,
        taskId: old.taskId,
        name: newName,
        createdAt: old.createdAt,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      if (_currentGlobalSession?.id == sessionId) {
        _currentGlobalSession = _globalSessions[idx];
      }
    }
    notifyListeners();
  }

  Future<void> deleteSession(String sessionId) async {
    await ApiCloudflare.deleteChatSession(sessionId);
    _globalSessions.removeWhere((s) => s.id == sessionId);
    if (_currentGlobalSession?.id == sessionId) {
      if (_globalSessions.isNotEmpty) {
        await selectGlobalSession(_globalSessions.first);
      } else {
        await startNewGlobalSession();
      }
    } else {
      notifyListeners();
    }
  }

  Future<void> switchToGlobalContext() async {
    if (_isLoadingGlobalContext) return;
    _isLoadingGlobalContext = true;
    try {
      _activeTaskId = null;
      if (_currentGlobalSession != null) {
        await selectGlobalSession(_currentGlobalSession!);
      } else {
        await loadGlobalSessions();
      }
    } finally {
      _isLoadingGlobalContext = false;
    }
  }


  List<ChatMessage> _sanitizeLoadedMessages(List<ChatMessage> msgs) {
    return msgs.map((m) {
      if (m.isUser && m.attachments.isNotEmpty) {
        final cleanedAttachments = m.attachments.map((a) {
          final url = a['url'] ?? '';
          if (url.isEmpty) {
            final copy = Map<String, String>.from(a);
            copy['url'] = 'error';
            return copy;
          }
          return a;
        }).toList();
        return m.copyWith(attachments: cleanedAttachments);
      }
      return m;
    }).toList();
  }

  List<Map<String, dynamic>> _convertMessagesToAgentHistory(List<ChatMessage> msgs) {
    // Capping the history to the most recent 14 messages (approx. 7 turns) to limit context size
    final recentMsgs = msgs.take(14).toList();
    final chronological = recentMsgs.reversed.toList();
    List<Map<String, dynamic>> history = [];
    
    int lastUserIndex = -1;
    for (int i = chronological.length - 1; i >= 0; i--) {
      if (chronological[i].isUser) {
        lastUserIndex = i;
        break;
      }
    }

    for (int i = 0; i < chronological.length; i++) {
      final m = chronological[i];
      if (m.isUser) {
        final hasAttachments = m.attachments.isNotEmpty;
        if (hasAttachments) {
          final List<String> descriptionLines = [];
          final List<Map<String, dynamic>> remainingImageUrls = [];
          final isLatestUserMsg = (i == lastUserIndex);
          
          for (final att in m.attachments) {
            final name = att['name'] ?? 'image';
            final description = att['description'] ?? '';
            final mime = att['mime'] ?? '';
            final b64 = att['b64'] ?? '';
            final url = att['url'] ?? '';
            
            // Skip failed/empty attachments completely
            if (url == 'error' || url.isEmpty) continue;
            
            if (mime.startsWith('image/')) {
              if (description.isNotEmpty) {
                descriptionLines.add('[Attached Image "$name" Description: $description]');
              } else if (isLatestUserMsg && b64.isNotEmpty) {
                descriptionLines.add('[Attached Image Name: "$name", URL: "$url"]');
                remainingImageUrls.add({
                  'type': 'image_url', 
                  'image_url': {'url': 'data:$mime;base64,$b64'}
                });
              } else {
                descriptionLines.add('[Attached Image "$name" (No description available)]');
              }
            }
          }
          
          if (descriptionLines.isNotEmpty || remainingImageUrls.isNotEmpty) {
            final StringBuffer textBuffer = StringBuffer(m.text);
            if (descriptionLines.isNotEmpty) {
              if (textBuffer.isNotEmpty) textBuffer.writeln();
              textBuffer.write(descriptionLines.join('\n'));
            }
            final content = <Map<String, dynamic>>[{'type': 'text', 'text': textBuffer.toString()}];
            content.addAll(remainingImageUrls);
            history.add({'role': 'user', 'content': content});
          } else {
            history.add({'role': 'user', 'content': m.text});
          }
        } else {
          history.add({'role': 'user', 'content': m.text});
        }
      } else {
        final contentText = m.text.trim().isEmpty ? '[วิเคราะห์และดำเนินการสำเร็จ]' : m.text;
        final assistantEntry = <String, dynamic>{'role': 'assistant', 'content': contentText};
        history.add(assistantEntry);
      }
    }
    return history;
  }

  // Public test helper to expose history conversion
  List<Map<String, dynamic>> testConvertMessagesToAgentHistory(List<ChatMessage> msgs) {
    return _convertMessagesToAgentHistory(msgs);
  }

  // ─── Build draft from function call ───────────────────────────────────────
  Future<ProposalDraft?> _buildDraft(FunctionCall fc) async {
    const mutateActions = [
      'create_personal_task',
      'create_team_task',
      'update_team_task',
      'delete_team_task',
      'move_team_task',
      'synthetic_batch'
    ];
    if (!mutateActions.contains(fc.name)) {
      _draft = null;
      notifyListeners();
      return null;
    }

    final args = fc.args;
    final boardHint = (args['team_id'] ?? args['board_id'] ?? '').toString();
    final currentUid = AuthService().currentUser?.uid ?? '';

    // 1. Fetch common data
    List<BoardModel> boards = [];
    if (currentUid.isNotEmpty) {
      try { boards = await ApiCloudflare.getBoards(currentUid); } catch (_) {}
    }

    // 2. Fetch existing task(s) for mutations
    List<TaskModel> existingTasks = [];
    final needsFetch = fc.name == 'update_team_task' || fc.name == 'delete_team_task' || fc.name == 'move_team_task' || fc.name == 'synthetic_batch';
    final Set<String> idsToFetch = <String>{};

    if (needsFetch && currentUid.isNotEmpty) {
      try {
        if (args['id'] != null) idsToFetch.add(args['id'].toString());
        if (args['ids'] is List) {
          for (final id in (args['ids'] as List)) {
            idsToFetch.add(id.toString());
          }
        }
        final multi = args['_multi_payloads'] as List?;
        if (fc.name == 'synthetic_batch' && args['tasks'] is List) {
          for (final t in (args['tasks'] as List)) {
            final tid = (t as Map)['id'];
            if (tid != null) idsToFetch.add(tid.toString());
          }
        }
        if (multi != null) {
          for (final p in multi) {
            final pid = (p as Map)['id'] ?? p['ids'];
            if (pid != null) {
              if (pid is List) {
                for (final id in pid) {
                  idsToFetch.add(id.toString());
                }
              } else {
                idsToFetch.add(pid.toString());
              }
            }
          }
        }

        if (idsToFetch.isNotEmpty) {
          final Set<String> remainingIds = Set.from(idsToFetch);
          for (final b in boards) {
            if (remainingIds.isEmpty) break;
            final tasks = await ApiCloudflare.getTasksByBoard(b.id);
            for (final t in tasks) {
              if (remainingIds.contains(t.id)) {
                existingTasks.add(t);
                remainingIds.remove(t.id);
              }
            }
          }
          if (remainingIds.isNotEmpty) {
            final pTasks = await DbPersonalSqlite.instance.getAllTasks();
            for (final t in pTasks) {
              if (remainingIds.contains(t.id)) {
                existingTasks.add(t);
                remainingIds.remove(t.id);
              }
            }
          }
        }
      } catch (_) {}
    }

    // Task 7.3.1: Desync Guard
    if (needsFetch && existingTasks.isEmpty && idsToFetch.isNotEmpty) {
      addMessage(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: '⚠️ **ไม่พบข้อมูลงานที่ต้องการแก้ไข**\n\nระบบไม่พบงานที่ตรงกับ ID ที่ระบุ กรุณาลองตรวจสอบชื่อคอลัมน์หรือข้อมูลอีกครั้งครับ',
        isUser: false,
      ));
      _draft = null;
      notifyListeners();
      return null;
    }

    // 3. Determine selected board
    BoardModel? selectedBoard;
    String boardId = boardHint;
    if (needsFetch && existingTasks.isNotEmpty) {
      final taskBoardId = existingTasks.first.boardId;
      if (taskBoardId.isNotEmpty) boardId = taskBoardId;
    }
    if (boards.isNotEmpty) {
      if (boardId.isNotEmpty) {
        selectedBoard = boards.where((b) => b.id == boardId || b.name == boardId).firstOrNull;
      }
      selectedBoard ??= boards.first;
      boardId = selectedBoard.id;
    }

    // 4. Create draftedTasks list (UNLIMITED ROBUST PARSING)
    List<TaskDraftItem> draftedTasks = [];
    try {
      final List rawTasks = (fc.name == 'synthetic_batch') 
          ? (args['tasks'] is List ? args['tasks'] as List : [])
          : [args];

      for (final t in rawTasks) {
        if (t == null) continue;
        try {
          final tMap = Map<String, dynamic>.from(t as Map);
          final String? tId = tMap['id']?.toString();
          
          TaskModel? original;
          if (tId != null) {
            original = existingTasks.where((et) => et.id == tId).firstOrNull;
          }

          // Use fallback chain to ensure title is never null
          final String title = tMap['title']?.toString() ?? original?.title ?? 'Untitled Strategic Task';
          final String? action = tMap['_original_action']?.toString() ?? (fc.name == 'synthetic_batch' ? null : fc.name);
          
          draftedTasks.add(TaskDraftItem(
            originalAction: action,
            id: tId,
            title: title,
            dueDate: DateTime.tryParse(tMap['due_date']?.toString() ?? '') ?? original?.dueDate ?? DateTime.now(),
            description: tMap['description']?.toString() ?? original?.description ?? '',
            column: tMap['status']?.toString() ?? original?.status ?? 'todo',
            isCompleted: tMap['is_completed'] as bool? ?? original?.isCompleted ?? false,
            members: tMap['members'] is List ? (tMap['members'] as List).map((e) => e.toString()).toList() : (original?.members ?? []),
            labelIds: tMap['label_ids'] is List ? (tMap['label_ids'] as List).map((e) => e.toString()).toList() : (original?.labelIds ?? []),
            originalTitle: original?.title,
            originalDescription: original?.description,
            originalDueDate: original?.dueDate,
            originalMembers: original?.members,
            originalLabelIds: original?.labelIds,
            originalIsCompleted: original?.isCompleted,
            originalColumn: original?.status,
            originalUpdatedAt: original?.updatedAt,
          ));
        } catch (e) {
          debugPrint('Error parsing task in unlimited loop: $e');
          // Continue to next task so we don't break the whole batch
        }
      }
    } catch (e) {
      debugPrint('CRITICAL: Batch parsing root failure: $e');
    }
    // 5. Final setup (Board Scoring & Global Mapping)
    if (draftedTasks.isNotEmpty && fc.name == 'create_team_task') {
      final scoringTitle = draftedTasks.first.title;
      boards.sort((a, b) => _scoreBoard(scoringTitle, b).compareTo(_scoreBoard(scoringTitle, a)));
    }

    final allMemberUids = <String>{};
    if (selectedBoard != null) allMemberUids.addAll(selectedBoard.members);
    for (final t in existingTasks) {
      allMemberUids.addAll(t.members);
    }
    
    Map<String, Map<String, String>> userProfiles = {};
    if (allMemberUids.isNotEmpty) {
      try { userProfiles = await ApiCloudflare.getUsersByUids(allMemberUids.toList()); } catch (_) {}
    }
    final Map<String, String> memberNames = userProfiles.map((key, val) => MapEntry(key, val['name'] ?? key));

    List<String> mappedGlobalMembers = _mapNamesToUids(
      args['members'] is List ? (args['members'] as List).map((e) => e.toString()).toList() : [],
      allMemberUids.toList(),
      memberNames,
      currentUid,
    );

    // Map names to UIDs for each task if they came as raw names
    for (var task in draftedTasks) {
       if (task.members.isNotEmpty) {
          task.members = _mapNamesToUids(task.members, allMemberUids.toList(), memberNames, currentUid);
       }
       if (task.members.isEmpty && mappedGlobalMembers.isNotEmpty) {
          task.members = List<String>.from(mappedGlobalMembers);
       }
    }

    _draft = ProposalDraft(
      originalCall: fc,
      tasks: draftedTasks,
      boardId: boardId,
      column: draftedTasks.isNotEmpty ? draftedTasks.first.column : (selectedBoard?.columns.firstOrNull ?? 'todo'),
      members: mappedGlobalMembers,
      boardOptions: boards.take(5).toList(),
      selectedBoard: selectedBoard,
      memberNames: memberNames,
    );
    notifyListeners();
    return _draft;
  }

  // ─── Mutation Helpers ──────────────────────────────────────────────────────
  void updateDraftTitle(int index, String newTitle) {
    if (_draft != null && index >= 0 && index < _draft!.tasks.length) {
      _draft!.tasks[index].title = newTitle;
      notifyListeners();
    }
  }

  void updateDraftTime(int index, DateTime newTime) {
    if (_draft != null && index >= 0 && index < _draft!.tasks.length) {
      _draft!.tasks[index].dueDate = newTime;
      notifyListeners();
    }
  }

  void updateDraftDueDate(int index, DateTime? newDueDate) {
    if (_draft != null && index >= 0 && index < _draft!.tasks.length) {
      _draft!.tasks[index].dueDate = newDueDate ?? DateTime.now();
      notifyListeners();
    }
  }

  void updateDraftDescription(int index, String newDesc) {
    if (_draft != null && index >= 0 && index < _draft!.tasks.length) {
      _draft!.tasks[index].description = newDesc;
      notifyListeners();
    }
  }

  void updateDraftItemColumn(int index, String col) {
    if (_draft != null && index >= 0 && index < _draft!.tasks.length) {
      _draft!.tasks[index].column = col;
      notifyListeners();
    }
  }

  void updateDraftIsCompleted(int index, bool val) {
    if (_draft != null && index >= 0 && index < _draft!.tasks.length) {
      _draft!.tasks[index].isCompleted = val;
      notifyListeners();
    }
  }

  void updateDraftItemLabels(int index, String labelId) {
    if (_draft != null && index >= 0 && index < _draft!.tasks.length) {
      final task = _draft!.tasks[index];
      final current = List<String>.from(task.labelIds);
      if (current.contains(labelId)) {
        current.remove(labelId);
      } else {
        current.add(labelId);
      }
      task.labelIds = current;
      notifyListeners();
    }
  }

  void updateDraftItemMembers(int index, String uid) {
    if (_draft == null || index < 0 || index >= _draft!.tasks.length) return;
    if (_draft!.tasks[index].members.contains(uid)) {
      _draft!.tasks[index].members.remove(uid);
    } else {
      _draft!.tasks[index].members.add(uid);
    }
    notifyListeners();
  }

  // Task 9.2: Interactive Draft Helpers
  void toggleDraftItemSelection(int index) {
    if (_draft != null && index >= 0 && index < _draft!.tasks.length) {
      _draft!.tasks[index].isSelected = !_draft!.tasks[index].isSelected;
      notifyListeners();
    }
  }

  void updateDraftItemTitle(int index, String val) {
    if (_draft != null && index >= 0 && index < _draft!.tasks.length) {
      _draft!.tasks[index].title = val;
      notifyListeners();
    }
  }

  void updateDraftItemDescription(int index, String val) {
    if (_draft != null && index >= 0 && index < _draft!.tasks.length) {
      _draft!.tasks[index].description = val;
      notifyListeners();
    }
  }

  void updateDraftItemDueDate(int index, DateTime val) {
    if (_draft != null && index >= 0 && index < _draft!.tasks.length) {
      _draft!.tasks[index].dueDate = val;
      notifyListeners();
    }
  }

  void updateDraftBoard(BoardModel board) {
    if (_draft == null) return;
    _draft!.boardId = board.id;
    _draft!.selectedBoard = board;
    for (final task in _draft!.tasks) {
      if (!board.columns.contains(task.column)) {
        task.column = _guessColumn(task.title, board);
      }
    }
    notifyListeners();
  }

  // ─── Submit / Cancel ───────────────────────────────────────────────────────
  Future<void> submitDraft() async {
    if (_draft == null) return;
    _isTyping = true;
    notifyListeners();

    final d = _draft!;
    final batchFns = ['update_team_task', 'move_team_task', 'delete_team_task', 'synthetic_batch'];

    // ─── Phase 4: Mutation Conflict Guard ──────────────────────────────────────
    if (d.boardId.isNotEmpty) {
      try {
        final latestTasks = await ApiCloudflare.getTasksByBoard(d.boardId);
        bool hasConflict = false;
        List<String> conflictDetails = [];
        
        for (final t in d.tasks) {
        if (!t.isSelected) continue; // Task 30.3: Selective Submission

          if (t.id == null || t.originalUpdatedAt == null) continue;
          
          final latestTask = latestTasks.where((x) => x.id == t.id).firstOrNull;
          if (latestTask != null && latestTask.updatedAt > t.originalUpdatedAt!) {
             hasConflict = true;
             conflictDetails.add('งาน "${t.title}"');
          }
        }
        
        if (hasConflict) {
          _isTyping = false;
          addMessage(ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(), 
            text: '⚠️ **พบข้อขัดแย้งของข้อมูล (Data Conflict)**\n\n'
                  'มีสมาชิกคนอื่นในทีมเพิ่งอัปเดตข้อมูลเหล่านี้ในขณะที่คุณกำลังแก้ไข:\n'
                  '${conflictDetails.map((e) => "- $e").join('\n')}\n\n'
                  'เพื่อป้องกันข้อมูลทับซ้อน ระบบได้ยกเลิกการแก้ไขนี้ โปรดตรวจสอบข้อมูลล่าสุดก่อนดำเนินการต่อครับ', 
            isUser: false,
          ));
          _draft = null;
          notifyListeners();
          return;
        }
      } catch (e) {
        debugPrint('Conflict check failed: $e');
        // If fetch fails, we proceed with caution or log it
      }
    }

    if (batchFns.contains(d.originalCall.name) || d.originalCall.name == 'create_team_task' || d.originalCall.name == 'synthetic_batch') {
      int successCount = 0;
      List<String> errors = [];
      List<String> execLogs = []; // Task 33.3: Unified Itemized Logs
      List<ToolCallInfo> finalToolCalls = []; 

      for (final t in d.tasks) {
        if (!t.isSelected) {
          execLogs.add('CANCELLED: ${t.title}');
          continue;
        }

        final Map<String, dynamic> args = {'id': t.id};
        String actionName = t.originalAction ?? 'create_team_task';
        String itemLogPrefix = '';
        
        if (actionName == 'delete_team_task') {
          itemLogPrefix = 'DELETED';
        } else if (actionName == 'move_team_task') {
          itemLogPrefix = 'MOVED';
          args['status'] = t.column;
          if (t.isCompleted != t.originalIsCompleted) {
             args['is_completed'] = t.isCompleted;
             itemLogPrefix = t.isCompleted ? 'MOVED & COMPLETED' : 'MOVED & UPDATED';
          }
        } else if (t.id != null) {
          actionName = 'update_team_task';
          itemLogPrefix = 'UPDATED';
          if (t.title != t.originalTitle) args['title'] = t.title;
          if (t.description != t.originalDescription) args['description'] = t.description;
          if (t.isCompleted != t.originalIsCompleted) {
            args['is_completed'] = t.isCompleted;
            itemLogPrefix = t.isCompleted ? 'COMPLETED' : 'UPDATED';
          }
          if (t.column != t.originalColumn) args['status'] = t.column;
          if (t.dueDate != t.originalDueDate) args['due_date'] = t.dueDate.toIso8601String();
          
          bool membersChanged = t.members.length != (t.originalMembers?.length ?? 0);
          if (!membersChanged && t.originalMembers != null) {
             for (var m in t.members) {
               if (!t.originalMembers!.contains(m)) { membersChanged = true; break; }
             }
          }
          if (membersChanged) args['members'] = t.members;

          bool labelsChanged = t.labelIds.length != (t.originalLabelIds?.length ?? 0);
          if (!labelsChanged && t.originalLabelIds != null) {
             for (var l in t.labelIds) {
               if (!t.originalLabelIds!.contains(l)) { labelsChanged = true; break; }
             }
          }
          if (labelsChanged) args['label_ids'] = t.labelIds;
          
          if (args.length == 1) continue; 
        } else {
          actionName = 'create_team_task';
          itemLogPrefix = 'CREATED';
          args['title'] = t.title;
          args['description'] = t.description;
          args['due_date'] = t.dueDate.toIso8601String();
          args['status'] = t.column;
          args['members'] = t.members;
          args['label_ids'] = t.labelIds;
          args['is_completed'] = t.isCompleted;
          args['board_id'] = d.boardId.isNotEmpty ? d.boardId : (d.selectedBoard?.id ?? '');
          if (t.isCompleted) itemLogPrefix = 'CREATED & COMPLETED';
        }

        final res = await _agent.executePending(FunctionCall(actionName, args));
        
        if (res.contains('Error') || res.contains('Failed')) {
          errors.add('FAILED "${t.title}": $res');
        } else {
          successCount++;
          execLogs.add('$itemLogPrefix: ${t.title}');
          finalToolCalls.add(ToolCallInfo(name: actionName, arguments: args));
        }
      }
      
      d.executionLogs = execLogs; // Attach to draft for card rendering
      d.isConfirmed = true;
      
      final msgIdx = _messages.indexWhere((m) => !m.isUser && m.hasDraft && m.confirmedDraft == null);
      if (msgIdx != -1) {
         final oldMsg = _messages[msgIdx];
         _messages[msgIdx] = ChatMessage(
           id: oldMsg.id,
           text: oldMsg.text,
           reasoning: oldMsg.reasoning,
           isUser: oldMsg.isUser,
           hasDraft: true,
           pendingCall: oldMsg.pendingCall,
           toolCalls: oldMsg.toolCalls, 
           draft: oldMsg.draft, 
           confirmedDraft: d,
           timestamp: oldMsg.timestamp,
         );
      }

      _draft = null;
      _isTyping = false;
      
      if (errors.isNotEmpty) {
        addMessage(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(), 
          text: 'ERRORS DETECTED:\n${errors.join('\n')}', 
          isUser: false
        ));
      }
      
      notifyListeners();
      return;
    }
    final updatedArgs = Map<String, Object?>.from(d.originalCall.args);
    final result = await _agent.executePending(FunctionCall(d.originalCall.name, updatedArgs));
    
    d.isConfirmed = true;
    final msgIdx = _messages.indexWhere((m) => !m.isUser && m.hasDraft && m.confirmedDraft == null);
    if (msgIdx != -1) {
       final oldMsg = _messages[msgIdx];
       _messages[msgIdx] = ChatMessage(
         id: oldMsg.id,
         text: oldMsg.text,
         reasoning: oldMsg.reasoning,
         isUser: oldMsg.isUser,
         hasDraft: true,
         pendingCall: oldMsg.pendingCall,
         toolCalls: oldMsg.toolCalls, draft: oldMsg.draft, confirmedDraft: d,
         timestamp: oldMsg.timestamp,
       );
    }

    _draft = null;
    _isTyping = false;
    addMessage(ChatMessage(id: DateTime.now().millisecondsSinceEpoch.toString(), text: result, isUser: false));
    notifyListeners();
  }

  void updateMoveTargetColumn(String newCol) {
    if (_draft != null && _draft!.originalCall.name == 'move_team_task') {
      final newArgs = Map<String, Object?>.from(_draft!.originalCall.args);
      newArgs['status'] = newCol;
      _draft!.originalCall = FunctionCall('move_team_task', newArgs);
      
      // สำคัญ: ต้องอัปเดตฟิลด์ column ของทุกงานในดราฟต์ด้วย
      for (var t in _draft!.tasks) {
        t.column = newCol;
      }
      
      notifyListeners();
    }
  }

  void cancelDraft() {
    _draft = null;
    addMessage(ChatMessage(id: DateTime.now().millisecondsSinceEpoch.toString(), text: 'ยกเลิกแผนดำเนินการแล้วครับ', isUser: false));
    notifyListeners();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  List<String> _mapNamesToUids(List<String> rawNames, List<String> availableUids, Map<String, String> memberNames, [String? currentUid]) {
    if (rawNames.isEmpty) return [];
    final namesFromAi = rawNames.map((e) => e.toLowerCase().trim()).toList();
    Set<String> resultSet = {};
    
    if (namesFromAi.any((n) => n == 'all' || n == 'ทุกคน')) {
      resultSet.addAll(availableUids);
    }
    
    for (final uid in availableUids) {
      final name = (memberNames[uid] ?? '').toLowerCase().trim();
      if (name.isEmpty) continue;
      
      for (final aiN in namesFromAi) {
        // Fuzzy match: check if name contains AI name or vice versa
        // Useful for "พี่เจ" vs "เจ", "น้องนก" vs "นก"
        if (name.contains(aiN) || aiN.contains(name)) {
          resultSet.add(uid);
          break;
        }
      }
    }
    
    // If "me" or "ผม/ฉัน" mentioned, add current user
    final meKeywords = ['me', 'ผม', 'ฉัน', 'เรา', 'หนู', 'i'];
    if (namesFromAi.any((n) => meKeywords.contains(n)) && currentUid != null) {
      resultSet.add(currentUid);
    }

    return resultSet.toList();
  }

  int _scoreBoard(String text, BoardModel board) {
    final lower = text.toLowerCase();
    int score = 0;
    if (lower.contains(board.name.toLowerCase())) score += 5;
    return score;
  }

  String _guessColumn(String text, BoardModel? board) {
    if (board == null || board.columns.isEmpty) return 'todo';
    final lower = text.toLowerCase();
    if (lower.contains('เสร็จ') || lower.contains('จบ')) return board.columns.last;
    return board.columns.first;
  }
}
