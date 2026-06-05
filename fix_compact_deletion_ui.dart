import 'dart:io';

void main() {
  var file = File('my_ai_assistant/lib/ui/chat/widgets/draft_cards.dart');
  var content = file.readAsStringSync();

  // 1. Refactor _buildSmallChip to support disabled state
  content = content.replaceFirst(
    'Widget _buildSmallChip({required IconData icon, required String label, VoidCallback? onTap}) {',
    'Widget _buildSmallChip({required IconData icon, required String label, VoidCallback? onTap, bool enabled = true}) {'
  );
  
  content = content.replaceFirst(
    'color: GlassColors.primary.withOpacity(0.05),',
    'color: enabled ? GlassColors.primary.withOpacity(0.05) : Colors.white.withOpacity(0.02),'
  );
  
  content = content.replaceFirst(
    'Icon(icon, size: 12, color: GlassColors.primary),',
    'Icon(icon, size: 12, color: enabled ? GlassColors.primary : GlassColors.primary.withOpacity(0.3)),'
  );
  
  content = content.replaceFirst(
    "Text(label, style: GlassText.labelSM().copyWith(fontSize: 9, color: GlassColors.primary, fontWeight: FontWeight.bold)),",
    "Text(label, style: GlassText.labelSM().copyWith(fontSize: 9, color: enabled ? GlassColors.primary : GlassColors.primary.withOpacity(0.3), fontWeight: FontWeight.bold)),"
  );

  // 2. Overhaul _buildInteractiveTaskItem for Ultra-Compact Deletion
  var oldItemMethodStart = '  Widget _buildInteractiveTaskItem(BuildContext context, StateChat state, ProposalDraft draft, int idx, TaskDraftItem task) {';
  var oldItemMethodEnd = '  }';
  
  var newItemMethod = r'''  Widget _buildInteractiveTaskItem(BuildContext context, StateChat state, ProposalDraft draft, int idx, TaskDraftItem task) {
    final isDeletion = task.originalAction == 'delete_team_task';
    final accentColor = isDeletion ? GlassColors.error : GlassColors.primary;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.symmetric(
        horizontal: 16, 
        vertical: isDeletion ? 8 : 16 // Task 30.2: Reduced padding for deletion
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: task.isSelected ? accentColor.withOpacity(0.2) : Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Task 30.1: Selection Toggle
              InkWell(
                onTap: () => state.toggleDraftItemSelection(idx),
                child: Icon(
                  task.isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                  size: 20,
                  color: task.isSelected ? accentColor : GlassColors.onSurface.withOpacity(0.3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: task.title,
                  enabled: !isDeletion, // Task 30.2: Locked for deletion
                  style: GlassText.bodyMD().copyWith(
                    fontWeight: FontWeight.bold, 
                    fontSize: isDeletion ? 13 : 14, // Task 30.2: Smaller font
                    decoration: task.isSelected ? null : TextDecoration.lineThrough,
                    color: task.isSelected ? null : GlassColors.onSurface.withOpacity(0.3),
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                  onChanged: (val) => state.updateDraftItemTitle(idx, val),
                ),
              ),
            ],
          ),
          
          if (task.isSelected) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSmallChip(
                  icon: Icons.calendar_today_outlined,
                  label: _formatDate(task.dueDate),
                  enabled: !isDeletion, // Task 30.2: Read-Only
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
                  icon: Icons.view_column_rounded,
                  label: task.column.toUpperCase(),
                  enabled: !isDeletion, // Task 30.2: Read-Only
                  onTap: isDeletion ? null : () => _showColumnPicker(context, state, draft, idx, task),
                ),
                _buildSmallChip(
                  icon: Icons.group_outlined,
                  label: '${task.members.length} ASSIGNEES',
                  enabled: !isDeletion, // Task 30.2: Read-Only
                  onTap: isDeletion ? null : () => _showMemberPicker(context, state, draft, idx, task),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }''';

  // Surgical replacement of the whole method
  int startIdx = content.indexOf(oldItemMethodStart);
  int endIdx = content.indexOf('  String _formatDate', startIdx); // Find next method to mark end
  
  if (startIdx != -1 && endIdx != -1) {
    content = content.replaceRange(startIdx, endIdx, newItemMethod + '\n\n');
    file.writeAsStringSync(content);
    print('Ultra-Compact Deletion UI implemented in draft_cards.dart.');
  }
}
