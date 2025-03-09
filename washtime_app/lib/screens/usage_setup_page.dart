import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:washtime_app/services/supabase_service.dart';

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
      _loadDeviceStatus();
    }
  }

  Future<void> _loadDeviceStatus() async {
    final status =
        await SupabaseService().getDeviceStatus(int.parse(widget.deviceId));
    setState(() {
      _isUnavailable = status == 'unavailable';
    });
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

  void _navigateToHome() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _showIOSConfirmationDialog() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('변경 완료'),
          content: const Text('기기 상태가 변경되었습니다.\n홈 화면으로 이동할까요?'),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: _navigateToHome,
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
            if (_userRole != 'admin')
              ElevatedButton(
                onPressed: _isLoading ? null : () {},
                child: _isLoading
                    ? const CupertinoActivityIndicator()
                    : const Text('기기 사용 시작'),
              ),
            if (_userRole == 'admin') ...[
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
