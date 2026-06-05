import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/chat_model.dart';
import '../models/board_model.dart';
import '../models/task_model.dart';
import '../ai_agent/core/misty_agent.dart';
import '../services/auth_service.dart';
import '../databases/api_cloudflare.dart';
import '../databases/db_personal_sqlite.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

// ─── StateChat ──────────────────────────────────────────────────────────────
class StateChat extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  late MistyAgent _agent;
  final String _provider = 'cf'; // Kept for compatibility if UI needs it
  final String _cfModel = MistyAgent.cfModelId;

  bool _isTyping = false;
  ProposalDraft? _draft;

  StateChat() {
    _initRouter();
  }

  Future<void> _initRouter() async {
    _agent = MistyAgent();
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
  final List<PlatformFile> _pendingFiles = [];
  List<PlatformFile> get pendingFiles => _pendingFiles;
  List<Map<String, String>> get pendingFileMaps => _pendingFiles.map((f) => {
    'name': f.name,
    'mime': _guessMimeType(f.name),
    'size': f.size.toString(),
  }).toList();

  Future<void> pickFiles() async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        _pendingFiles.addAll(result.files);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error picking files: $e');
    }
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

  List<ChatMessage> get messages => _messages;
  bool get isTyping => _isTyping;
  ProposalDraft? get draft => _draft;

  void addMessage(ChatMessage message) {
    _messages.insert(0, message);
    notifyListeners();
  }

  void resetFullChat() {
    _messages.clear();
    _draft = null;
    _agent.resetSession();
    notifyListeners();
  }

  // ─── Send message ──────────────────────────────────────────────────────────
  Future<void> sendMessageToAI(String text, [String? boardId]) async {
    if (text.trim().isEmpty && _pendingFiles.isEmpty) return;
    if (_isTyping) return;

    final attachmentsToDisplay = _pendingFiles.map((f) => {
      'name': f.name,
      'mime': _guessMimeType(f.name),
      'size': f.size.toString(),
    }).toList();

    addMessage(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      attachments: attachmentsToDisplay,
    ));

    _isTyping = true;
    notifyListeners();

    // ─── Phase 2: R2 Upload Pipeline ──────────────────────────────────────────
    final List<Map<String, String>> uploadedAttachments = [];
    final List<PlatformFile> filesToUpload = List.from(_pendingFiles);
    clearPendingFiles();

    for (final file in filesToUpload) {
      try {
        final bytes = file.bytes;
        if (bytes == null) continue;
        final res = await ApiCloudflare.uploadImage(
          bytes, 
          file.name, 
          path: 'tmp', // Transient storage
        );
        if (res['url'] != null) {
          uploadedAttachments.add({
            'name': file.name,
            'url': res['url'].toString(),
            'mime': _guessMimeType(file.name),
            'b64': base64Encode(bytes),
          });
        }
      } catch (e) {
        debugPrint('Upload failed for ${file.name}: $e');
      }
    }

    // ─── Phase 1: Context injection is now handled automatically by MistyAgent
    // We don't need background query calls here anymore.

    // Route to unified provider
    final reply = await _agent.processMessageStream(text, attachments: uploadedAttachments);
        
    _isTyping = false;

    // Create the message object
    final aiMessageId = DateTime.now().millisecondsSinceEpoch.toString();
    final aiMessage = ChatMessage(
      id: aiMessageId,
      text: reply.text, // Could be empty if streaming
      reasoning: reply.reasoning,
      isUser: false,
      hasDraft: reply.pendingCall != null,
      pendingCall: reply.pendingCall,
      toolCalls: reply.toolCalls,
    );
    
    addMessage(aiMessage);

    if (reply.stream != null) {
      // Handle streaming updates
      String fullText = reply.text;
      reply.stream!.listen((chunk) {
        fullText += chunk;
        // Update the message in the list
        final index = _messages.indexWhere((m) => m.id == aiMessageId);
        if (index != -1) {
          _messages[index] = ChatMessage(
            id: aiMessageId,
            text: fullText,
            reasoning: aiMessage.reasoning,
            isUser: false,
            hasDraft: aiMessage.hasDraft,
            pendingCall: aiMessage.pendingCall,
            toolCalls: aiMessage.toolCalls,
            timestamp: aiMessage.timestamp,
          );
          notifyListeners();
        }
      }, onDone: () {
        // Finalize if needed
        if (reply.pendingCall != null) {
          _buildDraft(reply.pendingCall!);
        }
      });
    } else {
      if (reply.pendingCall != null) {
        await _buildDraft(reply.pendingCall!);
      } else {
        _draft = null;
      }
    }

    notifyListeners();
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
          for (final id in (args['ids'] as List)) idsToFetch.add(id.toString());
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
                for (final id in pid) idsToFetch.add(id.toString());
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
    for (final t in existingTasks) allMemberUids.addAll(t.members);
    
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
             for (var m in t.members) if (!t.originalMembers!.contains(m)) { membersChanged = true; break; }
          }
          if (membersChanged) args['members'] = t.members;

          bool labelsChanged = t.labelIds.length != (t.originalLabelIds?.length ?? 0);
          if (!labelsChanged && t.originalLabelIds != null) {
             for (var l in t.labelIds) if (!t.originalLabelIds!.contains(l)) { labelsChanged = true; break; }
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
