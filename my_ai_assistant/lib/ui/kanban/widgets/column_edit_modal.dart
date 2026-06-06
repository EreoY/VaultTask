import 'package:flutter/material.dart';
import '../../common/ime_safe_text_field.dart';
import 'package:provider/provider.dart';
import '../../../models/board_model.dart';
import '../../../state_managers/state_boards.dart';
import '../../theme/glass_theme.dart';
import '../../common/glass_widgets.dart';

class ColumnEditModal extends StatefulWidget {
  final BoardModel board;
  final String? existingColumn;

  const ColumnEditModal({
    super.key,
    required this.board,
    this.existingColumn,
  });

  @override
  State<ColumnEditModal> createState() => _ColumnEditModalState();
}

class _ColumnEditModalState extends State<ColumnEditModal> {
  final _nameController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingColumn != null) {
      _nameController.text = widget.existingColumn!;
    }
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      List<String> updatedColumns = List.from(widget.board.columns);
      
      if (widget.existingColumn != null) {
        // Rename existing column
        final index = updatedColumns.indexOf(widget.existingColumn!);
        if (index != -1) {
          updatedColumns[index] = name;
        }
      } else {
        // Add new column
        if (!updatedColumns.contains(name)) {
          updatedColumns.add(name);
        }
      }

      final updatedBoard = widget.board.copyWith(columns: updatedColumns);
      await context.read<StateBoards>().updateBoard(updatedBoard);
      
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Error saving column: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleDelete() async {
    if (widget.existingColumn == null) return;
    
    setState(() => _isSaving = true);
    try {
      List<String> updatedColumns = List.from(widget.board.columns);
      updatedColumns.remove(widget.existingColumn);
      
      final updatedBoard = widget.board.copyWith(columns: updatedColumns);
      await context.read<StateBoards>().updateBoard(updatedBoard);
      
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Error deleting column: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: GlassDecorations.solidSurface(radius: 32, hasShadow: true),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 48),
          _buildTextField(),
          const SizedBox(height: 64),
          _buildActionRow(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          widget.existingColumn != null ? 'EDIT STRATEGIC PHASE' : 'NEW STRATEGIC PHASE',
          style: GlassText.labelSM().copyWith(letterSpacing: 2.0, color: GlassColors.primary),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded, size: 24),
          onPressed: () => Navigator.pop(context),
          color: GlassColors.onSurfaceVariant.withOpacity(0.5),
        ),
      ],
    );
  }

  Widget _buildTextField() {
    return ImeSafeTextField(
      controller: _nameController,
      autofocus: true,
      style: GlassText.headlineLG().copyWith(fontSize: 38),
      decoration: InputDecoration(
        hintText: 'Phase Name (e.g. Quality Assurance)',
        hintStyle: GlassText.headlineLG().copyWith(fontSize: 38, color: GlassColors.onSurfaceVariant.withOpacity(0.2)),
        border: InputBorder.none,
      ),
    );
  }

  Widget _buildActionRow() {
    return Row(
      children: [
        if (widget.existingColumn != null)
          _buildIconButton(Icons.delete_outline_rounded, GlassColors.error, () async {
            // Confirm deletion
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: GlassColors.background,
                title: Text('DELETE PHASE', style: GlassText.headlineLG().copyWith(fontSize: 24, color: GlassColors.error)),
                content: Text('Are you sure you want to delete this strategic phase? All tasks in this phase will need to be re-assigned.', style: GlassText.bodyMD()),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: Text('CANCEL', style: GlassText.label())),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: Text('DELETE', style: GlassText.label().copyWith(color: GlassColors.error))),
                ],
              ),
            );
            if (confirmed == true) {
              await _handleDelete();
            }
          }),
        const Spacer(),
        _buildGhostButton('CANCEL', () => Navigator.pop(context)),
        const SizedBox(width: 16),
        _buildGhostButton(_isSaving ? 'SAVING...' : 'SAVE PHASE', _handleSave, isPrimary: true),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ExecutiveRadius.circular),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ExecutiveRadius.circular),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildGhostButton(String label, VoidCallback onTap, {bool isPrimary = false}) {
    final color = isPrimary ? GlassColors.gold : GlassColors.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ExecutiveRadius.circular),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          color: isPrimary ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(ExecutiveRadius.circular),
          border: Border.all(color: color.withOpacity(isPrimary ? 0.3 : 0.1)),
        ),
        child: Text(
          label,
          style: GlassText.labelSM().copyWith(
            color: color.withOpacity(isPrimary ? 1.0 : 0.6),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
