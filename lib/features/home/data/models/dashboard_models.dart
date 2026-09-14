class DashboardStats {
  final int todayVisitsCount;
  final int pendingRequestsCount;
  final int completedVisitsCount;
  final double todayEarnings;
  final double overallRating;
  final bool isOnline;

  const DashboardStats({
    this.todayVisitsCount = 0,
    this.pendingRequestsCount = 0,
    this.completedVisitsCount = 0,
    this.todayEarnings = 0.0,
    this.overallRating = 0.0,
    this.isOnline = true,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      todayVisitsCount: json['todayVisitsCount'] as int? ?? json['todayVisits'] as int? ?? 0,
      pendingRequestsCount: json['pendingRequestsCount'] as int? ?? json['pendingRequests'] as int? ?? 0,
      completedVisitsCount: json['completedVisitsCount'] as int? ?? json['completedVisits'] as int? ?? 0,
      todayEarnings: (json['todayEarnings'] as num?)?.toDouble() ?? 0.0,
      overallRating: (json['overallRating'] as num?)?.toDouble() ?? 0.0,
      isOnline: json['isOnline'] as bool? ?? true,
    );
  }
}

class LiveTelemetryRequest {
  final double latitude;
  final double longitude;
  final double? heading;
  final double? speed;
  final double? accuracy;
  final int? battery;

  const LiveTelemetryRequest({
    required this.latitude,
    required this.longitude,
    this.heading,
    this.speed,
    this.accuracy,
    this.battery,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        if (heading != null) 'heading': heading,
        if (speed != null) 'speed': speed,
        if (accuracy != null) 'accuracy': accuracy,
        if (battery != null) 'battery': battery,
      };
}
