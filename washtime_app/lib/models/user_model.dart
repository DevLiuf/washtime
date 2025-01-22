class UserModel {
  final String id;
  final String name;
  final String kakaoToken;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.kakaoToken,
    required this.createdAt,
  });

  // JSON -> UserModel 변환
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      kakaoToken: json['kakao_token'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // UserModel -> JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'kakao_token': kakaoToken,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
