import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:washtime_app/models/device_model.dart';
import 'package:washtime_app/services/supabase_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final SupabaseService _supabaseService = SupabaseService();
  List<DeviceModel> _washers = [];
  List<DeviceModel> _dryers = [];
  Map<int, Duration> _remainingTimes = {};
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final devices = await _supabaseService.fetchDevices();
      final usageStatus = await _supabaseService.fetchDeviceStatus();

      Map<int, Duration> newRemainingTimes = {};
      DateTime now = DateTime.now();

      for (var entry in usageStatus.entries) {
        int deviceId = entry.key;
        DateTime? endTime = entry.value;
        if (endTime != null) {
          Duration remaining = endTime.difference(now);
          if (remaining.isNegative) {
            newRemainingTimes[deviceId] = Duration.zero;
            await _supabaseService.updateDeviceStatus(
                deviceId, 'available', null);
          } else {
            newRemainingTimes[deviceId] = remaining;
          }
        }
      }

      setState(() {
        _washers = devices.where((d) => d.type == 'washer').toList();
        _dryers = devices.where((d) => d.type == 'dryer').toList();
        _remainingTimes = newRemainingTimes;
      });

      _startTimer();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('데이터 로딩 실패: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingTimes.updateAll((key, value) {
            if (value > const Duration(seconds: 0)) {
              return value - const Duration(seconds: 1);
            } else {
              _supabaseService.updateDeviceStatus(key, 'available', null);
              return Duration.zero;
            }
          });
        });
      }
    });
  }

  String _formatRemainingTime(int deviceId) {
    if (!_remainingTimes.containsKey(deviceId) ||
        _remainingTimes[deviceId]!.inSeconds <= 0) {
      return '사용 가능';
    }
    Duration remaining = _remainingTimes[deviceId]!;
    return '${remaining.inMinutes.toString().padLeft(2, '0')}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('대시보드')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: EdgeInsets.all(16.w),
                children: [
                  _buildDeviceSection(
                      '세탁기', _washers, Icons.local_laundry_service),
                  SizedBox(height: 16.h),
                  _buildDeviceSection('건조기', _dryers, Icons.dry),
                ],
              ),
            ),
    );
  }

  Widget _buildDeviceSection(
      String title, List<DeviceModel> devices, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 8.h),
        LayoutBuilder(
          builder: (context, constraints) {
            double screenWidth = constraints.maxWidth;
            int crossAxisCount = (screenWidth / 150).floor(); // 최소 카드 크기 150px
            crossAxisCount =
                crossAxisCount < 5 ? 5 : crossAxisCount; // 최소 5개 유지

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: devices.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 1.2,
                crossAxisSpacing: 8.w,
                mainAxisSpacing: 8.h,
              ),
              itemBuilder: (context, index) {
                final device = devices[index];
                return _buildDeviceItem(device, icon);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildDeviceItem(DeviceModel device, IconData icon) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double cardHeight =
            constraints.maxHeight > 0 ? constraints.maxHeight : 100.h;
        return Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: _remainingTimes[device.id] == null ||
                    _remainingTimes[device.id]!.inSeconds <= 0
                ? Colors.green
                : Colors.red,
            borderRadius: BorderRadius.circular(8.w),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                flex: 1,
                child: FittedBox(
                  child: Text(
                    'ID: ${device.id}',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
                  ),
                ),
              ),
              Flexible(
                flex: 2,
                child: FittedBox(
                  child:
                      Icon(icon, size: cardHeight * 0.4, color: Colors.black),
                ),
              ),
              Flexible(
                flex: 1,
                child: FittedBox(
                  child: Text(
                    _formatRemainingTime(device.id),
                    style: TextStyle(fontSize: 14.sp),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
