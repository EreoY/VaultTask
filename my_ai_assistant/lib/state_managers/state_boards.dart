import 'dart:async';
import 'package:flutter/foundation.dart' show ChangeNotifier, kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/board_model.dart';
import '../databases/db_personal_sqlite.dart';
import '../databases/api_cloudflare.dart';

class StateBoards extends ChangeNotifier {
  // 🔄 Broadcast stream for board structure changes (columns, labels, etc.)
  static final _boardChangeController = StreamController<String>.broadcast();
  static Stream<String> get onBoardChange => _boardChangeController.stream;
  static void _notifyBoardChange(String boardId) => _boardChangeController.add(boardId);

  List<BoardModel> _boards = [];
  bool _isLoading = false;
  BoardModel? _selectedBoard;

  List<BoardModel> get boards => _boards;
  bool get isLoading => _isLoading;
  BoardModel? get selectedBoard => _selectedBoard;

  void setSelectedBoard(BoardModel? board) {
    _selectedBoard = board;
    notifyListeners();
  }

  final Map<String, Map<String, String>> _userProfiles = {}; // UID -> {name, photo}

  Map<String, String>? getMemberProfile(String uid) => _userProfiles[uid];

  Future<void> fetchAllBoards() async {
    _isLoading = true;
    notifyListeners();

    try {
      final personalBoards = kIsWeb ? <BoardModel>[] : await DbPersonalSqlite.instance.getAllBoards();

      List<BoardModel> teamBoards = [];
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        teamBoards = await ApiCloudflare.getBoards(uid);
      }

      _boards = [...personalBoards, ...teamBoards];

      // Task 25.1: Fetch profiles for all members found in boards
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
      print('Error fetching boards: $e');
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
      print('Error adding board: $e');
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
      print('Error joining board: $e');
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
      print('Error removing member: $e');
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
      print('Error updating board: $e');
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
      print('Error deleting board: $e');
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
      print('Error fetching single board: $e');
    }
  }
}
