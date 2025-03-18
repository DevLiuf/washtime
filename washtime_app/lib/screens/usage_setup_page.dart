import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:washtime_app/services/supabase_service.dart';
import 'package:washtime_app/screens/main_page.dart';

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_userRole == 'admin') ...[
              const Text(
                '사용 시간 설정',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              DropdownButton<int>(
                value: _selectedUsageTime,
                items: List<int>.generate(120, (index) => index + 1)
                    .map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text('$value 분'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedUsageTime = value);
                  }
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _startUsage,
                child: _isLoading
                    ? const CupertinoActivityIndicator()
                    : const Text('기기 사용 시작'),
              ),
              const SizedBox(height: 32),
              SwitchListTile(
                title: const Text('고장/점검 상태'),
                value: _isUnavailable,
                onChanged: _isLoading ? null : _toggleDeviceStatus,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
