import 'dart:math';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'dart:io';
import 'app_theme.dart';
import 'app_config.dart';
import 'drawing_painter.dart';
import 'drawing_widgets.dart';
import 'bluetooth_page.dart';
import 'upload_page.dart';

class DrawingPage extends StatefulWidget {
  final BluetoothConnection? connection;
  const DrawingPage({super.key, this.connection});

  @override
  State<DrawingPage> createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  final List<DrawingPoint?> _points = [];
  final GlobalKey _canvasKey = GlobalKey(); // 캔버스 캡처용
  Color _selectedColor = Colors.black;
  double _strokeWidth = 5.0;
  bool _isEraser = false;
  bool _isDomainMode = false;
  int _selectedThumb = 0;
  bool _showPalette = false; // 펜 버튼 누를 때만 슬라이더+팔레트 노출
  // [수정] 하드코딩 제거 — AppConfig 공통 상수 사용
  String get _serverUrl => AppConfig.serverUrl;
  BluetoothConnection? _connection;

  bool get _isConnected => _connection != null && _connection!.isConnected;

  static const _palette = [
    Colors.black,
    AppColors.red,
    Colors.orange,
    Colors.yellow,
    AppColors.green,
    AppColors.blue,
    Colors.purple,
  ];

  @override
  void initState() {
    super.initState();
    _connection = widget.connection;
    // [수정] 블루투스 연결 종료 이벤트 구독
    _listenConnectionDone(_connection);
  }

  // [신규] 연결 종료 감지 — 상대방이 끊거나 범위 벗어났을 때 UI 자동 초기화
  void _listenConnectionDone(BluetoothConnection? conn) {
    conn?.input?.listen(
      null,
      onDone: () {
        if (mounted) setState(() => _connection = null);
      },
    );
  }

  // [신규] dispose — 소켓 누수 방지
  @override
  void dispose() {
    _connection?.finish();
    super.dispose();
  }

  // ── RGB → CMYK ─────────────────────────────────────────────────────────────
  Map<String, int> _rgbToCmyk(Color color) {
    final r = color.red / 255.0;
    final g = color.green / 255.0;
    final b = color.blue / 255.0;
    final k = 1.0 - [r, g, b].reduce(max);
    if (k == 1.0) return {'c': 0, 'm': 0, 'y': 0, 'k': 100};
    return {
      'c': ((1.0 - r - k) / (1.0 - k) * 100).round(),
      'm': ((1.0 - g - k) / (1.0 - k) * 100).round(),
      'y': ((1.0 - b - k) / (1.0 - k) * 100).round(),
      'k': (k * 100).round(),
    };
  }

