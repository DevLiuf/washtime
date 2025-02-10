class DeviceModel {
  final int id;
  final String type;
  final String status;
  final DateTime createdAt;

  DeviceModel({
    required this.id,
    required this.type,
    required this.status,
    required this.createdAt,
  });

  // JSON 데이터를 Dart 객체로 변환
  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'] as int,
      type: json['type'] ?? 'unknown', // null 값일 경우 기본값 제공
      status: json['status'] ?? 'unknown', // null 값일 경우 기본값 제공
      createdAt:
          DateTime.parse(json['createdat'] ?? DateTime.now().toIso8601String()),
    );
  }
}
