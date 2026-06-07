
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state_managers/state_chat.dart';
import '../../theme/glass_theme.dart';
import 'chat_widgets.dart';
import 'chat_bubbles.dart';
import 'chat_input.dart';
import '../../common/glass_widgets.dart';

class AetherChatView extends StatefulWidget {
  final bool isDark;
  final bool isFloating;
  const AetherChatView({super.key, required this.isDark, this.isFloating = false});

  @override
  State<AetherChatView> createState() => _AetherChatViewState();
}

class _AetherChatViewState extends State<AetherChatView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0, 
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutQuart,
      );
    }
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final state = context.read<StateChat>();
    state.sendMessageToAI(text);
    _controller.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    // 🔒 CRITICAL: Do NOT use context.watch<StateChat>() here.
    // That would rebuild the entire tree (including TextField) on every
    // notifyListeners() — causing Web IME focus loss.
    // Instead, child widgets use Selector for only the data they need.

    return Stack(
      children: [
        // 🌌 Background Ambient Glow
        Positioned(
          top: -100,
          right: -100,
          child: IgnorePointer(
            child: Container(
              width: widget.isFloating ? 400 : 800,
              height: widget.isFloating ? 400 : 800,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [GlassColors.primary.withOpacity(0.02), Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        
        Positioned.fill(
          child: Column(
          children: [
            Expanded(
              child: _MessageList(
                scrollController: _scrollController,
                isDark: widget.isDark,
                isFloating: widget.isFloating,
              ),
            ),
            
            // Input Area — isolated from StateChat rebuilds
            _ChatInputArea(
              controller: _controller,
              focusNode: _focusNode,
              onSend: _handleSend,
              isDark: widget.isDark,
              isFloating: widget.isFloating,
            ),
          ],
        ),
        ),
      
        // 🗑️ Task 36.1: Reset Session Button (ONLY SHOW IN FLOATING MODE)
        if (widget.isFloating)
          Positioned(
            top: 8,
            left: 8,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  context.read<StateChat>().resetFullChat();
                  GlassNotifications.show(context, 'SESSION RESET');
                },
                borderRadius: BorderRadius.circular(ExecutiveRadius.circular),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(ExecutiveRadius.circular),
                    border: Border.all(color: GlassColors.outlineVariant.withOpacity(0.1)),
                  ),
                  child: Icon(Icons.delete_sweep_rounded, size: 16, color: GlassColors.onSurfaceVariant.withOpacity(0.6)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _MessageList — watches StateChat.messages + isTyping
// Isolated rebuild: only this subtree rebuilds when chat data changes.
// ═══════════════════════════════════════════════════════════════════════════
class _MessageList extends StatelessWidget {
  final ScrollController scrollController;
  final bool isDark;
  final bool isFloating;

  const _MessageList({
    required this.scrollController,
    required this.isDark,
    required this.isFloating,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = isFloating ? 16.0 : ExecutiveSpacing.containerPadding(context);

    // Selector uses a hash of (message count + last message text hashCode)
    // so it rebuilds both when new messages arrive AND during streaming.
    return Selector<StateChat, int>(
      selector: (_, chat) {
        if (chat.messages.isEmpty) return 0;
        return Object.hash(chat.messages.length, chat.messages.first.text.hashCode);
      },
      builder: (_, _, __) {
        final chatState = context.read<StateChat>();
        final messages = chatState.messages;
        final isTyping = chatState.isTyping;

        return SelectionArea(
          child: ListView.builder(
            controller: scrollController,
            reverse: true,
            padding: EdgeInsets.all(horizontalPadding),
            itemCount: messages.length + (isTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (isTyping && index == 0) {
                return ThinkingIndicator(isDark: isDark);
              }
              final msgIndex = isTyping ? index - 1 : index;
              final msg = messages[msgIndex];
              if (!msg.isUser) {
                return AssistantMessageBubble(
                  message: msg,
                  isDark: isDark,
                );
              } else {
                return UserMessageBubble(
                  message: msg,
                  isDark: isDark,
                );
              }
            },
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _ChatInputArea — watches ONLY pendingFileMaps count
// Does NOT rebuild when isTyping changes → prevents IME focus loss.
// ═══════════════════════════════════════════════════════════════════════════
class _ChatInputArea extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final bool isDark;
  final bool isFloating;

  const _ChatInputArea({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.isDark,
    required this.isFloating,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = isFloating ? 16.0 : ExecutiveSpacing.containerPadding(context);
    final bottomPadding = isFloating ? 16.0 : 32.0;

    return Selector<StateChat, int>(
      selector: (_, chat) => chat.pendingFileMaps.length,
      builder: (_, fileCount, __) {
        final chatState = context.read<StateChat>();
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: bottomPadding,
          ),
          child: AetherChatInput(
            isDark: isDark,
            controller: controller,
            focusNode: focusNode,
            pendingFiles: chatState.pendingFileMaps,
            onSend: onSend,
            onFilesPicked: (files) => chatState.addPendingFiles(files),
            onRemoveFile: (i) => chatState.removeFile(i),
            onPreviewImage: (url) {},
          ),
        );
      },
    );
  }
}

