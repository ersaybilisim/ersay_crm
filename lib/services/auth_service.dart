import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class AuthService {
  static const String baseUrl = 'https://crmapi.ersayerp.com.tr';

  static Future<AuthResult> login({
    required String username,
    required String password,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/Auth/login');

      final response = await http
          .post(
            url,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);

        if (decoded is! Map<String, dynamic>) {
          return AuthResult(
            success: false,
            errorMessage: 'Sunucudan beklenmeyen cevap geldi.',
          );
        }

        final token =
            decoded['token'] ??
            decoded['Token'] ??
            decoded['accessToken'] ??
            decoded['AccessToken'];

        final tokenType =
            decoded['tokenType'] ??
            decoded['TokenType'] ??
            decoded['type'] ??
            decoded['Type'];

        final expiresAt =
            decoded['expiresAt'] ??
            decoded['ExpiresAt'] ??
            decoded['expiration'] ??
            decoded['Expiration'];

        final user = decoded['user'] ?? decoded['User'];

        if (token == null || token.toString().trim().isEmpty) {
          return AuthResult(
            success: false,
            errorMessage: 'Token alınamadı. API cevabı kontrol edilmeli.',
          );
        }

        await StorageService.saveToken(token.toString());

        return AuthResult(
          success: true,
          token: token.toString(),
          tokenType: tokenType?.toString(),
          expiresAt: expiresAt?.toString(),
          user: user is Map<String, dynamic> ? user : null,
        );
      }

      String message = 'Giriş başarısız. Kod: ${response.statusCode}';

      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          message =
              decoded['mesaj']?.toString() ??
              decoded['message']?.toString() ??
              decoded['error']?.toString() ??
              message;
        }
      } catch (_) {}

      return AuthResult(success: false, errorMessage: message);
    } on TimeoutException {
      return AuthResult(
        success: false,
        errorMessage: 'Sunucuya ulaşılamadı. Bağlantı zaman aşımına uğradı.',
      );
    } catch (e) {
      return AuthResult(success: false, errorMessage: 'Bağlantı hatası: $e');
    }
  }

  static Future<void> logout() async {
    await StorageService.clear();
  }
}

class AuthResult {
  final bool success;
  final String? token;
  final String? tokenType;
  final String? expiresAt;
  final Map<String, dynamic>? user;
  final String? errorMessage;

  AuthResult({
    required this.success,
    this.token,
    this.tokenType,
    this.expiresAt,
    this.user,
    this.errorMessage,
  });
}
