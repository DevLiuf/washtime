// 기기 데이터 모델
enum DeviceStatus { available, inUse, unavailable }

extension DeviceStatusExtension on DeviceStatus {
  String get name => toString().split('.').last.toLowerCase(); // 모든 값을 소문자로 변환
}

class DeviceModel {
  final String id;
  final String name;
  DeviceStatus status;
  late final int remainingTime;
  DateTime? startTime;
  DateTime? endTime;
  final DateTime createdAt;

  DeviceModel({
    required this.id,
    required this.name,
    required this.status,
    required this.remainingTime,
    this.startTime,
    this.endTime,
    required this.createdAt,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'],
      name: json['name'],
      status: DeviceStatus.values.byName(json['status']),
      remainingTime: json['remainingTime'],
      startTime:
          json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status.name,
      'remainingTime': remainingTime,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  int calculateRemainingTime() {
    if (endTime == null) return 0;
    final now = DateTime.now();
    final remaining = endTime!.difference(now).inSeconds;
    return remaining > 0 ? remaining : 0;
  }
}
