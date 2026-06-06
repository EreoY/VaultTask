import 'package:flutter/material.dart';
import '../../common/ime_safe_text_field.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/chat_model.dart';
import '../../../state_managers/state_chat.dart';
import '../../../state_managers/state_boards.dart';
import '../../theme/glass_theme.dart';
import '../../common/glass_widgets.dart';

class ProposalDraftCard extends StatelessWidget {
  final bool isDark;
  final ProposalDraft? draft;
  const ProposalDraftCard({super.key, required this.isDark, this.draft});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StateChat>();
    final draft = this.draft ?? state.draft;
    if (draft == null) return const SizedBox.shrink();

    return Container(
      width: 500,
      decoration: BoxDecoration(
        color: GlassColors.glassSurface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: GlassColors.gold.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDraftHeader(draft),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                ...draft.tasks.asMap().entries.map((entry) {
                  return _buildInteractiveTaskItem(context, state, draft, entry.key, entry.value, isDark);
                }),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: DraftActionButton(
                        label: 'CANCEL',
                        onTap: () => state.cancelDraft(),
                        isPrimary: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DraftActionButton(
                        label: 'EXECUTE STRATEGY',
                        onTap: () => state.submitDraft(),
                        isPrimary: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftHeader(ProposalDraft draft) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: GlassColors.gold.withOpacity(0.05),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, size: 16, color: GlassColors.gold),
          const SizedBox(width: 12),
          Text(
            draft.originalCall.name.replaceAll('_', ' ').toUpperCase(),
            style: GlassText.labelSM().copyWith(color: GlassColors.gold, letterSpacing: 2),
          ),
          const Spacer(),
          if (draft.selectedBoard != null)
            Text(
              draft.selectedBoard!.name.toUpperCase(),
              style: GlassText.labelSM().copyWith(color: GlassColors.gold.withOpacity(0.5), fontSize: 10),
            ),
        ],
      ),
    );
  }

  Widget _buildInteractiveTaskItem(BuildContext context, StateChat state, ProposalDraft draft, int idx, TaskDraftItem task, bool isDark) {
    final isDeletion = task.originalAction == 'delete_team_task';
    final accentColor = isDeletion ? GlassColors.error : GlassColors.gold;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.symmetric(
        horizontal: 16, 
        vertical: isDeletion ? 10 : 20 
      ),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isDeletion ? task.isSelected : true) ? accentColor.withOpacity(0.2) : Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Task 31.1: Multi-Purpose Checkbox
              if (isDeletion)
                InkWell(
                  onTap: () => state.toggleDraftItemSelection(idx),
                  child: Icon(
                    task.isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                    size: 20,
                    color: task.isSelected ? accentColor : GlassColors.onSurface.withOpacity(0.3),
                  ),
                )
              else
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: task.isCompleted,
                    onChanged: (v) => state.updateDraftIsCompleted(idx, v ?? false),
                    activeColor: GlassColors.success,
                    checkColor: Colors.white,
                    side: BorderSide(color: GlassColors.gold.withOpacity(0.5), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ImeSafeTextField(
                            controller: TextEditingController(text: task.title)..selection = TextSelection.fromPosition(TextPosition(offset: task.title.length)),
                            onChanged: (v) => state.updateDraftItemTitle(idx, v),
                            enabled: !isDeletion, 
                            style: GlassText.bodyMD().copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: isDeletion ? 13 : 14,
                              decoration: (isDeletion ? false : task.isCompleted) ? TextDecoration.lineThrough : null,
                              color: (isDeletion ? !task.isSelected : task.isCompleted) ? GlassColors.onSurfaceVariant.withOpacity(0.3) : null,
                            ),
                            decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: 'Task Title'),
                          ),
                        ),
                        
                        // Task 31.2: Status Indicator in Deletion Mode
                        if (isDeletion) 
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (task.isCompleted ? GlassColors.success : const Color(0xFFFB923C)).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: (task.isCompleted ? GlassColors.success : const Color(0xFFFB923C)).withOpacity(0.2)),
                            ),
                            child: Text(
                              task.isCompleted ? 'DONE' : 'PENDING',
                              style: GlassText.labelSM().copyWith(
                                fontSize: 8, 
                                color: task.isCompleted ? GlassColors.success : const Color(0xFFFB923C),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (!isDeletion || task.isSelected) ...[
            if (!isDeletion) ...[
              const Divider(height: 24),
              ImeSafeTextField(
                controller: TextEditingController(text: task.description)..selection = TextSelection.fromPosition(TextPosition(offset: task.description.length)),
                onChanged: (v) => state.updateDraftItemDescription(idx, v),
                style: GlassText.bodyMD().copyWith(color: GlassColors.onSurfaceVariant),
                maxLines: null,
                decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: 'Add tactical details...'),
              ),
            ],
            
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSmallChip(
                  icon: Icons.calendar_today_outlined,
                  label: _formatDate(task.dueDate),
                  enabled: !isDeletion,
                  onTap: isDeletion ? null : () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: task.dueDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) state.updateDraftItemDueDate(idx, picked);
                  },
                ),
                _buildSmallChip(
                  icon: Icons.label_outline_rounded,
                  label: task.labelIds.isEmpty ? 'LABELS' : '${task.labelIds.length} LABELS',
                  enabled: !isDeletion,
                  onTap: isDeletion ? null : () => _showLabelPicker(context, state, draft, idx, task),
                ),
                _buildSmallChip(
                  icon: Icons.view_column_rounded,
                  label: task.column.toUpperCase(),
                  enabled: !isDeletion,
                  onTap: isDeletion ? null : () => _showColumnPicker(context, state, draft, idx, task),
                ),
                _buildSmallChip(
                  icon: Icons.group_outlined,
                  label: '${task.members.length} ASSIGNEES',
                  enabled: !isDeletion,
                  onTap: isDeletion ? null : () => _showMemberPicker(context, state, draft, idx, task),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDraftMemberAvatars(BuildContext context, StateChat state, TaskDraftItem task) {
    final boardState = context.read<StateBoards>();
    return Row(
      children: task.members.take(5).map((uid) {
        final profile = boardState.getMemberProfile(uid);
        final profileName = profile?['name'] ?? state.draft?.memberNames[uid] ?? uid;
        final photo = profile?['photo'] ?? '';
        final color = GlassColors.getMemberColor(uid);
        
        final fallback = Center(
          child: Text(
            profileName.isNotEmpty ? profileName[0].toUpperCase() : '?',
            style: GlassText.labelSM().copyWith(fontSize: 9, color: color),
          ),
        );

        return Container(
          width: 24,
          height: 24,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.15),
            border: Border.all(color: GlassColors.ghostBorder, width: 0.5),
          ),
          child: ClipOval(
            child: photo.isNotEmpty
                ? Image.network(
                    photo,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => fallback,
                  )
                : fallback,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSmallChip({required IconData icon, required String label, VoidCallback? onTap, bool enabled = true}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: enabled ? GlassColors.gold.withOpacity(0.05) : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: GlassColors.gold.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: enabled ? GlassColors.gold : GlassColors.gold.withOpacity(0.3)),
            const SizedBox(width: 8),
            Text(label, style: GlassText.labelSM().copyWith(fontSize: 9, color: enabled ? GlassColors.gold : GlassColors.gold.withOpacity(0.3), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) => DateFormat('MMM dd, yyyy').format(date);

  void _showColumnPicker(BuildContext context, StateChat state, ProposalDraft draft, int taskIdx, TaskDraftItem task) {
    final board = draft.selectedBoard;
    if (board == null) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: GlassDecorations.solidSurface(radius: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SELECT STATUS (COLUMN)', style: GlassText.labelSM().copyWith(letterSpacing: 2)),
                const SizedBox(height: 24),
                ...board.columns.map((col) {
                  final isSelected = task.column == col;
                  return ListTile(
                    title: Text(col.toUpperCase(), style: GlassText.bodyMD().copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? GlassColors.primary : null,
                    )),
                    trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: GlassColors.primary, size: 20) : null,
                    onTap: () {
                       state.updateDraftItemColumn(taskIdx, col);
                       Navigator.pop(context);
                     },
                  );
                }).toList(),
                const SizedBox(height: 24),
                Center(child: DraftActionButton(label: 'DONE', onTap: () => Navigator.pop(context), isPrimary: true)),
              ],
            ),
          );
        }
      ),
    );
  }

  void _showMemberPicker(BuildContext context, StateChat state, ProposalDraft draft, int taskIdx, TaskDraftItem task) {
    final board = draft.selectedBoard;
    if (board == null) return;
    final boardState = context.read<StateBoards>();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: GlassDecorations.solidSurface(radius: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SELECT ASSIGNEES', style: GlassText.labelSM().copyWith(letterSpacing: 2)),
                const SizedBox(height: 24),
                ...board.members.map((uid) {
                  final isSelected = task.members.contains(uid);
                  final profile = boardState.getMemberProfile(uid);
                  final name = profile?['name'] ?? draft.memberNames[uid] ?? uid;
                  final photo = profile?['photo'] ?? '';
                  final color = GlassColors.getMemberColor(uid);

                  return CheckboxListTile(
                    value: isSelected,
                    activeColor: GlassColors.primary,
                    title: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          foregroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                          onForegroundImageError: photo.isNotEmpty
                              ? (exception, stackTrace) {
                                  // Cleanly capture CORS/network loading failure
                                }
                              : null,
                          backgroundColor: color.withOpacity(0.2),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: GlassText.labelSM().copyWith(fontSize: 10, color: color),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(name, style: GlassText.bodyMD()),
                      ],
                    ),
                    onChanged: (v) {
                       setModalState(() {
                         state.updateDraftItemMembers(taskIdx, uid);
                       });
                    },
                  );
                }).toList(),
                if (board.members.isEmpty)
                  Text('No members in this board.', style: GlassText.secondary()),
                const SizedBox(height: 24),
                Center(child: DraftActionButton(label: 'DONE', onTap: () => Navigator.pop(context), isPrimary: true)),
              ],
            ),
          );
        }
      ),
    );
  }

  void _showLabelPicker(BuildContext context, StateChat state, ProposalDraft draft, int taskIdx, TaskDraftItem task) {
    final board = draft.selectedBoard;
    if (board == null) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: GlassDecorations.solidSurface(radius: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SELECT LABELS', style: GlassText.labelSM().copyWith(letterSpacing: 2)),
                const SizedBox(height: 24),
                ...board.labels.map((label) {
                  final isSelected = task.labelIds.contains(label['id']);
                  final colorValue = label['color'] as int? ?? GlassColors.primary.value;
                  return CheckboxListTile(
                    value: isSelected,
                    activeColor: Color(colorValue),
                    title: Row(
                      children: [
                        Container(width: 12, height: 12, decoration: BoxDecoration(color: Color(colorValue), shape: BoxShape.circle)),
                        const SizedBox(width: 12),
                        Text(label['name'] ?? '', style: GlassText.bodyMD()),
                      ],
                    ),
                    onChanged: (v) {
                       setModalState(() {
                         state.updateDraftItemLabels(taskIdx, label['id']);
                       });
                    },
                  );
                }).toList(),
                if (board.labels.isEmpty)
                  Text('No labels configured for this board.', style: GlassText.secondary()),
                const SizedBox(height: 24),
                Center(child: DraftActionButton(label: 'DONE', onTap: () => Navigator.pop(context), isPrimary: true)),
              ],
            ),
          );
        }
      ),
    );
  }
}

