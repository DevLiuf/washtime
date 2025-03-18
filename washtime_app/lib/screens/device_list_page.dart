import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:washtime_app/models/device_model.dart';
import 'package:washtime_app/services/supabase_service.dart';

class DeviceListPage extends StatefulWidget {
  final int laundryRoomId;
  final String laundryRoomName;

  const DeviceListPage(
      {super.key, required this.laundryRoomId, required this.laundryRoomName});

  @override
  _DeviceListPageState createState() => _DeviceListPageState();
}

class _DeviceListPageState extends State<DeviceListPage> {
  final SupabaseService _supabaseService = SupabaseService();
  List<DeviceModel> _washers = [];
  List<DeviceModel> _dryers = [];
  Map<int, Duration> _remainingTimes = {};
  Map<int, String> _deviceStatuses = {};
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchDevices();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchDevices() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final devices =
          await _supabaseService.fetchDevicesByRoom(widget.laundryRoomId);
      final usageStatus =
          await _supabaseService.fetchDeviceStatusByRoom(widget.laundryRoomId);

      if (!mounted) return;

      Map<int, Duration> newRemainingTimes = {};
      Map<int, String> newDeviceStatuses = {};
      DateTime now = DateTime.now();

      for (var entry in usageStatus.entries) {
        int deviceId = entry.key;
        DateTime? endTime = entry.value;
        String status = await _supabaseService.getDeviceStatus(deviceId);

        if (status == 'unavailable') {
          newDeviceStatuses[deviceId] = 'unavailable';
        } else {
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
          newDeviceStatuses[deviceId] = 'in_use';
        }
      }

      setState(() {
        _washers = devices.where((d) => d.type == 'washer').toList();
        _dryers = devices.where((d) => d.type == 'dryer').toList();
        _remainingTimes = newRemainingTimes;
        _deviceStatuses = newDeviceStatuses;
      });

      _startTimer();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('기기 목록 불러오기 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _remainingTimes.updateAll((key, value) {
          return value > const Duration(seconds: 0)
              ? value - const Duration(seconds: 1)
              : Duration.zero;
        });
      });
    });
  }

  String _formatRemainingTime(int deviceId) {
    if (_deviceStatuses[deviceId] == 'unavailable') {
      return '고장';
    }
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
      appBar: AppBar(title: Text(widget.laundryRoomName)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchDevices,
              child: ListView(
                padding: EdgeInsets.all(16.w),
                children: [
                  _buildDeviceSection(
                      '세탁기', _washers, Icons.local_laundry_service),
                  SizedBox(height: 16.h),
                  _buildDeviceSection('건조기', _dryers, Icons.dry_cleaning),
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
            int crossAxisCount = (screenWidth / 150).floor();
            crossAxisCount = crossAxisCount < 5 ? 5 : crossAxisCount;

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
            color: _deviceStatuses[device.id] == 'unavailable'
                ? Colors.grey
                : (_remainingTimes[device.id] == null ||
                        _remainingTimes[device.id]!.inSeconds <= 0
                    ? Colors.lightBlue
                    : Colors.red),
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
                  child: Icon(
                    icon,
                    size: cardHeight * 0.4,
                  ),
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
