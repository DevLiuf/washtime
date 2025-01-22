import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/device_model.dart';

class SupabaseService {
  final supabase = Supabase.instance.client;

  /// 기기 목록 가져오기
  Future<List<DeviceModel>> fetchDevices() async {
    try {
      final response = await supabase
          .from('devices')
          .select()
          .order('id', ascending: true); // 'id' 기준으로 정렬

      if (response.isEmpty) {
        throw Exception('No devices found');
      }

      // 디버깅용 출력
      print('Fetched devices: $response');

      return (response as List<dynamic>)
          .map((json) => DeviceModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching devices: $e');
      throw Exception('Failed to fetch devices');
    }
  }

  /// 특정 기기 상태 업데이트
  Future<void> updateDeviceStatus(String deviceId, DeviceStatus status) async {
    try {
      final response = await supabase
          .from('devices')
          .update({'status': status.name}) // status 값을 문자열로 변환하여 저장
          .eq('id', deviceId); // deviceId로 기기 특정
      print('Supabase Response: $response'); // 디버깅용 출력

      if (response == null || response.isEmpty) {
        throw Exception('Failed to update status for device $deviceId');
      } else {
        print('Device status updated successfully: $deviceId');
      }
    } catch (e) {
      print('Error updating device status for $deviceId: $e');
      throw Exception('Failed to update status for device $deviceId');
    }
  }

  /// 특정 기기의 남은 시간 업데이트
  Future<void> updateDeviceTime(String deviceId, int remainingTime) async {
    final response = await supabase
        .from('devices')
        .update({'remainingTime': remainingTime}).eq('id', deviceId);

    if (response == null || response.isEmpty) {
      throw Exception('Failed to update remaining time for device $deviceId');
    }
  }

  /// 특정 기기 가져오기
  Future<DeviceModel?> getDeviceById(String deviceId) async {
    final response =
        await supabase.from('devices').select().eq('id', deviceId).single();

    return DeviceModel.fromJson(response);
  }

  /// 기기 사용 시간 저장
  Future<void> saveDeviceUsage(
    String deviceId,
    int minutes,
    DateTime startTime,
    DateTime endTime,
  ) async {
    final response = await supabase.from('devices').update({
      'status': 'inUse',
      'remainingTime': minutes * 60, // 초 단위 저장
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
    }).eq('id', deviceId);

    if (response == null || response.isEmpty) {
      throw Exception('Failed to save device usage for $deviceId');
    }
  }
}
