import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'app_config.dart';
import 'drawing_widgets.dart';
import 'drawing_page.dart';
import 'bluetooth_page.dart';
import 'upload_page.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

// PPT 9page - 메인 화면
// 우측 상단: 블루투스, 네트워크 아이콘
// 중앙: 내작업 만들기 버튼
// 하단: 추천 콘텐츠 (AI 기능) 5개 카드

class MainHomePage extends StatefulWidget {
  const MainHomePage({super.key});

  @override
  State<MainHomePage> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> {
  BluetoothConnection? _connection;
  bool get _isConnected => _connection != null && _connection!.isConnected;
  // [수정] 하드코딩 제거 — AppConfig.serverUrl 사용
  String get _serverUrl => AppConfig.serverUrl;

  // 추천 콘텐츠 카드 데이터
  final List<Map<String, dynamic>> _contents = [
    {'icon': Icons.pets, 'label': '동물', 'color': Color(0xFFE3F2FD)},
    {'icon': Icons.park, 'label': '자연', 'color': Color(0xFFE8F5E9)},
    {'icon': Icons.directions_car, 'label': '탈것', 'color': Color(0xFFFFF9C4)},
    {'icon': Icons.emoji_emotions, 'label': '캐릭터', 'color': Color(0xFFFCE4EC)},
    {'icon': Icons.architecture, 'label': '건물', 'color': Color(0xFFEDE7F6)},
  ];

  // [수정] dispose — 소켓 누수 방지
  @override
  void dispose() {
    _connection?.finish();
    super.dispose();
  }

  // [수정] 블루투스 연결 종료 감지
  void _listenConnectionDone(BluetoothConnection conn) {
    conn.input?.listen(
      null,
      onDone: () {
        if (mounted) setState(() => _connection = null);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        title: const BrandTitle(),
        actions: [
          // 네트워크 아이콘
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Icon(Icons.wifi, color: Colors.white70, size: 22),
          ),
          const SizedBox(width: 8),
          // 블루투스 버튼
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BluetoothPage()),
                );
                if (result is BluetoothConnection) {
                  setState(() => _connection = result);
                  // [수정] 연결 종료 이벤트 구독
                  _listenConnectionDone(result);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _isConnected
                      ? AppColors.green.withValues(alpha: 0.2)
                      : Colors.white12,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isConnected ? AppColors.green : Colors.white38,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isConnected
                          ? Icons.bluetooth_connected
                          : Icons.bluetooth,
                      color: _isConnected ? AppColors.green : AppColors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    // PPT의 "My" 텍스트
                    Text(
                      'My',
                      style: TextStyle(
                        color: _isConnected ? AppColors.green : AppColors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // 내작업 만들기 버튼
            Center(
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DrawingPage(connection: _connection),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 36,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.navy,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: AppColors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        '내작업 만들기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.border,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // 추천 콘텐츠 섹션 헤더
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.navy,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '추천 콘텐츠',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.border,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.yellow,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'AI',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppColors.border,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 추천 콘텐츠 카드 5개
            Row(
              children: _contents.map((item) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DrawingPage(connection: _connection),
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: item['color'] as Color,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(1, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            color: AppColors.navy,
                            size: 28,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item['label'] as String,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.border,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const Spacer(),

            // 하단 네비게이션 버튼들
            Row(
              children: [
                Expanded(
                  child: _navButton(
                    icon: Icons.upload,
                    label: '사진 전송',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UploadPage(base: _serverUrl),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _navButton(
                    icon: Icons.download,
                    label: '결과 다운로드',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UploadPage(base: _serverUrl),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _navButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
