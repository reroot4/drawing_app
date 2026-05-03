import 'package:flutter/material.dart';
import 'app_theme.dart';

/// AppBar 노란 배지 타이틀
class BrandTitle extends StatelessWidget {
  const BrandTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.yellow,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'RGB',
            style: TextStyle(
              color: AppColors.border,
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'DISPENSER',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

/// PPT 스타일 다이얼로그 헤더 (양쪽 흰 점 + 네이비 배경)
class DialogHeader extends StatelessWidget {
  final String title;
  const DialogHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: Row(
        children: [
          _dot(),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          _dot(),
        ],
      ),
    );
  }

  Widget _dot() => Container(
    width: 8,
    height: 8,
    decoration: const BoxDecoration(
      color: AppColors.white,
      shape: BoxShape.circle,
    ),
  );
}

/// 번호 배지 + 제목 + 부제목을 가진 Drawer 항목
class DrawerNavItem extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const DrawerNavItem({
    super.key,
    required this.number,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bgLight,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                number,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.border,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.navy, size: 20),
          ],
        ),
      ),
    );
  }
}

/// 툴바 아이콘 버튼 (활성/비활성 스타일)
class ToolButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final String? label;
  final Color? activeColor;

  const ToolButton({
    super.key,
    required this.icon,
    required this.active,
    required this.onTap,
    this.label,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? AppColors.navy;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? color : Colors.grey.shade400,
            width: active ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: active ? AppColors.white : Colors.grey.shade600,
              size: 22,
            ),
            if (label != null) ...[
              const SizedBox(height: 2),
              Text(
                label!,
                style: TextStyle(
                  fontSize: 10,
                  color: active ? AppColors.white : Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 팔레트 색상 원형 버튼
class PaletteColor extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const PaletteColor({
    super.key,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: isSelected ? 38 : 30,
        height: isSelected ? 38 : 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.yellow : AppColors.border,
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
      ),
    );
  }
}

/// 레인보우 커스텀 색상 버튼
class RainbowColorButton extends StatelessWidget {
  final VoidCallback onTap;
  const RainbowColorButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          gradient: const SweepGradient(
            colors: [
              Colors.red,
              Colors.orange,
              Colors.yellow,
              Colors.green,
              Colors.blue,
              Colors.purple,
              Colors.red,
            ],
          ),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border, width: 2),
        ),
        child: const Icon(Icons.colorize, color: Colors.white, size: 18),
      ),
    );
  }
}