class ConfirmedActionCard extends StatelessWidget {
  final ProposalDraft draft;
  final bool isDark;
  const ConfirmedActionCard({super.key, required this.draft, required this.isDark});

  @override
  Widget build(BuildContext context) {
    Color cardColor = GlassColors.gold;
    String headerText;
    IconData headerIcon;

    final actionName = draft.originalCall.name;
    if (actionName == 'delete_team_task') {
      headerText = 'STRATEGY DELETED';
      headerIcon = Icons.delete_outline_rounded;
    } else if (actionName == 'update_team_task') {
      headerText = 'STRATEGY UPDATED';
      headerIcon = Icons.edit_rounded;
    } else {
      headerText = 'STRATEGY EXECUTED';
      headerIcon = Icons.check_circle_rounded;
    }

    // Task 33.4: Use execution logs for detailed reporting
    final displayItems = draft.executionLogs.isNotEmpty 
        ? draft.executionLogs 
        : draft.tasks.map((t) => 'PROCESSED: ${t.title}').toList();

    return Container(
      width: 450,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: GlassColors.glassSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: GlassColors.gold.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(headerIcon, color: cardColor, size: 20),
              const SizedBox(width: 12),
              Text(headerText, style: GlassText.labelSM().copyWith(color: cardColor, letterSpacing: 2.5, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 20),
          ...displayItems.map((log) {
            final parts = log.split(': ');
            final label = parts.length > 1 ? parts[0] : '';
            final title = parts.length > 1 ? parts[1] : log;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: cardColor.withOpacity(0.5), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (label.isNotEmpty)
                          Text(label.toUpperCase(), style: GlassText.labelSM().copyWith(
                            fontSize: 8, 
                            color: cardColor.withOpacity(0.5),
                            letterSpacing: 1.5,
                          )),
                        const SizedBox(height: 2),
                        Text(title, style: GlassText.bodyMD().copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: GlassColors.onSurface,
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class DraftActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  const DraftActionButton({super.key, required this.label, required this.onTap, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    final goldColor = GlassColors.gold;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ExecutiveRadius.circular),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isPrimary ? goldColor : Colors.transparent,
          borderRadius: BorderRadius.circular(ExecutiveRadius.circular),
          border: Border.all(
            color: isPrimary ? goldColor : GlassColors.outlineVariant.withOpacity(0.3),
            width: 1.2,
          ),
        ),
        child: Center(
          child: Text(
            label.toUpperCase(),
            style: GlassText.labelSM().copyWith(
              color: isPrimary ? Colors.black : GlassColors.onSurface,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 2.0,
            ),
          ),
        ),
      ),
    );
  }
}
