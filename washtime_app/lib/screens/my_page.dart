import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:washtime_app/services/alarm_service.dart';
import 'package:washtime_app/services/supabase_service.dart';
import 'package:washtime_app/screens/login_page.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  String? userEmail;
  bool isAlarmEnabled = true; // 5분 전 알람 여부

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('user_email') ?? "이메일 정보 없음";
      isAlarmEnabled = prefs.getBool('alarm_enabled') ?? true;
    });
  }

  Future<void> _toggleAlarm(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('alarm_enabled', value);
    setState(() {
      isAlarmEnabled = value;
    });

    if (value) {
      // 🔹 기존 예약된 기기들에 대해 알람 예약
      // 여기서 userEmail 대신 user_uuid를 가져와야 함
      final String? userUuid = prefs.getString('user_uuid');
      if (userUuid != null) {
        final List<Map<String, dynamic>> devices =
            await SupabaseService().fetchUserDevices(userUuid);
        for (var device in devices) {
          if (device['endtime'] != null) {
            DateTime endTime = DateTime.parse(device['endtime']);
            await AlarmService.setAlarmForDevice(device['device_id'], endTime);
          }
        }
      }
    } else {
      // 🔹 알람 OFF 시 모든 알람 취소
      await AlarmService.clearAllAlarms();
    }
  }

  void _showConfirmDialog(
      {required String title,
      required String content,
      required VoidCallback onConfirm}) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            CupertinoDialogAction(
              child: const Text("취소",
                  style: TextStyle(color: CupertinoColors.systemGrey)),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              child: const Text("확인",
                  style: TextStyle(color: CupertinoColors.systemRed)),
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    _showConfirmDialog(
      title: "로그아웃",
      content: "정말 로그아웃 하시겠습니까?",
      onConfirm: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('user_uuid'); // UUID 삭제
        await prefs.remove('user_email'); // 이메일 삭제
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
      },
    );
  }

  Future<void> _deleteAccount() async {
    _showConfirmDialog(
      title: "회원 탈퇴",
      content: "정말 회원 탈퇴하시겠습니까? \n 계정이 완전히 삭제됩니다.",
      onConfirm: () async {
        try {
          final prefs = await SharedPreferences.getInstance();
          final userId = prefs.getString('user_uuid');

          if (userId != null) {
            await SupabaseService().deleteUserAccount(userId);
          }

          await prefs.clear(); // 모든 로컬 데이터 삭제

          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false,
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('회원 탈퇴 실패: $e')),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('마이페이지')),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w), // 반응형 패딩
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 30.h), // 상단 간격 조정
            Text(
              '계정 정보',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.h),
            Text(
              '이메일: ${userEmail ?? "불러오는 중..."}',
              style: TextStyle(fontSize: 16.sp),
            ),
            SizedBox(height: 30.h),

            // 🔹 5분 전 알람 설정
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('사용 종료 5분 전 알람', style: TextStyle(fontSize: 16.sp)),
                Switch(
                  value: isAlarmEnabled,
                  onChanged: _toggleAlarm,
                ),
              ],
            ),
            const Spacer(), // 하단 버튼을 하단으로 밀기

            // 🔹 버튼을 하단에 배치 & 띄워서 배치
            Padding(
              padding: EdgeInsets.only(bottom: 30.h), // 하단 간격 추가
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: Size(140.w, 50.h), // 버튼 크기 조정
                    ),
                    child: Text('로그아웃',
                        style: TextStyle(color: Colors.white, fontSize: 16.sp)),
                  ),
                  ElevatedButton(
                    onPressed: _deleteAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: Size(140.w, 50.h), // 버튼 크기 조정
                    ),
                    child: Text('회원 탈퇴',
                        style: TextStyle(color: Colors.white, fontSize: 16.sp)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
