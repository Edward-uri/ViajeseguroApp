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
  Future<User> updateProfile({
    String? nombre,
    String? apellidoPaterno,
    String? apellidoMaterno,
    int? idSexo,
    String? fechaNacimiento,
    String? telefono,
  }) async {
    final body = <String, dynamic>{
      if (nombre != null) 'nombre': nombre,
      if (apellidoPaterno != null) 'apellidoPaterno': apellidoPaterno,
      if (apellidoMaterno != null) 'apellidoMaterno': apellidoMaterno,
      if (idSexo != null) 'idSexo': idSexo,
      if (fechaNacimiento != null) 'fechaNacimiento': fechaNacimiento,
      if (telefono != null) 'telefono': telefono,
    };
    final response = await _api.updateProfile(body);
    return UserMapper.fromJson(_unwrapData(response));
  }

  @override
  Future<User> uploadPhotoDirect({
    required List<int> bytes,
    required String fileName,
    required String contentType,
  }) async {
    final response = await _api.uploadPhotoDirect(
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
    );
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
