import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ehsan_pathways/core/services/api_service.dart';

/// Seek Guidance: private, free counselling answered by trusted advisers.
///
/// Mirrors /api/v1/guidance. Every request belongs to the signed-in user;
/// the server never returns anyone else's, nor an adviser's surname or email.

const String guidancePhone = '0727184694';

class GuidanceTopic {
  final String key;
  final String label;
  final String blurb;
  final IconData icon;
  const GuidanceTopic(this.key, this.label, this.blurb, this.icon);
}

/// Kept in step with CounsellingRequest::TOPICS on the server. Bundled so the
/// grid renders instantly and offline; the server validates the key.
const List<GuidanceTopic> guidanceTopics = [
  GuidanceTopic('marriage', 'Marriage', 'Choosing a spouse, nikah, rights, conflict, divorce', Icons.favorite_border_rounded),
  GuidanceTopic('family', 'Family', 'Parents, siblings, in-laws, ties of kinship', Icons.people_outline_rounded),
  GuidanceTopic('faith', 'Faith & Worship', 'Salah, doubts, iman, repentance', Icons.menu_book_outlined),
  GuidanceTopic('finance', 'Business & Finance', 'Halal income, debt, riba, zakat', Icons.account_balance_wallet_outlined),
  GuidanceTopic('struggles', 'Personal struggles', 'Anxiety, grief, loneliness, sins you want to leave', Icons.psychology_outlined),
  GuidanceTopic('education', 'Education', 'Seeking knowledge, studies, career', Icons.school_outlined),
  GuidanceTopic('parenting', 'Parenting', 'Raising children, teenagers, upbringing', Icons.child_care_rounded),
  GuidanceTopic('other', 'Other matters', 'Anything else you need guidance on', Icons.volunteer_activism_outlined),
];

GuidanceTopic topicFor(String key) =>
    guidanceTopics.firstWhere((t) => t.key == key, orElse: () => guidanceTopics.last);

class GuidanceMessage {
  final int id;
  final bool fromAdviser;
  final String author;
  final String body;
  final DateTime createdAt;

  const GuidanceMessage({
    required this.id,
    required this.fromAdviser,
    required this.author,
    required this.body,
    required this.createdAt,
  });

  factory GuidanceMessage.fromJson(Map<String, dynamic> j) => GuidanceMessage(
        id: (j['id'] as num?)?.toInt() ?? 0,
        fromAdviser: j['from_adviser'] == true,
        author: j['author'] as String? ?? '',
        body: j['body'] as String? ?? '',
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '')?.toLocal() ?? DateTime.now(),
      );
}

class GuidanceRequest {
  final String uuid;
  final String reference;
  final String topic;
  final String topicLabel;
  final String responseMode;
  final String status;
  final String statusLabel;
  final String concern;
  final bool awaitingAdviser;
  final String? adviserName;
  final String? referralNote;
  final DateTime createdAt;
  final List<GuidanceMessage> messages;

  const GuidanceRequest({
    required this.uuid,
    required this.reference,
    required this.topic,
    required this.topicLabel,
    required this.responseMode,
    required this.status,
    required this.statusLabel,
    required this.concern,
    required this.awaitingAdviser,
    this.adviserName,
    this.referralNote,
    required this.createdAt,
    this.messages = const [],
  });

  bool get isClosed => status == 'closed';

  /// What the seeker needs to know: is somebody working on it?
  String get stateLabel {
    if (isClosed) return 'Closed';
    if (awaitingAdviser) return adviserName != null ? 'With your adviser' : 'Waiting to be assigned';
    return statusLabel;
  }

  factory GuidanceRequest.fromJson(Map<String, dynamic> j) => GuidanceRequest(
        uuid: j['uuid'] as String? ?? '',
        reference: j['reference'] as String? ?? '',
        topic: j['topic'] as String? ?? 'other',
        topicLabel: j['topic_label'] as String? ?? '',
        responseMode: j['response_mode'] as String? ?? 'written',
        status: j['status'] as String? ?? 'new',
        statusLabel: j['status_label'] as String? ?? '',
        concern: j['concern'] as String? ?? '',
        awaitingAdviser: j['awaiting_adviser'] == true,
        adviserName: j['adviser_name'] as String?,
        referralNote: j['referral_note'] as String?,
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '')?.toLocal() ?? DateTime.now(),
        messages: ((j['messages'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(GuidanceMessage.fromJson)
            .toList(),
      );
}

/// Turns a Dio failure into something a person can act on.
String guidanceError(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map) {
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
      }
      if (data['message'] is String) return data['message'] as String;
    }
    if (e.response?.statusCode == 429) return 'Too many requests. Please try again later.';
    if (e.response == null) return 'No connection. Check your internet and try again.';
  }
  return 'Something went wrong. Please try again.';
}

class GuidanceRepository {
  GuidanceRepository(this._dio);
  final Dio _dio;

  Map<String, dynamic> _data(Response r) =>
      ((r.data as Map<String, dynamic>)['data']) as Map<String, dynamic>;

  Future<List<GuidanceRequest>> mine() async {
    final r = await _dio.get('/guidance');
    final list = ((r.data as Map<String, dynamic>)['data'] as List?) ?? const [];
    return list.whereType<Map<String, dynamic>>().map(GuidanceRequest.fromJson).toList();
  }

  Future<GuidanceRequest> show(String uuid) async =>
      GuidanceRequest.fromJson(_data(await _dio.get('/guidance/$uuid')));

  Future<GuidanceRequest> submit({
    required String topic,
    required String responseMode,
    required String concern,
    String? name,
    String? phone,
  }) async {
    final r = await _dio.post('/guidance', data: {
      'topic': topic,
      'response_mode': responseMode,
      'concern': concern,
      if (name != null && name.isNotEmpty) 'name': name,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    });
    return GuidanceRequest.fromJson(_data(r));
  }

  Future<GuidanceRequest> reply(String uuid, String body) async =>
      GuidanceRequest.fromJson(_data(await _dio.post('/guidance/$uuid/reply', data: {'body': body})));
}

final guidanceRepositoryProvider =
    Provider<GuidanceRepository>((ref) => GuidanceRepository(ref.watch(apiProvider)));

final myGuidanceProvider = FutureProvider.autoDispose<List<GuidanceRequest>>(
  (ref) => ref.watch(guidanceRepositoryProvider).mine(),
);

final guidanceThreadProvider = FutureProvider.autoDispose.family<GuidanceRequest, String>(
  (ref, uuid) => ref.watch(guidanceRepositoryProvider).show(uuid),
);
