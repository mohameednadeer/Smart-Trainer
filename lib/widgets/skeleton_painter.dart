import 'dart:math';
import 'package:flutter/material.dart';
import 'package:smart_trainer/core/ai/angle_calculator.dart';
import 'package:smart_trainer/core/ai/models/pose_landmark.dart';
import 'package:smart_trainer/core/ai/models/pose_result.dart';
import 'package:smart_trainer/theme/app_colors.dart';

/// Paints the MoveNet skeleton overlay on top of the camera preview.
///
/// Maps normalized [PoseResult] coordinates to the actual canvas size,
/// drawing landmarks as neon-green dots and bone connections as
/// electric-blue lines. Optionally displays angle arcs on key joints.
class SkeletonPainter extends CustomPainter {
  final PoseResult poseResult;
  final Size imageSize;
  final bool showAngles;

  SkeletonPainter({
    required this.poseResult,
    required this.imageSize,
    this.showAngles = true,
  });

  // MoveNet 17-keypoint bone connections (index pairs).
  static const List<List<int>> _connections = [
    [0, 1], [0, 2], [1, 3], [2, 4], // head
    [5, 6], // shoulders
    [5, 7], [7, 9], // left arm
    [6, 8], [8, 10], // right arm
    [5, 11], [6, 12], // torso
    [11, 12], // hips
    [11, 13], [13, 15], // left leg
    [12, 14], [14, 16], // right leg
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (poseResult.isEmpty) return;

    final landmarks = poseResult.landmarks;

    final bonePaint = Paint()
      ..color = AppColors.electricBlue.withValues(alpha: 0.7)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final jointPaint = Paint()
      ..color = AppColors.neonGreen
      ..style = PaintingStyle.fill;

    final jointOutlinePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final lowConfPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Map normalized coords to canvas
    Offset toCanvas(PoseLandmark lm) {
      // MoveNet coordinates are normalized [0, 1].
      // We mirror X for front-camera selfie view.
      return Offset(
        (1.0 - lm.x) * size.width,
        lm.y * size.height,
      );
    }

    // ── Draw bones ──
    for (final conn in _connections) {
      final a = landmarks[conn[0]];
      final b = landmarks[conn[1]];

      final paint = (a.isVisible && b.isVisible) ? bonePaint : lowConfPaint;
      canvas.drawLine(toCanvas(a), toCanvas(b), paint);
    }

    // ── Draw joints ──
    for (final lm in landmarks) {
      final pos = toCanvas(lm);
      final radius = lm.isVisible ? 6.0 : 3.0;

      if (lm.isVisible) {
        canvas.drawCircle(pos, radius, jointPaint);
        canvas.drawCircle(pos, radius, jointOutlinePaint);
      } else {
        canvas.drawCircle(
          pos,
          radius,
          Paint()..color = Colors.white.withValues(alpha: 0.3),
        );
      }
    }

    // ── Draw angle arcs on key joints ──
    if (showAngles) {
      _drawAngleArc(canvas, size, poseResult.leftHip, poseResult.leftKnee,
          poseResult.leftAnkle, toCanvas);
      _drawAngleArc(canvas, size, poseResult.rightHip, poseResult.rightKnee,
          poseResult.rightAnkle, toCanvas);
      _drawAngleArc(canvas, size, poseResult.leftShoulder,
          poseResult.leftElbow, poseResult.leftWrist, toCanvas);
      _drawAngleArc(canvas, size, poseResult.rightShoulder,
          poseResult.rightElbow, poseResult.rightWrist, toCanvas);
    }
  }

  void _drawAngleArc(
    Canvas canvas,
    Size size,
    PoseLandmark? a,
    PoseLandmark? b,
    PoseLandmark? c,
    Offset Function(PoseLandmark) toCanvas,
  ) {
    final angle = AngleCalculator.calculateAngle(a, b, c);
    if (angle == null || b == null) return;

    final center = toCanvas(b);
    final arcRadius = 20.0;

    // Determine color from angle quality
    final Color arcColor;
    if (angle >= 70 && angle <= 160) {
      arcColor = AppColors.neonGreen.withValues(alpha: 0.6);
    } else {
      arcColor = AppColors.biometricRed.withValues(alpha: 0.6);
    }

    final arcPaint = Paint()
      ..color = arcColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final sweepAngle = angle * pi / 180;
    final startAngle = atan2(
      toCanvas(a!).dy - center.dy,
      toCanvas(a).dx - center.dx,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: arcRadius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );

    // Draw angle text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${angle.round()}°',
        style: TextStyle(
          color: arcColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      center + const Offset(22, -6),
    );
  }

  @override
  bool shouldRepaint(covariant SkeletonPainter oldDelegate) {
    return oldDelegate.poseResult.timestamp != poseResult.timestamp;
  }
}
