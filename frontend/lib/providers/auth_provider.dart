import 'package:dio/dio.dart';
import 'package:expense_tracker_frontend/core/constants/api_endpoints.dart';
import 'package:expense_tracker_frontend/core/storage/token_storage.dart';
import 'package:expense_tracker_frontend/models/user_model.dart';
import 'package:expense_tracker_frontend/providers/api_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  final bool isLoading;
  final UserModel? user;
  final String? error;
  final bool isAuthenticated;

  AuthState({
    this.isLoading = false,
    this.user,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    bool? isLoading,
    UserModel? user,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;

  AuthNotifier(this.ref) : super(AuthState(isLoading: true)) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true, error: null);
    final hasToken = await TokenStorage.hasAccessToken();
    if (!hasToken) {
      state = state.copyWith(isLoading: false, isAuthenticated: false, user: null);
      return;
    }

    try {
      final dio = ref.read(apiClientProvider).dio;
      final response = await dio.get(ApiEndpoints.me);
      if (response.statusCode == 200) {
        final user = UserModel.fromJson(response.data as Map<String, dynamic>);
        state = state.copyWith(isLoading: false, isAuthenticated: true, user: user);
      } else {
        await TokenStorage.clearTokens();
        state = state.copyWith(isLoading: false, isAuthenticated: false, user: null);
      }
    } catch (_) {
      await TokenStorage.clearTokens();
      state = state.copyWith(isLoading: false, isAuthenticated: false, user: null);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dio = ref.read(apiClientProvider).dio;
      final response = await dio.post(
        ApiEndpoints.login,
        data: {'email': email.trim(), 'password': password},
      );

      if (response.statusCode == 200) {
        final accessToken = response.data['accessToken'] as String;
        final refreshToken = response.data['refreshToken'] as String;
        final user = UserModel.fromJson(response.data['user'] as Map<String, dynamic>);

        await TokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );

        state = state.copyWith(isLoading: false, isAuthenticated: true, user: user);
        return true;
      }
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response?.data['message'] ?? 'Đăng nhập thất bại')
          : 'Đăng nhập thất bại';
      state = state.copyWith(isLoading: false, error: msg.toString());
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
    return false;
  }

  Future<bool> register(String email, String password, String fullName) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dio = ref.read(apiClientProvider).dio;
      final response = await dio.post(
        ApiEndpoints.register,
        data: {
          'email': email.trim(),
          'password': password,
          'fullName': fullName.trim(),
        },
      );

      if (response.statusCode == 201) {
        final accessToken = response.data['accessToken'] as String;
        final refreshToken = response.data['refreshToken'] as String;
        final user = UserModel.fromJson(response.data['user'] as Map<String, dynamic>);

        await TokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );

        state = state.copyWith(isLoading: false, isAuthenticated: true, user: user);
        return true;
      }
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response?.data['message'] ?? 'Đăng ký thất bại')
          : 'Đăng ký thất bại';
      state = state.copyWith(isLoading: false, error: msg.toString());
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
    return false;
  }

  Future<void> logout() async {
    try {
      final dio = ref.read(apiClientProvider).dio;
      await dio.post(ApiEndpoints.logout);
    } catch (_) {}
    await TokenStorage.clearTokens();
    state = AuthState(isLoading: false, isAuthenticated: false, user: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
