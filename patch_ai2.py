import re

with open('/home/kimbiaw/calenda/calenda_flow/my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart', 'r') as f:
    content = f.read()

# 1. New Session button
old_new_session = """                onPressed: () {
                  _syncCurrentSession();
                  final newSession = AiChatSession(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: 'เสสชัน ${_sessions.length + 1}',
                  );
                  setState(() {
                    _sessions.add(newSession);
                    _activeSessionIndex = _sessions.length - 1;
                    _summaryOutput = '';
                    _chatMessages = [];
                    _outputTabIndex = 0;
                  });
                },"""
new_new_session = """                onPressed: () async {
                  final uid = AuthService().currentUser?.uid ?? 'temp';
                  final newSessId = '${widget.targetId}_${DateTime.now().millisecondsSinceEpoch}';
                  final newName = 'เสสชัน ${_sessions.length + 1}';
                  await ApiCloudflare.insertChatSession(newSessId, uid, newName, taskId: widget.targetId);
                  final newSession = ChatSession(
                    id: newSessId,
                    uid: uid,
                    taskId: widget.targetId,
                    name: newName,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now().millisecondsSinceEpoch,
                  );
                  setState(() {
                    _sessions.add(newSession);
                    _activeSessionIndex = _sessions.length - 1;
                    _summaryOutput = '';
                    _chatMessages = [];
                    _outputTabIndex = 0;
                  });
                },"""
content = content.replace(old_new_session, new_new_session)

# 2. Switch session
old_switch = """              onSelected: (selected) {
                if (selected && !isActive) {
                  _syncCurrentSession();
                  setState(() {
                    _activeSessionIndex = index;
                    _summaryOutput = _sessions[index].summaryText;
                    _chatMessages = List.from(_sessions[index].messages);
                  });
                  if (_outputTabIndex == 1) {
                    _scrollToBottom();
                  }
                }
              },"""
new_switch = """              onSelected: (selected) async {
                if (selected && !isActive) {
                  setState(() {
                    _activeSessionIndex = index;
                    _summaryOutput = '';
                    _chatMessages = [];
                  });
                  await _loadCurrentSessionMessages();
                }
              },"""
content = content.replace(old_switch, new_switch)
content = content.replace("Text(_sessions[index].title)", "Text(_sessions[index].name)")

# 3. syncCurrentSession
old_sync = """  void _syncCurrentSession() {
    _sessions[_activeSessionIndex] = _sessions[_activeSessionIndex].copyWith(
      summaryText: _summaryOutput,
      messages: _chatMessages,
    );
  }"""
new_sync = """  void _syncCurrentSession() {
    // Legacy method, not needed with DB-backed messages
  }"""
content = content.replace(old_sync, new_sync)

# 4. _handleSummarize saving
old_summarize_save = """      if (summaryResult.isNotEmpty) {
        final normalized = serializeBlocksToMarkdown(
          parseMarkdownToBlocks(summaryResult),
        );
        setState(() {
          _summaryOutput = normalized;
          _syncCurrentSession();
        });
      }"""
new_summarize_save = """      if (summaryResult.isNotEmpty) {
        final normalized = serializeBlocksToMarkdown(
          parseMarkdownToBlocks(summaryResult),
        );
        
        final userMsg = ChatMessage(id: DateTime.now().millisecondsSinceEpoch.toString(), text: 'สร้างสรุปข้อมูล', isUser: true);
        final aiMsg = ChatMessage(id: (DateTime.now().millisecondsSinceEpoch + 1).toString(), text: normalized, isUser: false);
        final sessionId = _sessions[_activeSessionIndex].id;
        
        await ApiCloudflare.insertChatMessage(userMsg, sessionId);
        await ApiCloudflare.insertChatMessage(aiMsg, sessionId);
        
        setState(() {
          _chatMessages.insert(0, aiMsg);
          _chatMessages.insert(0, userMsg);
          _summaryOutput = normalized;
        });
      }"""
content = content.replace(old_summarize_save, new_summarize_save)

