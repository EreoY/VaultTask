import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/chat_model.dart';
import '../../theme/glass_theme.dart';
import '../../common/glass_widgets.dart';

/// Aether AI Chat Atomic Components

class ChatAI {
  static Widget avatar(bool isDark) {
    final fallback = Container(
      color: GlassColors.primary.withOpacity(0.1),
      child: const Center(
        child: Icon(Icons.psychology_rounded, color: GlassColors.primary, size: 24),
      ),
    );

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: GlassColors.primary.withOpacity(0.2), width: 1),
      ),
      child: ClipOval(
        child: Container(
          color: GlassColors.primary.withOpacity(0.1),
          child: const Center(
            child: Text('🤖', style: TextStyle(fontSize: 22)),
          ),
        ),
      ),
    );
  }

  static Widget label(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: GlassText.label().copyWith(
          fontSize: 10,
          color: GlassColors.primary,
          letterSpacing: 2.0,
        ),
      ),
    );
  }
}

class ChatUser {
  static Widget avatar(bool isDark) {
    final user = FirebaseAuth.instance.currentUser;
    final fallback = const Icon(Icons.person_outline, color: GlassColors.primary, size: 22);

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: GlassColors.surfaceHighest.withOpacity(0.2),
        border: Border.all(color: GlassColors.outline.withOpacity(0.1), width: 1),
      ),
      child: ClipOval(
        child: user?.photoURL != null 
          ? Image.network(
              user!.photoURL!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => fallback,
            )
          : fallback,
      ),
    );
  }

  static Widget label(String text, bool isDark) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? user?.email?.split('@').first ?? 'Commander';
    
    return Padding(
      padding: const EdgeInsets.only(right: 4, bottom: 8),
      child: Text(
        name.toUpperCase(),
        style: GlassText.label().copyWith(
          fontSize: 10,
          color: GlassColors.onSurfaceVariant.withOpacity(0.6),
          letterSpacing: 2.0,
        ),
      ),
    );
  }
}

class CollapsibleCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final String content;
  final bool isDark;
  final double maxWidth;

  const CollapsibleCard({
    super.key,
    required this.title,
    required this.icon,
    required this.content,
    required this.isDark,
    required this.maxWidth,
  });

  @override
  State<CollapsibleCard> createState() => _CollapsibleCardState();
}

class _CollapsibleCardState extends State<CollapsibleCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        isDark: widget.isDark,
        padding: EdgeInsets.zero,
        radius: ExecutiveRadius.m,
        child: InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(ExecutiveRadius.m),
          child: Container(
            constraints: BoxConstraints(maxWidth: widget.maxWidth),
            padding: const EdgeInsets.all(16),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutQuart,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(widget.icon, size: 16, color: GlassColors.primary),
                      const SizedBox(width: 10),
                      Text(
                        widget.title.toUpperCase(),
                        style: GlassText.label().copyWith(fontSize: 10, letterSpacing: 1.5),
                      ),
                      const SizedBox(width: 10),
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 250),
                        child: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: GlassColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                  if (_isExpanded) ...[
                    const SizedBox(height: 16),
                    Text(
                      widget.content,
                      style: GlassText.body().copyWith(
                        fontSize: 14,
                        color: GlassColors.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CollapsibleTools extends StatefulWidget {
  final List<ToolCallInfo> toolCalls;
  final bool isDark;

  const CollapsibleTools({
    super.key,
    required this.toolCalls, 
    required this.isDark,
  });

  @override
  State<CollapsibleTools> createState() => _CollapsibleToolsState();
}

class _CollapsibleToolsState extends State<CollapsibleTools> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: GlassDecorations.surface(radius: ExecutiveRadius.s),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  size: 16,
                  color: GlassColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'SYSTEM ACTIONS (${widget.toolCalls.length})',
                  style: GlassText.label().copyWith(fontSize: 9),
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.toolCalls.map((tool) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: GlassDecorations.surface(radius: ExecutiveRadius.s),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.terminal_rounded, size: 12, color: GlassColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      "TOOL: ${tool.name.toUpperCase()}",
                      style: GlassText.label().copyWith(fontSize: 9),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ],
    );
  }
}

class ThinkingIndicator extends StatelessWidget {
  final bool isDark;
  const ThinkingIndicator({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ChatAI.avatar(isDark),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: GlassDecorations.surface(radius: ExecutiveRadius.m),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AnimatedDots(color: GlassColors.primary),
                const SizedBox(width: 12),
                Text(
                  'Thinking...',
                  style: GlassText.body().copyWith(
                    fontSize: 14,
                    color: GlassColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedDots extends StatefulWidget {
  final Color color;
  const _AnimatedDots({required this.color});

  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) => AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true));

    _animations = _controllers.asMap().entries.map((entry) {
      final index = entry.key;
      final controller = entry.value;
      return Tween<double>(begin: 0.2, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Interval(index * 0.2, 0.6 + (index * 0.2), curve: Curves.easeInOut),
        ),
      );
    }).toList();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) => AnimatedBuilder(
        animation: _animations[index],
        builder: (context, child) => Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(_animations[index].value),
            shape: BoxShape.circle,
          ),
        ),
      )),
    );
  }
}
