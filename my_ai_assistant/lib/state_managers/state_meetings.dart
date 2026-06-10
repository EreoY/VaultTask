import 'package:flutter/foundation.dart';

import '../databases/api_cloudflare.dart';
import '../databases/db_personal_sqlite.dart';
import '../models/board_model.dart';
import '../models/meeting_model.dart';

class StateMeetings extends ChangeNotifier {
  final Map<String, List<MeetingModel>> _meetingsByBoard = {};
  bool _isLoading = false;
  String? _activeBoardId;
  String? _selectedMeetingId;

  bool get isLoading => _isLoading;
  String? get activeBoardId => _activeBoardId;
  String? get selectedMeetingId => _selectedMeetingId;

  List<MeetingModel> meetingsForBoard(String boardId) {
    final list = List<MeetingModel>.from(_meetingsByBoard[boardId] ?? const []);
    list.sort((a, b) => a.startAt.compareTo(b.startAt));
    return list;
  }

  int meetingCountForBoard(String boardId) =>
      _meetingsByBoard[boardId]?.length ?? 0;

  List<MeetingModel> get allMeetings {
    final merged = _meetingsByBoard.values.expand((items) => items).toList();
    merged.sort((a, b) => a.startAt.compareTo(b.startAt));
    return merged;
  }

  MeetingModel? selectedMeetingForBoard(String boardId) {
    final selectedId = _selectedMeetingId;
    if (_activeBoardId != boardId || selectedId == null) return null;
    final meetings = _meetingsByBoard[boardId] ?? const [];
    for (final meeting in meetings) {
      if (meeting.id == selectedId) return meeting;
    }
    return null;
  }

  void openBoardHome(String boardId) {
    _activeBoardId = boardId;
    _selectedMeetingId = null;
    notifyListeners();
  }

  void openMeetingDetail(String boardId, String meetingId) {
    _activeBoardId = boardId;
    _selectedMeetingId = meetingId;
    notifyListeners();
  }

  void closeMeetingDetail() {
    _selectedMeetingId = null;
    notifyListeners();
  }

  void clearActiveBoard(String? boardId) {
    if (boardId == null || _activeBoardId == boardId) {
      _activeBoardId = null;
      _selectedMeetingId = null;
      notifyListeners();
    }
  }

  Future<void> fetchAllMeetings(
    List<BoardModel> boards, {
    bool silent = false,
  }) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }
    try {
      for (final board in boards) {
        await fetchMeetingsForBoard(board, silent: true);
      }
    } finally {
      if (!silent) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> fetchMeetingsForBoard(
    BoardModel board, {
    bool silent = false,
  }) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }
    try {
      final meetings = board.type == 'personal'
          ? await DbPersonalSqlite.instance.getMeetingsByBoard(board.id)
          : await ApiCloudflare.getMeetingsByBoard(board.id);
      _meetingsByBoard[board.id] = meetings;
    } catch (e) {
      debugPrint('Error fetching meetings for board ${board.id}: $e');
    } finally {
      if (!silent) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> addMeeting(BoardModel board, MeetingModel meeting) async {
    try {
      final saved = meeting.copyWith(
        boardId: board.id,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      final id = board.type == 'personal'
          ? await DbPersonalSqlite.instance.insertMeeting(saved)
          : await ApiCloudflare.insertMeeting(saved);
      final finalMeeting = saved.copyWith(id: id);
      _upsert(board.id, finalMeeting);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding meeting: $e');
    }
  }

  Future<void> updateMeeting(BoardModel board, MeetingModel meeting) async {
    try {
      final updated = meeting.copyWith(
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      if (board.type == 'personal') {
        await DbPersonalSqlite.instance.updateMeeting(updated);
      } else {
        await ApiCloudflare.updateMeeting(updated);
      }
      _upsert(board.id, updated);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating meeting: $e');
    }
  }

  Future<void> deleteMeeting(BoardModel board, String meetingId) async {
    try {
      if (board.type == 'personal') {
        await DbPersonalSqlite.instance.deleteMeeting(meetingId);
      } else {
        await ApiCloudflare.deleteMeeting(meetingId);
      }
      _meetingsByBoard[board.id] = meetingsForBoard(
        board.id,
      ).where((meeting) => meeting.id != meetingId).toList();
      if (_activeBoardId == board.id && _selectedMeetingId == meetingId) {
        _selectedMeetingId = null;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting meeting: $e');
    }
  }

  void _upsert(String boardId, MeetingModel meeting) {
    final current = List<MeetingModel>.from(
      _meetingsByBoard[boardId] ?? const [],
    );
    final index = current.indexWhere((item) => item.id == meeting.id);
    if (index >= 0) {
      current[index] = meeting;
    } else {
      current.add(meeting);
    }
    current.sort((a, b) => a.startAt.compareTo(b.startAt));
    _meetingsByBoard[boardId] = current;
  }
}
