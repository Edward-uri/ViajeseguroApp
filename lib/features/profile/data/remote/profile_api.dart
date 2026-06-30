import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../../core/http/api_client.dart';
import '../../../../core/http/api_exception.dart';
import '../../../../core/routes/routes.dart';


class ProfileApi {
  ProfileApi(this._api, this._rawClient);

  final ApiClient _api;
  final http.Client _rawClient;

  Future<Map<String, dynamic>> getMe() => _api.get(ApiRoutes.usersMe);

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> body) =>
      _api.put(ApiRoutes.usersMe, body: body);

  Future<Map<String, dynamic>> uploadPhotoDirect({
    required List<int> bytes,
    required String fileName,
    required String contentType,
  }) async {
    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('${_api.baseUrl}${ApiRoutes.usersMePhoto}'),
    );

    final token = _api.currentToken;
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers['Accept'] = 'application/json';

    request.files.add(
      http.MultipartFile.fromBytes(
        'foto',
        bytes,
        filename: fileName,
        contentType: MediaType.parse(contentType),
      ),
    );

    final streamed = await request.send().timeout(
      const Duration(seconds: 30),
    );
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return const <String, dynamic>{};
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    final bodySnippet = response.body.length > 400
        ? '${response.body.substring(0, 400)}...'
        : response.body;
    throw ApiException(
      'Error al subir foto (status ${response.statusCode}): $bodySnippet',
      statusCode: response.statusCode,
    );
  }

  Future<Map<String, dynamic>> requestPhotoUpload(String contentType) =>
      _api.post(
        ApiRoutes.usersMePhotoPresign,
        auth: true,
        body: <String, dynamic>{'contentType': contentType},
      );

  Future<Map<String, dynamic>> confirmPhotoUpload(String s3Key) => _api.put(
        ApiRoutes.usersMePhotoConfirm,
        body: <String, dynamic>{'s3Key': s3Key},
      );

  Future<void> deleteAccount() => _api.delete(ApiRoutes.usersMe);


  Future<void> uploadBytesToS3({
    required String uploadUrl,
    required List<int> bytes,
    required String contentType,
  }) async {
    final response = await _rawClient
        .put(
          Uri.parse(uploadUrl),
          headers: <String, String>{'Content-Type': contentType},
          body: bytes,
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode >= 200 && response.statusCode < 300) return;

    final bodySnippet = response.body.length > 400
        ? '${response.body.substring(0, 400)}...'
        : response.body;
    throw ApiException(
      'S3 rechazo la subida (status ${response.statusCode}): $bodySnippet',
      statusCode: response.statusCode,
    );
  }
}
