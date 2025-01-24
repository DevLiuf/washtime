// supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getDevices() async {
    try {
      final List<dynamic> response = await supabase.from('devices').select('*');

      return response
          .map((device) => Map<String, dynamic>.from(device))
          .toList();
    } catch (e) {
      throw Exception('Error fetching devices: $e');
    }
  }

  Future<void> updateDevice(String deviceId,
      {String? status, int? remainingTime}) async {
    try {
      final updateData = <String, dynamic>{};
      if (status != null) updateData['status'] = status;
      if (remainingTime != null) updateData['remainingTime'] = remainingTime;
      print(status);
      await supabase.from('devices').update(updateData).eq('id', deviceId);
    } catch (e) {
      throw Exception('Error updating device: $e');
    }
  }

  Future<void> setUsageTimes(String deviceId, DateTime startTime,
      DateTime endTime, int remainingTime) async {
    try {
      await supabase.from('devices').update({
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'remainingTime': remainingTime,
        'status': 'inUse',
      }).eq('id', deviceId);
    } catch (e) {
      throw Exception('Error setting usage times: $e');
    }
  }
}
