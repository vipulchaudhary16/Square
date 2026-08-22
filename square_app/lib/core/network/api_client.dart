import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/auth_provider.dart';
import '../constants/api_constants.dart';
import 'token_storage.dart';

/// Endpoints that must never go through the auto-attach/auto-refresh
/// machinery below — login/signup have no token yet, and refresh's own
/// 401s mean "the refresh token is dead," not "go refresh and retry".
const _unauthenticatedPaths = ['/auth/login', '/auth/signup', '/auth/refresh'];

final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
  final tokenStorage = ref.watch(tokenStorageProvider);

  // Single-flight guard so N concurrent 401s trigger exactly one refresh
  // call instead of a stampede of parallel ones.
  Completer<String>? refreshing;

  Future<String> refreshAccessToken() {
    if (refreshing != null) return refreshing!.future;

    final completer = Completer<String>();
    refreshing = completer;

    () async {
      try {
        final refreshToken = await tokenStorage.readRefreshToken();
        if (refreshToken == null) throw Exception('No refresh token available');

        final response = await dio.post(
          '/auth/refresh',
          data: {'refresh_token': refreshToken},
        );
        final newAccessToken = response.data['access_token'] as String;
        await tokenStorage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: response.data['refresh_token'] as String,
        );
        completer.complete(newAccessToken);
      } catch (e) {
        completer.completeError(e);
      } finally {
        refreshing = null;
      }
    }();

    return completer.future;
  }

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (!_unauthenticatedPaths.contains(options.path)) {
          final token = await tokenStorage.readAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final path = error.requestOptions.path;
        final alreadyRetried = error.requestOptions.extra['retried'] == true;

        if (error.response?.statusCode != 401 ||
            _unauthenticatedPaths.contains(path) ||
            alreadyRetried) {
          return handler.next(error);
        }

        try {
          final newAccessToken = await refreshAccessToken();
          final retryOptions = error.requestOptions
            ..headers['Authorization'] = 'Bearer $newAccessToken'
            ..extra['retried'] = true;
          final response = await dio.fetch(retryOptions);
          return handler.resolve(response);
        } catch (_) {
          await tokenStorage.clear();
          await ref.read(authProvider.notifier).forceSignOut();
          return handler.next(error);
        }
      },
    ),
  );

  return dio;
});
