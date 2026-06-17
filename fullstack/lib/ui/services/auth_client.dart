import 'dart:async';

import 'package:flint_ui/flint_ui.dart';

import '../middleware/auth_middleware.dart';

class AuthClient {
  AuthClient({String authBase = '/auth'})
      : authBase = authBase.endsWith('/')
            ? authBase.substring(0, authBase.length - 1)
            : authBase;

  final String authBase;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response =
        await clientRouter.group(authBase).post<Map<String, dynamic>>(
      '/login',
      body: {
        'email': email,
        'password': password,
      },
    );

    if (response.isError) {
      throw response.error ?? const AuthException('Login failed.');
    }

    final payload = response.data ?? const {};
    final data = _map(payload['data']);
    final user = _map(data['user']);
    final token = data['token']?.toString();

    if (token == null || token.isEmpty) {
      throw const AuthException('Login succeeded, but no token was returned.');
    }

    final session = AuthSession(token: token, user: user);
    session.save();
    return session;
  }

  Map<String, dynamic> _map(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value
          .map((key, entryValue) => MapEntry(key.toString(), entryValue));
    }
    return const {};
  }
}

class AuthSession {
  const AuthSession({
    required this.token,
    required this.user,
  });

  final String token;
  final Map<String, dynamic> user;

  String get role => user['role']?.toString().toLowerCase() ?? 'customer';

  String get dashboardPath {
    return switch (role) {
      'admin' => '/dashboard/admin',
      'reseller' => '/dashboard/reseller',
      _ => '/dashboard',
    };
  }

  void save() {
    cookies.write(
      'auth.token',
      token,
      maxAge: const Duration(days: 7),
      sameSite: CookieSameSite.lax,
    );
    cookies.write(
      'eupanel.token',
      token,
      maxAge: const Duration(days: 7),
      sameSite: CookieSameSite.lax,
    );
    eupanelSession.save(token: token, user: user);
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
