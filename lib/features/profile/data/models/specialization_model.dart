class SpecializationModel {
  final String id;
  final String name;
  final String description;

  const SpecializationModel({
    required this.id,
    required this.name,
    required this.description,
  });

  factory SpecializationModel.fromJson(Map<String, dynamic> json) {
    return SpecializationModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
  };

  static List<SpecializationModel> defaultList() => const [
    SpecializationModel(
      id: '1',
      name: 'Elder Care Specialist',
      description: 'Senior citizen assistance and elderly health management',
    ),
    SpecializationModel(
      id: '2',
      name: 'Critical Care',
      description: 'Intensive care, ventilator support, and emergency monitoring',
    ),
    SpecializationModel(
      id: '3',
      name: 'General Care',
      description: 'Routine nursing care, vitals monitoring, and injections',
    ),
    SpecializationModel(
      id: '4',
      name: 'Post-Surgery Care',
      description: 'Post-operative recovery, wound dressing, and surgical drains',
    ),
    SpecializationModel(
      id: '5',
      name: 'Pediatric Care',
      description: 'Infant and child nursing, vaccination, and growth monitoring',
    ),
    SpecializationModel(
      id: '6',
      name: 'Palliative Care',
      description: 'Compassionate symptom management and comfort care',
    ),
  ];
}

class SpecializationsResponse {
  final bool success;
  final int total;
  final List<SpecializationModel> data;

  const SpecializationsResponse({
    required this.success,
    required this.total,
    required this.data,
  });

  factory SpecializationsResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['data'] as List<dynamic>?)
            ?.map((e) => SpecializationModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return SpecializationsResponse(
      success: json['success'] ?? true,
      total: json['total'] ?? list.length,
      data: list,
    );
  }
}
