import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:washtime_app/models/device_model.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // 1. 모든 기기 가져오기
  Future<List<DeviceModel>> fetchDevices() async {
    try {
      final List<dynamic> response = await _client.from('devices').select('*');

      return response.map((e) {
        return DeviceModel(
          id: e['id'] as int,
          type: e['type'] ?? 'unknown',
          status: e['status'] ?? 'unknown',
          createdAt: DateTime.parse(
              e['createdat'] ?? DateTime.now().toIso8601String()),
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch devices: $e');
    }
  }

  // 2. 현재 작동 중인 기기 가져오기
  Future<List<int>> fetchActiveDeviceIds() async {
    try {
      final List<dynamic> response = await _client
          .from('operation_logs')
          .select('washerid')
          .gt('endtime', DateTime.now().toIso8601String());

      return response.map((e) => e['washerid'] as int).toList();
    } catch (e) {
      throw Exception('Failed to fetch active devices: $e');
    }
  }

  // 3. 작동 이력 추가하기
  Future<void> addUsageLog({
    required int washerid,
    required int courseid,
    required DateTime starttime,
    required DateTime endtime,
    required int userid,
  }) async {
    try {
      await _client.from('operation_logs').insert({
        'washerid': washerid,
        'courseid': courseid,
        'starttime': starttime.toIso8601String(),
        'endtime': endtime.toIso8601String(),
        'userid': userid,
      });
    } catch (e) {
      throw Exception('Failed to add usage log: $e');
    }
  }
}