# 5. _handleRefine prompt and saving
old_refine_start = """    try {
      final chatHistoryStr = _chatMessages
          .map(
            (msg) =>
                "${msg['role'] == 'user' ? 'ผู้ใช้' : 'AI'}: ${msg['text']}",
          )
          .join('\\n');
      final chatContext = _chatMessages.isNotEmpty
          ? '\\nประวัติการสนทนาและคำสั่งก่อนหน้านี้ (Chat History):\\n$chatHistoryStr\\n'
          : '';

      final prompt =
          '''
คุณคือผู้ช่วยเลขานุการ HR มืออาชีพ กรุณาอ่านข้อมูลจากเอกสารอ้างอิงและปรับปรุงแก้ไขสรุปข้อมูลปัจจุบันตามคำสั่งของผู้ใช้
$chatContext
ข้อมูลอ้างอิง (Ticked Files):
$_lastCombinedText

ข้อมูลสรุปปัจจุบัน:
$_summaryOutput

คำสั่งแก้ไขล่าสุด (Latest Instruction): $refineText

ข้อกำหนดที่สำคัญที่สุด:
1. ห้ามใส่อิโมจิ (Emoji) หรือสติกเกอร์สัญลักษณ์พิเศษใดๆ ในเอกสารเด็ดขาด (No emojis allowed at all)
2. เขียนสรุปเป็นภาษาไทยอย่างเป็นทางการและกระชับ สละสลวย เข้าใจง่ายสำหรับผู้บริหารและเลขา HR
3. รูปแบบ Markdown ที่อนุญาตให้ใช้มีเพียง 4 แบบเท่านั้น: หัวข้อใหญ่ขึ้นต้นด้วย "# " (มีเว้นวรรค), หัวข้อย่อยขึ้นต้นด้วย "## " (มีเว้นวรรค), รายการขึ้นต้นด้วย "- " (มีเว้นวรรค), และรายการสิ่งที่ต้องทำขึ้นต้นด้วย "- [ ] " หรือ "- [x] "
4. ห้ามใช้ตัวหนา (**), ตัวเอียง (*), อินไลน์โค้ด (`), หัวข้อระดับ "###" ขึ้นไป, เลขลำดับ (1. 2. 3.), หรือเส้นคั่น (---) โดยเด็ดขาด เพราะระบบแสดงผลรองรับเฉพาะ 4 รูปแบบในข้อ 3 เท่านั้น

แก้ไขและตอบกลับเป็นสรุปฉบับใหม่แบบเต็ม (คงรูปแบบ Markdown 4 แบบที่อนุญาตไว้เท่านั้น)
''';

      _refinePromptController.clear();
      setState(() {
        _chatMessages.add({'role': 'user', 'text': refineText});
        _outputTabIndex = 1;
      });"""

new_refine_start = """    try {
      final prompt =
          '''คุณคือผู้ช่วยเลขานุการ HR มืออาชีพที่มีหน้าที่สรุปและปรับปรุงเอกสาร
=== ข้อมูล RAG อ้างอิง (ไฟล์และบันทึกที่เลือก) ===
$_lastCombinedText

=== สรุปปัจจุบัน ===
$_summaryOutput

คำสั่งแก้ไขล่าสุด: $refineText

ข้อกำหนดที่สำคัญที่สุด:
1. ห้ามใส่อิโมจิ (Emoji) หรือสติกเกอร์สัญลักษณ์พิเศษใดๆ ในเอกสารเด็ดขาด (No emojis allowed at all)
2. เขียนสรุปเป็นภาษาไทยอย่างเป็นทางการและกระชับ สละสลวย เข้าใจง่ายสำหรับผู้บริหารและเลขา HR
3. รูปแบบ Markdown ที่อนุญาตให้ใช้มีเพียง 4 แบบเท่านั้น: หัวข้อใหญ่ขึ้นต้นด้วย "# " (มีเว้นวรรค), หัวข้อย่อยขึ้นต้นด้วย "## " (มีเว้นวรรค), รายการขึ้นต้นด้วย "- " (มีเว้นวรรค), และรายการสิ่งที่ต้องทำขึ้นต้นด้วย "- [ ] " หรือ "- [x] "
4. ห้ามใช้ตัวหนา (**), ตัวเอียง (*), อินไลน์โค้ด (`), หัวข้อระดับ "###" ขึ้นไป, เลขลำดับ (1. 2. 3.), หรือเส้นคั่น (---) โดยเด็ดขาด เพราะระบบแสดงผลรองรับเฉพาะ 4 รูปแบบในข้อ 3 เท่านั้น

แก้ไขและตอบกลับเป็นสรุปฉบับใหม่แบบเต็ม (คงรูปแบบ Markdown 4 แบบที่อนุญาตไว้เท่านั้น)
''';

      _refinePromptController.clear();
      final userMsg = ChatMessage(id: DateTime.now().millisecondsSinceEpoch.toString(), text: refineText, isUser: true);
      final sessionId = _sessions[_activeSessionIndex].id;
      await ApiCloudflare.insertChatMessage(userMsg, sessionId);
      
      setState(() {
        _chatMessages.insert(0, userMsg);
        _outputTabIndex = 1;
      });"""
