import 'package:dio/dio.dart';
import 'app_config.dart';

class HttpClient {
  HttpClient._();

  static final Dio instance = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
}
