import 'package:flutter/material.dart';
import 'package:smart_trainer/core/ai/models/exercise_feedback.dart';
import 'package:smart_trainer/theme/app_colors.dart';

/// Animated banner that displays real-time posture feedback.
///
/// Color-coded: green for correct form, red for incorrect,
/// blue for neutral/idle messages.
class PoseFeedbackOverlay extends StatelessWidget {
  final ExerciseFeedback feedback;

  const PoseFeedbackOverlay({super.key, required this.feedback});

  @override
  Widget build(BuildContext context) {
    final Color borderColor;
    final Color glowColor;
    final IconData icon;

    if (feedback.phase == 'idle') {
      borderColor = AppColors.electricBlue.withValues(alpha: 0.5);
      glowColor = AppColors.electricBlue.withValues(alpha: 0.15);
      icon = Icons.info_outline;
    } else if (feedback.isCorrect) {
      borderColor = AppColors.neonGreen.withValues(alpha: 0.6);
      glowColor = AppColors.neonGreen.withValues(alpha: 0.15);
      icon = Icons.check_circle_outline;
    } else {
      borderColor = AppColors.biometricRed.withValues(alpha: 0.6);
      glowColor = AppColors.biometricRed.withValues(alpha: 0.15);
      icon = Icons.warning_amber_rounded;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: Container(
        key: ValueKey(feedback.message),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: glowColor,
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: borderColor, size: 22),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                feedback.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
