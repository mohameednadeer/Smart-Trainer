import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_trainer/core/providers.dart';
import 'package:smart_trainer/theme/app_colors.dart';
import 'package:smart_trainer/theme/theme_ext.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 32),
              _buildStatCardsRow(context, ref),
              const SizedBox(height: 32),
              _buildStartWorkoutButton(context),
              const SizedBox(height: 32),
              _buildTodaysSummary(context),
              const SizedBox(height: 32),
              _buildRecentWorkouts(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.zap, color: AppColors.neonGreen, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'WELCOME BACK',
                    style: TextStyle(
                      color: AppColors.neonGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Ready to crush it? 💪',
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            InkWell(
              onTap: () => context.push('/profile'),
              borderRadius: BorderRadius.circular(24),
              child: _buildIconButton(context, LucideIcons.user),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: () => context.push('/settings'),
              borderRadius: BorderRadius.circular(24),
              child: _buildIconButton(context, LucideIcons.settings),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildIconButton(BuildContext context, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        shape: BoxShape.circle,
        border: Border.all(color: context.glassBorderColor),
      ),
      padding: const EdgeInsets.all(12),
      child: Icon(icon, color: AppColors.electricBlue, size: 20),
    );
  }

  Widget _buildStatCardsRow(BuildContext context, WidgetRef ref) {
    final steps = ref.watch(stepsProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatCard(context,
            icon: LucideIcons.heart,
            iconColor: AppColors.biometricRed,
            value: '72',
            label: 'BPM',
          ),
          const SizedBox(width: 12),
          _buildStatCard(context,
            icon: LucideIcons.flame,
            iconColor: Colors.orangeAccent,
            value: '245',
            label: 'Calories',
          ),
          const SizedBox(width: 12),
          _buildStatCard(context,
            icon: LucideIcons.target,
            iconColor: AppColors.electricBlue,
            value: '3/5',
            label: 'Week Goal',
          ),
          const SizedBox(width: 12),
          _buildStatCard(context,
            icon: LucideIcons.footprints,
            iconColor: AppColors.neonGreen,
            value: steps >= 1000
                ? '${(steps / 1000).toStringAsFixed(1)}k'
                : '$steps',
            label: 'Steps Today',
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.glassBorderColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: context.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: context.secondaryTextColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartWorkoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.electricBlue,
            AppColors.electricBlue.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.electricBlue.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.push('/training');
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Start Workout',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Icon(LucideIcons.zap, color: context.textColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodaysSummary(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.calendar, color: AppColors.electricBlue, size: 20),
            const SizedBox(width: 8),
            Text(
              "Today's Summary",
              style: TextStyle(
                color: context.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.glassBorderColor),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.electricBlue.withOpacity(0.5)),
                      color: AppColors.electricBlue.withOpacity(0.1),
                    ),
                    child: const Icon(LucideIcons.activity, color: AppColors.electricBlue, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Active Time', style: TextStyle(color: context.secondaryTextColor, fontSize: 13)),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('0', style: TextStyle(color: context.textColor, fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text('min', style: TextStyle(color: context.textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Accuracy', style: TextStyle(color: context.secondaryTextColor, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                        '0%',
                        style: TextStyle(
                          color: AppColors.electricBlue,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: context.glassBorderColor),
              const SizedBox(height: 16),
              Text(
                "No workouts today yet. Let's get started! 🚀",
                style: TextStyle(
                  color: context.secondaryTextColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentWorkouts(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.trendingUp, color: AppColors.neonGreen, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Recent Workouts",
                  style: TextStyle(
                    color: context.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {},
              child: Text('View all', style: TextStyle(color: AppColors.electricBlue)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildWorkoutListItem(context, 'Squats', '2 days ago', '92%', '12 min'),
        const SizedBox(height: 12),
        _buildWorkoutListItem(context, 'Push-ups', '3 days ago', '88%', '8 min'),
        const SizedBox(height: 12),
        _buildWorkoutListItem(context, 'Lunges', '4 days ago', '95%', '15 min'),
      ],
    );
  }

  Widget _buildWorkoutListItem(BuildContext context, String title, String subtitle, String accuracy, String duration) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.glassBorderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.electricBlue.withOpacity(0.3)),
            ),
            child: const Icon(LucideIcons.activity, color: AppColors.electricBlue, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: context.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: context.secondaryTextColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.neonGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.neonGreen.withOpacity(0.3)),
                ),
                child: Text(
                  accuracy,
                  style: TextStyle(
                    color: AppColors.neonGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                duration,
                style: TextStyle(
                  color: context.secondaryTextColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
