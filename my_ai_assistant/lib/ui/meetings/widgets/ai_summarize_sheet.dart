import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../databases/api_cloudflare.dart';
import '../../theme/glass_theme.dart';
import '../../common/glass_widgets.dart';
import 'markdown_block_editor.dart';
import '../../common/defer_pointer.dart';
import '../../../models/chat_model.dart';
import '../../../services/auth_service.dart';

class AiSummarizeSheet extends StatefulWidget {
  final bool isMeeting;
  final String notesText;
  final String mainTranscriptText;
  final List<Map<String, String>> recordingTakes;
  final List<Map<String, dynamic>> fileAttachments;
  final String targetId;
  final String? initialSummary;

  const AiSummarizeSheet({
    super.key,
    required this.isMeeting,
    required this.notesText,
    required this.mainTranscriptText,
    required this.recordingTakes,
    required this.fileAttachments,
    required this.targetId,
    this.initialSummary,
  });

  @override
  State<AiSummarizeSheet> createState() => _AiSummarizeSheetState();
}

class _AiSummarizeSheetState extends State<AiSummarizeSheet> {
  bool _includeNotes = false;
  bool _includeMainTranscript = false;
  final Map<String, bool> _includeTakes = {};
  final Map<int, bool> _includeFiles = {};

  final _customPromptController = TextEditingController();
  final _refinePromptController = TextEditingController();

  bool _isSummarizing = false;
  String _summarizingLabel = 'กำลังสรุปด้วย AI...';
  String _summaryOutput = '';

  String _lastCombinedText = '';

  List<ChatSession> _sessions = [];
  int _activeSessionIndex = 0;

  List<ChatMessage> _chatMessages = [];

