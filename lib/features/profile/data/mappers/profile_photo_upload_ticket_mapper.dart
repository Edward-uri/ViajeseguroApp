import '../../domain/entities/profile_photo_upload_ticket.dart';


class ProfilePhotoUploadTicketMapper {
  const ProfilePhotoUploadTicketMapper._();

  static ProfilePhotoUploadTicket fromJson(Map<String, dynamic> json) {
    return ProfilePhotoUploadTicket(
      uploadUrl: json['uploadUrl'] as String,
      s3Key: json['s3Key'] as String,
      publicUrl: json['publicUrl'] as String,
      expiresIn: (json['expiresIn'] as num).toInt(),
      maxBytes: (json['maxBytes'] as num).toInt(),
    );
  }
}
