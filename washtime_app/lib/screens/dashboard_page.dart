import 'package:flutter/material.dart';
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
  List<int> _activeDeviceIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData(); // 앱이 열렸을 때 데이터 로드
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true; // 로딩 상태 시작
    });
    try {
      final devices = await _supabaseService.fetchDevices();
      final activeDeviceIds = await _supabaseService.fetchActiveDeviceIds();

      final washers =
          devices.where((device) => device.type == 'washer').toList();
      final dryers = devices.where((device) => device.type == 'dryer').toList();

      setState(() {
        _washers = washers;
        _dryers = dryers;
        _activeDeviceIds = activeDeviceIds;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('데이터를 불러오지 못했습니다: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false; // 로딩 상태 종료
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width; // 화면 너비
    final cardWidth = (screenWidth - 64) / 5; // 한 줄에 5개, 패딩 포함

    return Scaffold(
      appBar: AppBar(
        title: const Text('대시보드'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // 로딩 상태
          : RefreshIndicator(
              onRefresh: _loadData, // 새로고침 시 데이터 로드
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildDeviceSection('세탁기', _washers, cardWidth),
                  const SizedBox(height: 16.0),
                  _buildDeviceSection('건조기', _dryers, cardWidth),
                ],
              ),
            ),
    );
  }

  Widget _buildDeviceSection(
      String title, List<DeviceModel> devices, double cardWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8.0),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5, // 한 줄에 5개
            mainAxisSpacing: 16.0,
            crossAxisSpacing: 16.0,
            childAspectRatio: 1, // 카드의 비율을 정사각형으로 유지
          ),
          itemCount: devices.length,
          itemBuilder: (context, index) {
            final device = devices[index];
            final isActive = _activeDeviceIds.contains(device.id);

            return _buildDeviceCard(device, isActive, cardWidth);
          },
        ),
      ],
    );
  }

  Widget _buildDeviceCard(DeviceModel device, bool isActive, double cardWidth) {
    return Container(
      width: cardWidth,
      height: cardWidth,
      decoration: BoxDecoration(
        color: isActive ? Colors.red[300] : Colors.green[300], // 상태에 따라 색상 변경
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          // 1: 텍스트 비율
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                'ID: ${device.id}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: cardWidth * 0.1, // 카드 크기에 비례한 텍스트 크기
                ),
                overflow: TextOverflow.ellipsis, // 텍스트 오버플로우 방지
              ),
            ),
          ),
          // 3: 아이콘 비율
          Expanded(
            flex: 3,
            child: Center(
              child: Icon(
                device.type == 'washer'
                    ? Icons.local_laundry_service
                    : Icons.dry_cleaning,
                size: cardWidth * 0.5, // 카드 크기에 비례한 아이콘 크기
              ),
            ),
          ),
          // 1: 상태/남은 시간 비율
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                isActive ? '사용 중' : '사용 가능',
                style: TextStyle(
                  fontSize: cardWidth * 0.1, // 카드 크기에 비례한 텍스트 크기
                ),
                overflow: TextOverflow.ellipsis, // 텍스트 오버플로우 방지
              ),
            ),
          ),
        ],
      ),
    );
  }
}
