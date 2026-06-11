import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../theme/glass_theme.dart';
import '../../common/ime_safe_text_field.dart';
import 'package:my_ai_assistant/ui/common/defer_pointer.dart';

class MarkdownBlock {
  final String id;
  String type; // 'paragraph', 'h1', 'h2', 'bullet', 'todo'
  String text;
  bool isChecked;

  MarkdownBlock({
    required this.id,
    required this.type,
    required this.text,
    this.isChecked = false,
  });

  MarkdownBlock copyWith({
    String? id,
    String? type,
    String? text,
    bool? isChecked,
  }) {
    return MarkdownBlock(
      id: id ?? this.id,
      type: type ?? this.type,
      text: text ?? this.text,
      isChecked: isChecked ?? this.isChecked,
    );
  }
}

List<MarkdownBlock> parseMarkdownToBlocks(String markdown) {
  if (markdown.trim().isEmpty) {
    return [MarkdownBlock(id: const Uuid().v4(), type: 'paragraph', text: '')];
  }
  final lines = markdown.split('\n');
  return lines.map((line) {
    final id = const Uuid().v4();
    if (line.startsWith('# ')) {
      return MarkdownBlock(id: id, type: 'h1', text: line.substring(2));
    } else if (line.startsWith('## ')) {
      return MarkdownBlock(id: id, type: 'h2', text: line.substring(3));
    } else if (line.startsWith('- [ ] ')) {
      return MarkdownBlock(id: id, type: 'todo', text: line.substring(6), isChecked: false);
    } else if (line.startsWith('- [x] ')) {
      return MarkdownBlock(id: id, type: 'todo', text: line.substring(6), isChecked: true);
    } else if (line.startsWith('- ')) {
      return MarkdownBlock(id: id, type: 'bullet', text: line.substring(2));
    } else if (line.startsWith('* ')) {
      return MarkdownBlock(id: id, type: 'bullet', text: line.substring(2));
    } else {
      return MarkdownBlock(id: id, type: 'paragraph', text: line);
    }
  }).toList();
}

String serializeBlocksToMarkdown(List<MarkdownBlock> blocks) {
  return blocks.map((block) {
    switch (block.type) {
      case 'h1':
        return '# ${block.text}';
      case 'h2':
        return '## ${block.text}';
      case 'bullet':
        return '- ${block.text}';
      case 'todo':
        return block.isChecked ? '- [x] ${block.text}' : '- [ ] ${block.text}';
      case 'paragraph':
      default:
        return block.text;
    }
  }).join('\n');
}

class MarkdownBlockEditor extends StatefulWidget {
  final String initialMarkdown;
  final ValueChanged<String> onChanged;
  final ValueChanged<bool>? onDragStateChanged;

  const MarkdownBlockEditor({
    super.key,
    required this.initialMarkdown,
    required this.onChanged,
    this.onDragStateChanged,
  });

  @override
  State<MarkdownBlockEditor> createState() => _MarkdownBlockEditorState();
}

class _MarkdownBlockEditorState extends State<MarkdownBlockEditor> {
  late List<MarkdownBlock> _blocks;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  String? _hoveredBlockId;
  String? _focusedBlockId;
  int? _draggingIndex;
  final Map<String, LayerLink> _layerLinks = {};
  OverlayEntry? _menuEntry;

