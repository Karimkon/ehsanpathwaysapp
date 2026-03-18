import 'package:dio/dio.dart';
import 'package:ehsan_pathways/config/app_config.dart';

/// Service for all content types: Arabic, Khutbahs, Hajj/Umrah,
/// Live Streams, Sadaqah, and Comments.
class ContentService {
  final Dio _dio;

  ContentService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout:
                  const Duration(milliseconds: AppConfig.connectTimeout),
              receiveTimeout:
                  const Duration(milliseconds: AppConfig.receiveTimeout),
              sendTimeout:
                  const Duration(milliseconds: AppConfig.sendTimeout),
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
            ));

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Options _authOptions(String token) =>
      Options(headers: {'Authorization': 'Bearer $token'});

  Map<String, dynamic> _body(Response response) =>
      response.data as Map<String, dynamic>;

  // ---------------------------------------------------------------------------
  // Arabic Learning
  // ---------------------------------------------------------------------------

  /// GET /arabic/courses?page=&level=
  Future<Map<String, dynamic>> fetchArabicCourses({
    int page = 1,
    String? level,
  }) async {
    final params = <String, dynamic>{'page': page};
    if (level != null && level.isNotEmpty) params['level'] = level;
    final response = await _dio.get('/arabic/courses', queryParameters: params);
    return _body(response);
  }

  /// GET /arabic/courses/{slug}
  Future<Map<String, dynamic>> fetchArabicCourseDetail(String slug) async {
    final response = await _dio.get('/arabic/courses/$slug');
    final body = _body(response);
    return body['data'] is Map<String, dynamic>
        ? body['data'] as Map<String, dynamic>
        : body;
  }

  /// GET /arabic/courses/{courseSlug}/lessons/{lessonId}
  Future<Map<String, dynamic>> fetchArabicLesson(
    String courseSlug,
    int lessonId,
  ) async {
    final response =
        await _dio.get('/arabic/courses/$courseSlug/lessons/$lessonId');
    final body = _body(response);
    return body['data'] is Map<String, dynamic>
        ? body['data'] as Map<String, dynamic>
        : body;
  }

  // ---------------------------------------------------------------------------
  // Khutbahs
  // ---------------------------------------------------------------------------

  /// GET /khutbahs?page=
  Future<Map<String, dynamic>> fetchKhutbahs({int page = 1}) async {
    final response =
        await _dio.get('/khutbahs', queryParameters: {'page': page});
    return _body(response);
  }

  /// GET /khutbahs/{slug}
  Future<Map<String, dynamic>> fetchKhutbahDetail(String slug) async {
    final response = await _dio.get('/khutbahs/$slug');
    final body = _body(response);
    return body['data'] is Map<String, dynamic>
        ? body['data'] as Map<String, dynamic>
        : body;
  }

  // ---------------------------------------------------------------------------
  // Hajj / Umrah
  // ---------------------------------------------------------------------------

  /// GET /hajj-umrah
  Future<Map<String, dynamic>> fetchHajjGuides() async {
    final response = await _dio.get('/hajj-umrah');
    return _body(response);
  }

  /// GET /hajj-umrah/{slug}
  Future<Map<String, dynamic>> fetchHajjGuideDetail(String slug) async {
    final response = await _dio.get('/hajj-umrah/$slug');
    final body = _body(response);
    return body['data'] is Map<String, dynamic>
        ? body['data'] as Map<String, dynamic>
        : body;
  }

  // ---------------------------------------------------------------------------
  // Live Streams
  // ---------------------------------------------------------------------------

  /// GET /live-streams
  Future<Map<String, dynamic>> fetchLiveStreams() async {
    final response = await _dio.get('/live-streams');
    return _body(response);
  }

  // ---------------------------------------------------------------------------
  // Sadaqah
  // ---------------------------------------------------------------------------

  /// GET /sadaqah/purposes
  Future<List<dynamic>> fetchSadaqahPurposes() async {
    final response = await _dio.get('/sadaqah/purposes');
    final body = _body(response);
    if (body['data'] is List) return body['data'] as List<dynamic>;
    return response.data as List<dynamic>;
  }

  /// POST /sadaqah/donate
  Future<Map<String, dynamic>> submitDonation({
    required int purposeId,
    required double amount,
    required String currency,
    required String paymentMethod,
    bool isAnonymous = false,
    String? donorName,
    String? donorEmail,
  }) async {
    final data = <String, dynamic>{
      'purpose_id': purposeId,
      'amount': amount,
      'currency': currency,
      'payment_method': paymentMethod,
      'is_anonymous': isAnonymous,
      if (donorName != null && donorName.isNotEmpty) 'donor_name': donorName,
      if (donorEmail != null && donorEmail.isNotEmpty)
        'donor_email': donorEmail,
    };
    final response = await _dio.post('/sadaqah/donate', data: data);
    return _body(response);
  }

  /// GET /sadaqah/reports
  Future<List<dynamic>> fetchSadaqahReports() async {
    final response = await _dio.get('/sadaqah/reports');
    final body = _body(response);
    if (body['data'] is List) return body['data'] as List<dynamic>;
    return response.data as List<dynamic>;
  }

  // ---------------------------------------------------------------------------
  // Comments
  // ---------------------------------------------------------------------------

  /// GET /comments/{type}/{id}?page=
  Future<Map<String, dynamic>> fetchComments(
    String type,
    int id, {
    int page = 1,
  }) async {
    final response = await _dio.get(
      '/comments/$type/$id',
      queryParameters: {'page': page},
    );
    return _body(response);
  }

  /// POST /comments/{type}/{id}
  Future<Map<String, dynamic>> postComment({
    required String type,
    required int id,
    required String body,
    int? parentId,
    required String authToken,
  }) async {
    final data = <String, dynamic>{
      'body': body,
      if (parentId != null) 'parent_id': parentId,
    };
    final response = await _dio.post(
      '/comments/$type/$id',
      data: data,
      options: _authOptions(authToken),
    );
    return _body(response);
  }

  /// DELETE /comments/{id}
  Future<void> deleteComment(int id, String authToken) async {
    await _dio.delete(
      '/comments/$id',
      options: _authOptions(authToken),
    );
  }
}
