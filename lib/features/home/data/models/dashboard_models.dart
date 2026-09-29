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
    final data = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;
    return DashboardStats(
      todayVisitsCount: data['todayVisits'] as int? ?? data['todayVisitsCount'] as int? ?? 0,
      pendingRequestsCount: data['waitingRequests'] as int? ?? data['pendingRequestsCount'] as int? ?? data['pendingRequests'] as int? ?? 0,
      completedVisitsCount: data['completedVisits'] as int? ?? data['completedVisitsCount'] as int? ?? 0,
      todayEarnings: (data['todayEarnings'] as num?)?.toDouble() ?? 0.0,
      overallRating: (data['overallRating'] as num?)?.toDouble() ?? (data['rating'] as num?)?.toDouble() ?? 0.0,
      isOnline: data['isOnline'] as bool? ?? true,
    );
  }
}

class LiveTelemetryRequest {
  final double latitude;
  final double longitude;
  final String? address;
  final double? heading;
  final double? speed;
  final double? accuracy;
  final int? battery;

  const LiveTelemetryRequest({
    required this.latitude,
    required this.longitude,
    this.address,
    this.heading,
    this.speed,
    this.accuracy,
    this.battery,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        if (address != null) 'address': address,
        if (heading != null) 'heading': heading,
        if (speed != null) 'speed': speed,
        if (accuracy != null) 'accuracy': accuracy,
        if (battery != null) 'battery': battery,
      };
}
