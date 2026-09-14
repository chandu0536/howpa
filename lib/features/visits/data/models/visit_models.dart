class VisitRequestItem {
  final String id;
  final String patientName;
  final String address;
  final String distance;
  final String serviceTag;
  final String time;
  final String avatarUrl;
  final String status; // REQUESTED, ACCEPTED, ARRIVING, ARRIVED, STARTED, COMPLETED

  const VisitRequestItem({
    required this.id,
    required this.patientName,
    required this.address,
    required this.distance,
    required this.serviceTag,
    required this.time,
    required this.avatarUrl,
    this.status = 'REQUESTED',
  });

  factory VisitRequestItem.fromJson(Map<String, dynamic> json) {
    return VisitRequestItem(
      id: json['_id'] as String? ?? json['id'] as String? ?? json['appointmentId'] as String? ?? '',
      patientName: json['patientName'] as String? ?? json['name'] as String? ?? 'Patient',
      address: json['address'] as String? ?? json['location'] as String? ?? '',
      distance: json['distance'] as String? ?? '2.4 km',
      serviceTag: json['serviceTag'] as String? ?? json['serviceType'] as String? ?? 'Home Care',
      time: json['time'] as String? ?? '10:30 AM',
      avatarUrl: json['avatarUrl'] as String? ?? 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
      status: json['status'] as String? ?? 'REQUESTED',
    );
  }
}

class RecordVitalsRequest {
  final String appointmentId;
  final String bloodPressure;
  final int heartRate;
  final double temperature;
  final int bloodSugar;
  final int spo2;
  final double weight;
  final String reason;
  final String notes;

  const RecordVitalsRequest({
    required this.appointmentId,
    required this.bloodPressure,
    required this.heartRate,
    required this.temperature,
    required this.bloodSugar,
    required this.spo2,
    required this.weight,
    required this.reason,
    required this.notes,
  });

  Map<String, dynamic> toJson() => {
        'appointmentId': appointmentId,
        'bloodPressure': bloodPressure,
        'heartRate': heartRate,
        'temperature': temperature,
        'bloodSugar': bloodSugar,
        'spo2': spo2,
        'weight': weight,
        'reason': reason,
        'notes': notes,
      };
}

class SubmitReportRequest {
  final String appointmentId;
  final String summary;
  final String observations;
  final String nurseNotes;
  final int visitDuration;

  const SubmitReportRequest({
    required this.appointmentId,
    required this.summary,
    required this.observations,
    required this.nurseNotes,
    required this.visitDuration,
  });

  Map<String, dynamic> toJson() => {
        'appointmentId': appointmentId,
        'summary': summary,
        'observations': observations,
        'nurseNotes': nurseNotes,
        'visitDuration': visitDuration,
      };
}
