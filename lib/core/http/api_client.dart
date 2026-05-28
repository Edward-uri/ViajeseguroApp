import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../env/api_config.dart';
import '../storage/auth_storage.dart';
import 'api_exception.dart';


class ApiClient {
  ApiClient(this._client, this._authStorage, {this.baseUrl = ApiConfig.baseUrl});

  final http.Client _client;
  final AuthStorage _authStorage;
  final String baseUrl;

  Future<Map<String, dynamic>> get(String path, {bool auth = true}) async {
    return _send(
      () async => _client.get(
        _uri(path),
        headers: await _headers(auth: auth),
      ),
    );
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Object? body,
    bool auth = false,
  }) async {
    return _send(
      () async => _client.post(
        _uri(path),
        headers: await _headers(auth: auth, hasBody: true),
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Object? body,
    bool auth = true,
  }) async {
    return _send(
      () async => _client.put(
        _uri(path),
        headers: await _headers(auth: auth, hasBody: true),
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  Future<void> delete(String path, {bool auth = true}) async {
    final response = await _runWithErrors(
      () async => _client.delete(
        _uri(path),
        headers: await _headers(auth: auth),
      ),
    );
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
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }


  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() send,
  ) async {
    final response = await _runWithErrors(send);
    _throwIfError(response);
    if (response.body.isEmpty) return const <String, dynamic>{};
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw ApiException(
      'Respuesta del servidor en formato inesperado',
      statusCode: response.statusCode,
    );
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
    } catch (_) {
    }

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
