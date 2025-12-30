import 'package:dio/dio.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String message = 'An error occurred';
    
    if (err.response != null) {
      message = err.response?.data['message'] ?? 
                err.response?.statusMessage ?? 
                'Server error';
    } else if (err.type == DioExceptionType.connectionTimeout ||
               err.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timeout. Please check your internet connection.';
    } else if (err.type == DioExceptionType.connectionError) {
      message = 'No internet connection. Please check your network.';
    }
    
    err = err.copyWith(
      error: message,
    );
    
    handler.next(err);
  }
}

