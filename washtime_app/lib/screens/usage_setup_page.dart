import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:washtime_app/services/supabase_service.dart';
import 'package:washtime_app/screens/main_page.dart';
import 'package:washtime_app/styles/app_colors.dart';
import 'package:washtime_app/styles/app_paddings.dart';
import 'package:washtime_app/styles/app_text_styles.dart';

class UsageSetupPage extends StatefulWidget {
  final String deviceId;
  const UsageSetupPage({super.key, required this.deviceId});

  @override
  _UsageSetupPageState createState() => _UsageSetupPageState();
}

class _UsageSetupPageState extends State<UsageSetupPage> {
  bool _isUnavailable = false;
  String _userRole = 'user';
  bool _isLoading = false;
  bool _isReady = false;
  int _selectedUsageTime = 10; // 기본 사용 시간 10분

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final String? uuid = prefs.getString('user_uuid');

    if (uuid != null) {
      _userRole = await SupabaseService().getUserRole(uuid);
      await _loadDeviceStatus(); // ✅ 수정된 함수 호출
    }
    if (mounted) {
      setState(() {
        _isReady = true;
      });
    }
  }

  Future<void> _loadDeviceStatus() async {
    try {
      final status =
          await SupabaseService().getDeviceStatus(int.parse(widget.deviceId));
      setState(() {
        _isUnavailable = status == 'unavailable';
      });
    } catch (e) {
      print('기기 상태 불러오기 실패: $e');
    }
  }

  Future<void> _startUsage() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString('user_uuid');

    if (userId != null) {
      await SupabaseService().startDeviceUsage(
        int.parse(widget.deviceId),
        userId,
        _selectedUsageTime,
      );
    }

    setState(() => _isLoading = false);

    // 🔹 UsageSetupPage와 QRScannerPage를 닫고 MainPage로 이동
    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainPage()),
    );
  }

  Future<void> _toggleDeviceStatus(bool value) async {
    setState(() => _isLoading = true);
    await SupabaseService()
        .toggleDeviceAvailability(int.parse(widget.deviceId), value);
    setState(() {
      _isUnavailable = value;
      _isLoading = false;
    });

    _showIOSConfirmationDialog();
  }

  void _showIOSConfirmationDialog() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('변경 완료'),
          content: const Text('기기 상태가 변경되었습니다.'),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('기기 사용 설정 (${widget.deviceId})')),
      body: !_isReady
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: AppPaddings.defaultPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ✅ 공통: 사용 시간 설정
                  Text(
                    '사용 시간 설정',
                    style: AppTextStyles.subtitle,
                  ),
                  const SizedBox(height: 10),
                  DropdownButton<int>(
                    value: _selectedUsageTime,
                    items: List<int>.generate(120, (index) => index + 1)
                        .map((int value) => DropdownMenuItem<int>(
                              value: value,
                              child: Text(
                                '$value 분',
                                style: AppTextStyles.body,
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedUsageTime = value);
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  // ✅ 공통: 기기 사용 시작 버튼
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.pastelBlue,
                      minimumSize: Size(double.infinity, 50.h),
                    ),
                    onPressed: _isLoading ? null : _startUsage,
                    child: _isLoading
                        ? const CupertinoActivityIndicator()
                        : const Text('기기 사용 시작'),
                  ),

                  const SizedBox(height: 32),

                  // ✅ 관리자 전용: 고장/점검 토글
                  if (_userRole == 'admin') ...[
                    SwitchListTile(
                      title: Text(
                        '고장/점검 상태',
                        style: AppTextStyles.body,
                      ),
                      value: _isUnavailable,
                      onChanged:
                          _isLoading ? null : (val) => _toggleDeviceStatus(val),
                      activeColor: AppColors.errorRed, // 🔘 스위치 썸(버튼) 색
                      activeTrackColor:
                          AppColors.pastelPink.withOpacity(0.5), // ▬ 트랙 색
                      inactiveThumbColor: Colors.grey[400], // 비활성화 썸 색
                      inactiveTrackColor: Colors.grey[300], // 비활성화 트랙 색
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
