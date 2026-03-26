import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_trainer/core/providers.dart';
import 'package:smart_trainer/theme/app_colors.dart';
import 'package:smart_trainer/theme/theme_ext.dart';

class WorkoutResultScreen extends ConsumerWidget {
  const WorkoutResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedback = ref.read(exerciseFeedbackProvider);
    final accuracy = feedback.accuracyScore;
    final repCount = feedback.repCount;
    final accuracyPct = (accuracy * 100).round();

    // Determine label from accuracy
    final String accuracyLabel;
    final Color accuracyColor;
    if (accuracyPct >= 85) {
      accuracyLabel = 'Excellent!';
      accuracyColor = AppColors.neonGreen;
    } else if (accuracyPct >= 65) {
      accuracyLabel = 'Good';
      accuracyColor = Colors.orangeAccent;
    } else {
      accuracyLabel = 'Needs Work';
      accuracyColor = AppColors.biometricRed;
    }

    // Suggestions based on accuracy
    final suggestions = <Map<String, dynamic>>[];
    if (accuracyPct >= 85) {
      suggestions.add({
        'title': 'Great form!',
        'desc': 'Your posture was consistently correct throughout the session.',
        'icon': LucideIcons.checkCircle,
        'color': AppColors.neonGreen,
      });
    } else {
      suggestions.add({
        'title': 'Improve form consistency',
        'desc': 'Focus on maintaining correct posture during each rep.',
        'icon': LucideIcons.trendingUp,
        'color': Colors.orangeAccent,
      });
    }
    if (repCount > 0) {
      suggestions.add({
        'title': 'Rep count: $repCount',
        'desc': repCount >= 10
            ? 'Great session! Try increasing reps next time.'
            : 'Try aiming for 10+ reps next time.',
        'icon': LucideIcons.target,
        'color': AppColors.electricBlue,
      });
    }

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Badge Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.neonGreen.withOpacity(0.1),
                  border: Border.all(
                    color: AppColors.neonGreen.withOpacity(0.3), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neonGreen.withOpacity(0.15),
                      blurRadius: 32, spreadRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(LucideIcons.award,
                    color: AppColors.neonGreen, size: 64),
              ),
              const SizedBox(height: 24),

              Text(
                'Workout Complete! 🎉',
                style: TextStyle(
                  color: context.textColor, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                accuracyPct >= 70 ? 'You crushed it today!' : 'Keep practicing!',
                style: TextStyle(
                  color: accuracyColor, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 48),

              // Accuracy Circular Progress (REAL DATA)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: context.glassBorderColor),
                ),
                child: Column(
                  children: [
                    Text(
                      'Posture Accuracy Score',
                      style: TextStyle(
                          color: context.secondaryTextColor, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 140,
                      width: 140,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: accuracy,
                            strokeWidth: 12,
                            backgroundColor: Colors.white.withOpacity(0.05),
                            valueColor: AlwaysStoppedAnimation<Color>(accuracyColor),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$accuracyPct%',
                                style: TextStyle(
                                  color: AppColors.electricBlue,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                accuracyLabel,
                                style: TextStyle(
                                  color: accuracyColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4 Grid Stats — fixed childAspectRatio to prevent overflow
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.15,
                children: [
                  _buildStatGridItem(context, LucideIcons.clock, 'Duration', '0:45', 'mins', AppColors.electricBlue),
                  _buildStatGridItem(context, LucideIcons.heart, 'Avg BPM', '142', 'bpm', AppColors.biometricRed),
                  _buildStatGridItem(context, LucideIcons.flame, 'Calories', '9', 'kcal', Colors.orangeAccent),
                  _buildStatGridItem(context, LucideIcons.target, 'Reps', '$repCount', 'total', AppColors.neonGreen),
                ],
              ),
              const SizedBox(height: 40),

              // Suggestions
              Row(
                children: [
                  Icon(LucideIcons.trendingUp, color: AppColors.electricBlue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Suggestions for Improvement',
                    style: TextStyle(
                      color: context.textColor, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...suggestions.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildSuggestionItem(
                  context,
                  s['title'] as String,
                  s['desc'] as String,
                  s['icon'] as IconData,
                  s['color'] as Color,
                ),
              )),
              const SizedBox(height: 48),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/training'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricBlue,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.zap, color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      const Text('Try Another Exercise',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      const Icon(LucideIcons.arrowRight, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/dashboard'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.surfaceColor,
                    side: BorderSide(color: context.glassBorderColor),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.home, color: context.secondaryTextColor, size: 20),
                      const SizedBox(width: 12),
                      Text('Back to Dashboard',
                          style: TextStyle(
                              color: context.secondaryTextColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatGridItem(BuildContext context, IconData icon, String title,
      String value, String unit, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.glassBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withOpacity(0.1),
                  border: Border.all(color: iconColor.withOpacity(0.2)),
                ),
                child: Icon(icon, color: iconColor, size: 14),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                      color: context.secondaryTextColor, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
                color: context.textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold),
          ),
          Text(
            unit,
            style: TextStyle(
                color: context.secondaryTextColor.withOpacity(0.5),
                fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(BuildContext context, String title, String desc,
      IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle, color: color.withOpacity(0.15)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: context.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(desc,
                    style: TextStyle(
                        color: context.secondaryTextColor, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
