import '../../../../shared/domain/entities/user.dart';
import '../entities/profile_photo_upload_ticket.dart';

abstract class ProfileRepository {
  Future<User> getMe();

  Future<User> updateProfile({
    String? nombre,
    String? apellidoPaterno,
    String? apellidoMaterno,
    int? idSexo,
    String? fechaNacimiento,
    String? telefono,
  });

  Future<User> uploadPhotoDirect({
    required List<int> bytes,
    required String fileName,
    required String contentType,
  });

  Future<ProfilePhotoUploadTicket> requestPhotoUpload({
    required String contentType,
  });

  Future<User> confirmPhotoUpload({required String s3Key});

  Future<void> uploadBytesToS3({
    required String uploadUrl,
    required List<int> bytes,
    required String contentType,
  });

  Future<void> deleteAccount();
}
