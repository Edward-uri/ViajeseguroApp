import '../../../../shared/domain/entities/user.dart';
import '../entities/profile_photo_upload_ticket.dart';

abstract class ProfileRepository {
  Future<User> getMe();

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
