import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/glass_theme.dart';
import '../../common/glass_widgets.dart';
import '../../common/ime_safe_text_field.dart';

class AetherChatInput extends StatelessWidget {
  final bool isDark;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final List<PlatformFile> pendingFiles;
  final VoidCallback onSend;
  final Function(List<PlatformFile>) onFilesPicked;
  final Function(int) onRemoveFile;
  final Function(String) onPreviewImage;

  const AetherChatInput({
    super.key,
    required this.isDark,
    required this.controller,
    this.focusNode,
    required this.pendingFiles,
    required this.onSend,
    required this.onFilesPicked,
    required this.onRemoveFile,
    required this.onPreviewImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: GlassColors.background.withOpacity(0.4),
        border: Border(
          top: BorderSide(color: GlassColors.glassBorder(), width: 0.8),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pendingFiles.isNotEmpty) _buildFileChips(),

          GlassContainer(
            isDark: isDark,
            padding: const EdgeInsets.all(8),
            radius: ExecutiveRadius.xl,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 🔑 Use Material IconButton instead of GlassIconButton.
                // GlassIconButton wraps with GlassContainer which has BackdropFilter
                // that interferes with the file picker's hit test on Flutter Web.
                IconButton(
                  onPressed: () async {
                    try {
                      final result = await FilePicker.pickFiles(withData: true);
                      if (result != null && result.files.isNotEmpty) {
                        onFilesPicked(result.files);
                      }
                    } catch (e) {
                      debugPrint('Error picking files: $e');
                    }
                  },
                  icon: Icon(
                    Icons.attach_file_rounded,
                    color: GlassColors.onSurfaceVariant,
                    size: 20,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: GlassColors.glassSurface,
                    fixedSize: const Size(44, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                      side: BorderSide(color: GlassColors.glassBorder()),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ImeSafeTextField(
                    controller: controller,
                    focusNode: focusNode,
                    style: GlassText.body().copyWith(fontSize: 16),
                    maxLines: 5,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: 'Message Jonny...',
                      hintStyle: GlassText.body().copyWith(
                        color: GlassColors.onSurfaceVariant.withOpacity(0.5),
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => onSend(),
                  ),
                ),
                const SizedBox(width: 8),
                _buildSendButton(),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'AI MAY PROVIDE INACCURATE INFORMATION. VERIFY IMPORTANT DATA.',
            style: GlassText.label().copyWith(
              fontSize: 9,
              color: GlassColors.onSurfaceVariant.withOpacity(0.4),
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileChips() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: pendingFiles.asMap().entries.map((entry) {
          final i = entry.key;
          final f = entry.value;
          final mime = _guessMimeType(f.name);
          final isImage = mime.startsWith('image/');

          return Container(
            padding: const EdgeInsets.all(6),
            decoration: GlassDecorations.surface(
              isDark: isDark,
              radius: ExecutiveRadius.m,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isImage) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(ExecutiveRadius.s),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: f.bytes != null
                          ? Image.memory(f.bytes!, fit: BoxFit.cover)
                          : (!kIsWeb && f.path != null
                                ? Image.file(
                                    io.File(f.path!),
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(
                                    Icons.image,
                                    size: 20,
                                    color: GlassColors.primary,
                                  )),
                    ),
                  ),
                  const SizedBox(width: 10),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(
                      _fileTypeIcon(mime),
                      size: 20,
                      color: GlassColors.primary,
                    ),
                  ),
                ],
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 140),
                    child: Text(
                      f.name,
                      overflow: TextOverflow.ellipsis,
                      style: GlassText.caption().copyWith(fontSize: 12),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 14),
                  onPressed: () => onRemoveFile(i),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  color: GlassColors.onSurfaceVariant.withOpacity(0.6),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _guessMimeType(String? filename) {
    final ext = filename?.split('.').last.toLowerCase() ?? '';
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg'].contains(ext)) {
      return 'image/$ext';
    }
    return 'application/octet-stream';
  }

  IconData _fileTypeIcon(String? mime) {
    if (mime == null) return Icons.insert_drive_file_outlined;
    if (mime.startsWith('image/')) return Icons.image_outlined;
    if (mime.startsWith('audio/')) return Icons.audiotrack_outlined;
    if (mime.startsWith('video/')) return Icons.videocam_outlined;
    if (mime == 'application/pdf') return Icons.picture_as_pdf_outlined;
    if (mime.contains('word') || mime.contains('document'))
      return Icons.description_outlined;
    if (mime.contains('excel') || mime.contains('sheet'))
      return Icons.table_chart_outlined;
    if (mime.contains('powerpoint') || mime.contains('presentation'))
      return Icons.slideshow_outlined;
    if (mime.startsWith('text/')) return Icons.text_snippet_outlined;
    return Icons.insert_drive_file_outlined;
  }

  Widget _buildSendButton() {
    return InkWell(
      onTap: onSend,
      borderRadius: BorderRadius.circular(ExecutiveRadius.l),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: GlassColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(ExecutiveRadius.l),
        ),
        child: const Icon(
          Icons.send_rounded,
          color: GlassColors.primary,
          size: 18,
        ),
      ),
    );
  }
}
