// dashboard_page.dart
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:washtime_app/services/supabase_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final SupabaseService supabaseService = SupabaseService();
  List<Map<String, dynamic>> devices = [];
  bool isLoading = true;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _loadDevices();
    _startTimer();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _loadDevices() async {
    setState(() {
      isLoading = true;
    });

    try {
      final fetchedDevices = await supabaseService.getDevices();
      fetchedDevices.sort((a, b) => a['name'].compareTo(b['name'])); // 이름으로 정렬
      setState(() {
        devices = fetchedDevices;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showError('기기를 불러오는 중 오류가 발생했습니다: $e');
    }
  }

  void _startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      final List<Map<String, dynamic>> devicesToUpdate = [];

      for (var device in devices) {
        if (device['status'] == 'inUse') {
          final endTime = DateTime.parse(device['endTime']);
          final remaining = endTime.difference(now).inSeconds;

          if (remaining <= 0 && device['status'] != 'available') {
            // 업데이트가 필요한 기기를 리스트에 추가
            devicesToUpdate.add(device);
          } else if (remaining > 0) {
            // 로컬 상태 갱신
            device['remainingTime'] = remaining;
          }
        }
      }

      // 서버 호출: 업데이트가 필요한 기기만 처리
      if (devicesToUpdate.isNotEmpty) {
        _updateDevicesOnServer(devicesToUpdate);
      }

      setState(() {});
    });
  }

  Future<void> _updateDevicesOnServer(
      List<Map<String, dynamic>> devicesToUpdate) async {
    for (var device in devicesToUpdate) {
      await supabaseService.updateDevice(
        device['id'],
        status: 'available',
        remainingTime: 0,
      );
      device['status'] = 'available';
      device['remainingTime'] = 0;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String formatTime(int remainingTime) {
    final minutes = remainingTime ~/ 60;
    final seconds = remainingTime % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('세탁기 현황'),
        actions: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDevices,
              child: devices.isEmpty
                  ? const Center(child: Text('기기가 없습니다.'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(16.0),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 1,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        final isInUse = device['status'] == 'inUse';

                        return Container(
                          decoration: BoxDecoration(
                            color: isInUse ? Colors.red : Colors.blue,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.local_laundry_service,
                                  color: Colors.white,
                                  size: 40.0,
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  isInUse
                                      ? formatTime(device['remainingTime'])
                                      : '사용 가능',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
