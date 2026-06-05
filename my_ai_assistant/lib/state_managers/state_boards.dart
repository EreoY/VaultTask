import 'dart:async';
import 'package:flutter/foundation.dart' show ChangeNotifier, kIsWeb, debugPrint;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/board_model.dart';
import '../models/workspace_model.dart';
import '../databases/db_personal_sqlite.dart';
import '../databases/api_cloudflare.dart';

class StateBoards extends ChangeNotifier {
  // 🔄 Broadcast stream for board structure changes (columns, labels, etc.)
  static final _boardChangeController = StreamController<String>.broadcast();
  static Stream<String> get onBoardChange => _boardChangeController.stream;
  static void _notifyBoardChange(String boardId) => _boardChangeController.add(boardId);

  List<WorkspaceModel> _workspaces = [];
  WorkspaceModel? _selectedWorkspace;
  List<BoardModel> _boards = [];
  bool _isLoading = false;
  BoardModel? _selectedBoard;

  List<WorkspaceModel> get workspaces => _workspaces;
  WorkspaceModel? get selectedWorkspace => _selectedWorkspace;
  List<BoardModel> get boards => _boards;
  bool get isLoading => _isLoading;
  BoardModel? get selectedBoard => _selectedBoard;

  void setSelectedWorkspace(WorkspaceModel? workspace) {
    _selectedWorkspace = workspace;
    notifyListeners();
  }

  void setSelectedBoard(BoardModel? board) {
    _selectedBoard = board;
    notifyListeners();
  }

  final Map<String, Map<String, String>> _userProfiles = {}; // UID -> {name, photo}

  Map<String, String>? getMemberProfile(String uid) => _userProfiles[uid];

  Future<void> fetchAllBoards() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      // 1. Fetch workspaces
      final localWorkspaces = kIsWeb ? <WorkspaceModel>[] : await DbPersonalSqlite.instance.getAllWorkspaces();
      List<WorkspaceModel> remoteWorkspaces = [];
      if (uid != null) {
        try {
          remoteWorkspaces = await ApiCloudflare.getWorkspaces(uid);
        } catch (e) {
          debugPrint('Error fetching remote workspaces: $e');
        }
      }
      
      _workspaces = [...localWorkspaces, ...remoteWorkspaces];

      // 2. Auto-provision default workspaces if empty
      bool hasPersonalDefault = _workspaces.any((w) => w.type == 'personal' && w.id == 'default_personal');
      if (!hasPersonalDefault && !kIsWeb) {
        final personalDefault = WorkspaceModel(
          id: 'default_personal',
          name: 'Default Personal Workspace',
          type: 'personal',
          ownerUid: uid ?? '',
          members: [],
          createdAt: DateTime.now().subtract(const Duration(days: 365)),
        );
        await DbPersonalSqlite.instance.insertWorkspace(personalDefault);
        _workspaces.add(personalDefault);
      }

      bool hasTeamDefault = _workspaces.any((w) => w.type == 'team' && w.id == 'default_team_${uid}');
      if (!hasTeamDefault && uid != null) {
        final teamDefault = WorkspaceModel(
          id: 'default_team_$uid',
          name: 'Default Team Workspace',
          type: 'team',
          ownerUid: uid,
          members: [uid],
          createdAt: DateTime.now().subtract(const Duration(days: 365)),
        );
        try {
          await ApiCloudflare.insertWorkspace(teamDefault);
          _workspaces.add(teamDefault);
        } catch (e) {
          debugPrint('Error auto-provisioning team workspace: $e');
        }
      }

      // Sort workspaces: default ones at the top, others below
      _workspaces.sort((a, b) {
        final aIsDefault = a.id.startsWith('default_');
        final bIsDefault = b.id.startsWith('default_');
        if (aIsDefault && !bIsDefault) return -1;
        if (!aIsDefault && bIsDefault) return 1;
        return a.createdAt.compareTo(b.createdAt);
      });

      // If _selectedWorkspace is null, select the first workspace
      if (_selectedWorkspace == null && _workspaces.isNotEmpty) {
        _selectedWorkspace = _workspaces.first;
      } else if (_selectedWorkspace != null) {
        try {
          _selectedWorkspace = _workspaces.firstWhere((w) => w.id == _selectedWorkspace!.id);
        } catch (_) {
          _selectedWorkspace = _workspaces.isNotEmpty ? _workspaces.first : null;
        }
      }

