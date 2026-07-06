import 'package:dio/dio.dart';
import '../config.dart';

typedef TokenProvider = String? Function();
typedef OnUnauthorized = void Function();

/// Dio 单例 + Token 拦截器 + 401 处理
class HttpClient {
  late final Dio dio;
  TokenProvider tokenProvider;
  OnUnauthorized onUnauthorized;

  HttpClient({
    TokenProvider? tokenProvider,
    OnUnauthorized? onUnauthorized,
  })  : tokenProvider = tokenProvider ?? (() => null),
        onUnauthorized = onUnauthorized ?? (() {}) {
    dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = this.tokenProvider();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          this.onUnauthorized();
        }
        handler.next(error);
      },
    ));
  }
}
