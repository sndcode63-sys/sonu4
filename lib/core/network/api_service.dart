import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';
import '../utils/app_logger.dart';

class ApiService {
  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
        receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
        sendTimeout: const Duration(milliseconds: ApiConstants.sendTimeout),
        headers: {
          ApiConstants.contentTypeHeader: 'application/json',
        },
      ),
    );

    if (_dio.httpClientAdapter is IOHttpClientAdapter) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
        return client;
      };
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.extra['skipAuth'] == true) {
            options.headers.remove(ApiConstants.authHeader);
            return handler.next(options);
          }
          final token = await SecureStorageService.instance.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers[ApiConstants.authHeader] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          AppLogger.e(
            '${error.requestOptions.method} ${error.requestOptions.path} failed',
            error,
            error.stackTrace,
          );
          return handler.next(error);
        },
      ),
    );

    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        compact: true,
        maxWidth: 120,
      ),
    );
  }

  static final ApiService instance = ApiService._internal();
  late final Dio _dio;
  static void Function()? onUnauthorized;


  Future<Response> _withColdStartRetry(
    Future<Response> Function() call, {
    bool isFormData = false,
  }) async {
    try {
      return await call();
    } on DioException catch (e) {
      final isStreamFinalized = isFormData || e.requestOptions.data is FormData;
      final isRetryable = !isStreamFinalized &&
          (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.connectionError ||
              e.error is SocketException ||
              e.error is HttpException);
      if (!isRetryable) rethrow;

      AppLogger.w('${e.requestOptions.method} ${e.requestOptions.path} transient network issue (${e.type} / ${e.error}) — '
          'retrying once in case server was waking up or connection aborted.');
      try {
        return await call();
      } catch (_) {
        rethrow;
      }
    }
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _withColdStartRetry(() => _dio.get(path, queryParameters: queryParameters));
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    final isFormData = data is FormData;
    Options? effectiveOptions = options;
    if (isFormData) {
      effectiveOptions = (options ?? Options()).copyWith(
        sendTimeout: options?.sendTimeout ?? const Duration(milliseconds: ApiConstants.uploadTimeout),
        receiveTimeout: options?.receiveTimeout ?? const Duration(milliseconds: ApiConstants.uploadTimeout),
      );
    }
    return _withColdStartRetry(
      () => _dio.post(path, data: data, queryParameters: queryParameters, options: effectiveOptions),
      isFormData: isFormData,
    );
  }

  Future<Response> put(String path, {dynamic data, Options? options}) {
    final isFormData = data is FormData;
    Options? effectiveOptions = options;
    if (isFormData) {
      effectiveOptions = (options ?? Options()).copyWith(
        sendTimeout: options?.sendTimeout ?? const Duration(milliseconds: ApiConstants.uploadTimeout),
        receiveTimeout: options?.receiveTimeout ?? const Duration(milliseconds: ApiConstants.uploadTimeout),
      );
    }
    return _withColdStartRetry(
      () => _dio.put(path, data: data, options: effectiveOptions),
      isFormData: isFormData,
    );
  }

  Future<Response> delete(String path, {dynamic data}) {
    return _withColdStartRetry(() => _dio.delete(path, data: data));
  }

  Future<Response> patch(String path, {dynamic data, Options? options}) {
    final isFormData = data is FormData;
    Options? effectiveOptions = options;
    if (isFormData) {
      effectiveOptions = (options ?? Options()).copyWith(
        sendTimeout: options?.sendTimeout ?? const Duration(milliseconds: ApiConstants.uploadTimeout),
        receiveTimeout: options?.receiveTimeout ?? const Duration(milliseconds: ApiConstants.uploadTimeout),
      );
    }
    return _withColdStartRetry(
      () => _dio.patch(path, data: data, options: effectiveOptions),
      isFormData: isFormData,
    );
  }

  Future<Response> postMultipart(String path, {required FormData data, Options? options}) {
    final effectiveOptions = (options ?? Options()).copyWith(
      contentType: 'multipart/form-data',
      sendTimeout: options?.sendTimeout ?? const Duration(milliseconds: ApiConstants.uploadTimeout),
      receiveTimeout: options?.receiveTimeout ?? const Duration(milliseconds: ApiConstants.uploadTimeout),
    );
    return _withColdStartRetry(
      () => _dio.post(
        path,
        data: data,
        options: effectiveOptions,
      ),
      isFormData: true,
    );
  }

  Future<Response> patchMultipart(String path, {required FormData data, Options? options}) {
    final effectiveOptions = (options ?? Options()).copyWith(
      contentType: 'multipart/form-data',
      sendTimeout: options?.sendTimeout ?? const Duration(milliseconds: ApiConstants.uploadTimeout),
      receiveTimeout: options?.receiveTimeout ?? const Duration(milliseconds: ApiConstants.uploadTimeout),
    );
    return _withColdStartRetry(
      () => _dio.patch(
        path,
        data: data,
        options: effectiveOptions,
      ),
      isFormData: true,
    );
  }

}