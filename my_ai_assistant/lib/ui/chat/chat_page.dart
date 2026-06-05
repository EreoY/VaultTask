import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chat_model.dart';
import '../../state_managers/state_chat.dart';
import '../theme/glass_theme.dart';
import '../common/glass_widgets.dart';
import 'widgets/chat_widgets.dart';
import 'widgets/chat_bubbles.dart';
import 'widgets/chat_input.dart';
import 'widgets/aether_chat_view.dart';

class ChatPage extends StatefulWidget {
  final bool isDark;
  const ChatPage({super.key, required this.isDark});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: AetherChatView(isDark: widget.isDark),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ExecutiveSpacing.containerPadding(context),
        ExecutiveSpacing.containerPadding(context),
        ExecutiveSpacing.containerPadding(context),
        0,
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Misty AI',
                style: GlassText.headlineXL().copyWith(fontSize: 48),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: GlassColors.success, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Ready to collaborate with your strategic workflow.',
                    style: GlassText.bodyMD().copyWith(color: GlassColors.onSurfaceVariant.withOpacity(0.6)),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    context.read<StateChat>().resetFullChat();
                    GlassNotifications.show(context, 'SESSION RESET');
                  },
                  borderRadius: BorderRadius.circular(ExecutiveRadius.circular),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(ExecutiveRadius.circular),
                      border: Border.all(color: GlassColors.outlineVariant.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.delete_sweep_rounded, size: 20, color: GlassColors.onSurfaceVariant.withOpacity(0.6)),
                        const SizedBox(width: 12),
                        Text('RESET SESSION', style: GlassText.labelSM().copyWith(
                          fontSize: 10,
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.bold,
                          color: GlassColors.onSurfaceVariant.withOpacity(0.6),
                        )),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


}

class _AmbientGlow extends StatelessWidget {
  final Color color;
  final double size;

  const _AmbientGlow({required this.color, this.size = 800});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}
