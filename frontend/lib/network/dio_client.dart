import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';

/// Creates and configures the shared [Dio] HTTP client.
///
/// [readToken] supplies the current bearer token (null when signed out). [onUnauthorized] runs
/// when the server refuses the token, so the app can sign out and ask the user to sign in again.
Dio createDioClient({
  required String? Function() readToken,
  required void Function() onUnauthorized,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      sendTimeout: ApiConfig.sendTimeout,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      final token = readToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) {
      final isSignIn = error.requestOptions.path.startsWith('/auth/login');
      if (error.response?.statusCode == 401 && !isSignIn) {
        onUnauthorized();
      }
      handler.next(error);
    },
  ));

  if (kDebugMode) {
    dio.interceptors.add(_SafeLogInterceptor());
  }

  return dio;
}

/// Debug logging that never prints headers (the token) or anything from sign-in (the password
/// and the token in the reply).
class _SafeLogInterceptor extends Interceptor {
  final _log = LogInterceptor(
    requestHeader: false,
    responseHeader: false,
    requestBody: true,
    responseBody: true,
    error: true,
    logPrint: (obj) => debugPrint('[DIO] $obj'),
  );

  bool _private(RequestOptions o) => o.path.startsWith('/auth/');

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) =>
      _private(options) ? handler.next(options) : _log.onRequest(options, handler);

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) =>
      _private(response.requestOptions) ? handler.next(response) : _log.onResponse(response, handler);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) =>
      _private(err.requestOptions) ? handler.next(err) : _log.onError(err, handler);
}
