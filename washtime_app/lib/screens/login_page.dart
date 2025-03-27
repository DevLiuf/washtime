import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:washtime_app/screens/main_page.dart';
import 'package:washtime_app/services/supabase_service.dart';
import 'package:washtime_app/services/univcert_service.dart';
import 'package:washtime_app/styles/app_colors.dart';
import 'package:washtime_app/styles/app_paddings.dart';
import 'package:washtime_app/styles/app_text_styles.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final SupabaseService _supabaseService = SupabaseService();
  final UnivCertService _univCertService = UnivCertService();

  bool isCodeSent = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyLoggedIn();
  }

  Future<void> _checkIfAlreadyLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final String? uuid = prefs.getString('user_uuid');
    if (uuid != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainPage()),
      );
    }
  }

  Future<void> _sendVerificationCode() async {
    final String userId = _emailController.text.trim();
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디를 입력해주세요.')),
      );
      return;
    }

    final String email = '$userId@wonkwang.ac.kr';
    setState(() => isLoading = true);

    final isVerified = await _univCertService.isAlreadyVerified(email);

    if (isVerified) {
      // ✅ 이미 인증된 사용자 → 바로 로그인 처리
      final uuid = await _supabaseService.getOrCreateUUIDForUser(email);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_uuid', uuid);
      await prefs.setString(
          'user_email', email.replaceAll('@wonkwang.ac.kr', '@wku.ac.kr'));

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainPage()),
      );
      return;
    }

    final success = await _univCertService.sendVerificationCode(email);

    if (success) {
      setState(() => isCodeSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증 코드가 전송되었습니다. 이메일을 확인해주세요.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증 코드 전송 실패. 이메일을 확인해주세요.')),
      );
    }
    setState(() => isLoading = false);
  }

  Future<void> _verifyCodeAndLogin() async {
    final String userId = _emailController.text.trim();
    final String email = '$userId@wonkwang.ac.kr';
    final String code = _codeController.text.trim();

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증 코드를 입력해주세요.')),
      );
      return;
    }

    setState(() => isLoading = true);

    final verified = await _univCertService.verifyCode(email, code);

    if (!verified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증 실패. 올바른 인증 코드를 입력해주세요.')),
      );
      setState(() => isLoading = false);
      return;
    }

    try {
      final uuid = await _supabaseService.getOrCreateUUIDForUser(email);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_uuid', uuid);
      await prefs.setString(
          'user_email', email.replaceAll('@wonkwang.ac.kr', '@wku.ac.kr'));

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 실패: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('원광대 이메일 인증 로그인')),
      body: Padding(
        padding: AppPaddings.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: '웹정보서비스 아이디 (예: hongildong1234)',
                labelStyle: AppTextStyles.caption,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            ElevatedButton(
              onPressed: isLoading ? null : _sendVerificationCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pastelBlue,
                minimumSize: Size(double.infinity, 48.h),
              ),
              child: Text('인증 코드 요청', style: AppTextStyles.button),
            ),
            if (isCodeSent) ...[
              SizedBox(height: 16.h),
              TextField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: '인증 코드 입력',
                  labelStyle: AppTextStyles.caption,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              ElevatedButton(
                onPressed: isLoading ? null : _verifyCodeAndLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pastelPink,
                  minimumSize: Size(double.infinity, 48.h),
                ),
                child: Text('인증 및 로그인', style: AppTextStyles.button),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
