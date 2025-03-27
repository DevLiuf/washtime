import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:washtime_app/services/supabase_service.dart';
import 'package:washtime_app/screens/device_list_page.dart';
import 'package:washtime_app/styles/app_colors.dart';
import 'package:washtime_app/styles/app_paddings.dart';
import 'package:washtime_app/styles/app_text_styles.dart';

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
      // ✅ 사용 종료된 기기 상태 먼저 서버에 반영
      final prefs = await SharedPreferences.getInstance();
      final uuid = prefs.getString('user_uuid');
      if (uuid != null) {
        await _endExpiredDeviceUsages(uuid);
      }

      // ✅ 세탁방 데이터 불러오기
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

  // ✅ 상태 자동 갱신 함수
  Future<void> _endExpiredDeviceUsages(String userId) async {
    final supabaseService = SupabaseService();
    final devices = await supabaseService.fetchUserDevices(userId);

    for (var device in devices) {
      final String? endtimeStr = device['endtime'];
      if (endtimeStr != null) {
        final DateTime endtime = DateTime.parse(endtimeStr);
        if (endtime.isBefore(DateTime.now())) {
          await supabaseService.endDeviceUsage(device['device_id']);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('WashTime')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: AppPaddings.defaultPadding,
                children: [
                  ..._laundryRooms.map((room) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DeviceListPage(
                              laundryRoomId:
                                  (room['laundry_room_id'] as int?) ?? 0,
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
                            style: AppTextStyles.subtitle,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🧺 세탁기: ${room['available_washers']}/${room['total_washers']}',
                                style: AppTextStyles.caption,
                              ),
                              Text(
                                '🌀 건조기: ${room['available_dryers']}/${room['total_dryers']}',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.blue[100],
                    child: Padding(
                      padding: AppPaddings.defaultPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('📘 WashTime 사용 안내',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 12),
                          Text('🧺 요금 안내',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('- 세탁기: 1,000원 / 건조기: 1,000원'),
                          SizedBox(height: 8),
                          Text('📱 사용 방법',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('1. QR코드 스캔\n2. 시간 선택\n3. 시작 누르면 완료!'),
                          SizedBox(height: 8),
                          Text('📢 공지사항',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                              '- 고장 기기는 회색으로 표시됩니다\n- 세탁 후 세탁물은 꼭 꺼내주세요\n- 기기 앞에 있는 QR만 스캔 가능합니다'),
                          SizedBox(height: 8),
                          Text('🎁 지금 인증하면?',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('간식 / 상품권 / 세제 키트 제공! (선착순 100명)'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
