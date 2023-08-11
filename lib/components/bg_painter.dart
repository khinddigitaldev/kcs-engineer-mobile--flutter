import 'package:flutter/material.dart';
import 'package:kcs_engineer/themes/app_colors.dart';

class BgPainter extends CustomPainter {
  final bool hasAppBar;

  BgPainter({this.hasAppBar = false});

  @override
  void paint(Canvas canvas, Size size) {
    final height = size.height;
    final width = size.width;
    Paint paint = Paint();

    // Path mainBg = Path();
    // mainBg.addRect(Rect.fromLTRB(0, 0, width, size.height));
    // paint.color = Colors.white;
    // canvas.drawPath(mainBg, paint);

    Path rectPath = Path();
    rectPath.addRect(Rect.fromLTRB(0, height, width, height / 2));
    paint.color = AppColors.primary;
    canvas.drawPath(rectPath, paint);

    paint.color = Colors.white;
    Path path = Path();
    path.moveTo(0, height / 2);
    path.quadraticBezierTo(width / 2, height * 0.6, width, height * 0.5);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}
