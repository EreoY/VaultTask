import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chat_model.dart';
import '../../state_managers/state_chat.dart';
import '../theme/glass_theme.dart';
import '../common/glass_widgets.dart';
import 'widgets/aether_chat_view.dart';

class ChatPage extends StatefulWidget {
  final bool isDark;
  final ValueChanged<int>? onNavigate;
  final bool isActive;
  const ChatPage({
    super.key,
    required this.isDark,
    this.onNavigate,
    this.isActive = true,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  bool _showSidebar = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StateChat>().switchToGlobalContext();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StateChat>(
      builder: (context, chatState, _) {
        return Column(
          children: [
            AetherStaggeredFadeIn(
              index: 0,
              isActive: widget.isActive,
              child: _buildHeader(),
            ),
            Expanded(
              child: AetherStaggeredFadeIn(
                index: 1,
                isActive: widget.isActive,
                child: Row(
                  children: [
                    if (_showSidebar) _buildSidebar(chatState),
                    Expanded(
                      child: AetherChatView(
                        isDark: widget.isDark,
                        onNavigate: widget.onNavigate,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
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
              Row(
                children: [
                  Text(
                    'Global Chat',
                    style: GlassText.headlineXL().copyWith(fontSize: 48),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: Icon(
                      _showSidebar
                          ? Icons.menu_open_rounded
                          : Icons.menu_rounded,
                      color: GlassColors.primary.withOpacity(0.7),
                      size: 24,
                    ),
                    onPressed: () {
                      setState(() {
                        _showSidebar = !_showSidebar;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: GlassColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Ready to collaborate with your strategic workflow.',
                    style: GlassText.bodyMD().copyWith(
                      color: GlassColors.onSurfaceVariant.withOpacity(0.6),
                    ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(
                        ExecutiveRadius.circular,
                      ),
                      border: Border.all(
                        color: GlassColors.outlineVariant.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_sweep_rounded,
                          size: 20,
                          color: GlassColors.onSurfaceVariant.withOpacity(0.6),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'RESET SESSION',
                          style: GlassText.labelSM().copyWith(
                            fontSize: 10,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.bold,
                            color: GlassColors.onSurfaceVariant.withOpacity(
                              0.6,
                            ),
                          ),
                        ),
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

  Widget _buildSidebar(StateChat stateChat) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: GlassColors.onSurface.withOpacity(0.01),
        border: Border(right: BorderSide(color: GlassColors.ghostBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () {
                stateChat.startNewGlobalSession();
                setState(() {
                  _showSidebar = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GlassColors.primary.withOpacity(0.1),
                foregroundColor: GlassColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ExecutiveRadius.m),
                  side: BorderSide(color: GlassColors.primary.withOpacity(0.2)),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.add, size: 16),
              label: Text(
                'New Session',
                style: GlassText.labelSM().copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: stateChat.globalSessions.length,
              itemBuilder: (context, index) {
                final session = stateChat.globalSessions[index];
                final isSelected =
                    stateChat.currentGlobalSession?.id == session.id;

                return _buildSidebarSessionItem(session, isSelected, stateChat);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarSessionItem(
    ChatSession session,
    bool isSelected,
    StateChat stateChat,
  ) {
    final nameController = TextEditingController(text: session.name);
    bool isEditing = false;

    return StatefulBuilder(
      builder: (context, setSessionState) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? GlassColors.primary.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(ExecutiveRadius.m),
            border: Border.all(
              color: isSelected
                  ? GlassColors.primary.withOpacity(0.2)
                  : Colors.transparent,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.only(left: 12, right: 4),
            dense: true,
            title: isEditing
                ? TextField(
                    controller: nameController,
                    style: GlassText.bodyMD(),
                    autofocus: true,
                    onSubmitted: (val) async {
                      if (val.trim().isNotEmpty) {
                        await stateChat.renameSession(session.id, val.trim());
                      }
                      setSessionState(() => isEditing = false);
                    },
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  )
                : Text(
                    session.name,
                    style: GlassText.bodyMD().copyWith(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? GlassColors.primary
                          : GlassColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
            onTap: isEditing ? null : () => _selectSession(session, stateChat),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected && !isEditing) ...[
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    onPressed: () {
                      setSessionState(() => isEditing = true);
                    },
                    color: GlassColors.onSurfaceVariant.withOpacity(0.5),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 14),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Session'),
                          content: const Text(
                            'Are you sure you want to delete this session?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await stateChat.deleteSession(session.id);
                      }
                    },
                    color: GlassColors.error.withOpacity(0.7),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _selectSession(ChatSession session, StateChat stateChat) {
    stateChat.selectGlobalSession(session);
    setState(() {
      _showSidebar = false;
    });
  }
}

class _AmbientGlow extends StatelessWidget {
  final Color color;
  final double size;

  const _AmbientGlow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}
