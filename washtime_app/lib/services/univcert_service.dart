import 'package:http/http.dart' as http;
import 'dart:convert';

class UnivCertService {
  final String apiKey =
      '715da0c2-e68c-4f7c-aede-6c14cec9dda6'; // ✅ UnivCert API 키

  bool isWKUEmail(String email) {
    return email.endsWith('@wonkwang.ac.kr');
  }

  /// 🔍 이미 인증된 이메일인지 확인
  Future<bool> isAlreadyVerified(String email) async {
    final response = await http.post(
      Uri.parse('https://univcert.com/api/v1/check'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'key': apiKey,
        'email': email,
        'univName': '원광대학교',
      }),
    );

    print('🔍 인증 여부 확인 응답: ${response.statusCode}, ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'];
    }
    return false;
  }

  /// 🔹 이메일 인증 코드 요청
  Future<bool> sendVerificationCode(String email) async {
    if (!isWKUEmail(email)) return false;

    // 이미 인증된 경우 → 인증 요청 생략
    if (await isAlreadyVerified(email)) {
      print('✅ 이미 인증된 이메일입니다.');
      return true;
    }

    final response = await http.post(
      Uri.parse('https://univcert.com/api/v1/certify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'key': apiKey,
        'email': email,
        'univName': '원광대학교',
        'univ_check': true,
      }),
    );

    print('📢 UnivCert API Response: ${response.statusCode}, ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData['success'];
    } else {
      print('❌ UnivCert API 요청 실패: ${response.body}');
      return false;
    }
  }

  /// 🔸 인증 코드 검증 (최종 인증 단계)
  Future<bool> verifyCode(String email, String code) async {
    if (!isWKUEmail(email)) return false;

    final response = await http.post(
      Uri.parse('https://univcert.com/api/v1/certifycode'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'key': apiKey,
        'email': email,
        'univName': '원광대학교',
        'code': code,
      }),
    );

    print(
        '📢 Verify Code API Response: ${response.statusCode}, ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData['success'];
    } else {
      print('❌ 인증 코드 검증 실패: ${response.body}');
      return false;
    }
  }
}
