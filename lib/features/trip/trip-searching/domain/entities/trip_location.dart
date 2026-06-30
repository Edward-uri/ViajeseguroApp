class TripLocation {
  const TripLocation({
    required this.address,
    required this.latitude,
    required this.longitude,
    this.placeName,
  });

  static const empty = TripLocation(
    address: '',
    latitude: 0.0,
    longitude: 0.0,
  );

  final String address;
  final double latitude;
  final double longitude;
  final String? placeName;

  TripLocation copyWith({
    String? address,
    double? latitude,
    double? longitude,
    String? placeName,
  }) {
    return TripLocation(
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      placeName: placeName ?? this.placeName,
    );
  }

  Map<String, dynamic> toJson() => {
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        if (placeName != null) 'placeName': placeName,
      };
}
