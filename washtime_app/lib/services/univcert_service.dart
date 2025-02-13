import 'package:http/http.dart' as http;
import 'dart:convert';

class UnivCertService {
  final String apiKey =
      '715da0c2-e68c-4f7c-aede-6c14cec9dda6'; // ✅ UnivCert API 키 적용

  bool isWKUEmail(String email) {
    return email.endsWith('@wonkwang.ac.kr');
  }

  // 🔹 이메일 인증 코드 요청
  Future<bool> sendVerificationCode(String email) async {
    if (!isWKUEmail(email)) return false;

    final response = await http.post(
      Uri.parse('https://univcert.com/api/v1/certify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'key': apiKey,
        'email': email,
        'univName': '원광대학교', // ✅ UnivCert에서 등록된 정확한 명칭 필요
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

  // 🔹 인증 코드 검증
  Future<bool> verifyCode(String email, String code) async {
    if (!isWKUEmail(email)) return false;

    final response = await http.post(
      Uri.parse('https://univcert.com/api/v1/certifycode'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'key': apiKey,
        'email': email,
        'univName': '원광대학교', // ✅ UnivCert에서 등록된 정확한 명칭 필요
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
