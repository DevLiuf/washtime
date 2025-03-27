import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:washtime_app/services/supabase_service.dart';
import 'package:washtime_app/services/alarm_service.dart';
import 'package:washtime_app/styles/app_colors.dart';
import 'package:washtime_app/styles/app_text_styles.dart';

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
    _initializeDevices();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initializeDevices() async {
    await _fetchMyDevices();
    _startTimer();
  }

  Future<void> _fetchMyDevices() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString('user_uuid');

    if (userId == null) return;

    final devices = await _supabaseService.fetchUserDevices(userId);

    setState(() {
      _myDevices = devices;
    });

    _updateRemainingTimesAndFilterDevices();
  }

  void _updateRemainingTimesAndFilterDevices() {
    final now = DateTime.now();
    final Map<int, Duration> updatedTimes = {};
    final List<Map<String, dynamic>> activeDevices = [];

    for (var device in _myDevices) {
      if (device['endtime'] != null) {
        final endTime = DateTime.parse(device['endtime']);
        final remaining = endTime.difference(now);
        final clamped = remaining.isNegative ? Duration.zero : remaining;

        if (clamped.inSeconds > 0) {
          updatedTimes[device['device_id']] = clamped;
          activeDevices.add(device);
        }
      }
    }

    setState(() {
      _remainingTimes = updatedTimes;
      _myDevices = activeDevices;
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _updateRemainingTimesAndFilterDevices();
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
    await AlarmService.cancelAlarm(deviceId);
    await _supabaseService.endDeviceUsage(deviceId);
    await _fetchMyDevices();
  }

  String _formatRemainingTime(int deviceId) {
    if (!_remainingTimes.containsKey(deviceId)) return '00:00';
    final remaining = _remainingTimes[deviceId]!;
    return '${remaining.inMinutes.toString().padLeft(2, '0')}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 기기')),
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
                      color: AppColors.pastelWhite,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5.r,
                        ),
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
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.errorRed,
                            minimumSize: Size(80.w, 40.h),
                          ),
                          onPressed: () =>
                              _showEndDeviceDialog(device['device_id']),
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
