import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_config.dart';
import 'token_store.dart';

/// ProblemDetails from the API as a typed error (`code` is stable, see API docs).
class ApiException implements Exception {
  const ApiException(this.status, this.code, [this.data = const {}]);
  final int status;
  final String code;
  final Map<String, Object?> data;

  /// Thrown by a request its caller cancelled; nobody shows it.
  static const cancelled = ApiException(0, 'cancelled');

  bool get offline => status == 0 && code != 'cancelled';
  bool get isCancelled => status == 0 && code == 'cancelled';
  int? get retryIn => (data['retryIn'] as num?)?.toInt();
  List<String> get errors =>
      (data['errors'] as List?)?.whereType<String>().toList() ?? const [];

  @override
  String toString() => 'ApiException($status, $code)';
}

String newId() {
  final r = Random.secure();
  String hex(int n) =>
      List.generate(n, (_) => r.nextInt(16).toRadixString(16)).join();
  return '${hex(8)}-${hex(4)}-4${hex(3)}-${hex(4)}-${hex(12)}';
}

/// Thin Dio wrapper: auth header, single-flight refresh on 401 + replay,
/// Idempotency-Key on POST, X-App-Version / X-Device-Id, ProblemDetails → [ApiException].
class ApiClient {
  ApiClient(this.baseUrl, this.tokens) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: ApiDefaults.connectTimeout,
        receiveTimeout: ApiDefaults.receiveTimeout,
        headers: {'X-App-Version': ApiDefaults.appVersion},
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) async {
          await tokens.load();
          final a = tokens.access;
          if (a != null) o.headers['Authorization'] = 'Bearer $a';
          o.headers['X-Device-Id'] = await tokens.device(newId);
          if (o.method == 'POST') {
            o.headers.putIfAbsent('Idempotency-Key', newId);
          }
          h.next(o);
        },
        onError: (e, h) async {
          final req = e.requestOptions;
          if (e.response?.statusCode == 401 &&
              req.extra['retried'] != true &&
              !req.path.contains('/auth/') &&
              await _refresh()) {
            req.extra['retried'] = true;
            req.headers['Authorization'] = 'Bearer ${tokens.access}';
            try {
              return h.resolve(await _dio.fetch(req));
            } on DioException catch (e2) {
              return h.next(e2);
            }
          }
          h.next(e);
        },
      ),
    );
  }

  final String baseUrl;
  final TokenStore tokens;
  late final Dio _dio;
  Future<bool>? _refreshing;

  /// Called after a refresh fails (session over) so the app can sign out.
  void Function()? onSessionExpired;

  Future<bool> _refresh() => _refreshing ??= () async {
    try {
      final r = tokens.refresh;
      if (r == null) return false;
      final res = await Dio(BaseOptions(baseUrl: baseUrl))
          .post<Map<String, dynamic>>(
            '/api/v1/auth/refresh',
            data: {'refreshToken': r, 'deviceId': tokens.deviceId},
          );
      final d = res.data!;
      await tokens.save(
        d['accessToken'] as String,
        d['refreshToken'] as String,
      );
      return true;
    } on DioException {
      await tokens.clear();
      onSessionExpired?.call();
      return false;
    } finally {
      _refreshing = null;
    }
  }();

  /// [cancelToken] aborts the request (a superseded search); it then throws
  /// [ApiException.cancelled].
  Future<T> get<T>(
    String path, {
    Map<String, Object?>? query,
    CancelToken? cancelToken,
  }) => _send(
    () => _dio.get<T>(path, queryParameters: query, cancelToken: cancelToken),
  );

  Future<T> post<T>(String path, [Object? body]) =>
      _send(() => _dio.post<T>(path, data: body));

  Future<T> put<T>(String path, [Object? body]) =>
      _send(() => _dio.put<T>(path, data: body));

  Future<T> delete<T>(String path) => _send(() => _dio.delete<T>(path));

  /// Multipart upload → storage key.
  Future<String> upload(Uint8List bytes, String filename, String kind) async {
    final form = FormData.fromMap({
      'kind': kind,
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final res = await _send<Map<String, dynamic>>(
      () => _dio.post('/api/v1/media', data: form),
    );
    return res['key'] as String;
  }

  Future<T> _send<T>(Future<Response<T>> Function() call) async {
    try {
      return (await call()).data as T;
    } on DioException catch (e) {
      throw _toApi(e);
    }
  }

  static ApiException _toApi(DioException e) {
    if (e.type == DioExceptionType.cancel) return ApiException.cancelled;
    final res = e.response;
    if (res == null) return const ApiException(0, 'network');
    final body = res.data;
    if (body is Map) {
      final m = body.cast<String, Object?>();
      return ApiException(
        res.statusCode ?? 0,
        (m['code'] as String?) ?? 'error',
        m,
      );
    }
    return ApiException(res.statusCode ?? 0, 'http_${res.statusCode}');
  }
}

final apiClientProvider = Provider<ApiClient>(
  (ref) =>
      ApiClient(ref.watch(apiBaseUrlProvider), ref.watch(tokenStoreProvider)),
);

/// JSON helpers for hand-written DTO mapping.
extension JsonX on Map<String, dynamic> {
  String s(String k) => (this[k] as String?) ?? '';
  String? os(String k) => this[k] as String?;
  int i(String k) => (this[k] as num?)?.toInt() ?? 0;
  int? oi(String k) => (this[k] as num?)?.toInt();
  double d(String k) => (this[k] as num?)?.toDouble() ?? 0;
  bool b(String k) => this[k] as bool? ?? false;
  DateTime t(String k) => DateTime.parse(this[k] as String).toLocal();
  DateTime? ot(String k) =>
      this[k] == null ? null : DateTime.parse(this[k] as String).toLocal();
  Map<String, dynamic> m(String k) => (this[k] as Map).cast<String, dynamic>();
  Map<String, dynamic>? om(String k) =>
      (this[k] as Map?)?.cast<String, dynamic>();
  List<Map<String, dynamic>> l(String k) => ((this[k] as List?) ?? const [])
      .map((e) => (e as Map).cast<String, dynamic>())
      .toList();
  List<T> list<T>(String k) => ((this[k] as List?) ?? const []).cast<T>();
}

List<Map<String, dynamic>> asList(Object? v) => ((v as List?) ?? const [])
    .map((e) => (e as Map).cast<String, dynamic>())
    .toList();
