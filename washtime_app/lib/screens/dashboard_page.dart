import 'package:flutter/material.dart';
import '../components/washing_machine_card.dart';
import '../services/supabase_service.dart';
import '../models/device_model.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final SupabaseService _supabaseService = SupabaseService();
  List<DeviceModel> devices = [];

  @override
  void initState() {
    super.initState();
    _fetchDevices(); // 데이터를 가져오는 메서드 호출
  }

  /// 기기 목록 가져오기
  Future<void> _fetchDevices() async {
    try {
      final fetchedDevices = await _supabaseService.fetchDevices();

      setState(() {
        devices = fetchedDevices;
      });

      // 디버깅용 출력
      print('Devices from DashboardPage: $devices');
    } catch (e) {
      print('Error fetching devices in DashboardPage: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('기기 데이터를 가져오는 중 오류가 발생했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('대시보드'),
      ),
      body: devices.isEmpty
          ? const Center(child: CircularProgressIndicator()) // 로딩 화면
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                final remainingTime = device.calculateRemainingTime();

                // 디버깅용 출력
                print(
                    'Rendering device: ${device.name}, status: ${device.status}, remainingTime: $remainingTime');

                // 상태가 inUse인 경우 남은 시간에 따라 카드 색상과 텍스트 업데이트
                if (remainingTime <= 0) {
                  // remainingTime이 0 이하이면 사용 가능으로 변경
                  device.status =
                      DeviceStatus.available; // DeviceStatus 열거형 값으로 변환
                  _supabaseService.updateDeviceStatus(
                      device.id, DeviceStatus.available);
                }

                return WashingMachineCard(
                  status:
                      device.status == DeviceStatus.inUse ? '사용 중' : '사용 가능',
                  endTime: device.endTime,
                  remainingTime: remainingTime,
                );
              },
            ),
    );
  }
}
