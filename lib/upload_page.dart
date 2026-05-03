import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'app_theme.dart';
import 'drawing_widgets.dart';

// 작업 화면
// 상단: ←→  저장하기  펜 지우개 사진  [Color ○  추출하기](빨간테두리)  BT
// 중앙: 큰 캔버스
// 하단: 운동 / AI내보내기 / 스파크 / 꽃 / 격자 / 책 / 색상(팔레트)

class UploadPage extends StatefulWidget {
  final String base;
  final String uploadPath;

  const UploadPage({
    super.key,
    required this.base,
    this.uploadPath = '/api/upload',
  });

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  String _status = '대기 중';
  bool _isLoading = false;
  bool _isDomainMode = false; // false=일반탭  true=도메인 썸네일
  int _selectedThumb = 0;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndUpload(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;
      setState(() {
        _status = '업로드 중...';
        _isLoading = true;
      });

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(widget.base + widget.uploadPath),
      );
      request.files.add(await http.MultipartFile.fromPath('file', image.path));

      final response = await request.send();
      final body = await response.stream.bytesToString();
      setState(() {
        _status = response.statusCode == 200 ? '업로드 성공 ✓' : '실패: $body';
        _isLoading = false;
      });
      if (mounted) _snack(_status, error: response.statusCode != 200);
    } catch (e) {
      setState(() {
        _status = '오류: $e';
        _isLoading = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const BrandTitle(),
      ),
      body: Column(
        children: [
          _buildToolbar(),
          _buildCanvas(),
          _isDomainMode ? _buildDomainPanel() : _buildBottomTabs(),
        ],
      ),
    );
  }

  // ── 상단 툴바 ──────────────────────────────────────────────────────────────
  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFDDDDDD), width: 1)),
      ),
      child: Row(
        children: [
          _iconBtn(Icons.arrow_back_ios_new, size: 16),
          const SizedBox(width: 2),
          _iconBtn(Icons.arrow_forward_ios, size: 16),
          _vDivider(),
          _textBtn('저장하기'),
          _vDivider(),
          _iconBtn(Icons.edit_outlined, size: 18),
          _iconBtn(Icons.cleaning_services_outlined, size: 18),
          _iconBtn(Icons.image_outlined, size: 18),
          const Spacer(),
          // 빨간 테두리 묶음: Color ○  추출하기
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.red, width: 2),
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.circle_outlined,
                  size: 16,
                  color: AppColors.border,
                ),
                const SizedBox(width: 3),
                const Text(
                  'Color',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.border,
                  ),
                ),
                Container(
                  width: 1,
                  height: 16,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  color: Colors.grey.shade300,
                ),
                GestureDetector(
                  onTap: () => _pickAndUpload(ImageSource.gallery),
                  child: const Text(
                    '추출하기',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.border,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _iconBtn(Icons.bluetooth, size: 18),
        ],
      ),
    );
  }

  // ── 큰 캔버스 ──────────────────────────────────────────────────────────────
  Widget _buildCanvas() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: const Color(0xFFCCCCCC), width: 1.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.navy),
              )
            : Center(
                child: Text(
                  _status,
                  style: TextStyle(
                    color: _status.contains('성공')
                        ? AppColors.green
                        : _status == '대기 중'
                        ? Colors.grey.shade300
                        : AppColors.red,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
      ),
    );
  }

  // ── 하단 탭 6개 ────────────────────────────────────────────────────────────
  Widget _buildBottomTabs() {
    final tabs = [
      {'icon': Icons.border_outer, 'label': '윤곽선'},
      {'icon': Icons.auto_awesome, 'label': '도메인변화'},
      {'icon': Icons.psychology, 'label': '스마트'},
      {'icon': Icons.crop_free, 'label': '구도'},
      {'icon': Icons.menu_book, 'label': '가이드'},
      {'icon': Icons.palette, 'label': '색상'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: Color(0xFFDDDDDD), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: tabs.map((t) {
          final label = t['label'] as String;
          final isDomain = label == '도메인변화';
          return _tabItem(
            icon: t['icon'] as IconData,
            label: label,
            highlight: label == '색상' || isDomain,
            active: isDomain && _isDomainMode,
            onTap: isDomain
                ? () => setState(() => _isDomainMode = true)
                : label == '색상'
                ? () => _pickAndUpload(ImageSource.gallery)
                : label == '윤곽선'
                ? () => _pickAndUpload(ImageSource.camera)
                : null,
          );
        }).toList(),
      ),
    );
  }

  // ── 도메인 패널 (썸네일 5개 + 뒤로가기) ──────────────────────────────────
  Widget _buildDomainPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: Color(0xFFDDDDDD), width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상단: 탭바 (도메인변화 활성 표시) + 닫기
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
          // 썸네일 5개 (빨간 테두리로 묶음)
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
                      height: 56,
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
  }

  Widget _iconBtn(IconData icon, {double size = 20}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 5),
    child: Icon(icon, size: size, color: Colors.grey.shade600),
  );

  Widget _textBtn(String label) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey.shade700,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  Widget _vDivider() => Container(
    width: 1,
    height: 18,
    margin: const EdgeInsets.symmetric(horizontal: 4),
    color: Colors.grey.shade300,
  );

  Widget _tabItem({
    required IconData icon,
    required String label,
    bool highlight = false,
    bool active = false,
    VoidCallback? onTap,
  }) {
    final color = active
        ? AppColors.navy
        : highlight
        ? AppColors.navy
        : Colors.grey.shade500;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: active ? FontWeight.w900 : FontWeight.w600,
              color: color,
            ),
          ),
          if (active)
            Container(
              margin: const EdgeInsets.only(top: 3),
              width: 20,
              height: 2,
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
        ],
      ),
    );
  }
}
