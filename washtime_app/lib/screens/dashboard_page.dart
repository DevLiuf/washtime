import 'package:flutter/material.dart';
import 'package:washtime_app/services/supabase_service.dart';
import 'package:washtime_app/screens/device_list_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _laundryRooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final laundryRooms = await _supabaseService.fetchLaundryRoomStatus();
      setState(() {
        _laundryRooms = laundryRooms;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('대시보드 로딩 실패: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WashTime')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: _laundryRooms.map((room) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DeviceListPage(
                            laundryRoomId: (room['laundry_room_id'] as int?) ??
                                0, // ✅ null 값 방지
                            laundryRoomName: room['laundry_room_name'],
                          ),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 2,
                      child: ListTile(
                        title: Text(
                          room['laundry_room_name'],
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '🧺 세탁기: ${room['available_washers']}/${room['total_washers']}'),
                            Text(
                                '🌀 건조기: ${room['available_dryers']}/${room['total_dryers']}'),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
    );
  }
}