  void _sendCmyk() {
    if (!_isConnected) {
      _snack('블루투스 연결이 필요합니다.', error: true);
      return;
    }
    final cmyk = _rgbToCmyk(_selectedColor);
    final data =
        'C:${cmyk['c']},M:${cmyk['m']},Y:${cmyk['y']},K:${cmyk['k']}\n';
    _connection!.output.add(ascii.encode(data));
    _connection!.output.allSent.then((_) => _snack('전송 완료: $data'));
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: error ? AppColors.red : AppColors.navy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.yellow, width: 2),
        ),
      ),
    );
  }

  Paint get _currentPaint => Paint()
    ..color = _isEraser ? Colors.white : _selectedColor
    ..isAntiAlias = true
    ..strokeWidth = _strokeWidth
    ..strokeCap = StrokeCap.round;

  // [수정] undo 로직 수정 — 끝의 null 구분자를 먼저 제거한 뒤 포인트 제거
  void _undo() {
    if (_points.isEmpty) return;
    setState(() {
      // 마지막 null(세그먼트 구분자) 먼저 제거
      if (_points.last == null) _points.removeLast();
      // 해당 세그먼트의 포인트를 모두 제거
      while (_points.isNotEmpty && _points.last != null) {
        _points.removeLast();
      }
    });
  }

  // ── 캔버스 저장 (갤러리에 PNG로 저장) ─────────────────────────────────────
  Future<void> _saveCanvas() async {
    try {
      final boundary =
          _canvasKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        _snack('캔버스를 찾을 수 없습니다.', error: true);
        return;
      }
      final image = await boundary.toImage(
        pixelRatio: AppConfig.exportPixelRatio,
      );
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      if (byteData == null) {
        _snack('이미지 변환 실패', error: true);
        return;
      }

      final bytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final fileName = 'pilink_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      await Gal.putImage(file.path, album: AppConfig.exportAlbum);
      if (mounted) _snack('갤러리에 저장 완료 ✓');
    } catch (e) {
      if (mounted) _snack('저장 실패: $e', error: true);
    }
  }

  // ── 색상 피커 다이얼로그 ────────────────────────────────────────────────────
  void _showColorPicker() {
    Color temp = _selectedColor;
    final rCtrl = TextEditingController(text: temp.red.toString());
    final gCtrl = TextEditingController(text: temp.green.toString());
    final bCtrl = TextEditingController(text: temp.blue.toString());

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialog) {
          void fromText() {
            final r = (int.tryParse(rCtrl.text) ?? 0).clamp(0, 255);
            final g = (int.tryParse(gCtrl.text) ?? 0).clamp(0, 255);
            final b = (int.tryParse(bCtrl.text) ?? 0).clamp(0, 255);
            setDialog(() => temp = Color.fromRGBO(r, g, b, 1.0));
          }

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const DialogHeader('색상 선택 및 RGB 입력'),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ColorPicker(
                          pickerColor: temp,
                          onColorChanged: (c) => setDialog(() {
                            temp = c;
                            rCtrl.text = c.red.toString();
                            gCtrl.text = c.green.toString();
                            bCtrl.text = c.blue.toString();
                          }),
                          pickerAreaHeightPercent: 0.7,
                          enableAlpha: false,
                          displayThumbColor: true,
                          paletteType: PaletteType.hueWheel,
                          labelTypes: const [],
                        ),
                        const Divider(height: 24, thickness: 2),
                        const Text(
                          'RGB 값 직접 입력 (0 ~ 255)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _rgbField('R', rCtrl, AppColors.red, fromText),
                            const SizedBox(width: 8),
                            _rgbField('G', gCtrl, AppColors.green, fromText),
                            const SizedBox(width: 8),
                            _rgbField('B', bCtrl, AppColors.blue, fromText),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            '취소',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.navy,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedColor = temp;
                              _isEraser = false;
                            });
                            Navigator.pop(ctx);
                          },
                          child: const Text(
                            '적용하기',
                            style: TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _rgbField(
    String label,
    TextEditingController ctrl,
    Color labelColor,
    VoidCallback onChange,
  ) {
    return Expanded(
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        onChanged: (_) => onChange(),
        style: const TextStyle(fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: labelColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: labelColor, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 10,
          ),
        ),
      ),
    );
  }

  void _showServerDialog() {
    final ctrl = TextEditingController(text: _serverUrl);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DialogHeader('서버 URL 설정'),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: ctrl,
                decoration: InputDecoration(
                  hintText: 'http://192.168.x.x:8080',
                  prefixIcon: const Icon(Icons.link, color: AppColors.navy),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppColors.navy,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        '취소',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        setState(() => AppConfig.serverUrl = ctrl.text);
                        Navigator.pop(ctx);
                      },
                      child: const Text(
                        '저장',
                        style: TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            if (_showPalette) _buildPaletteStrip(),
            _buildCanvas(),
            _buildBottomTabs(),
          ],
        ),
      ),
    );
  }

  // ── 통합 TopBar (네이비 한 줄) ─────────────────────────────────────────────
  // 🍔  RGB DISPENSER  |  ←→  저장하기  펜 지우개 사진  [Color|추출하기]  BT
  Widget _buildTopBar() => Container(
    color: AppColors.navy,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    child: Row(
      children: [
        // 햄버거
        Builder(
          builder: (ctx) => GestureDetector(
            onTap: () => Scaffold.of(ctx).openDrawer(),
            child: const Icon(Icons.menu, color: AppColors.white, size: 22),
          ),
        ),
        const SizedBox(width: 8),
        // 구분선
        Container(
          width: 1,
          height: 20,
          color: Colors.white24,
          margin: const EdgeInsets.symmetric(horizontal: 8),
        ),
        // ← →
        _tbIcon(
          Icons.arrow_back_ios_new,
          size: 14,
          color: Colors.white70,
          onTap: _undo,
        ),
        _tbIcon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Colors.white70,
          onTap: () {},
        ),
        _tbDividerW(),
        // 저장하기
        GestureDetector(
          onTap: _saveCanvas,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 5),
            child: Text(
              '저장하기',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        _tbDividerW(),
        // 펜 (누르면 팔레트 토글, 활성 시 노란 배경)
        _tbIconActiveW(
          Icons.edit_outlined,
          active: !_isEraser && _showPalette,
          onTap: () => setState(() {
            _isEraser = false;
            _showPalette = !_showPalette;
          }),
        ),
        // 지우개
        _tbIconActiveW(
          Icons.cleaning_services_outlined,
          active: _isEraser,
          onTap: () => setState(() {
            _isEraser = true;
            _showPalette = false;
          }),
        ),
        // 사진
        _tbIcon(
          Icons.image_outlined,
          size: 18,
          color: Colors.white70,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => UploadPage(base: _serverUrl)),
          ),
        ),
        const Spacer(),
        // [Color ○ | 추출하기] 빨간 테두리
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.red, width: 2),
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.circle_outlined,
                size: 13,
                color: AppColors.white,
              ),
              const SizedBox(width: 3),
              const Text(
                'Color',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
              Container(
                width: 1,
                height: 13,
                color: Colors.white24,
                margin: const EdgeInsets.symmetric(horizontal: 5),
              ),
              GestureDetector(
                onTap: _sendCmyk,
                child: const Text(
                  '추출하기',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        // BT 버튼
        GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BluetoothPage()),
            );
            if (result is BluetoothConnection) {
              setState(() => _connection = result);
              // [수정] 새 연결에도 종료 이벤트 구독
              _listenConnectionDone(result);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _isConnected
                  ? AppColors.green.withValues(alpha: 0.25)
                  : Colors.white12,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isConnected ? AppColors.green : Colors.white38,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                  color: _isConnected ? AppColors.green : AppColors.white,
                  size: 15,
                ),
                const SizedBox(width: 3),
                Text(
                  _isConnected ? '연결됨' : 'BT',
                  style: TextStyle(
                    color: _isConnected ? AppColors.green : AppColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  // ── 펜 굵기 슬라이더 + 색상 팔레트 ────────────────────────────────────────
  Widget _buildPaletteStrip() => Container(
    padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
    color: AppColors.white,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 슬라이더 행
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '펜 굵기',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: Slider(
                value: _strokeWidth,
                min: 1.0,
                max: 30.0,
                onChanged: (v) => setState(() => _strokeWidth = v),
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isEraser ? Colors.white : _selectedColor,
                border: Border.all(color: Colors.grey.shade400, width: 1.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // 팔레트 행
        Row(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _palette
                    .map(
                      (c) => PaletteColor(
                        color: c,
                        isSelected: _selectedColor == c && !_isEraser,
                        onTap: () => setState(() {
                          _selectedColor = c;
                          _isEraser = false;
                        }),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(width: 6),
            RainbowColorButton(onTap: _showColorPicker),
          ],
        ),
      ],
    ),
  );

  // ── 캔버스 ─────────────────────────────────────────────────────────────────
  Widget _buildCanvas() => Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: const Color(0xFFCCCCCC), width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: RepaintBoundary(
          key: _canvasKey,
          child: GestureDetector(
            onPanStart: (d) => setState(
              () => _points.add(
                DrawingPoint(offset: d.localPosition, paint: _currentPaint),
              ),
            ),
            onPanUpdate: (d) => setState(
              () => _points.add(
                DrawingPoint(offset: d.localPosition, paint: _currentPaint),
              ),
            ),
            onPanEnd: (_) => setState(() => _points.add(null)),
            child: CustomPaint(
              painter: DrawingPainter(pointsList: _points),
              size: Size.infinite,
            ),
          ),
        ),
      ),
    ),
  );

  // ── 하단 탭 (6개 or 도메인 썸네일) ─────────────────────────────────────────
  Widget _buildBottomTabs() => Container(
    decoration: const BoxDecoration(
      color: AppColors.white,
      border: Border(top: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
    ),
    child: _isDomainMode ? _buildDomainPanel() : _buildFeatureTabs(),
  );

  Widget _buildFeatureTabs() {
    final tabs = [
      {'icon': Icons.border_outer, 'label': '윤곽선'},
      {'icon': Icons.auto_awesome, 'label': '도메인변화'},
      {'icon': Icons.psychology, 'label': '스마트'},
      {'icon': Icons.crop_free, 'label': '구도'},
      {'icon': Icons.menu_book, 'label': '가이드'},
      {'icon': Icons.palette, 'label': '색상'},
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: tabs.map((t) {
          final label = t['label'] as String;
          final isDomain = label == '도메인변화';
          return GestureDetector(
            onTap: () {
              if (isDomain) {
                setState(() => _isDomainMode = true);
              } else if (label == '색상') {
                _showColorPicker();
              } else if (label == '윤곽선') {
                _sendCmyk();
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  t['icon'] as IconData,
                  size: 22,
                  color: isDomain ? AppColors.navy : Colors.grey.shade600,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: isDomain ? FontWeight.w800 : FontWeight.w500,
                    color: isDomain ? AppColors.navy : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDomainPanel() => Padding(
    padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _isDomainMode = false),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 14,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '도메인변화',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.red, width: 2),
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.all(8),
          child: Row(
            children: List.generate(5, (i) {
              final isSel = _selectedThumb == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedThumb = i),
                  child: Container(
                    margin: EdgeInsets.only(right: i < 4 ? 6 : 0),
                    height: 52,
                    decoration: BoxDecoration(
                      color: isSel
                          ? AppColors.navy.withValues(alpha: 0.08)
                          : AppColors.white,
                      border: Border.all(
                        color: isSel ? AppColors.navy : Colors.grey.shade400,
                        width: isSel ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    ),
  );

  // ── Drawer ─────────────────────────────────────────────────────────────────
  Widget _buildDrawer() => Drawer(
    child: Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 48, 16, 20),
          color: AppColors.navy,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.yellow,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'PiLink',
                  style: TextStyle(
                    color: AppColors.border,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'RGB DISPENSER',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        DrawerNavItem(
          number: '01',
          icon: Icons.settings,
          title: '서버 URL 설정',
          subtitle: _serverUrl,
          onTap: () {
            Navigator.pop(context);
            _showServerDialog();
          },
        ),
      ],
    ),
  );

  // ── 툴바 헬퍼 위젯들 ──────────────────────────────────────────────────────
  // 아이콘 버튼 (color 파라미터로 네이비/흰색 모두 대응)
  Widget _tbIcon(
    IconData icon, {
    double size = 18,
    Color? color,
    VoidCallback? onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      child: Icon(icon, size: size, color: color ?? Colors.grey.shade600),
    ),
  );

  // 네이비 배경용: 활성 시 노란 배경 + 어두운 아이콘
  Widget _tbIconActiveW(
    IconData icon, {
    required bool active,
    VoidCallback? onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: active ? AppColors.yellow : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        icon,
        size: 18,
        color: active ? AppColors.border : Colors.white70,
      ),
    ),
  );

  // 네이비 배경용 구분선
  Widget _tbDividerW() => Container(
    width: 1,
    height: 18,
    margin: const EdgeInsets.symmetric(horizontal: 4),
    color: Colors.white24,
  );
}
