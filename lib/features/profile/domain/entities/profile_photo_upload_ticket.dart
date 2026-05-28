class ProfilePhotoUploadTicket {
  const ProfilePhotoUploadTicket({
    required this.uploadUrl,
    required this.s3Key,
    required this.publicUrl,
    required this.expiresIn,
    required this.maxBytes,
  });

  final String uploadUrl;
  final String s3Key;
  final String publicUrl;
  final int expiresIn;
  final int maxBytes;
}
