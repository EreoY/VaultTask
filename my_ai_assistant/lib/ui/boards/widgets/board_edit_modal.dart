import 'package:flutter/material.dart';
import '../../common/ime_safe_text_field.dart';
import 'package:provider/provider.dart';
import '../../../models/board_model.dart';
import '../../../state_managers/state_boards.dart';
import '../../theme/glass_theme.dart';
import '../../common/glass_widgets.dart';

class BoardEditModal extends StatefulWidget {
  final bool isDark;
  const BoardEditModal({super.key, required this.isDark});

  @override
  State<BoardEditModal> createState() => _BoardEditModalState();
}

class _BoardEditModalState extends State<BoardEditModal> {
  final _nameController = TextEditingController();
  int _selectedColor = GlassColors.primary.value;
  bool _isSaving = false;

  final List<Color> _colors = [
    GlassColors.primary,
    GlassColors.gold,
    GlassColors.tertiary,
    GlassColors.success,
    GlassColors.error,
    const Color(0xFF9B59B6),
    const Color(0xFF3498DB),
  ];

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final board = BoardModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        color: _selectedColor,
        type: 'team', // Default to team board for this project
        columns: ['todo', 'doing', 'done'],
        members: [],
      );

      await context.read<StateBoards>().addBoard(board);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Error creating board: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: GlassDecorations.surface(radius: 32, hasShadow: true),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 48),
          _buildTextField(),
          const SizedBox(height: 48),
          Text('CLUSTER COLOR', style: GlassText.labelSM().copyWith(color: GlassColors.onSurfaceVariant.withOpacity(0.5))),
          const SizedBox(height: 24),
          _buildColorPicker(),
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
          'CREATE NEW CLUSTER',
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
        hintText: 'Board Name',
        hintStyle: GlassText.headlineLG().copyWith(fontSize: 38, color: GlassColors.onSurfaceVariant.withOpacity(0.2)),
        border: InputBorder.none,
      ),
    );
  }

  Widget _buildColorPicker() {
    return Row(
      children: _colors.map((color) {
        final isSelected = _selectedColor == color.value;
        return GestureDetector(
          onTap: () => setState(() => _selectedColor = color.value),
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? color : color.withOpacity(0.1),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: isSelected ? Icon(Icons.check, size: 16, color: color) : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildGhostButton('CANCEL', () => Navigator.pop(context)),
        const SizedBox(width: 16),
        _buildGhostButton(_isSaving ? 'CREATING...' : 'CREATE BOARD', _handleSave, isPrimary: true),
      ],
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
