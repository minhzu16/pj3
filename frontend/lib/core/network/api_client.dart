import 'package:dio/dio.dart';
import 'package:expense_tracker_frontend/core/constants/api_endpoints.dart';
import 'package:expense_tracker_frontend/core/storage/token_storage.dart';

class ApiClient {
  late final Dio dio;

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final accessToken = await TokenStorage.getAccessToken();
          if (accessToken != null && accessToken.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401 && !error.requestOptions.path.contains('/auth/')) {
            // Attempt token refresh
            final refreshToken = await TokenStorage.getRefreshToken();
            if (refreshToken != null && refreshToken.isNotEmpty) {
              try {
                final refreshDio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
                final response = await refreshDio.post(
                  ApiEndpoints.refresh,
                  data: {'refreshToken': refreshToken},
                );

                if (response.statusCode == 200) {
                  final newAccessToken = response.data['accessToken'];
                  final newRefreshToken = response.data['refreshToken'];

                  await TokenStorage.saveTokens(
                    accessToken: newAccessToken,
                    refreshToken: newRefreshToken,
                  );

                  // Retry original request with new token
                  error.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                  final retryResponse = await dio.fetch(error.requestOptions);
                  return handler.resolve(retryResponse);
                }
              } catch (_) {
                await TokenStorage.clearTokens();
              }
            } else {
              await TokenStorage.clearTokens();
            }
          }
          return handler.next(error);
        },
      ),
    );
  }
}
