import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:washtime_app/services/supabase_service.dart';

class MyDevicePage extends StatefulWidget {
  const MyDevicePage({super.key});

  @override
  _MyDevicePageState createState() => _MyDevicePageState();
}

class _MyDevicePageState extends State<MyDevicePage> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _myDevices = [];
  Map<int, Duration> _remainingTimes = {};
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchMyDevices();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchMyDevices() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString('user_uuid');

    if (userId == null) return;

    final List<Map<String, dynamic>> devices =
        await _supabaseService.fetchUserDevices(userId);

    setState(() {
      _myDevices = devices;
      _updateRemainingTimes();
    });

    _startTimer();
  }

  void _updateRemainingTimes() {
    final now = DateTime.now();
    Map<int, Duration> updatedTimes = {};

    for (var device in _myDevices) {
      if (device['endtime'] != null) {
        DateTime endTime = DateTime.parse(device['endtime']);
        Duration remaining = endTime.difference(now);
        updatedTimes[device['device_id']] =
            remaining.isNegative ? Duration.zero : remaining;
      }
    }

    setState(() {
      _remainingTimes = updatedTimes;
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _updateRemainingTimes();
        });
      }
    });
  }

  void _showEndDeviceDialog(int deviceId) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text("기기 사용 종료", style: TextStyle(fontSize: 18.sp)),
          content: Text("정말로 이 기기의 사용을 종료하시겠습니까?",
              style: TextStyle(fontSize: 16.sp)),
          actions: [
            CupertinoDialogAction(
              child: Text("취소",
                  style: TextStyle(
                      color: CupertinoColors.systemGrey, fontSize: 16.sp)),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              child: Text("확인",
                  style: TextStyle(
                      color: CupertinoColors.systemRed, fontSize: 16.sp)),
              onPressed: () async {
                Navigator.pop(context);
                await _endDeviceUsage(deviceId);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _endDeviceUsage(int deviceId) async {
    await _supabaseService.endDeviceUsage(deviceId);
    await _fetchMyDevices();
  }

  String _formatRemainingTime(int deviceId) {
    if (!_remainingTimes.containsKey(deviceId)) return '00:00';
    Duration remaining = _remainingTimes[deviceId]!;
    return '${remaining.inMinutes.toString().padLeft(2, '0')}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('내 기기', style: TextStyle(fontSize: 20.sp))),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: _myDevices.isEmpty
            ? Center(
                child: Text(
                  '현재 사용 중인 기기가 없습니다.',
                  style:
                      TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
              )
            : ListView.builder(
                itemCount: _myDevices.length,
                itemBuilder: (context, index) {
                  final device = _myDevices[index];
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 8.h),
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5.r,
                          spreadRadius: 1.r,
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('기기 ID: ${device['device_id']}',
                                style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold)),
                            SizedBox(height: 5.h),
                            Text(
                                '남은 시간: ${_formatRemainingTime(device['device_id'])}',
                                style: TextStyle(fontSize: 14.sp)),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () =>
                              _showEndDeviceDialog(device['device_id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            minimumSize: Size(80.w, 40.h), // 반응형 버튼 크기 조정
                          ),
                          child: Text('사용 종료',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 14.sp)),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
