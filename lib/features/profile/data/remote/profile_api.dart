import 'package:http/http.dart' as http;

import '../../../../core/http/api_client.dart';
import '../../../../core/http/api_exception.dart';


class ProfileApi {
  ProfileApi(this._api, this._rawClient);

  final ApiClient _api;
  final http.Client _rawClient;

  static const String _mePath = '/api/users/me';
  static const String _presignPath = '/api/users/me/photo/presign';
  static const String _confirmPath = '/api/users/me/photo/confirm';

  Future<Map<String, dynamic>> getMe() => _api.get(_mePath);

  Future<Map<String, dynamic>> requestPhotoUpload(String contentType) =>
      _api.post(
        _presignPath,
        auth: true,
        body: <String, dynamic>{'contentType': contentType},
      );

  Future<Map<String, dynamic>> confirmPhotoUpload(String s3Key) => _api.put(
        _confirmPath,
        body: <String, dynamic>{'s3Key': s3Key},
      );

  Future<void> deleteAccount() => _api.delete(_mePath);


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
