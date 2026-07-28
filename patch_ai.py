import re

with open('/home/kimbiaw/calenda/calenda_flow/my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart', 'r') as f:
    content = f.read()

# 1. Update imports
content = content.replace("import '../../../models/ai_chat_session.dart';", "import '../../../models/chat_model.dart';\nimport '../../../services/auth_service.dart';")

# 2. Update constructor
content = content.replace("final List<AiChatSession>? initialSessions;", "final String targetId;")
content = content.replace("this.initialSessions,", "required this.targetId,")

# 3. Update state variables
content = content.replace("List<AiChatSession> _sessions = [];", "List<ChatSession> _sessions = [];")
content = content.replace("List<Map<String, String>> _chatMessages = [];", "List<ChatMessage> _chatMessages = [];")

# 4. _showRenameSessionDialog
old_rename = """  Future<void> _showRenameSessionDialog(int index) async {
    final controller = TextEditingController(text: _sessions[index].title);
    final newTitle = await showDialog<String>("""
new_rename = """  Future<void> _showRenameSessionDialog(int index) async {
    final session = _sessions[index];
    final controller = TextEditingController(text: session.name);
    final newTitle = await showDialog<String>("""
content = content.replace(old_rename, new_rename)

old_rename_save = """    if (newTitle != null && newTitle.isNotEmpty) {
      setState(() {
        _sessions[index] = _sessions[index].copyWith(title: newTitle);
        _syncCurrentSession();
      });
    }"""
new_rename_save = """    if (newTitle != null && newTitle.isNotEmpty) {
      final uid = AuthService().currentUser?.uid ?? 'temp';
      await ApiCloudflare.insertChatSession(session.id, uid, newTitle, taskId: widget.targetId);
      setState(() {
        _sessions[index] = ChatSession(
          id: session.id,
          uid: session.uid,
          taskId: session.taskId,
          name: newTitle,
          createdAt: session.createdAt,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
      });
    }"""
content = content.replace(old_rename_save, new_rename_save)

# 5. initState
old_init_state = """  @override
  void initState() {
    super.initState();
    if (widget.initialSessions != null && widget.initialSessions!.isNotEmpty) {
      _sessions = List.from(widget.initialSessions!);
    } else {
      _sessions = [
        AiChatSession(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'เสสชัน 1',
        ),
      ];
    }
    _activeSessionIndex = _sessions.length - 1;
    _summaryOutput = _sessions[_activeSessionIndex].summaryText;
    _chatMessages = List.from(_sessions[_activeSessionIndex].messages);
    _includeNotes = widget.notesText.trim().isNotEmpty;"""

new_init_state = """  @override
  void initState() {
    super.initState();
    _initSessions();
    _includeNotes = widget.notesText.trim().isNotEmpty;"""

content = content.replace(old_init_state, new_init_state)

init_funcs = """
  Future<void> _initSessions() async {
    final uid = AuthService().currentUser?.uid ?? 'temp';
    final fetched = await ApiCloudflare.getChatSessions(uid, taskId: widget.targetId);
    if (fetched.isNotEmpty) {
      _sessions = fetched;
      _activeSessionIndex = _sessions.length - 1;
    } else {
      final newSessId = '${widget.targetId}_${DateTime.now().millisecondsSinceEpoch}';
      await ApiCloudflare.insertChatSession(newSessId, uid, 'เสสชัน 1', taskId: widget.targetId);
      _sessions = [
        ChatSession(
          id: newSessId,
          uid: uid,
          taskId: widget.targetId,
          name: 'เสสชัน 1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        )
      ];
      _activeSessionIndex = 0;
    }
    await _loadCurrentSessionMessages();
  }

  Future<void> _loadCurrentSessionMessages() async {
    if (_sessions.isEmpty) return;
    final sessionId = _sessions[_activeSessionIndex].id;
    final msgs = await ApiCloudflare.getChatMessages(sessionId);
    if (mounted) {
      setState(() {
        _chatMessages = msgs;
        final lastAiMsg = msgs.where((m) => !m.isUser).toList().lastOrNull;
        _summaryOutput = lastAiMsg?.text ?? '';
      });
      if (_outputTabIndex == 1) {
        _scrollToBottom();
      }
    }
  }
"""
content = content.replace("  @override\n  void dispose() {", init_funcs + "\n  @override\n  void dispose() {")


with open('/home/kimbiaw/calenda/calenda_flow/my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart', 'w') as f:
    f.write(content)
