import 'dart:ui';
import 'package:flutter/material.dart';

class DrawingPoint {
  final Offset offset;
  final Paint paint;
  DrawingPoint({required this.offset, required this.paint});
}

class DrawingPainter extends CustomPainter {
  final List<DrawingPoint?> pointsList;
  DrawingPainter({required this.pointsList});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < pointsList.length - 1; i++) {
      final cur = pointsList[i];
      final next = pointsList[i + 1];
      if (cur != null && next != null) {
        canvas.drawLine(cur.offset, next.offset, cur.paint);
      } else if (cur != null && next == null) {
        canvas.drawPoints(PointMode.points, [cur.offset], cur.paint);
      }
    }
  }

  // 드로잉 중 실시간 렌더링을 위해 항상 true 반환
  @override
  bool shouldRepaint(DrawingPainter old) => true;
}
