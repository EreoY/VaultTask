import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/board_model.dart';
import '../../models/workspace_model.dart';
import '../../state_managers/state_boards.dart';

/// Modal dialog/bottom sheet for quickly selecting a Workspace and Board to create a meeting.
class QuickCreateMeetingModal extends StatefulWidget {
  const QuickCreateMeetingModal({super.key});

  static Future<({WorkspaceModel workspace, BoardModel board})?> show(
    BuildContext context,
  ) async {
    final isDesktop = MediaQuery.of(context).size.width > 700;
    if (isDesktop) {
      return showDialog<({WorkspaceModel workspace, BoardModel board})>(
        context: context,
        barrierColor: Colors.black.withOpacity(0.65),
        builder: (_) => const Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: QuickCreateMeetingModal(),
        ),
      );
    }

    return showModalBottomSheet<({WorkspaceModel workspace, BoardModel board})>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const QuickCreateMeetingModal(),
    );
  }

  @override
  State<QuickCreateMeetingModal> createState() =>
      _QuickCreateMeetingModalState();
}

class _QuickCreateMeetingModalState extends State<QuickCreateMeetingModal> {
  WorkspaceModel? _selectedWorkspace;
  BoardModel? _selectedBoard;

  @override
  void initState() {
    super.initState();
    final boardsState = context.read<StateBoards>();
    _selectedWorkspace = boardsState.selectedWorkspace ??
        (boardsState.workspaces.isNotEmpty
            ? boardsState.workspaces.first
            : null);
    
    final matchingBoards = _getBoardsForWorkspace(boardsState, _selectedWorkspace);
    final currentSelectedBoard = boardsState.selectedBoard;
    if (currentSelectedBoard != null && matchingBoards.contains(currentSelectedBoard)) {
      _selectedBoard = currentSelectedBoard;
    } else {
      _selectedBoard = matchingBoards.isNotEmpty ? matchingBoards.first : null;
    }
  }

  List<BoardModel> _getBoardsForWorkspace(
    StateBoards state,
    WorkspaceModel? workspace,
  ) {
    if (workspace == null) return state.boards;
    return state.boards.where((b) {
      if (b.workspaceId == workspace.id) return true;
      if (b.workspaceId.isEmpty && workspace.id == 'default_personal') return true;
      return false;
    }).toList();
  }

  void _onWorkspaceChanged(WorkspaceModel? newWorkspace, StateBoards state) {
    if (newWorkspace == null) return;
    setState(() {
      _selectedWorkspace = newWorkspace;
      final matchingBoards = _getBoardsForWorkspace(state, newWorkspace);
      if (_selectedBoard == null || !matchingBoards.contains(_selectedBoard)) {
        _selectedBoard = matchingBoards.isNotEmpty ? matchingBoards.first : null;
      }
    });
  }

  void _confirmSelection() {
    if (_selectedWorkspace != null && _selectedBoard != null) {
      Navigator.of(context).pop((
        workspace: _selectedWorkspace!,
        board: _selectedBoard!,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final boardsState = context.watch<StateBoards>();
    final workspaces = boardsState.workspaces;
    final availableBoards = _getBoardsForWorkspace(boardsState, _selectedWorkspace);
    final isDesktop = MediaQuery.of(context).size.width > 700;

    final content = Container(
      width: isDesktop ? 480 : double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF141722), // Deep Calenda Theme
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modal Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.video_call_rounded,
                  color: Color(0xFFE53935),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Create Meeting',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'เลือก Workspace และ Board สำหรับการประชุมใหม่',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Workspace Selection Section
          Text(
            'WORKSPACE',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFE53935),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<WorkspaceModel>(
                value: _selectedWorkspace,
                isExpanded: true,
                dropdownColor: const Color(0xFF1D2130),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70),
                items: workspaces.map((ws) {
                  return DropdownMenuItem<WorkspaceModel>(
                    value: ws,
                    child: Row(
                      children: [
                        const Icon(Icons.workspaces_rounded, size: 18, color: Colors.white70),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            ws.name,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (ws) => _onWorkspaceChanged(ws, boardsState),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Board / Project Selection Section
          Text(
            'PROJECT / BOARD',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFE53935),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          if (availableBoards.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'ไม่พบ Board ใน Workspace นี้',
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.white38),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<BoardModel>(
                  value: _selectedBoard,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1D2130),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70),
                  items: availableBoards.map((b) {
                    return DropdownMenuItem<BoardModel>(
                      value: b,
                      child: Row(
                        children: [
                          const Icon(Icons.dashboard_rounded, size: 18, color: Colors.white70),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              b.name,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (b) {
                    setState(() {
                      _selectedBoard = b;
                    });
                  },
                ),
              ),
            ),

          const SizedBox(height: 28),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (_selectedWorkspace != null && _selectedBoard != null)
                  ? _confirmSelection
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                disabledBackgroundColor: Colors.white10,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                'สร้างการประชุมใหม่',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (isDesktop) return content;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
      ),
      child: SingleChildScrollView(child: content),
    );
  }
}
