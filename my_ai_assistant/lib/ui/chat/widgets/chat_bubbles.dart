import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../models/chat_model.dart';
import '../../theme/glass_theme.dart';
import '../../../config/env_config.dart';

// Modular Widgets
import 'draft_cards.dart';
import 'structured_ui_bubbles.dart';
import 'technical_logs.dart';

class UserMessageBubble extends StatelessWidget {
  static final Map<String, Uint8List> _b64Cache = {};
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
            final b64 = a['b64'] ?? '';
            final isFailed = url == 'error' || url.isEmpty;
            final sanitizedUrl = EnvConfig.sanitizeUrl(url);

            return Container(
              width: 200,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: GlassColors.ghostBorder),
                color: GlassColors.surfaceHighest.withOpacity(0.05),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 184,
                      height: 110,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          b64.isNotEmpty
                              ? Image.memory(
                                  _b64Cache.putIfAbsent(b64, () => base64Decode(b64)),
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true,
                                  errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 24)),
                                )
                              : (isFailed
                                  ? const Center(child: Icon(Icons.broken_image, size: 24))
                                  : Image.network(
                                      sanitizedUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 24)),
                                    )),
                          if (isFailed)
                            Container(
                              color: Colors.black.withOpacity(0.55),
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 24),
                                    SizedBox(height: 4),
                                    Text(
                                      'Failed',
                                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    a['name'] ?? 'Image',
                    style: GlassText.caption().copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  CollapsibleDescription(
                    description: a['description'] ?? '',
                    isDark: isDark,
                  ),
                ],
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

class CollapsibleDescription extends StatefulWidget {
  final String description;
  final bool isDark;

  const CollapsibleDescription({
    super.key,
    required this.description,
    required this.isDark,
  });

  @override
  State<CollapsibleDescription> createState() => _CollapsibleDescriptionState();
}

class _CollapsibleDescriptionState extends State<CollapsibleDescription> {
  bool _isExpanded = false;

  @override
  void didUpdateWidget(covariant CollapsibleDescription oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.description.isEmpty && widget.description.isNotEmpty) {
      _isExpanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = widget.description.isEmpty;
    final text = isEmpty ? 'กำลังวิเคราะห์รูปภาพด้วย AI...' : widget.description;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: isEmpty
              ? null
              : () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isEmpty
                      ? Icons.hourglass_empty_rounded
                      : (_isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded),
                  size: 14,
                  color: GlassColors.primary.withOpacity(0.8),
                ),
                const SizedBox(width: 4),
                Text(
                  isEmpty ? 'กำลังวิเคราะห์รูปภาพด้วย AI...' : '🤖 คำอธิบาย AI',
                  style: GlassText.caption().copyWith(
                    fontWeight: FontWeight.w600,
                    color: GlassColors.primary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded && !isEmpty) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: GlassColors.ghostBorder),
            ),
            child: Text(
              text,
              style: GlassText.caption().copyWith(
                color: widget.isDark ? Colors.white60 : Colors.black54,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ),
        ],
      ],
    );
  }
}


