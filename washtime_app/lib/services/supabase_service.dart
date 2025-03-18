import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:washtime_app/models/device_model.dart';
import 'package:washtime_app/services/alarm_service.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;
  final Uuid uuid = Uuid();

  // 🔹 모든 기기의 사용 상태 조회 (대시보드에서 사용)
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

  // 🔹 사용자 UUID 조회 또는 생성 (복구된 코드)
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

  // 🔹 사용자 계정 삭제 (회원 탈퇴)
  Future<void> deleteUserAccount(String userId) async {
    try {
      await _client.from('users').delete().eq('id', userId);
    } catch (e) {
      throw Exception('회원 탈퇴 실패: $e');
    }
  }

  // 🔹 사용자 역할 가져오기
  Future<String> getUserRole(String userId) async {
    final response = await _client
        .from('users')
        .select('role')
        .eq('id', userId)
        .maybeSingle();

    return response != null ? response['role'] : 'user';
  }

  // 🔹 사용자가 현재 사용 중인 기기 목록 가져오기 (UUID 기반)
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

  // 🔹 모든 기기 목록 가져오기
  Future<List<DeviceModel>> fetchDevices() async {
    try {
      final List<dynamic> response = await _client.from('devices').select('*');
      return response.map((e) => DeviceModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to fetch devices: $e');
    }
  }

  // 🔹 특정 세탁방의 기기 목록 조회
  Future<List<DeviceModel>> fetchDevicesByRoom(int laundryRoomId) async {
    try {
      final List<dynamic> response = await _client
          .from('devices')
          .select('*')
          .eq('laundry_room_id', laundryRoomId);

      return response.map((e) => DeviceModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to fetch devices by room: $e');
    }
  }

  // 🔹 특정 세탁방의 모든 기기 ID 조회 (내부적으로 사용)
  Future<List<int>> fetchDeviceIds(int laundryRoomId) async {
    try {
      final response = await _client
          .from('devices')
          .select('id')
          .eq('laundry_room_id', laundryRoomId);

      return response.map<int>((e) => e['id'] as int).toList();
    } catch (e) {
      throw Exception('Failed to fetch device IDs: $e');
    }
  }

  // 🔹 세탁방별 사용 가능 기기 개수 조회 (대시보드에서 사용)
  Future<List<Map<String, dynamic>>> fetchLaundryRoomStatus() async {
    try {
      final List<dynamic> response =
          await _client.rpc('get_laundry_room_status').select();

      return response.map((room) {
        return {
          'laundry_room_id':
              (room['laundry_room_id'] as int?) ?? 0, // ✅ null 방지
          'laundry_room_name': room['laundry_room_name'] ?? '알 수 없음',
          'total_washers': (room['total_washers'] as num?)?.toInt() ?? 0,
          'available_washers':
              (room['available_washers'] as num?)?.toInt() ?? 0,
          'total_dryers': (room['total_dryers'] as num?)?.toInt() ?? 0,
          'available_dryers': (room['available_dryers'] as num?)?.toInt() ?? 0,
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch laundry room status: $e');
    }
  }

  // 🔹 특정 세탁방의 기기 상태 조회 (대시보드 및 개별 세탁방 UI에서 사용)
  Future<List<DeviceModel>> fetchDevicesWithStatus(int laundryRoomId) async {
    final response = await _client
        .from('devices')
        .select('id, type, created_at, device_usage_status(endtime, status)')
        .eq('laundry_room_id', laundryRoomId);

    return response.map((device) {
      return DeviceModel(
        id: device['id'],
        type: device['type'],
        status: device['device_usage_status']?['status'] ?? 'available',
        createdAt: DateTime.parse(device['created_at']), // ✅ createdAt 추가
        endTime: device['device_usage_status']?['endtime'] != null
            ? DateTime.parse(device['device_usage_status']['endtime'])
            : null,
      );
    }).toList();
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

  // 🔹 사용 중인 기기 조기 종료
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

  // 🔹 기기 상태 변경 (고장/점검)
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

  // 🔹 특정 기기의 상태 조회 (UsageSetupPage에서 사용)
  Future<String> getDeviceStatus(int deviceId) async {
    try {
      final response = await _client
          .from('device_usage_status')
          .select('status')
          .eq('device_id', deviceId)
          .maybeSingle();

      return response != null ? response['status'] : 'available';
    } catch (e) {
      throw Exception('Failed to fetch device status: $e');
    }
  }

  // 🔹 기기 상태 업데이트 (사용 가능, 사용 중, 고장/점검)
  Future<void> updateDeviceStatus(
      int deviceId, String status, DateTime? endTime) async {
    try {
      await _client.from('device_usage_status').upsert({
        'device_id': deviceId,
        'status': status,
        'endtime': endTime?.toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update device status: $e');
    }
  }
}
