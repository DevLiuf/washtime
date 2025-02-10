class UsageLogModel {
  final int id; // 작동 이력 고유 ID
  final int washerId; // 세탁기/건조기 ID
  final int courseId; // 세탁 코스 ID
  final DateTime startTime; // 시작 시간
  final DateTime endTime; // 종료 시간
  final int userId; // 사용자 ID
  final DateTime createdAt;

  UsageLogModel({
    required this.id,
    required this.washerId,
    required this.courseId,
    required this.startTime,
    required this.endTime,
    required this.userId,
    required this.createdAt,
  });

  // JSON 데이터를 Dart 객체로 변환
  factory UsageLogModel.fromJson(Map<String, dynamic> json) {
    return UsageLogModel(
      id: json['id'] as int,
      washerId: json['washerId'] as int,
      courseId: json['courseId'] as int,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      userId: json['userId'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  // Dart 객체를 JSON 데이터로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'washerId': washerId,
      'courseId': courseId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
