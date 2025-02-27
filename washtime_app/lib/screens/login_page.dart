import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:washtime_app/services/supabase_service.dart';
import 'package:washtime_app/screens/main_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final SupabaseService _supabaseService = SupabaseService();

  Future<void> _login() async {
    final String email = '${_emailController.text}@wku.ac.kr'; // ✅ 이메일 도메인 변경

    try {
      final uuid = await _supabaseService.getOrCreateUUIDForUser(email);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_uuid', uuid);
      await prefs.setString('user_email', email); // ✅ 이메일 저장 추가

      if (!mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const MainPage()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('이메일 인증 로그인')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: '웹정보서비스 아이디'),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _login,
              child: const Text('로그인'),
            ),
          ],
        ),
      ),
    );
  }
}
