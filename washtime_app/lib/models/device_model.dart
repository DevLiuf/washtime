class DeviceModel {
  final int id;
  final String type;
  final String status;
  final DateTime createdAt;
  final DateTime? endTime;

  DeviceModel({
    required this.id,
    required this.type,
    required this.status,
    required this.createdAt,
    this.endTime,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'],
      type: json['type'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']), // ✅ createdAt 추가
      endTime: json['endtime'] != null ? DateTime.parse(json['endtime']) : null,
    );
  }
}
