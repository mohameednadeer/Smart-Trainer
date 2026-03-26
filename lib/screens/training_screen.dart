import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_trainer/core/ai/models/exercise_feedback.dart';
import 'package:smart_trainer/core/providers.dart';
import 'package:smart_trainer/theme/app_colors.dart';
import 'package:smart_trainer/theme/theme_ext.dart';

class TrainingScreen extends ConsumerStatefulWidget {
  const TrainingScreen({super.key});

  @override
  ConsumerState<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends ConsumerState<TrainingScreen> {
  bool _isRequestingPermission = false;

  Future<void> _handleStartWorkout() async {
    if (_isRequestingPermission) return;

    setState(() => _isRequestingPermission = true);

    try {
      final status = await Permission.camera.request();

      if (!mounted) return;

      if (status.isGranted) {
        context.go('/active_workout');
      } else if (status.isPermanentlyDenied) {
        _showPermissionDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: context.surfaceColor,
            content: Text(
              'Camera permission is required for pose detection',
              style: TextStyle(color: context.textColor),
            ),
            action: SnackBarAction(
              label: 'Settings',
              textColor: AppColors.electricBlue,
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRequestingPermission = false);
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.electricBlue.withValues(alpha: 0.3)),
        ),
        title: Text(
          'Camera Access Required',
          style: TextStyle(color: context.textColor),
        ),
        content: Text(
          'Smart Trainer needs camera access to analyze your exercise posture in real-time. Please enable it in your device settings.',
          style: TextStyle(color: context.secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: context.secondaryTextColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Open Settings',
                style: TextStyle(color: AppColors.electricBlue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedExercise = ref.watch(selectedExerciseProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Background Grid
          CustomPaint(
            size: Size.infinite,
            painter: GridPainter(),
          ),

          // 2. Corner Brackets Layer
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: CustomPaint(
                painter: CornerBracketsPainter(
                  color: AppColors.electricBlue,
                  length: 32.0,
                  strokeWidth: 2.0,
                ),
                child: Container(),
              ),
            ),
          ),

          // 3. UI Overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Close Button
                      Container(
                        margin: const EdgeInsets.only(top: 4, left: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(LucideIcons.x,
                              color: Colors.white, size: 24),
                          onPressed: () => context.pop(),
                        ),
                      ),

                      // Heart Rate Indicator
                      Container(
                        margin: const EdgeInsets.only(top: 4, right: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color:
                                AppColors.biometricRed.withValues(alpha: 0.5),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.biometricRed
                                  .withValues(alpha: 0.3),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.heart,
                                color: AppColors.biometricRed, size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              '66 BPM',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Center Content
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                AppColors.electricBlue.withValues(alpha: 0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.electricBlue
                                  .withValues(alpha: 0.1),
                              blurRadius: 32,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                AppColors.electricBlue.withValues(alpha: 0.05),
                          ),
                          child: const Icon(
                            LucideIcons.camera,
                            color: AppColors.electricBlue,
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Camera activates when you start',
                        style: TextStyle(
                          color: context.secondaryTextColor,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),

                  // Bottom Content
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Record Button
                      GestureDetector(
                        onTap: _handleStartWorkout,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isRequestingPermission
                                ? AppColors.electricBlue.withValues(alpha: 0.3)
                                : AppColors.electricBlue
                                    .withValues(alpha: 0.15),
                            border: Border.all(
                              color: AppColors.electricBlue
                                  .withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.electricBlue,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.electricBlue
                                      .withValues(alpha: 0.5),
                                  blurRadius: 16,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: _isRequestingPermission
                                ? const SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: Padding(
                                      padding: EdgeInsets.all(12),
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 48,
                                    height: 48,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Exercise Type Selector
                      _ExerciseToggle(
                        selected: selectedExercise,
                        onChanged: (type) {
                          ref.read(selectedExerciseProvider.notifier).state =
                              type;
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────── Exercise Toggle Pill ───────────────────

class _ExerciseToggle extends StatelessWidget {
  final ExerciseType selected;
  final ValueChanged<ExerciseType> onChanged;

  const _ExerciseToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: context.surfaceColor.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: AppColors.electricBlue.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOption(
              context,
              ExerciseType.squat,
              'Squat',
              LucideIcons.activity,
            ),
            _buildOption(
              context,
              ExerciseType.pushUp,
              'Push-up',
              LucideIcons.zap,
            ),
            _buildOption(
              context,
              ExerciseType.bicepCurl,
              'Bicep Curl',
              LucideIcons.dumbbell,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, ExerciseType type, String label, IconData icon) {
    final isSelected = selected == type;

    return GestureDetector(
      onTap: () => onChanged(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.electricBlue.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isSelected
                ? AppColors.electricBlue.withValues(alpha: 0.5)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.electricBlue
                  : context.secondaryTextColor,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppColors.electricBlue
                    : context.secondaryTextColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────── Painters (unchanged) ───────────────────

class CornerBracketsPainter extends CustomPainter {
  final Color color;
  final double length;
  final double strokeWidth;

  CornerBracketsPainter({
    required this.color,
    this.length = 24.0,
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawPath(
      Path()
        ..moveTo(0, length)
        ..lineTo(0, 0)
        ..lineTo(length, 0),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width - length, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, length),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - length)
        ..lineTo(0, size.height)
        ..lineTo(length, size.height),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width, size.height - length)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width - length, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
