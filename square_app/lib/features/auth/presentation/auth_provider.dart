import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/token_storage.dart';
import '../../dashboard/data/dashboard_cache.dart';
import '../data/auth_repository.dart';
import '../data/user_model.dart';

final authRepositoryProvider = Provider(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);

final authProvider = AsyncNotifierProvider<AuthNotifier, User?>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    return _checkLoginStatus();
  }

  Future<User?> _checkLoginStatus() async {
    final refreshToken = await ref
        .read(tokenStorageProvider)
        .readRefreshToken();
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');

    if (refreshToken != null && userData != null) {
      try {
        return User.fromJson(jsonDecode(userData));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      final data = await repository.login(email, password);
      return _persistSession(data);
    });
  }

  Future<void> signup(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      final data = await repository.signup(
        email,
        password,
        firstName,
        lastName,
      );
      return _persistSession(data);
    });
  }

  Future<User> _persistSession(Map<String, dynamic> data) async {
    final user = User.fromJson(data['user']);

    await ref
        .read(tokenStorageProvider)
        .saveTokens(
          accessToken: data['access_token'] as String,
          refreshToken: data['refresh_token'] as String,
        );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user.toJson()));

    return user;
  }

  Future<void> logout() async {
    final tokenStorage = ref.read(tokenStorageProvider);
    final refreshToken = await tokenStorage.readRefreshToken();
    if (refreshToken != null) {
      try {
        await ref.read(authRepositoryProvider).logout(refreshToken);
      } catch (_) {
        // Best-effort — always clear local state below regardless.
      }
    }
    await forceSignOut();
  }

  /// Clears local session state without calling the backend — used when the
  /// API client's interceptor has already determined the session is dead
  /// (e.g. a refresh attempt failed) and there's nothing left to revoke.
  Future<void> forceSignOut() async {
    await ref.read(tokenStorageProvider).clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await DashboardCache.clear();
    state = const AsyncValue.data(null);
  }
}
