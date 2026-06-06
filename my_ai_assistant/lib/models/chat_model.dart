import 'package:google_generative_ai/google_generative_ai.dart';
import 'board_model.dart';

class ToolCallInfo {
  final String name;
  final Map<String, dynamic> arguments;
  ToolCallInfo({required this.name, required this.arguments});
}

// ─── TaskDraftItem — individual task in a proposal ───────────────────────────
class TaskDraftItem {
  String? originalAction; // The specific tool call name for this task (create, move, delete, etc.)
  String? originalTitle;
  String? originalDescription;
  DateTime? originalDueDate;
  List<String>? originalMembers;
  List<String>? originalLabelIds;
  String? id;           // Original task ID (for update/delete/move)
  String title;
  DateTime dueDate;
  String description;
  String? aiColumnHint; // AI-suggested column for this task
  String column;        // Actual selected column (per-task)
  String? originalColumn; // Original column before edit
  bool isCompleted;
  bool? originalIsCompleted; // Original status before edit
  int? originalUpdatedAt; // Add this field for conflict detection
  List<String> members; // UIDs assigned to this specific task
  List<String> labelIds;
  bool isSelected; // For multi-task selection (e.g., choosing which items to delete)

  TaskDraftItem({
    this.originalAction,
    this.originalTitle,
    this.originalDescription,
    this.originalDueDate,
    this.originalMembers,
    this.originalLabelIds,
    this.id,
    required this.title,
    required this.dueDate,
    this.description = '',
    this.aiColumnHint,
    this.column = 'todo',
    this.originalColumn,
    this.isCompleted = false,
    this.originalIsCompleted,
    this.originalUpdatedAt,
    this.isSubmitting = false,
    this.isSelected = true,
    List<String>? members,
    List<String>? labelIds,
  }) : members = members ?? [], labelIds = labelIds ?? [];

  bool isSubmitting;
}

// ─── ProposalDraft — mutable draft that user can edit before submit ───────────
class ProposalDraft {
  FunctionCall originalCall;
  List<TaskDraftItem> tasks;
  String boardId;
  String column;
  List<String> members;
  List<BoardModel> boardOptions;
  BoardModel? selectedBoard;
  Map<String, String> memberNames;
  List<String> executionLogs; // Task 33.2: Store itemized results

  ProposalDraft({
    required this.originalCall,
    required this.tasks,
    this.boardId = '',
    this.column = 'todo',
    this.members = const [],
    this.boardOptions = const [],
    this.selectedBoard,
    this.memberNames = const {},
    this.executionLogs = const [],
  });

  List<String> get availableColumns =>
      selectedBoard?.columns ?? ['todo', 'doing', 'done'];

  bool get isTeamTask =>
      originalCall.name == 'create_team_task' ||
      originalCall.name == 'update_team_task' ||
      originalCall.name == 'delete_team_task' ||
      originalCall.name == 'move_team_task';

  bool get needsBoardSelection =>
      (originalCall.name == 'create_team_task') && (boardId.isEmpty);

  bool isConfirmed = false;
}

class ChatMessage {
  final String id;
  final String text;
  final String? reasoning; // AI's internal thought process
  final bool isUser;
  final bool hasDraft; 
  final ProposalDraft? draft; // Current active draft attached to this message
  final bool isConflictAlert; // High-visibility conflict notification
  final dynamic pendingCall; // The call that generated the draft
  final List<ToolCallInfo> toolCalls; // Detailed tool calls in this turn
  final ProposalDraft? confirmedDraft; // Store the draft even after confirmation
  final List<Map<String, String>> attachments; // Attached files {name, url, mime}
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    this.reasoning,
    required this.isUser,
    this.hasDraft = false,
    this.draft,
    this.isConflictAlert = false,
    this.pendingCall,
    this.toolCalls = const [],
    this.confirmedDraft,
    this.attachments = const [],
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AiReply {
  final String text;
  final String? reasoning;
  final FunctionCall? pendingCall;
  final List<ToolCallInfo> toolCalls;
  final Stream<String>? stream;

  AiReply({
    required this.text,
    this.reasoning,
    this.pendingCall,
    this.toolCalls = const [],
    this.stream,
  });
}

class ChatSession {
  final String id;
  final String uid;
  final String taskId;
  final String name;
  final DateTime createdAt;
  final int updatedAt;

  ChatSession({
    required this.id,
    required this.uid,
    this.taskId = '',
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatSession.fromMap(Map<String, dynamic> map) {
    return ChatSession(
      id: map['id'] as String? ?? '',
      uid: map['uid'] as String? ?? '',
      taskId: map['task_id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: map['updated_at'] is int ? map['updated_at'] as int : 0,
    );
  }
}

