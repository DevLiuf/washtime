import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

    try {
      final now = DateTime.now();
      final endTime = now.add(Duration(minutes: _selectedMinutes!));

      // 🔹 작동 이력 추가
      await supabase.from('operation_logs').insert({
        'washerid': int.parse(widget.deviceId), // deviceId를 int로 변환
        'courseid': 1, // 기본 세탁 코스 ID (수정 가능)
        'starttime': now.toIso8601String(),
        'endtime': endTime.toIso8601String(),
        'userid': 1, // 사용자의 ID (테스트 목적으로 기본값 1)
      });

      _showMessage('기기 사용이 시작되었습니다');

      // 메인 페이지로 이동
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      _showMessage('오류 발생: $e');
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
            // 뒤로 가기 시 메인 페이지로 이동
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
