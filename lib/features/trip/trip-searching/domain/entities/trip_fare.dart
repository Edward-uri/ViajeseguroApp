class TripFare {
  const TripFare({
    required this.baseFare,
    required this.distanceFare,
    required this.totalFare,
    required this.distance,
    required this.duration,
    this.currency = 'MXN',
  });

  static const empty = TripFare(
    baseFare: 0,
    distanceFare: 0,
    totalFare: 0,
    distance: 0,
    duration: 0,
  );

  final double baseFare;
  final double distanceFare;
  final double totalFare;
  final double distance;
  final double duration;
  final String currency;

  factory TripFare.fromJson(Map<String, dynamic> json) {
    return TripFare(
      baseFare: (json['baseFare'] as num).toDouble(),
      distanceFare: (json['distanceFare'] as num).toDouble(),
      totalFare: (json['totalFare'] as num).toDouble(),
      distance: (json['distance'] as num).toDouble(),
      duration: (json['duration'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'MXN',
    );
  }

  Map<String, dynamic> toJson() => {
        'baseFare': baseFare,
        'distanceFare': distanceFare,
        'totalFare': totalFare,
        'distance': distance,
        'duration': duration,
        'currency': currency,
      };
}
