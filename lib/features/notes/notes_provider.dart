import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ehsan_pathways/core/services/api_service.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class Note {
  final int id;
  final String notableType;
  final int notableId;
  final String content;
  final int? timestampSeconds;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Note({
    required this.id,
    required this.notableType,
    required this.notableId,
    required this.content,
    this.timestampSeconds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as int,
      notableType: json['notable_type'] as String? ?? '',
      notableId: json['notable_id'] as int? ?? 0,
      content: json['content'] as String? ?? '',
      timestampSeconds: json['timestamp_seconds'] as int?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  String get typeLabel {
    switch (notableType) {
      case 'video':
        return 'Video';
      case 'pathway':
        return 'Pathway';
      case 'khutbah':
        return 'Khutbah';
      case 'arabic_course':
        return 'Arabic Course';
      case 'arabic_lesson':
        return 'Arabic Lesson';
      default:
        return notableType;
    }
  }

  String get formattedTimestamp {
    if (timestampSeconds == null) return '';
    final m = timestampSeconds! ~/ 60;
    final s = timestampSeconds! % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get preview {
    if (content.length <= 80) return content;
    return '${content.substring(0, 80)}...';
  }
}

class NoteListState {
  final List<Note> notes;
  final bool isLoading;
  final String? error;

  const NoteListState({
    this.notes = const [],
    this.isLoading = false,
    this.error,
  });

  NoteListState copyWith({
    List<Note>? notes,
    bool? isLoading,
    String? error,
  }) {
    return NoteListState(
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class NoteListNotifier extends Notifier<NoteListState> {
  @override
  NoteListState build() {
    Future.microtask(() => fetchNotes());
    return const NoteListState(isLoading: true);
  }

  Dio get _dio => ref.read(apiProvider);

  Future<void> fetchNotes({String? type}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final query = <String, dynamic>{};
      if (type != null) query['type'] = type;

      final response = await _dio.get('/notes', queryParameters: query);

      List<dynamic> items;
      if (response.data is String) {
        final decoded = jsonDecode(response.data as String);
        if (decoded is List) {
          items = decoded;
        } else if (decoded is Map) {
          items = (decoded['data'] ?? decoded['notes'] ?? []) as List<dynamic>;
        } else {
          items = [];
        }
      } else if (response.data is List) {
        items = response.data as List<dynamic>;
      } else if (response.data is Map) {
        final body = response.data as Map<String, dynamic>;
        items = (body['data'] ?? body['notes'] ?? []) as List<dynamic>;
      } else {
        items = [];
      }

      state = state.copyWith(
        notes: items
            .map((e) => Note.fromJson(e as Map<String, dynamic>))
            .toList(),
        isLoading: false,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message']?.toString() ??
            'Failed to load notes',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createNote({
    required String notableType,
    required int notableId,
    required String content,
    int? timestampSeconds,
  }) async {
    try {
      await _dio.post('/notes', data: {
        'notable_type': notableType,
        'notable_id': notableId,
        'content': content,
        if (timestampSeconds != null) 'timestamp_seconds': timestampSeconds,
      });
      await fetchNotes();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateNote(int id, String content,
      {int? timestampSeconds}) async {
    try {
      await _dio.put('/notes/$id', data: {
        'content': content,
        if (timestampSeconds != null) 'timestamp_seconds': timestampSeconds,
      });
      await fetchNotes();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> deleteNote(int id) async {
    try {
      await _dio.delete('/notes/$id');
      state = state.copyWith(
        notes: state.notes.where((n) => n.id != id).toList(),
      );
    } catch (_) {
      // silently fail
    }
  }
}

final noteListProvider =
    NotifierProvider<NoteListNotifier, NoteListState>(NoteListNotifier.new);
