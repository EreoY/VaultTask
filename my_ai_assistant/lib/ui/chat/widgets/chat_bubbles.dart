import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../models/chat_model.dart';
import '../../theme/glass_theme.dart';

// Modular Widgets
import 'draft_cards.dart';
import 'structured_ui_bubbles.dart';
import 'technical_logs.dart';

class UserMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isDark;
  const UserMessageBubble({super.key, required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        margin: const EdgeInsets.only(bottom: 24, left: 64),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: GlassColors.primary.withOpacity(0.1),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            bottomLeft: Radius.circular(24),
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(8),
          ),
          border: Border.all(color: GlassColors.primary.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (message.attachments.isNotEmpty) _buildAttachments(context),
            Text(
              message.text,
              style: GlassText.bodyMD().copyWith(color: isDark ? Colors.white : Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachments(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: message.attachments.map((a) {
          final url = a['url'] ?? '';
          final mime = a['mime'] ?? '';
          final isImage = mime.startsWith('image/');

          if (isImage) {
            return Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: GlassColors.ghostBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 24)),
              ),
            );
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: GlassColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: GlassColors.ghostBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_fileTypeIcon(mime), size: 20, color: GlassColors.primary),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    a['name'] ?? 'File',
                    overflow: TextOverflow.ellipsis,
                    style: GlassText.caption().copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _fileTypeIcon(String mime) {
    if (mime.startsWith('image/')) return Icons.image_outlined;
    if (mime.startsWith('audio/')) return Icons.audiotrack_outlined;
    if (mime.startsWith('video/')) return Icons.videocam_outlined;
    if (mime == 'application/pdf') return Icons.picture_as_pdf_outlined;
    if (mime.contains('word') || mime.contains('document')) return Icons.description_outlined;
    if (mime.contains('excel') || mime.contains('sheet')) return Icons.table_chart_outlined;
    if (mime.contains('powerpoint') || mime.contains('presentation')) return Icons.slideshow_outlined;
    if (mime.startsWith('text/')) return Icons.text_snippet_outlined;
    return Icons.insert_drive_file_outlined;
  }
}

class AssistantMessageBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isDark;
  const AssistantMessageBubble({super.key, required this.message, required this.isDark});

  @override
  State<AssistantMessageBubble> createState() => _AssistantMessageBubbleState();
}

class _AssistantMessageBubbleState extends State<AssistantMessageBubble> {
  bool _showResultUI = false;

  @override
  void initState() {
    super.initState();
    // Logic: Text appears immediately, Result UI follows with animation
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _showResultUI = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final isDark = widget.isDark;

    // 🧮 Aggregate Tool Calls for Stacking
    final Map<String, int> toolCounts = {};
    for (var tc in message.toolCalls) {
       toolCounts[tc.name] = (toolCounts[tc.name] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔧 1. Diagnostics Layer (Logs at the VERY TOP)
        if (message.toolCalls.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: toolCounts.entries.map((e) => DiagnosticToolLog(toolName: e.key, count: e.value)).toList(),
            ),
          ),

        // 💬 2. Text Bubble (Immediate)
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
            margin: const EdgeInsets.only(bottom: 16, right: 48),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                bottomLeft: Radius.circular(8),
                topRight: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              border: Border.all(color: GlassColors.ghostBorder),
            ),
            child: MarkdownBody(
              data: message.text,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: GlassText.bodyMD().copyWith(height: 1.6),
                strong: GlassText.bodyMD().copyWith(fontWeight: FontWeight.bold, color: GlassColors.primary),
                code: GlassText.bodyMD().copyWith(
                  backgroundColor: GlassColors.primary.withOpacity(0.05),
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ),

        // 🎭 3. Delayed Result UI Layer (Tables, Cards, Proposals)
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          child: _showResultUI 
            ? Column(
                key: ValueKey('results_${message.id}'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 📊 Structured UI Layer
                  ...message.toolCalls.where((tc) => tc.name == 'show_ui_content').map((tc) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: StructuredUIBubble(
                        data: tc.arguments['data_json'] ?? tc.arguments['data'], 
                        type: tc.arguments['type']?.toString() ?? 'table'
                      ),
                    );
                  }),

                  // 📝 Proposal & Confirmation Layer
                  if (message.hasDraft && message.confirmedDraft == null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: ProposalDraftCard(isDark: isDark, draft: message.draft),
                    ),
                  if (message.confirmedDraft != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: ConfirmedActionCard(draft: message.confirmedDraft!, isDark: isDark),
                    ),
                ],
              )
            : const SizedBox.shrink(),
        ),
      ],
    );
  }
}


