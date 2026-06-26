import 'package:flutter/foundation.dart';

import '../databases/api_cloudflare.dart';
import '../databases/db_personal_sqlite.dart';
import '../models/board_model.dart';
import '../models/document_model.dart';

class StateDocuments extends ChangeNotifier {
  final Map<String, List<DocumentModel>> _documentsByBoard = {};
  bool _isLoading = false;
  String? _activeBoardId;
  String? _selectedDocumentId;

  bool get isLoading => _isLoading;
  String? get activeBoardId => _activeBoardId;
  String? get selectedDocumentId => _selectedDocumentId;

  List<DocumentModel> documentsForBoard(String boardId) {
    final list = List<DocumentModel>.from(
      _documentsByBoard[boardId] ?? const [],
    );
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  int documentCountForBoard(String boardId) =>
      _documentsByBoard[boardId]?.length ?? 0;

  List<DocumentModel> get allDocuments {
    final merged = _documentsByBoard.values.expand((items) => items).toList();
    merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return merged;
  }

  DocumentModel? selectedDocumentForBoard(String boardId) {
    final selectedId = _selectedDocumentId;
    if (_activeBoardId != boardId || selectedId == null) return null;
    final documents = _documentsByBoard[boardId] ?? const [];
    for (final document in documents) {
      if (document.id == selectedId) return document;
    }
    return null;
  }

  void openBoardHome(String boardId) {
    _activeBoardId = boardId;
    _selectedDocumentId = null;
    notifyListeners();
  }

  void openDocumentDetail(String boardId, String documentId) {
    _activeBoardId = boardId;
    _selectedDocumentId = documentId;
    notifyListeners();
  }

  void closeDocumentDetail() {
    _selectedDocumentId = null;
    notifyListeners();
  }

  void clearActiveBoard(String? boardId) {
    if (boardId == null || _activeBoardId == boardId) {
      _activeBoardId = null;
      _selectedDocumentId = null;
      notifyListeners();
    }
  }

  Future<void> fetchAllDocuments(
    List<BoardModel> boards, {
    bool silent = false,
  }) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }
    try {
      for (final board in boards) {
        await fetchDocumentsForBoard(board, silent: true);
      }
    } finally {
      if (!silent) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> fetchDocumentsForBoard(
    BoardModel board, {
    bool silent = false,
  }) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }
    try {
      final documents = board.type == 'personal'
          ? await DbPersonalSqlite.instance.getDocumentsByBoard(board.id)
          : await ApiCloudflare.getDocumentsByBoard(board.id);
      _documentsByBoard[board.id] = documents;
    } catch (e) {
      debugPrint('Error fetching documents for board ${board.id}: $e');
    } finally {
      if (!silent) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> addDocument(BoardModel board, DocumentModel document) async {
    try {
      final saved = document.copyWith(
        boardId: board.id,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      final id = board.type == 'personal'
          ? await DbPersonalSqlite.instance.insertDocument(saved)
          : await ApiCloudflare.insertDocument(saved);
      final finalDocument = saved.copyWith(id: id);
      _upsert(board.id, finalDocument);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding document: $e');
    }
  }

  Future<void> updateDocument(BoardModel board, DocumentModel document) async {
    try {
      final updated = document.copyWith(
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      if (board.type == 'personal') {
        await DbPersonalSqlite.instance.updateDocument(updated);
      } else {
        await ApiCloudflare.updateDocument(updated);
      }
      _upsert(board.id, updated);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating document: $e');
    }
  }

  Future<void> deleteDocument(BoardModel board, String documentId) async {
    try {
      if (board.type == 'personal') {
        await DbPersonalSqlite.instance.deleteDocument(documentId);
      } else {
        await ApiCloudflare.deleteDocument(documentId);
      }
      _documentsByBoard[board.id] = documentsForBoard(
        board.id,
      ).where((document) => document.id != documentId).toList();
      if (_activeBoardId == board.id && _selectedDocumentId == documentId) {
        _selectedDocumentId = null;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting document: $e');
    }
  }

  void _upsert(String boardId, DocumentModel document) {
    final current = List<DocumentModel>.from(
      _documentsByBoard[boardId] ?? const [],
    );
    final index = current.indexWhere((item) => item.id == document.id);
    if (index >= 0) {
      current[index] = document;
    } else {
      current.add(document);
    }
    current.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _documentsByBoard[boardId] = current;
  }
}