  int _outputTabIndex = 0;
  final ScrollController _chatScrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _showRenameSessionDialog(int index) async {
    final session = _sessions[index];
    final controller = TextEditingController(text: session.name);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: GlassColors.surface,
          title: const Text('เปลี่ยนชื่อเสสชัน', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'ชื่อเสสชัน...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              filled: true,
              fillColor: const Color(0x80161926),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('บันทึก', style: TextStyle(color: GlassColors.gold)),
            ),
          ],
        );
      },
    );

    if (newTitle != null && newTitle.isNotEmpty) {
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
    }
  }

  @override
  void initState() {
    super.initState();
    _initSessions();
    _includeNotes = widget.notesText.trim().isNotEmpty;
    _includeMainTranscript = widget.mainTranscriptText.trim().isNotEmpty;
    for (final take in widget.recordingTakes) {
      final id = take['id'];
      if (id != null) {
        final trans = take['transcript'];
        if (trans != null && trans.trim().isNotEmpty && trans != '[]') {
          _includeTakes[id] = true;
        }
      }
    }
    for (var i = 0; i < widget.fileAttachments.length; i++) {
      _includeFiles[i] = true;
    }
  }


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
        final newestAiMsg = msgs.where((m) => !m.isUser).firstOrNull;
        _summaryOutput = newestAiMsg?.text ?? (widget.initialSummary ?? '');
      });
      if (_outputTabIndex == 1) {
        _scrollToBottom();
      }
    }
  }

  @override
  void dispose() {
    _customPromptController.dispose();
    _refinePromptController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSummarize() async {
    final anySelected =
        _includeNotes ||
        _includeMainTranscript ||
        _includeTakes.values.contains(true) ||
        _includeFiles.values.contains(true);

    if (!anySelected) {
      GlassNotifications.show(
        context,
        'กรุณาเลือกแหล่งข้อมูลอย่างน้อย 1 แหล่ง',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSummarizing = true;
      _summarizingLabel = 'กำลังอ่านข้อมูล...';
    });

    try {
      final buffer = StringBuffer();

      if (_includeNotes) {
        buffer.writeln(
          '=== ${widget.isMeeting ? "MEETING" : "DOCUMENT"} NOTES ===',
        );
        buffer.writeln(widget.notesText.trim());
        buffer.writeln();
      }

      if (_includeMainTranscript) {
        buffer.writeln('=== MAIN TRANSCRIPT ===');
        buffer.writeln(widget.mainTranscriptText.trim());
        buffer.writeln();
      }

      for (final take in widget.recordingTakes) {
        final takeId = take['id'];
        if (takeId != null && _includeTakes[takeId] == true) {
          buffer.writeln('=== TRANSCRIPT FOR TAKE: ${take['name']} ===');
          try {
            final List<dynamic> parsed = jsonDecode(take['transcript'] ?? '[]');
            for (final item in parsed) {
              if (item is Map) {
                final speaker = item['speaker'] ?? '?';
                final text = item['text'] ?? '';
                buffer.writeln('Speaker $speaker: $text');
              }
            }
          } catch (e) {
            debugPrint('[Error] parsing transcript: $e');
            buffer.writeln('(Error parsing transcript)');
          }
          buffer.writeln();
        }
      }

      for (final i in _includeFiles.keys) {
        if (_includeFiles[i] != true) continue;
        final att = widget.fileAttachments[i];
        var fileText = (att['extractedText'] ?? '').toString();
        if (fileText.isEmpty) {
          debugPrint('[UI][Extract] Reading ${att['name']}...');
          fileText = await ApiCloudflare.extractAttachmentText(att);
          if (fileText.isNotEmpty) {
            att['extractedText'] = fileText;
          }
        }
        if (fileText.isNotEmpty) {
          buffer.writeln('=== FILE: ${att['name'] ?? 'document'} ===');
          buffer.writeln(fileText);
          buffer.writeln();
        } else {
          buffer.writeln(
            'Reference attachment: ${att['name']} (${att['url']?.isEmpty ?? true ? 'no link' : att['url']})',
          );
        }
      }

      final combinedText = buffer.toString().trim();
      if (combinedText.isEmpty) {
        GlassNotifications.show(context, 'ไม่มีเนื้อหาให้สรุป', isError: true);
        return;
      }

      _lastCombinedText = combinedText;

      setState(() {
        _summarizingLabel = 'กำลังสรุปด้วย AI...';
      });

      final systemInstruction = widget.isMeeting
          ? 'คุณคือผู้ช่วยเลขานุการ HR มืออาชีพที่มีหน้าที่สรุปการประชุม กรุณาเขียนบันทึกสรุปการประชุมจากข้อมูลที่ได้รับให้ออกมาเป็นเอกสารทางการ (Official Meeting Minutes) ในรูปแบบ Markdown ที่อ่านเข้าใจง่ายที่สุด แบ่งหัวข้อแยกประเด็นชัดเจนและสรุปประเด็นเป็นข้อๆ โดยต้องครอบคลุม: หัวข้อการประชุม, วันเวลา (ถ้าระบุ), รายการผู้เข้าร่วม (ถ้ามี), ประเด็นสำคัญที่พูดคุย, มติหรือข้อตกลงร่วมกัน, และ Action Items (สิ่งที่ต้องทำต่อไปพร้อมคนรับผิดชอบและกำหนดส่ง) ข้อกำหนดที่สำคัญที่สุด:\n1. ห้ามใส่อิโมจิ (Emoji) หรือสติกเกอร์สัญลักษณ์พิเศษใดๆ ในเอกสารเด็ดขาด (No emojis allowed at all)\n2. เขียนสรุปเป็นภาษาไทยอย่างเป็นทางการและกระชับ สละสลวย เข้าใจง่ายสำหรับผู้บริหารและเลขา HR\n3. รูปแบบ Markdown ที่อนุญาตให้ใช้มี 5 แบบเท่านั้น: หัวข้อใหญ่ขึ้นต้นด้วย "# " (มีเว้นวรรค), หัวข้อย่อยขึ้นต้นด้วย "## " (มีเว้นวรรค), รายการย่อยขึ้นต้นด้วย "- " (มีเว้นวรรค), รายการลำดับตัวเลขขึ้นต้นด้วย "1. ", "2. ", "3. " (มีเว้นวรรค), และรายการสิ่งที่ต้องทำขึ้นต้นด้วย "- [ ] " หรือ "- [x] "\n4. กฎการใช้รายการย่อย: หากมีย่อย ให้ใช้รายการ "- " ได้สูงสุดแค่ 3 ข้อเท่านั้น หากมีย่อยมากกว่า 3 ข้อขึ้นไป ให้ใช้รายการลำดับตัวเลข ("1. ", "2. ", "3. "...) แทน\n5. ห้ามใช้ตัวหนา (**), ตัวเอียง (*), อินไลน์โค้ด (`), หัวข้อระดับ "###" ขึ้นไป, หรือเส้นคั่น (---) โดยเด็ดขาด เพราะระบบแสดงผลรองรับเฉพาะ 5 รูปแบบในข้อ 3 เท่านั้น\n6. หากรายการ Action Items ใดในสรุปเดิมมีสถานะทำเสร็จแล้ว (- [x] ) และรายการนั้นยังคงอยู่ในสรุปฉบับใหม่ ให้คงสถานะทำเสร็จแล้ว (- [x] ) ไว้เสมอ ห้ามเปลี่ยนกลับเป็น (- [ ] ) เด็ดขาด'
          : 'คุณคือผู้ช่วยเลขานุการ HR มืออาชีพที่มีหน้าที่สรุปเอกสาร กรุณาเขียนบันทึกสรุปจากข้อมูลที่ได้รับให้ออกมาเป็นเอกสารทางการในรูปแบบ Markdown ที่อ่านเข้าใจง่ายที่สุด แบ่งหัวข้อแยกประเด็นชัดเจนและสรุปประเด็นเป็นข้อๆ โดยต้องครอบคลุม: หัวข้อเอกสาร, ประเด็นสำคัญ, ข้อสรุปหรือข้อตกลง, และ Action Items (สิ่งที่ต้องทำต่อไปพร้อมคนรับผิดชอบและกำหนดส่ง ถ้ามี) ข้อกำหนดที่สำคัญที่สุด:\n1. ห้ามใส่อิโมจิ (Emoji) หรือสติกเกอร์สัญลักษณ์พิเศษใดๆ ในเอกสารเด็ดขาด (No emojis allowed at all)\n2. เขียนสรุปเป็นภาษาไทยอย่างเป็นทางการและกระชับ สละสลวย เข้าใจง่ายสำหรับผู้บริหารและเลขา HR\n3. รูปแบบ Markdown ที่อนุญาตให้ใช้มี 5 แบบเท่านั้น: หัวข้อใหญ่ขึ้นต้นด้วย "# " (มีเว้นวรรค), หัวข้อย่อยขึ้นต้นด้วย "## " (มีเว้นวรรค), รายการย่อยขึ้นต้นด้วย "- " (มีเว้นวรรค), รายการลำดับตัวเลขขึ้นต้นด้วย "1. ", "2. ", "3. " (มีเว้นวรรค), และรายการสิ่งที่ต้องทำขึ้นต้นด้วย "- [ ] " หรือ "- [x] "\n4. กฎการใช้รายการย่อย: หากมีย่อย ให้ใช้รายการ "- " ได้สูงสุดแค่ 3 ข้อเท่านั้น หากมีย่อยมากกว่า 3 ข้อขึ้นไป ให้ใช้รายการลำดับตัวเลข ("1. ", "2. ", "3. "...) แทน\n5. ห้ามใช้ตัวหนา (**), ตัวเอียง (*), อินไลน์โค้ด (`), หัวข้อระดับ "###" ขึ้นไป, หรือเส้นคั่น (---) โดยเด็ดขาด เพราะระบบแสดงผลรองรับเฉพาะ 5 รูปแบบในข้อ 3 เท่านั้น\n6. หากรายการ Action Items ใดในสรุปเดิมมีสถานะทำเสร็จแล้ว (- [x] ) และรายการนั้นยังคงอยู่ในสรุปฉบับใหม่ ให้คงสถานะทำเสร็จแล้ว (- [x] ) ไว้เสมอ ห้ามเปลี่ยนกลับเป็น (- [ ] ) เด็ดขาด';

      String userPrompt =
          '$systemInstruction\n\nนี่คือข้อมูล:\n\n$combinedText';
      final customPromptText = _customPromptController.text.trim();
      if (customPromptText.isNotEmpty) {
        userPrompt +=
            '\n\nคำสั่งเพิ่มเติมจากผู้ใช้ (Custom Prompt):\n$customPromptText';
      }

      debugPrint('[UI] Requesting summarize...');
      final summaryResult = await ApiCloudflare.summarizeMeeting(
        prompt: userPrompt,
      );

      if (summaryResult.isNotEmpty) {
        final preservedResult = preserveCheckedItems(_summaryOutput, summaryResult);
        final normalized = serializeBlocksToMarkdown(
          parseMarkdownToBlocks(preservedResult),
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
      } else {
        GlassNotifications.show(
          context,
          'ไม่สามารถสรุปข้อมูลได้ กรุณาลองใหม่อีกครั้ง',
          isError: true,
        );
      }
    } catch (e) {
      debugPrint('[UI][Error] summarize: $e');
      GlassNotifications.show(context, 'เกิดข้อผิดพลาด: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSummarizing = false);
    }
  }

  void _syncCurrentSession() {
    // Legacy method, not needed with DB-backed messages
  }

  Future<void> _handleRefine() async {
    final refineText = _refinePromptController.text.trim();
    if (refineText.isEmpty || _summaryOutput.isEmpty) return;

    setState(() {
      _isSummarizing = true;
      _summarizingLabel = 'กำลังปรับแต่ง...';
    });

    try {
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
3. รูปแบบ Markdown ที่อนุญาตให้ใช้มี 5 แบบเท่านั้น: หัวข้อใหญ่ขึ้นต้นด้วย "# " (มีเว้นวรรค), หัวข้อย่อยขึ้นต้นด้วย "## " (มีเว้นวรรค), รายการย่อยขึ้นต้นด้วย "- " (มีเว้นวรรค), รายการลำดับตัวเลขขึ้นต้นด้วย "1. ", "2. ", "3. " (มีเว้นวรรค), และรายการสิ่งที่ต้องทำขึ้นต้นด้วย "- [ ] " หรือ "- [x] "
4. กฎการใช้รายการย่อย: หากมีย่อย ให้ใช้รายการ "- " ได้สูงสุดแค่ 3 ข้อเท่านั้น หากมีย่อยมากกว่า 3 ข้อขึ้นไป ให้ใช้รายการลำดับตัวเลข ("1. ", "2. ", "3. "...) แทน
5. ห้ามใช้ตัวหนา (**), ตัวเอียง (*), อินไลน์โค้ด (`), หัวข้อระดับ "###" ขึ้นไป, หรือเส้นคั่น (---) โดยเด็ดขาด เพราะระบบแสดงผลรองรับเฉพาะ 5 รูปแบบในข้อ 3 เท่านั้น
6. หากรายการ Action Items ใดในสรุปเดิมมีสถานะทำเสร็จแล้ว (- [x] ) และรายการนั้นยังคงอยู่ในสรุปฉบับใหม่ ให้คงสถานะทำเสร็จแล้ว (- [x] ) ไว้เสมอ ห้ามเปลี่ยนกลับเป็น (- [ ] ) เด็ดขาด

แก้ไขและตอบกลับเป็นสรุปฉบับใหม่แบบเต็ม (คงรูปแบบ Markdown 5 แบบที่อนุญาตไว้เท่านั้น)
''';

      _refinePromptController.clear();
      final userMsg = ChatMessage(id: DateTime.now().millisecondsSinceEpoch.toString(), text: refineText, isUser: true);
      final sessionId = _sessions[_activeSessionIndex].id;
      await ApiCloudflare.insertChatMessage(userMsg, sessionId);
      
      setState(() {
        _chatMessages.insert(0, userMsg);
        _outputTabIndex = 1;
      });
      _scrollToBottom();

      debugPrint('[UI] Requesting refine...');
      final oldSummary = _summaryOutput;
      final result = await ApiCloudflare.summarizeMeeting(prompt: prompt);

      if (result.isNotEmpty) {
        final preservedResult = preserveCheckedItems(oldSummary, result);
        final normalized = serializeBlocksToMarkdown(
          parseMarkdownToBlocks(preservedResult),
        );
        final aiMsg = ChatMessage(id: (DateTime.now().millisecondsSinceEpoch + 1).toString(), text: normalized, isUser: false);
        await ApiCloudflare.insertChatMessage(aiMsg, sessionId);
        setState(() {
          _summaryOutput = normalized;
          _chatMessages.insert(0, aiMsg);
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('[UI][Error] refine: $e');
      GlassNotifications.show(context, 'เกิดข้อผิดพลาด: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSummarizing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DeferredPointerHandler(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: GlassColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: GlassColors.gold, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'AI Summarizer',
                      style: GlassText.headlineMD().copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),

              _buildSessionSelector(),
              const Divider(color: Colors.white12, height: 1),

              Expanded(
                child: _summaryOutput.isEmpty && _chatMessages.isEmpty
                    ? _buildConfigView()
                    : _buildOutputView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionSelector() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _sessions.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == _sessions.length) {
            return Center(
              child: ActionChip(
                backgroundColor: GlassColors.gold.withOpacity(0.1),
                side: BorderSide(color: GlassColors.gold.withOpacity(0.5)),
                label: const Text(
                  '+ เสสชันใหม่',
                  style: TextStyle(color: GlassColors.gold),
                ),
                onPressed: () async {
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
                },
              ),
            );
          }
          final isActive = index == _activeSessionIndex;
          return Center(
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_sessions[index].name),
                  if (isActive) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showRenameSessionDialog(index),
                      child: const Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ],
              ),
              selected: isActive,
              selectedColor: GlassColors.gold,
              labelStyle: TextStyle(
                color: isActive ? Colors.black : Colors.white,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (selected) async {
                if (selected && !isActive) {
                  setState(() {
                    _activeSessionIndex = index;
                    _summaryOutput = '';
                    _chatMessages = [];
                  });
                  await _loadCurrentSessionMessages();
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildConfigView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'เลือกแหล่งข้อมูล',
            style: GlassText.bodyLG().copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          if (widget.notesText.trim().isNotEmpty)
            CheckboxListTile(
              title: const Text(
                'บันทึกข้อความ (Notes)',
                style: TextStyle(color: Colors.white),
              ),
              value: _includeNotes,
              activeColor: GlassColors.gold,
              checkColor: Colors.black,
              onChanged: (val) => setState(() => _includeNotes = val ?? false),
            ),
          if (widget.mainTranscriptText.trim().isNotEmpty)
            CheckboxListTile(
              title: const Text(
                'Transcript หลัก',
                style: TextStyle(color: Colors.white),
              ),
              value: _includeMainTranscript,
              activeColor: GlassColors.gold,
              checkColor: Colors.black,
              onChanged: (val) =>
                  setState(() => _includeMainTranscript = val ?? false),
            ),
          ...widget.recordingTakes
              .where(
                (t) =>
                    t['id'] != null &&
                    t['transcript'] != null &&
                    t['transcript']!.isNotEmpty &&
                    t['transcript'] != '[]',
              )
              .map((take) {
                return CheckboxListTile(
                  title: Text(
                    'Recording: ${take['name'] ?? 'Take'}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  value: _includeTakes[take['id']],
                  activeColor: GlassColors.gold,
                  checkColor: Colors.black,
                  onChanged: (val) =>
                      setState(() => _includeTakes[take['id']!] = val ?? false),
                );
              }),
          ...widget.fileAttachments.asMap().entries.map((entry) {
            final i = entry.key;
            final file = entry.value;
            return CheckboxListTile(
              title: Text(
                file['name'] ?? 'Document',
                style: const TextStyle(color: Colors.white),
              ),
              value: _includeFiles[i],
              activeColor: GlassColors.gold,
              checkColor: Colors.black,
              onChanged: (val) =>
                  setState(() => _includeFiles[i] = val ?? false),
            );
          }),

          const SizedBox(height: 24),
          Text(
            'คำสั่งเพิ่มเติม (Custom Prompt)',
            style: GlassText.bodyLG().copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _customPromptController,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'คำสั่งเพิ่มเติมล่วงหน้า...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              filled: true,
              fillColor: const Color(0x80161926),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: _isSummarizing ? null : _handleSummarize,
              icon: _isSummarizing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.auto_awesome, color: Colors.black),
              label: Text(
                _isSummarizing ? _summarizingLabel : 'สร้างสรุป',
                style: GlassText.bodyLG().copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: GlassColors.gold,
                disabledBackgroundColor: GlassColors.gold.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutputView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<int>(
                  style: SegmentedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.05),
                    selectedBackgroundColor: GlassColors.gold.withOpacity(0.2),
                    foregroundColor: Colors.white70,
                    selectedForegroundColor: GlassColors.gold,
                    side: const BorderSide(color: Colors.white12),
                  ),
                  segments: [
                    const ButtonSegment(
                      value: 0,
                      label: Text('📄 เอกสารสรุป'),
                    ),
                    ButtonSegment(
                      value: 1,
                      label: Text('💬 ประวัติแชท (${_chatMessages.length})'),
                    ),
                  ],
                  selected: {_outputTabIndex},
                  onSelectionChanged: (Set<int> newSelection) {
                    setState(() {
                      _outputTabIndex = newSelection.first;
                    });
                    if (_outputTabIndex == 1) {
                      _scrollToBottom();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _outputTabIndex == 0
              ? ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0x80161926),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: MarkdownBlockEditor(
                        initialMarkdown: _summaryOutput,
                        onChanged: (val) {
                          _summaryOutput = val;
                          if (_chatMessages.isNotEmpty) {
                            final newestAiIndex = _chatMessages.indexWhere((m) => !m.isUser);
                            if (newestAiIndex != -1) {
                              final updatedMsg = _chatMessages[newestAiIndex].copyWith(text: val);
                              _chatMessages[newestAiIndex] = updatedMsg;
                              final sessionId = _sessions[_activeSessionIndex].id;
                              ApiCloudflare.insertChatMessage(updatedMsg, sessionId);
                            }
                          }
                          _syncCurrentSession();
                        },
                        onDragStateChanged: (_) {},
                      ),
                    ),
                  ],
                )
              : ListView.builder(
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
                            : const Color(0x80161926),
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
                ),
        ),
        if (_isSummarizing)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: LinearProgressIndicator(color: GlassColors.gold),
          ),
        // Refinement Chat Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0x801E2235),
            border: Border(top: BorderSide(color: Colors.white12)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _refinePromptController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'สั่ง AI แก้ไข/ปรับแต่งสรุป...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _isSummarizing ? null : _handleRefine(),
                ),
              ),
              const SizedBox(width: 8),
              _isSummarizing
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: GlassColors.gold,
                        ),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        color: GlassColors.gold,
                      ),
                      onPressed: _handleRefine,
                    ),
            ],
          ),
        ),
        // Apply Button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _isSummarizing
                  ? null
                  : () {
                      _syncCurrentSession();
                      Navigator.pop(context, {
                        'summary': _summaryOutput,
                        'sessions': _sessions,
                      });
                    },
              style: FilledButton.styleFrom(
                backgroundColor: GlassColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'นำไปใช้',
                style: GlassText.bodyLG().copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
