import 'package:flutter/material.dart';
import 'package:washtime_app/services/supabase_service.dart';
import '../models/device_model.dart';

class UsageSetupPage extends StatefulWidget {
  final DeviceModel device;

  const UsageSetupPage({required this.device, super.key});

  @override
  State<UsageSetupPage> createState() => _UsageSetupPageState();
}

class _UsageSetupPageState extends State<UsageSetupPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose(); // 컨트롤러 메모리 해제
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('사용 시간 설정')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('기기 ID: ${widget.device.id}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            Text('기기 상태: ${widget.device.status}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            const Text(
              '사용 시간을 입력하세요:',
              style: TextStyle(fontSize: 18),
            ),
            TextField(
              controller: _controller, // 컨트롤러 연결
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: '사용 시간 (분)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (_controller.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('시간을 입력하세요!')),
                  );
                  return;
                }

                int usageMinutes = int.parse(_controller.text); // 입력값 가져오기
                DateTime startTime = DateTime.now();
                DateTime endTime =
                    startTime.add(Duration(minutes: usageMinutes));

                await SupabaseService().saveDeviceUsage(
                  widget.device.id,
                  usageMinutes,
                  startTime,
                  endTime,
                );

                Navigator.pop(context);
              },
              child: const Text('사용 시작'),
            ),
          ],
        ),
      ),
    );
  }
}
