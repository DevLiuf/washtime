// 사용 로그 모댈
class UsageLogModel {
  final String id;
  final String deviceId;
  final String userId;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime createdAt;

  UsageLogModel({
    required this.id,
    required this.deviceId,
    required this.userId,
    required this.startTime,
    required this.endTime,
    required this.createdAt,
  });

  factory UsageLogModel.fromJson(Map<String, dynamic> json) {
    return UsageLogModel(
      id: json['id'],
      deviceId: json['device_id'],
      userId: json['user_id'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
