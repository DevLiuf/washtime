import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:washtime_app/services/alarm_service.dart';

class UsageSetupPage extends StatefulWidget {
  final String deviceId;

  const UsageSetupPage({super.key, required this.deviceId});

  @override
  _UsageSetupPageState createState() => _UsageSetupPageState();
}

class _UsageSetupPageState extends State<UsageSetupPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  int? _selectedMinutes;

  Future<void> _startDeviceUsage() async {
    if (_selectedMinutes == null) {
      _showMessage('사용 시간을 선택해주세요');
      return;
    }

    // 🔹 UUID 가져오기
    final prefs = await SharedPreferences.getInstance();
    final String? uuid = prefs.getString('user_uuid');

    if (uuid == null) {
      _showMessage('사용자 인증이 필요합니다.');
      return;
    }

    try {
      final now = DateTime.now();
      final endTime = now.add(Duration(minutes: _selectedMinutes!));

      // ✅ device_usage_status 업데이트
      await supabase.from('device_usage_status').upsert({
        'device_id': int.parse(widget.deviceId),
        'user_id': uuid,
        'status': 'in_use',
        'endtime': endTime.toIso8601String(),
      });

      // ✅ operation_logs 기록
      await supabase.from('operation_logs').insert({
        'device_id': int.parse(widget.deviceId),
        'user_id': uuid,
        'starttime': now.toIso8601String(),
        'endtime': endTime.toIso8601String(),
      });

      // ✅ 알람 예약 추가
      await AlarmService.setAlarmForDevice(int.parse(widget.deviceId), endTime);

      _showMessage('기기 사용이 시작되었습니다');
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      _showMessage('오류 발생: ${e.toString()}');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('기기 사용 설정 (${widget.deviceId})'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '사용 시간을 분 단위로 설정해주세요 (최대 120분):',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16.0),
            DropdownButton<int>(
              value: _selectedMinutes,
              items: List.generate(120, (index) => index + 1)
                  .map((value) => DropdownMenuItem<int>(
                        value: value,
                        child: Text('$value 분'),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMinutes = value;
                });
              },
              hint: const Text('분 선택'),
            ),
            const SizedBox(height: 32.0),
            ElevatedButton(
              onPressed: _startDeviceUsage,
              child: const Text('기기 사용 시작'),
            ),
          ],
        ),
      ),
    );
  }
}
