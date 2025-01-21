// 기기 데이터 모델
class Device {
  final String id;
  final String name;
  final String status;
  final int remainingTime;

  Device({
    required this.id,
    required this.name,
    required this.status,
    required this.remainingTime,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      name: json['name'],
      status: json['status'],
      remainingTime: json['remainingTime'],
    );
  }
}