content = content.replace(old_refine_start, new_refine_start)

old_refine_save = """      if (result.isNotEmpty) {
        final normalized = serializeBlocksToMarkdown(
          parseMarkdownToBlocks(result),
        );
        setState(() {
          _summaryOutput = normalized;
          _chatMessages.add({
            'role': 'assistant',
            'text': 'อัปเดตสรุปข้อมูลเรียบร้อยแล้วค่ะ',
          });
          _syncCurrentSession();
        });
        _scrollToBottom();
      }"""
new_refine_save = """      if (result.isNotEmpty) {
        final normalized = serializeBlocksToMarkdown(
          parseMarkdownToBlocks(result),
        );
        final aiMsg = ChatMessage(id: (DateTime.now().millisecondsSinceEpoch + 1).toString(), text: normalized, isUser: false);
        await ApiCloudflare.insertChatMessage(aiMsg, sessionId);
        setState(() {
          _summaryOutput = normalized;
          _chatMessages.insert(0, aiMsg);
        });
        _scrollToBottom();
      }"""
content = content.replace(old_refine_save, new_refine_save)

# 6. Chat messages list builder
old_list = """              : ListView.builder(
                  controller: _chatScrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: _chatMessages.length,
                  itemBuilder: (context, index) {
                    final msg = _chatMessages[index];
                    final isUser = msg['role'] == 'user';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUser
                            ? GlassColors.primary.withOpacity(0.2)
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isUser
                              ? GlassColors.primary.withOpacity(0.5)
                              : Colors.white12,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isUser ? Icons.person : Icons.auto_awesome,
                            color: isUser
                                ? GlassColors.primary
                                : GlassColors.gold,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              msg['text'] ?? '',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),"""

# Wait! The messages in StateChat are usually inserted at index 0 (newest at 0).
# But how does the list render? If we use reverse: true it's easier, or we just insert at length (at end).
# Let's fix the insert in summarize and refine to just use insert(0, msg). And UI to use reverse: true.
new_list = """              : ListView.builder(
                  controller: _chatScrollController,
                  padding: const EdgeInsets.all(20),
                  reverse: true,
                  itemCount: _chatMessages.length,
                  itemBuilder: (context, index) {
                    final msg = _chatMessages[index];
                    final isUser = msg.isUser;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUser
                            ? GlassColors.primary.withOpacity(0.2)
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isUser
                              ? GlassColors.primary.withOpacity(0.5)
                              : Colors.white12,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isUser ? Icons.person : Icons.auto_awesome,
                            color: isUser
                                ? GlassColors.primary
                                : GlassColors.gold,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              msg.text,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),"""
content = content.replace(old_list, new_list)

with open('/home/kimbiaw/calenda/calenda_flow/my_ai_assistant/lib/ui/meetings/widgets/ai_summarize_sheet.dart', 'w') as f:
    f.write(content)
