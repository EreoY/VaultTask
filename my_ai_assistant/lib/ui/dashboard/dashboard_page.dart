import 'package:flutter/material.dart';
import '../common/ime_safe_text_field.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../models/board_model.dart';
import '../../state_managers/state_boards.dart';
import '../../state_managers/state_tasks.dart';
import '../theme/glass_theme.dart';
import '../common/glass_widgets.dart';
import '../common/responsive_layout.dart';
import 'widgets/dashboard_widgets.dart';

class DashboardPage extends StatefulWidget {
  final bool isDark;
  const DashboardPage({super.key, required this.isDark});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<StateBoards>().fetchAllBoards();
      if (mounted) {
        final boards = context.read<StateBoards>().boards;
        context.read<StateTasks>().fetchAllTasks(boards);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(ExecutiveSpacing.containerPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: ExecutiveSpacing.sectionGap(context)),
          
          // Layout Grid
          isDesktop 
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildMainColumn(context)),
                  SizedBox(width: ExecutiveSpacing.gutter(context)),
                  Expanded(flex: 1, child: _buildSideColumn(context)),
                ],
              )
            : Column(
                children: [
                  _buildMainColumn(context),
                  SizedBox(height: ExecutiveSpacing.stackMd(context)),
                  _buildSideColumn(context),
                ],
              ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat('MMMM').format(now),
          style: GlassText.headlineXL().copyWith(
            fontSize: MediaQuery.of(context).size.width < 600 ? 48 : 83,
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Text(
            'A curated overview of your upcoming commitments and strategic milestones.',
            style: GlassText.bodyLG().copyWith(
              color: GlassColors.onSurfaceVariant.withOpacity(0.8),
              fontSize: MediaQuery.of(context).size.width < 600 ? 16 : 21,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainColumn(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    
    return Column(
      children: [
        DashboardBentoCard(
          title: 'Daily Overview',
          icon: Icons.auto_awesome_outlined,
          isDark: widget.isDark,
          height: isMobile ? null : 360,
          child: Consumer<StateTasks>(
            builder: (context, state, child) {
              final total = state.totalCompletedCount + state.totalInProgressCount;
              final progress = total > 0 ? state.totalCompletedCount / total : 0.0;
              final boardsCount = context.read<StateBoards>().boards.length;
              
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ProgressMetric(label: 'Overall Strategic Completion', value: progress),
                  SizedBox(height: ExecutiveSpacing.stackMd(context)),
                  ProgressMetric(label: 'Active Strategic Clusters', value: boardsCount > 0 ? 1.0 : 0.0, color: GlassColors.gold),
                  const SizedBox(height: 48),
                  
                  // Responsive Stats layout
                  isMobile
                    ? Column(
                        children: [
                          _buildStatMiniCard('COMPLETED', state.totalCompletedCount.toString().padLeft(2, '0'), Icons.check_circle_outline),
                          const SizedBox(height: 12),
                          _buildStatMiniCard('IN PROGRESS', state.totalInProgressCount.toString().padLeft(2, '0'), Icons.pending_outlined),
                          const SizedBox(height: 12),
                          _buildStatMiniCard('UPCOMING', state.totalUpcomingCount.toString().padLeft(2, '0'), Icons.calendar_today_outlined),
                        ],
                      )
                    : SizedBox(
                        height: 120,
                        child: Row(
                          children: [
                            _buildStatMiniCard('COMPLETED', state.totalCompletedCount.toString().padLeft(2, '0'), Icons.check_circle_outline),
                            const SizedBox(width: 12),
                            _buildStatMiniCard('IN PROGRESS', state.totalInProgressCount.toString().padLeft(2, '0'), Icons.pending_outlined),
                            const SizedBox(width: 12),
                            _buildStatMiniCard('UPCOMING', state.totalUpcomingCount.toString().padLeft(2, '0'), Icons.calendar_today_outlined),
                          ],
                        ),
                      ),
                ],
              );
            },
          ),
        ),
        SizedBox(height: ExecutiveSpacing.stackMd(context)),
        DashboardBentoCard(
          title: 'Recent Projects',
          icon: Icons.folder_open_outlined,
          isDark: widget.isDark,
          height: 400,
          trailing: _buildGhostButton('JOIN TEAM BOARD', Icons.group_add_rounded, onTap: () => _showJoinBoardDialog(context)),
          child: Consumer<StateBoards>(
            builder: (context, state, child) {
              final boards = state.boards.take(3).toList();
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: boards.length,
                separatorBuilder: (context, index) => Divider(height: 40, color: GlassColors.ghostBorder),
                itemBuilder: (context, index) {
                  final board = boards[index];
                  final currentUid = AuthService().currentUser?.uid;
                  final isOwner = board.ownerUid == currentUid;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: GlassDecorations.surface(radius: ExecutiveRadius.xl),
                      child: Icon(Icons.grid_view_rounded, color: Color(board.color), size: 20),
                    ),
                    title: Text(
                      board.name, 
                      style: GlassText.bodyMD().copyWith(fontWeight: FontWeight.w600)
                    ),
                    subtitle: Text(
                      'Updated 2 hours ago', 
                      style: GlassText.secondary().copyWith(fontSize: 12)
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert_rounded, color: GlassColors.onSurfaceVariant.withOpacity(0.5)),
                      color: GlassColors.background,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (value) {
                        if (value == 'copy_id') {
                          Clipboard.setData(ClipboardData(text: board.id));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Board ID copied to clipboard')),
                          );
                        } else if (value == 'rename' && isOwner) {
                          _showRenameBoardDialog(context, board);
                        } else if (value == 'members' && isOwner) {
                          state.setSelectedBoard(board);
                        }
                      },
                      itemBuilder: (context) => [
                        if (isOwner)
                          PopupMenuItem(
                            value: 'rename',
                            child: Row(
                              children: [
                                Icon(Icons.edit_rounded, size: 16, color: GlassColors.primary),
                                const SizedBox(width: 8),
                                Text('Rename Board', style: GlassText.bodyMD()),
                              ],
                            ),
                          ),
                        if (isOwner)
                          PopupMenuItem(
                            value: 'members',
                            child: Row(
                              children: [
                                Icon(Icons.group_rounded, size: 16, color: GlassColors.primary),
                                const SizedBox(width: 8),
                                Text('Manage Members', style: GlassText.bodyMD()),
                              ],
                            ),
                          ),
                        PopupMenuItem(
                          value: 'copy_id',
                          child: Row(
                            children: [
                              Icon(Icons.copy_rounded, size: 16, color: GlassColors.primary),
                              const SizedBox(width: 8),
                              Text('Copy Board ID', style: GlassText.bodyMD()),
                            ],
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      state.setSelectedBoard(board);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSideColumn(BuildContext context) {
    return Column(
      children: [
        DashboardBentoCard(
          title: 'Aether Insight',
          icon: Icons.auto_awesome,
          isDark: widget.isDark,
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Based on your recent flow state, consider optimizing your upcoming schedule.',
                style: GlassText.bodyMD().copyWith(height: 1.6),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: GlassColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(ExecutiveRadius.xl),
                  border: Border.all(color: GlassColors.ghostBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SCHEDULE CONFLICT',
                      style: GlassText.labelSM().copyWith(color: GlassColors.gold, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Thursday afternoon looks heavy. Consider moving the Sync.',
                      style: GlassText.bodyMD().copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: ExecutiveSpacing.stackMd(context)),
        Container(
          height: 260,
          width: double.infinity,
          decoration: GlassDecorations.surface(radius: ExecutiveRadius.xl),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Image.network(
                'https://lh3.googleusercontent.com/aida/ADBb0ujiphgSb_p0c2_sYHwjXWA8fdhrcutU48fDIPm2q-NbWIIkrERsC3-kYCq0akTXYcfePGfRsxFd8QCHuSTvrsGz5F4FZFKZe-IWe6qlqk7lNux0yxW28zwTtMj1Pjs1RojgQf7PJzckgjccRm1Fs-IW6_RG4Btvh5dZ-0qXrFbX_BKUsTDnKysZdi0_YFbybQX1boX00jGXYRQ8nqZA9_vsWC6gh2vSvLMJxRNPaTUucnpwGMJz1BIcx8YW_f6LdE6BB5tAXr6oBg',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                opacity: const AlwaysStoppedAnimation(0.4),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                child: Text(
                  'FOCUS MODE',
                  style: GlassText.labelSM().copyWith(color: GlassColors.primary, letterSpacing: 2.0),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatMiniCard(String label, String value, IconData icon) {
    return Expanded(
      flex: Responsive.isMobile(context) ? 0 : 1,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: GlassColors.primary.withOpacity(0.03),
          borderRadius: BorderRadius.circular(ExecutiveRadius.xl),
          border: Border.all(color: GlassColors.ghostBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: GlassColors.primary.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text(value, style: GlassText.headlineLG().copyWith(fontSize: 28)),
            const SizedBox(height: 4),
            Text(label, style: GlassText.labelSM().copyWith(fontSize: 8, color: GlassColors.onSurfaceVariant.withOpacity(0.6))),
          ],
        ),
      ),
    );
  }

  Widget _buildGhostButton(String label, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: GlassColors.gold.withOpacity(0.1),
          borderRadius: BorderRadius.circular(ExecutiveRadius.circular),
          border: Border.all(color: GlassColors.gold.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: GlassColors.gold),
            const SizedBox(width: 8),
            Text(label, style: GlassText.labelSM().copyWith(color: GlassColors.gold, fontSize: 9, letterSpacing: 1.0)),
          ],
        ),
      ),
    );
  }

  void _showJoinBoardDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => Center(
        child: Container(
          width: 400,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: GlassDecorations.surface(radius: 24),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('JOIN TEAM BOARD', style: GlassText.labelSM().copyWith(color: GlassColors.primary, letterSpacing: 2)),
                const SizedBox(height: 24),
                Text('Enter the Board ID shared by your colleague.', style: GlassText.bodyMD().copyWith(color: GlassColors.onSurfaceVariant)),
                const SizedBox(height: 24),
                ImeSafeTextField(
                  controller: controller,
                  autofocus: true,
                  style: GlassText.bodyLG(),
                  decoration: InputDecoration(
                    hintText: 'e.g., 1715000000000',
                    hintStyle: GlassText.bodyLG().copyWith(color: GlassColors.onSurfaceVariant.withOpacity(0.3)),
                    filled: true,
                    fillColor: GlassColors.primary.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: GlassColors.ghostBorder),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('CANCEL', style: GlassText.labelSM().copyWith(color: GlassColors.onSurfaceVariant)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final id = controller.text.trim();
                          if (id.isEmpty) return;
                          try {
                            await context.read<StateBoards>().joinBoardById(id);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Joined board successfully!')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to join board: $e')),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GlassColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('JOIN BOARD', style: GlassText.labelSM().copyWith(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRenameBoardDialog(BuildContext context, BoardModel board) {
    final controller = TextEditingController(text: board.name);
    showDialog(
      context: context,
      builder: (context) => Center(
        child: Container(
          width: 400,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: GlassDecorations.surface(radius: 24),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RENAME BOARD', style: GlassText.labelSM().copyWith(color: GlassColors.primary, letterSpacing: 2)),
                const SizedBox(height: 24),
                ImeSafeTextField(
                  controller: controller,
                  autofocus: true,
                  style: GlassText.bodyLG(),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: GlassColors.primary.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: GlassColors.ghostBorder),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('CANCEL', style: GlassText.labelSM().copyWith(color: GlassColors.onSurfaceVariant)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final newName = controller.text.trim();
                          if (newName.isEmpty || newName == board.name) return;
                          try {
                            await context.read<StateBoards>().updateBoard(board.copyWith(name: newName));
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Board renamed successfully!')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to rename board: $e')),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GlassColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('RENAME', style: GlassText.labelSM().copyWith(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
