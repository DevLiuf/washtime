import 'package:flutter/material.dart';

class WashingMachineCard extends StatelessWidget {
  final String status;
  final DateTime? endTime;
  final int remainingTime; // 남은 시간(초)

  const WashingMachineCard({
    required this.status,
    required this.endTime,
    required this.remainingTime,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = status == '사용 가능';
    final isInUse = status == '사용 중';

    return Card(
      color: isAvailable ? Colors.blue : (isInUse ? Colors.red : Colors.grey),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isAvailable ? '사용 가능' : (isInUse ? '사용 중' : '상태 없음'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            if (isInUse)
              Text(
                '${remainingTime ~/ 60}:${(remainingTime % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }
}