  @override
  void initState() {
    super.initState();
    _blocks = parseMarkdownToBlocks(widget.initialMarkdown);
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant MarkdownBlockEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialMarkdown != oldWidget.initialMarkdown) {
      final currentSerialized = serializeBlocksToMarkdown(_blocks);
      if (widget.initialMarkdown != currentSerialized) {
        setState(() {
          _blocks = parseMarkdownToBlocks(widget.initialMarkdown);
          _syncControllers();
        });
      }
    }
  }

  @override
  void dispose() {
    _hideMenu();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _syncControllers() {
    final activeIds = _blocks.map((b) => b.id).toSet();

    // Dispose and remove deleted controllers & focus nodes
    _controllers.keys.where((id) => !activeIds.contains(id)).toList().forEach((id) {
      _controllers[id]?.dispose();
      _controllers.remove(id);
    });
    _focusNodes.keys.where((id) => !activeIds.contains(id)).toList().forEach((id) {
      _focusNodes[id]?.dispose();
      _focusNodes.remove(id);
    });

    // Create new controllers & focus nodes if needed
    for (final block in _blocks) {
      if (!_controllers.containsKey(block.id)) {
        final controller = TextEditingController(text: block.text);
        controller.addListener(() {
          if (block.text != controller.text) {
            block.text = controller.text;
            _notifyChanged();
          }
        });
        _controllers[block.id] = controller;
      }
      if (!_focusNodes.containsKey(block.id)) {
        final focusNode = FocusNode();
        focusNode.addListener(() {
          if (focusNode.hasFocus) {
            setState(() {
              _focusedBlockId = block.id;
            });
          } else {
            if (_focusedBlockId == block.id) {
              setState(() {
                _focusedBlockId = null;
              });
            }
          }
        });
        _focusNodes[block.id] = focusNode;
      }
    }
  }

  void _notifyChanged() {
    final md = serializeBlocksToMarkdown(_blocks);
    widget.onChanged(md);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event, int index) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final block = _blocks[index];
    final controller = _controllers[block.id]!;

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      final selection = controller.selection;
      if (selection.isValid) {
        final start = selection.start;
        final end = selection.end;
        final text = controller.text;

        final textBefore = text.substring(0, start);
        final textAfter = text.substring(end);

        setState(() {
          block.text = textBefore;
          controller.text = textBefore;

          final newBlock = MarkdownBlock(
            id: const Uuid().v4(),
            type: (block.type == 'todo' || block.type == 'bullet') ? block.type : 'paragraph',
            text: textAfter,
            isChecked: false,
          );
          _blocks.insert(index + 1, newBlock);
          _syncControllers();
          _notifyChanged();
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && index + 1 < _blocks.length) {
            final nextBlock = _blocks[index + 1];
            final nextFocus = _focusNodes[nextBlock.id];
            final nextController = _controllers[nextBlock.id];
            if (nextFocus != null && nextController != null) {
              nextFocus.requestFocus();
              nextController.selection = const TextSelection.collapsed(offset: 0);
            }
          }
        });
        return KeyEventResult.handled;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
      final selection = controller.selection;
      if (selection.isValid && selection.isCollapsed && selection.start == 0) {
        if (index > 0) {
          final prevBlock = _blocks[index - 1];
          final prevController = _controllers[prevBlock.id]!;
          final originalPrevLength = prevController.text.length;

          setState(() {
            prevBlock.text = prevBlock.text + block.text;
            prevController.text = prevBlock.text;
            _blocks.removeAt(index);
            _syncControllers();
            _notifyChanged();
          });

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              final prevFocus = _focusNodes[prevBlock.id];
              if (prevFocus != null) {
                prevFocus.requestFocus();
                prevController.selection = TextSelection.collapsed(offset: originalPrevLength);
              }
            }
          });
          return KeyEventResult.handled;
        }
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      final selection = controller.selection;
      if (selection.isValid && selection.isCollapsed && selection.start == 0) {
        if (index > 0) {
          final prevBlock = _blocks[index - 1];
          final prevFocus = _focusNodes[prevBlock.id];
          final prevController = _controllers[prevBlock.id];
          if (prevFocus != null && prevController != null) {
            prevFocus.requestFocus();
            prevController.selection = TextSelection.collapsed(offset: prevController.text.length);
            return KeyEventResult.handled;
          }
        }
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      final selection = controller.selection;
      if (selection.isValid && selection.isCollapsed && selection.start == controller.text.length) {
        if (index < _blocks.length - 1) {
          final nextBlock = _blocks[index + 1];
          final nextFocus = _focusNodes[nextBlock.id];
          final nextController = _controllers[nextBlock.id];
          if (nextFocus != null && nextController != null) {
            nextFocus.requestFocus();
            nextController.selection = const TextSelection.collapsed(offset: 0);
            return KeyEventResult.handled;
          }
        }
      }
    }

    return KeyEventResult.ignored;
  }

  void _showMenu(BuildContext context, int index, {bool isFromPlus = false}) {
    _hideMenu();

    final block = _blocks[index];
    final blockLink = _layerLinks.putIfAbsent(block.id, () => LayerLink());

    _menuEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            GestureDetector(
              onTap: _hideMenu,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
            Positioned(
              width: 220,
              child: CompositedTransformFollower(
                link: blockLink,
                showWhenUnlinked: false,
                offset: const Offset(56, 32),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: GlassDecorations.solidSurface(radius: 12, hasShadow: true),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _menuItem(index, 'paragraph', Icons.notes_rounded, 'Normal Text', isFromPlus),
                        _menuItem(index, 'h1', Icons.title_rounded, 'Heading 1', isFromPlus),
                        _menuItem(index, 'h2', Icons.subtitles_rounded, 'Heading 2', isFromPlus),
                        _menuItem(index, 'bullet', Icons.list_rounded, 'Bullet List', isFromPlus),
                        _menuItem(index, 'todo', Icons.check_box_outlined, 'To-do List', isFromPlus),
                        const Divider(height: 8, thickness: 1, indent: 8, endIndent: 8),
                        _menuItem(index, 'insert_below', Icons.add_circle_outline, 'Insert Below', isFromPlus),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_menuEntry!);
  }

  void _hideMenu() {
    _menuEntry?.remove();
    _menuEntry = null;
  }

  Widget _menuItem(int index, String type, IconData icon, String label, bool isFromPlus) {
    return InkWell(
      onTap: () {
        if (type == 'insert_below') {
          setState(() {
            final newBlock = MarkdownBlock(
              id: const Uuid().v4(),
              type: 'paragraph',
              text: '',
            );
            _blocks.insert(index + 1, newBlock);
            _syncControllers();
            _notifyChanged();
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && index + 1 < _blocks.length) {
              final nextBlock = _blocks[index + 1];
              final nextFocus = _focusNodes[nextBlock.id];
              final nextController = _controllers[nextBlock.id];
              if (nextFocus != null && nextController != null) {
                nextFocus.requestFocus();
                nextController.selection = const TextSelection.collapsed(offset: 0);
              }
            }
          });
        } else {
          setState(() {
            final currentBlock = _blocks[index];
            if (isFromPlus && currentBlock.text.trim().isNotEmpty) {
              final newBlock = MarkdownBlock(
                id: const Uuid().v4(),
                type: type,
                text: '',
              );
              _blocks.insert(index + 1, newBlock);
              _syncControllers();
              _notifyChanged();

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && index + 1 < _blocks.length) {
                  final nextBlock = _blocks[index + 1];
                  final nextFocus = _focusNodes[nextBlock.id];
                  final nextController = _controllers[nextBlock.id];
                  if (nextFocus != null && nextController != null) {
                    nextFocus.requestFocus();
                    nextController.selection = const TextSelection.collapsed(offset: 0);
                  }
                }
              });
            } else {
              currentBlock.type = type;

              final controller = _controllers[currentBlock.id];
              if (controller != null && (controller.text == '/' || controller.text == '')) {
                controller.text = '';
                currentBlock.text = '';
              }

              _syncControllers();
              _notifyChanged();
            }
          });
        }
        _hideMenu();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: GlassColors.onSurface.withOpacity(0.7),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GlassText.bodyMD().copyWith(
                color: GlassColors.onSurface.withOpacity(0.88),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double animValue = Curves.easeInOut.transform(animation.value);
        final double elevation = lerpDouble(0, 8, animValue)!;
        return Material(
          elevation: elevation,
          color: GlassColors.surface.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
          shadowColor: Colors.black.withOpacity(0.3),
          child: child,
        );
      },
      child: child,
    );
  }

  Widget _buildBlockRow(int index, MarkdownBlock block) {
    final controller = _controllers[block.id];
    final focusNode = _focusNodes[block.id];

    if (controller == null || focusNode == null) return const SizedBox.shrink();

    final isHovered = _hoveredBlockId == block.id;
    final isFocused = focusNode.hasFocus;

    TextStyle textStyle;
    double topPadding = 4.0;
    double bottomPadding = 4.0;
    switch (block.type) {
      case 'h1':
        textStyle = GlassText.bodyLG().copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          height: 1.35,
        );
        topPadding = 16.0;
        bottomPadding = 8.0;
        break;
      case 'h2':
        textStyle = GlassText.bodyLG().copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.35,
        );
        topPadding = 12.0;
        bottomPadding = 6.0;
        break;
      case 'bullet':
      case 'todo':
      case 'paragraph':
      default:
        textStyle = GlassText.bodyMD().copyWith(
          height: 1.55,
        );
        break;
    }

    final blockRowContent = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (block.type == 'bullet')
          Container(
            margin: const EdgeInsets.only(top: 8, right: 8, left: 4),
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: GlassColors.onSurfaceVariant,
              shape: BoxShape.circle,
            ),
          )
        else if (block.type == 'todo')
          GestureDetector(
            onTap: () {
              setState(() {
                block.isChecked = !block.isChecked;
                _notifyChanged();
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8, top: 4, left: 2),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: block.isChecked
                      ? GlassColors.success
                      : GlassColors.outlineVariant.withOpacity(0.4),
                  width: 1.5,
                ),
                color: block.isChecked
                    ? GlassColors.success.withOpacity(0.2)
                    : Colors.transparent,
              ),
              child: block.isChecked
                  ? const Icon(
                      Icons.check,
                      size: 11,
                      color: GlassColors.success,
                    )
                  : null,
            ),
          ),
        Expanded(
          child: CompositedTransformTarget(
            link: _layerLinks.putIfAbsent(block.id, () => LayerLink()),
            child: Focus(
              onKeyEvent: (node, event) => _handleKeyEvent(node, event, index),
              child: ImeSafeTextField(
                controller: controller,
                focusNode: focusNode,
                style: textStyle.copyWith(
                  decoration: (block.type == 'todo' && block.isChecked)
                      ? TextDecoration.lineThrough
                      : null,
                  color: (block.type == 'todo' && block.isChecked)
                      ? GlassColors.onSurfaceVariant.withOpacity(0.4)
                      : null,
                ),
                maxLines: null,
                decoration: InputDecoration(
                  hintText: block.type == 'todo'
                      ? 'To-do'
                      : block.type == 'bullet'
                          ? 'List item'
                          : (block.type == 'h1'
                              ? 'Heading 1'
                              : (block.type == 'h2' ? 'Heading 2' : 'Type \'/\' for commands...')),
                  hintStyle: GlassText.bodyMD().copyWith(
                    color: GlassColors.onSurfaceVariant.withOpacity(0.2),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                ),
                onChanged: (val) {
                  if (val == '/') {
                    _showMenu(context, index);
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );

    final isDraggingThis = _draggingIndex == index;
    final showControls = isHovered || isFocused || isDraggingThis;

    return MouseRegion(
      key: ValueKey(block.id),
      onEnter: (_) {
        setState(() => _hoveredBlockId = block.id);
      },
      child: Container(
        color: Colors.transparent, // Ensures entire row detects hover
        child: Padding(
          padding: EdgeInsets.only(
            left: 0,
            top: topPadding,
            bottom: bottomPadding,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // --- Block content (inside the card, occupying full width of row) ---
              blockRowContent,
              // --- Controls positioned outside the row bounds (negative offset) ---
              Positioned(
                left: -58,
                top: 0,
                bottom: 0,
                child: DeferPointer(
                  child: MouseRegion(
                    hitTestBehavior: HitTestBehavior.translucent,
                    onEnter: (_) {
                      setState(() => _hoveredBlockId = block.id);
                    },
                    child: IgnorePointer(
                      ignoring: !showControls,
                      child: AnimatedOpacity(
                        opacity: showControls ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 120),
                        child: Container(
                          width: 54,
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Tooltip(
                                message: 'Add / Convert Block',
                                child: GestureDetector(
                                  onTap: () => _showMenu(context, index, isFromPlus: true),
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.08),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.12),
                                          width: 1.0,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.add,
                                        size: 16,
                                        color: GlassColors.onSurface,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Listener(
                                onPointerDown: (_) {
                                  widget.onDragStateChanged?.call(true);
                                },
                                onPointerUp: (_) {
                                  widget.onDragStateChanged?.call(false);
                                },
                                onPointerCancel: (_) {
                                  widget.onDragStateChanged?.call(false);
                                },
                                child: ReorderableDragStartListener(
                                  index: index,
                                  child: Tooltip(
                                    message: 'Drag to reorder',
                                    child: MouseRegion(
                                      cursor: SystemMouseCursors.grab,
                                      child: Icon(
                                        Icons.drag_indicator_rounded,
                                        size: 22,
                                        color: GlassColors.onSurfaceVariant.withOpacity(0.85),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      clipBehavior: Clip.none,
      proxyDecorator: _proxyDecorator,
      itemCount: _blocks.length,
      onReorderStart: (index) {
        setState(() {
          _draggingIndex = index;
        });
      },
      onReorderEnd: (index) {
        setState(() {
          _draggingIndex = null;
        });
      },
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
          final item = _blocks.removeAt(oldIndex);
          _blocks.insert(newIndex, item);
          _syncControllers();
          _notifyChanged();
        });
      },
      itemBuilder: (context, index) {
        final block = _blocks[index];
        return _buildBlockRow(index, block);
      },
    );
  }
}
