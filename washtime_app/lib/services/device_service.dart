// 기기 상태 관리

import 'package:washtime_app/models/device_model.dart';

import 'supabase_service.dart';

class DeviceService {
  final SupabaseService supabaseService = SupabaseService();

  Future<List<DeviceModel>> getAllDevices() async {
    return await supabaseService.fetchDevices();
  }

  Future<void> startDeviceUsage(String deviceId) async {
    await supabaseService.updateDeviceStatus(deviceId, 'inUse' as DeviceStatus);
  }

  Future<void> stopDeviceUsage(String deviceId) async {
    await supabaseService.updateDeviceStatus(
        deviceId, 'available' as DeviceStatus);
  }
}