      // 3. Fetch boards
      final personalBoards = kIsWeb ? <BoardModel>[] : await DbPersonalSqlite.instance.getAllBoards();
      List<BoardModel> teamBoards = [];
      if (uid != null) {
        try {
          teamBoards = await ApiCloudflare.getBoards(uid);
        } catch (e) {
          debugPrint('Error fetching team boards: $e');
        }
      }

      // 4. Migrate orphaned boards (where workspaceId is empty)
      // For personal boards
      for (final pb in personalBoards) {
        if (pb.workspaceId.isEmpty) {
          final updated = pb.copyWith(workspaceId: 'default_personal');
          await DbPersonalSqlite.instance.updateBoard(updated);
        }
      }
      final finalPersonalBoards = kIsWeb ? <BoardModel>[] : await DbPersonalSqlite.instance.getAllBoards();

      // For team boards
      for (final tb in teamBoards) {
        if (tb.workspaceId.isEmpty && uid != null) {
          final updated = tb.copyWith(workspaceId: 'default_team_$uid');
          try {
            await ApiCloudflare.updateBoard(updated);
          } catch (e) {
            debugPrint('Error migrating team board $tb: $e');
          }
        }
      }

      List<BoardModel> finalTeamBoards = [];
      if (uid != null) {
        try {
          finalTeamBoards = await ApiCloudflare.getBoards(uid);
        } catch (_) {
          finalTeamBoards = teamBoards;
        }
      } else {
        finalTeamBoards = teamBoards;
      }

      _boards = [...finalPersonalBoards, ...finalTeamBoards];

