import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  
  AuthInterceptor(this._storage);
  
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Try to refresh token
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken != null) {
        try {
          final dio = Dio();
          final response = await dio.post(
            '${err.requestOptions.baseUrl}/refresh',
            data: {'refresh_token': refreshToken},
          );
          
          if (response.statusCode == 200) {
            final newToken = response.data['data']['access_token'];
            await _storage.write(key: 'access_token', value: newToken);
            
            // Retry original request with new token
            err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            final opts = Options(
              method: err.requestOptions.method,
              headers: err.requestOptions.headers,
            );
            final retryResponse = await dio.request(
              err.requestOptions.uri.toString(),
              options: opts,
              data: err.requestOptions.data,
              queryParameters: err.requestOptions.queryParameters,
            );
            handler.resolve(Response(
              requestOptions: err.requestOptions,
              data: retryResponse.data,
              statusCode: retryResponse.statusCode,
              statusMessage: retryResponse.statusMessage,
              headers: retryResponse.headers,
            ));
            return;
          }
        } catch (e) {
          // Refresh failed, clear tokens
          await _storage.delete(key: 'access_token');
          await _storage.delete(key: 'refresh_token');
        }
      }
    }
    handler.next(err);
  }
}

