import '../../../core/http/api_exception.dart';
import '../../../shared/data/mappers/user_mapper.dart';
import '../../../shared/domain/entities/user.dart';
import '../domain/entities/profile_photo_upload_ticket.dart';
import '../domain/repositories/profile_repository.dart';
import 'mappers/profile_photo_upload_ticket_mapper.dart';
import 'remote/profile_api.dart';


class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._api);

  final ProfileApi _api;

  @override
  Future<User> getMe() async {
    final response = await _api.getMe();
    return UserMapper.fromJson(_unwrapData(response));
  }

  @override
  Future<ProfilePhotoUploadTicket> requestPhotoUpload({
    required String contentType,
  }) async {
    final response = await _api.requestPhotoUpload(contentType);
    return ProfilePhotoUploadTicketMapper.fromJson(_unwrapData(response));
  }

  @override
  Future<User> confirmPhotoUpload({required String s3Key}) async {
    final response = await _api.confirmPhotoUpload(s3Key);
    return UserMapper.fromJson(_unwrapData(response));
  }

  @override
  Future<void> uploadBytesToS3({
    required String uploadUrl,
    required List<int> bytes,
    required String contentType,
  }) =>
      _api.uploadBytesToS3(
        uploadUrl: uploadUrl,
        bytes: bytes,
        contentType: contentType,
      );

  @override
  Future<void> deleteAccount() => _api.deleteAccount();


  Map<String, dynamic> _unwrapData(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException('Respuesta inesperada del servidor');
    }
    return data;
  }
}
