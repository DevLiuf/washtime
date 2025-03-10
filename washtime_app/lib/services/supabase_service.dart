import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:washtime_app/models/device_model.dart';
import 'package:washtime_app/services/alarm_service.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;
  final Uuid uuid = Uuid();

  // 🔹 모든 기기 목록 가져오기
  Future<List<DeviceModel>> fetchDevices() async {
    try {
      final List<dynamic> response = await _client.from('devices').select('*');
      return response.map((e) => DeviceModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to fetch devices: $e');
    }
  }

  // 🔹 기기 사용 현황 조회 (남은 시간 계산용)
  Future<Map<int, DateTime?>> fetchDeviceStatus() async {
    try {
      final response = await _client
          .from('device_usage_status')
          .select('device_id, endtime')
          .neq('status', 'available');

      Map<int, DateTime?> deviceStatus = {};
      for (var entry in response) {
        int deviceId = entry['device_id'];
        DateTime? endTime =
            entry['endtime'] != null ? DateTime.parse(entry['endtime']) : null;
        deviceStatus[deviceId] = endTime;
      }
      return deviceStatus;
    } catch (e) {
      throw Exception('Failed to fetch device status: $e');
    }
  }

  // 🔹 기기 사용 시작
  Future<void> startDeviceUsage(
      int deviceId, String userId, int minutes) async {
    try {
      DateTime endTime = DateTime.now().add(Duration(minutes: minutes));

      await _client.from('device_usage_status').upsert({
        'device_id': deviceId,
        'user_id': userId,
        'status': 'in_use',
        'endtime': endTime.toIso8601String(),
      });

      await _client.from('operation_logs').insert({
        'device_id': deviceId,
        'user_id': userId,
        'starttime': DateTime.now().toIso8601String(),
        'endtime': endTime.toIso8601String(),
      });
      // ✅ 5분 전 알람 예약
      await AlarmService.setAlarmForDevice(deviceId, endTime);
    } catch (e) {
      throw Exception('Failed to start device usage: $e');
    }
  }

  // 🔹 사용 종료 (자동 반영)
  Future<void> updateDeviceStatus(
      int deviceId, String status, DateTime? endTime) async {
    try {
      await _client.from('device_usage_status').update({
        'status': status,
        'endtime': endTime?.toIso8601String(),
      }).eq('device_id', deviceId);
    } catch (e) {
      throw Exception('Failed to update device status: $e');
    }
  }

  // 🔹 UUID 생성 또는 조회
  Future<String> getOrCreateUUIDForUser(String email) async {
    try {
      final response = await _client
          .from('users')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      if (response != null && response['id'] != null) {
        return response['id']; // ✅ 기존 UUID 반환
      }

      final String newUUID = uuid.v4();

      await _client.from('users').insert({
        'id': newUUID,
        'email': email,
        'created_at': DateTime.now().toIso8601String(),
      });

      return newUUID;
    } catch (e) {
      throw Exception('Failed to create or fetch UUID: $e');
    }
  }

  // 🔹 특정 기기의 상태 조회
  Future<String> getDeviceStatus(int deviceId) async {
    try {
      final response = await _client
          .from('device_usage_status')
          .select('status')
          .eq('device_id', deviceId)
          .maybeSingle();

      if (response == null) return 'available';
      return response['status'];
    } catch (e) {
      throw Exception('Failed to fetch device status: $e');
    }
  }

  // ✅ 사용자가 현재 사용 중인 기기 목록 가져오기
  Future<List<Map<String, dynamic>>> fetchUserDevices(String userId) async {
    try {
      final response = await _client
          .from('device_usage_status')
          .select('device_id, endtime')
          .eq('user_id', userId)
          .eq('status', 'in_use');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch user devices: $e');
    }
  }

  // ✅ 사용 중인 기기 조기 종료
  Future<void> endDeviceUsage(int deviceId) async {
    try {
      await _client.from('device_usage_status').update({
        'status': 'available',
        'endtime': null,
      }).eq('device_id', deviceId);

      await _client.from('operation_logs').update({
        'endtime': DateTime.now().toIso8601String(),
      }).eq('device_id', deviceId);
      // ✅ 알람 취소
      await AlarmService.clearAllAlarms();
    } catch (e) {
      throw Exception('Failed to end device usage: $e');
    }
  }

  // ✅ 회원 탈퇴
  Future<void> deleteUserAccount(String userId) async {
    try {
      await _client.from('users').delete().eq('id', userId);
    } catch (e) {
      throw Exception('회원 탈퇴 실패: $e');
    }
  }

  // ✅ 사용자 역할 가져오기
  Future<String> getUserRole(String userId) async {
    final response = await _client
        .from('users')
        .select('role')
        .eq('id', userId)
        .maybeSingle();

    return response != null ? response['role'] : 'user';
  }

  Future<void> toggleDeviceAvailability(
      int deviceId, bool isUnavailable) async {
    try {
      String status = isUnavailable ? 'unavailable' : 'available';
      await _client.from('device_usage_status').update({
        'status': status,
      }).eq('device_id', deviceId);
    } catch (e) {
      throw Exception('Failed to toggle device availability: $e');
    }
  }
}