      // Fetch profiles for all members found in boards
      final allUids = _boards.expand((b) => b.members).toSet().toList();
      if (allUids.isNotEmpty) {
        final profiles = await ApiCloudflare.getUsersByUids(allUids);
        for (final uid in allUids) {
          if (profiles.containsKey(uid)) {
            _userProfiles[uid] = profiles[uid]!;
          } else {
            _userProfiles[uid] = {'name': uid, 'photo': ''};
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching boards: $e');
    } finally {
      _isLoading = false;
      _refreshSelectedBoard(); // Task 34.1: Remap instance
      notifyListeners();
    }
  }

  void _refreshSelectedBoard() {
    if (_selectedBoard == null) return;
    try {
      _selectedBoard = _boards.firstWhere((b) => b.id == _selectedBoard!.id);
    } catch (_) {
      _selectedBoard = null;
    }
  }

  // ─── WORKSPACE CRUD ───────────────────────────────────

  Future<WorkspaceModel> addWorkspace(String name, String type) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final workspace = WorkspaceModel(
        id: id,
        name: name,
        type: type,
        ownerUid: uid,
        members: type == 'team' ? [uid] : [],
        createdAt: DateTime.now(),
      );

      if (type == 'personal') {
        if (!kIsWeb) {
          await DbPersonalSqlite.instance.insertWorkspace(workspace);
        }
      } else {
        if (uid.isNotEmpty) {
          await ApiCloudflare.insertWorkspace(workspace);
        }
      }

      _workspaces = [..._workspaces, workspace];
      notifyListeners();
      return workspace;
    } catch (e) {
      debugPrint('Error adding workspace: $e');
      rethrow;
    }
  }

  Future<void> deleteWorkspace(WorkspaceModel workspace) async {
    try {
      if (workspace.type == 'personal') {
        if (!kIsWeb) {
          await DbPersonalSqlite.instance.deleteWorkspace(workspace.id);
        }
      } else {
        await ApiCloudflare.deleteWorkspace(workspace.id);
      }
      _workspaces.removeWhere((w) => w.id == workspace.id);
      if (_selectedWorkspace?.id == workspace.id) {
        _selectedWorkspace = _workspaces.isNotEmpty ? _workspaces.first : null;
      }
      await fetchAllBoards();
    } catch (e) {
      debugPrint('Error deleting workspace: $e');
      rethrow;
    }
  }

  Future<void> updateWorkspaceName(WorkspaceModel workspace, String newName) async {
    try {
      final updated = workspace.copyWith(name: newName);
      if (workspace.type == 'personal') {
        if (!kIsWeb) {
          await DbPersonalSqlite.instance.updateWorkspace(updated);
        }
      } else {
        await ApiCloudflare.insertWorkspace(updated);
      }
      final idx = _workspaces.indexWhere((w) => w.id == workspace.id);
      if (idx != -1) {
        _workspaces[idx] = updated;
      }
      if (_selectedWorkspace?.id == workspace.id) {
        _selectedWorkspace = updated;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating workspace name: $e');
      rethrow;
    }
  }

  // ─── BOARD CRUD ───────────────────────────────────────

  Future<BoardModel> addBoard(BoardModel board) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      String id;

      if (board.type == 'personal') {
        id = await DbPersonalSqlite.instance.insertBoard(board);
      } else {
        // Ensure owner is in members list
        final members = board.members.contains(uid)
            ? board.members
            : [uid, ...board.members];
        final boardWithOwner = board.copyWith(members: members);
        id = await ApiCloudflare.insertBoard(uid, boardWithOwner);
      }

      final savedBoard = board.copyWith(id: id);
      _boards = [savedBoard, ..._boards];
      // Ensure persisted data is in sync (helps catch local DB write issues)
      if (board.type == 'personal') {
        await fetchAllBoards();
      } else {
        notifyListeners();
      }
      notifyListeners();
      return savedBoard;
    } catch (e) {
      debugPrint('Error adding board: $e');
      rethrow;
    }
  }

  Future<BoardModel> joinBoardById(String boardId) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final board = await ApiCloudflare.joinBoard(uid, boardId);
      _boards = [board, ..._boards];
      notifyListeners();
      return board;
    } catch (e) {
      debugPrint('Error joining board: $e');
      rethrow;
    }
  }

  Future<WorkspaceModel> joinWorkspaceById(String workspaceId) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final ws = await ApiCloudflare.joinWorkspace(uid, workspaceId);
      
      final exists = _workspaces.any((w) => w.id == ws.id);
      if (!exists) {
        _workspaces.add(ws);
      } else {
        final idx = _workspaces.indexWhere((w) => w.id == ws.id);
        if (idx != -1) {
          _workspaces[idx] = ws;
        }
      }
      
      _selectedWorkspace = ws;
      
      await fetchAllBoards();
      
      notifyListeners();
      return ws;
    } catch (e) {
      debugPrint('Error joining workspace: $e');
      rethrow;
    }
  }

  Future<void> removeMember(BoardModel board, String targetUid) async {
    try {
      await ApiCloudflare.removeMember(board.id, targetUid);
      // Update local state
      final updatedMembers = List<String>.from(board.members)..remove(targetUid);
      final updatedBoard = board.copyWith(members: updatedMembers);
      
      final idx = _boards.indexWhere((b) => b.id == board.id);
      if (idx != -1) {
        _boards[idx] = updatedBoard;
        if (_selectedBoard?.id == board.id) {
          _selectedBoard = updatedBoard;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error removing member: $e');
      rethrow;
    }
  }

  Future<void> updateBoard(BoardModel board) async {
    try {
      if (board.type == 'personal') {
        await DbPersonalSqlite.instance.updateBoard(board);
      } else {
        await ApiCloudflare.updateBoard(board);
        // 🔄 Notify other clients about board structure change
        _notifyBoardChange(board.id);
      }
      final idx = _boards.indexWhere((b) => b.id == board.id);
      if (idx != -1) {
        _boards[idx] = board;
      }
      if (_selectedBoard?.id == board.id) {
        _selectedBoard = board;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating board: $e');
    }
  }

  Future<void> addLabel(BoardModel board, String name, int color) async {
    final newLabel = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'color': color,
    };
    final updatedLabels = List<Map<String, dynamic>>.from(board.labels);
    updatedLabels.add(newLabel);
    final updatedBoard = board.copyWith(labels: updatedLabels);
    await updateBoard(updatedBoard);
  }

  Future<void> deleteBoard(BoardModel board) async {
    try {
      if (board.type == 'personal') {
        await DbPersonalSqlite.instance.deleteBoard(board.id);
      } else {
        await ApiCloudflare.deleteBoard(board.id);
      }
      _boards.removeWhere((b) => b.id == board.id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting board: $e');
    }
  }

  Future<void> fetchSingleBoard(String boardId) async {
    try {
      final board = await ApiCloudflare.getBoardById(boardId);
      final idx = _boards.indexWhere((b) => b.id == boardId);
      if (idx != -1) {
        _boards[idx] = board;
      } else {
        _boards.add(board);
      }
      if (_selectedBoard?.id == boardId) {
        _selectedBoard = board;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching single board: $e');
    }
  }
}
