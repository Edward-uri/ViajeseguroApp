import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../env/api_config.dart';
import '../routes/api_routes.dart';
import '../storage/auth_storage.dart';
import 'api_exception.dart';

typedef OnAuthFailure = void Function();

class ApiClient {
  ApiClient(
    this._client,
    this._authStorage, {
    this.baseUrl = ApiConfig.baseUrl,
    this.onAuthFailure,
  });

  final http.Client _client;
  final AuthStorage _authStorage;
  final String baseUrl;
  final OnAuthFailure? onAuthFailure;


  Future<bool>? _refreshing;

  String? _cachedToken;
  String? get currentToken => _cachedToken;

  Future<bool> refreshSession() => _tryRefreshToken();

  Future<Map<String, dynamic>> get(String path, {bool auth = true}) {
    return _sendRequest(
      (headers) => _client.get(_uri(path), headers: headers),
      auth: auth,
    );
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Object? body,
    bool auth = false,
  }) {
    return _sendRequest(
      (headers) => _client.post(
        _uri(path),
        headers: headers,
        body: body == null ? null : jsonEncode(body),
      ),
      auth: auth,
      hasBody: body != null,
    );
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Object? body,
    bool auth = true,
  }) {
    return _sendRequest(
      (headers) => _client.put(
        _uri(path),
        headers: headers,
        body: body == null ? null : jsonEncode(body),
      ),
      auth: auth,
      hasBody: body != null,
    );
  }

  Future<void> delete(String path, {bool auth = true}) async {
    final headers = await _headers(auth: auth);
    final response = await _runWithErrors(
      () => _client.delete(_uri(path), headers: headers),
    );

    if (response.statusCode == 401 && auth) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        final newHeaders = await _headers(auth: auth);
        final retry = await _runWithErrors(
          () => _client.delete(_uri(path), headers: newHeaders),
        );
        _throwIfError(retry);
        return;
      }
    }

    _throwIfError(response);
  }

  Uri _uri(String path) =>
      Uri.parse('$baseUrl${path.startsWith('/') ? path : '/$path'}');

  Future<Map<String, String>> _headers({
    required bool auth,
    bool hasBody = false,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      if (hasBody) 'Content-Type': 'application/json',
    };
    if (auth) {
      final token = await _authStorage.readToken();
      if (token != null) {
        _cachedToken = token;
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<Map<String, dynamic>> _sendRequest(
    Future<http.Response> Function(Map<String, String> headers) requestBuilder, {
    required bool auth,
    bool hasBody = false,
    bool isRetry = false,
  }) async {
    final headers = await _headers(auth: auth, hasBody: hasBody);
    final response = await _runWithErrors(() => requestBuilder(headers));

    if (response.statusCode == 401 && auth && !isRetry) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        return _sendRequest(
          requestBuilder,
          auth: auth,
          hasBody: hasBody,
          isRetry: true,
        );
      }
    }

    _throwIfError(response);
    if (response.body.isEmpty) return const <String, dynamic>{};
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw ApiException(
      'Respuesta del servidor en formato inesperado',
      statusCode: response.statusCode,
    );
  }

  Future<bool> _tryRefreshToken() {
    // Si ya hay un refresh en curso, comparte ese mismo Future (single-flight).
    return _refreshing ??= _doRefreshToken().whenComplete(() => _refreshing = null);
  }

  Future<bool> _doRefreshToken() async {
    try {
      final refreshToken = await _authStorage.readRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        _notifyAuthFailure();
        return false;
      }

      final response = await _client
          .post(
            _uri(ApiRoutes.refresh),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        await _authStorage.clear();
        _notifyAuthFailure();
        return false;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final newAccessToken = decoded['accessToken'] as String?;
      final newRefreshToken = decoded['refreshToken'] as String?;

      if (newAccessToken == null || newAccessToken.isEmpty) {
        await _authStorage.clear();
        _notifyAuthFailure();
        return false;
      }

      await _authStorage.writeToken(newAccessToken);
      _cachedToken = newAccessToken;
      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await _authStorage.writeRefreshToken(newRefreshToken);
      }
      return true;
    } catch (_) {
      await _authStorage.clear();
      _notifyAuthFailure();
      return false;
    }
  }

  void _notifyAuthFailure() {
    if (onAuthFailure != null) {
      Future.microtask(() => onAuthFailure!());
    }
  }

  Future<http.Response> _runWithErrors(
    Future<http.Response> Function() send,
  ) async {
    try {
      return await send().timeout(ApiConfig.requestTimeout);
    } on TimeoutException {
      throw NetworkException('La solicitud tardo demasiado. Revisa tu conexion.');
    } on SocketException {
      throw NetworkException('Sin conexion. Revisa internet e intenta de nuevo.');
    } on http.ClientException catch (e) {
      throw NetworkException('Error de red: ${e.message}');
    }
  }

  void _throwIfError(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    String message = 'Error ${response.statusCode}';
    Object? details;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['error'] is Map) {
        final err = decoded['error'] as Map<String, dynamic>;
        message = err['message']?.toString() ?? message;
        details = err['details'];
      }
    } catch (_) {}

    switch (response.statusCode) {
      case 401:
        throw UnauthorizedException(message);
      case 400:
      case 422:
        throw ValidationException(message, details: details);
      default:
        throw ApiException(
          message,
          statusCode: response.statusCode,
          details: details,
        );
    }
  }
}
