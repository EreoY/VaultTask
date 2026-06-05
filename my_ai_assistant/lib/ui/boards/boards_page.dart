import 'package:flutter/material.dart';
import '../common/ime_safe_text_field.dart';
import 'package:provider/provider.dart';
import '../../models/board_model.dart';
import '../../models/workspace_model.dart';
import '../../state_managers/state_boards.dart';
import '../theme/glass_theme.dart';
import '../common/glass_widgets.dart';
import '../common/responsive_layout.dart';
import 'widgets/board_edit_modal.dart';

class BoardsPage extends StatefulWidget {
  final bool isDark;
  const BoardsPage({super.key, required this.isDark});

  @override
  State<BoardsPage> createState() => _BoardsPageState();
}

class _BoardsPageState extends State<BoardsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StateBoards>().fetchAllBoards();
    });
  }

  @override
  Widget build(BuildContext context) {
    final boardsState = context.watch<StateBoards>();
    final selectedWorkspace = boardsState.selectedWorkspace;
    final boards = selectedWorkspace != null 
        ? boardsState.boards.where((b) => b.workspaceId == selectedWorkspace.id).toList()
        : <BoardModel>[];
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);

    return Column(
      children: [
        _buildHeader(context, selectedWorkspace),
        _buildWorkspaceTabs(context, boardsState),
        const SizedBox(height: 16),
        Expanded(
          child: boardsState.isLoading 
            ? const Center(child: CircularProgressIndicator(color: GlassColors.primary))
            : boards.isEmpty 
              ? _buildEmptyState(selectedWorkspace)
              : GridView.builder(
                  padding: EdgeInsets.all(isMobile ? 16 : ExecutiveSpacing.containerPadding(context)),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 3),
                    childAspectRatio: isMobile ? 1.8 : 1.5,
                    crossAxisSpacing: ExecutiveSpacing.stackMd(context),
                    mainAxisSpacing: ExecutiveSpacing.stackMd(context),
                  ),
                  itemCount: boards.length,
                  itemBuilder: (context, index) {
                    return _BoardCard(board: boards[index], isDark: widget.isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildWorkspaceTabs(BuildContext context, StateBoards boardsState) {
    if (boardsState.workspaces.isEmpty) return const SizedBox.shrink();

    final isMobile = Responsive.isMobile(context);

    return Container(
      height: 48,
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : ExecutiveSpacing.containerPadding(context),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: boardsState.workspaces.length,
        itemBuilder: (context, index) {
          final workspace = boardsState.workspaces[index];
          final isSelected = boardsState.selectedWorkspace?.id == workspace.id;

          return GestureDetector(
            onTap: () => boardsState.setSelectedWorkspace(workspace),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? GlassColors.primary.withOpacity(0.15) : GlassColors.surfaceBright.withOpacity(0.05),
                borderRadius: BorderRadius.circular(ExecutiveRadius.circular),
                border: Border.all(
                  color: isSelected ? GlassColors.primary : GlassColors.ghostBorder.withOpacity(0.5),
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    workspace.type == 'personal' ? Icons.person_rounded : Icons.group_rounded,
                    size: 16,
                    color: isSelected ? GlassColors.primary : GlassColors.onSurfaceVariant.withOpacity(0.6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    workspace.name,
                    style: GlassText.bodyMD().copyWith(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? GlassColors.onSurface : GlassColors.onSurfaceVariant.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WorkspaceModel? selectedWorkspace) {
    final isMobile = Responsive.isMobile(context);
    
    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : ExecutiveSpacing.containerPadding(context),
        isMobile ? 16 : ExecutiveSpacing.containerPadding(context),
        isMobile ? 16 : ExecutiveSpacing.containerPadding(context),
        24,
      ),
      child: isMobile 
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Project Boards',
                style: GlassText.headlineXL().copyWith(fontSize: 32),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildGhostButton('JOIN BOARD', Icons.group_add_rounded, onTap: () => _showJoinBoardDialog(context))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildNewBoardButton(selectedWorkspace)),
                ],
              ),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Project Boards',
                    style: GlassText.headlineXL().copyWith(fontSize: 48),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Navigate through your active strategic clusters.',
                    style: GlassText.bodyMD().copyWith(color: GlassColors.onSurfaceVariant.withOpacity(0.6)),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildGhostButton('JOIN BOARD', Icons.group_add_rounded, onTap: () => _showJoinBoardDialog(context)),
                  const SizedBox(width: 12),
                  _buildNewBoardButton(selectedWorkspace),
                ],
              ),
            ],
          ),
    );
  }

  Widget _buildGhostButton(String label, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: GlassColors.gold.withOpacity(0.1),
          borderRadius: BorderRadius.circular(ExecutiveRadius.circular),
          border: Border.all(color: GlassColors.gold.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: GlassColors.gold),
            const SizedBox(width: 8),
            Text(label, style: GlassText.labelSM().copyWith(color: GlassColors.gold, fontSize: 10)),
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
          decoration: GlassDecorations.solidSurface(radius: 24, hasShadow: true),
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
                        child: Text('JOIN BOARD', style: GlassText.labelSM().copyWith(color: GlassColors.onPrimary, fontWeight: FontWeight.bold)),
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

  Widget _buildNewBoardButton(WorkspaceModel? selectedWorkspace) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => BoardEditModal(isDark: widget.isDark, workspace: selectedWorkspace),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: GlassColors.gold.withOpacity(0.1),
          borderRadius: BorderRadius.circular(ExecutiveRadius.circular),
          border: Border.all(color: GlassColors.gold.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded, size: 20, color: GlassColors.gold),
            const SizedBox(width: 8),
            Text(
              'NEW BOARD',
              style: GlassText.labelSM().copyWith(color: GlassColors.gold, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(WorkspaceModel? selectedWorkspace) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.grid_view_rounded, size: 64, color: GlassColors.primary.withOpacity(0.1)),
          const SizedBox(height: 24),
          Text('No projects found in this workspace.', style: GlassText.bodyLG()),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (context) => BoardEditModal(isDark: widget.isDark, workspace: selectedWorkspace),
              );
            },
            child: Text('Create your first board', style: GlassText.bodyMD().copyWith(color: GlassColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _BoardCard extends StatelessWidget {
  final BoardModel board;
  final bool isDark;

  const _BoardCard({required this.board, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      isDark: isDark,
      padding: const EdgeInsets.all(24),
      radius: ExecutiveRadius.xl,
      onTap: () {
        context.read<StateBoards>().setSelectedBoard(board);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Color(board.color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(ExecutiveRadius.l),
              border: Border.all(color: Color(board.color).withOpacity(0.2)),
            ),
            child: Icon(Icons.grid_view_rounded, color: Color(board.color), size: 20),
          ),
          const Spacer(),
          Text(
            board.name,
            style: GlassText.headlineMD().copyWith(fontSize: 20, height: 1.2),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${board.members.length} MEMBERS',
                style: GlassText.labelSM().copyWith(fontSize: 9, color: GlassColors.onSurfaceVariant.withOpacity(0.5)),
              ),
              const SizedBox(width: 8),
              Container(width: 3, height: 3, decoration: BoxDecoration(color: GlassColors.ghostBorder, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(
                'ACTIVE',
                style: GlassText.labelSM().copyWith(fontSize: 9, color: GlassColors.success.withOpacity(0.8)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
