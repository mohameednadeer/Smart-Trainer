import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_trainer/theme/app_colors.dart';
import 'package:smart_trainer/theme/theme_ext.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildUserInfoCard(context),
              const SizedBox(height: 24),
              _buildStatsRow(context),
              const SizedBox(height: 32),
              _buildSectionTitle(context, LucideIcons.bluetooth, 'Connected Devices', color: AppColors.electricBlue),
              const SizedBox(height: 16),
              _buildConnectedDeviceCard(context),
              const SizedBox(height: 32),
              _buildSectionTitle(context, LucideIcons.trendingUp, 'Progress Chart', color: AppColors.electricBlue),
              const SizedBox(height: 16),
              _buildProgressChart(context),
              const SizedBox(height: 32),
              _buildSectionTitle(context, LucideIcons.award, 'Recent Achievements', color: AppColors.neonGreen),
              const SizedBox(height: 16),
              _buildAchievement(context, 'First Workout', 'Completed your first session', 'Jan 2026', Icons.emoji_events, Colors.orangeAccent),
              const SizedBox(height: 12),
              _buildAchievement(context, '5 Day Streak', 'Workout 5 days in a row', 'Feb 2026', Icons.local_fire_department, Colors.deepOrangeAccent),
              const SizedBox(height: 12),
              _buildAchievement(context, '90% Accuracy', 'Perfect form on squats', 'Feb 2026', Icons.star, Colors.amber),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppColors.electricBlue, size: 24),
            onPressed: () => context.pop(),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          'Profile',
          style: TextStyle(
            color: context.textColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.glassBorderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.electricBlue.withOpacity(0.5), width: 2),
              color: AppColors.electricBlue.withOpacity(0.1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.electricBlue.withOpacity(0.2),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(LucideIcons.user, color: AppColors.electricBlue, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alex Johnson',
                  style: TextStyle(
                    color: context.textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(LucideIcons.mail, color: context.secondaryTextColor, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'alex.johnson@email.com',
                        style: TextStyle(color: context.secondaryTextColor, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(LucideIcons.calendar, color: context.secondaryTextColor, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Joined January 2026',
                        style: TextStyle(color: context.secondaryTextColor, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.electricBlue.withOpacity(0.1),
            ),
            child: const Icon(LucideIcons.edit2, color: AppColors.electricBlue, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: LucideIcons.trendingUp,
            iconColor: AppColors.electricBlue,
            value: '47',
            label: 'Workouts',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: LucideIcons.award,
            iconColor: AppColors.neonGreen,
            value: '89%',
            label: 'Avg Score',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: LucideIcons.flame,
            iconColor: Colors.orangeAccent,
            value: '5',
            label: 'Day Streak',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.glassBorderColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              color: context.textColor,
              fontSize: 24,
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

  Widget _buildSectionTitle(BuildContext context, IconData icon, String title, {required Color color}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: context.textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildConnectedDeviceCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.glassBorderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.neonGreen.withOpacity(0.1),
              border: Border.all(color: AppColors.neonGreen.withOpacity(0.3)),
            ),
            child: const Icon(LucideIcons.bluetooth, color: AppColors.neonGreen, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MAX30102 Heart Rate Sensor',
                  style: TextStyle(
                    color: context.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Connected via Bluetooth',
                  style: TextStyle(color: context.secondaryTextColor, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.neonGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.neonGreen.withOpacity(0.4)),
            ),
            child: Text(
              'Active',
              style: TextStyle(
                color: AppColors.neonGreen,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressChart(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.glassBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Accuracy Trend (6 weeks)',
            style: TextStyle(color: context.secondaryTextColor, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(LucideIcons.zap, color: AppColors.neonGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                '+14% Improvement',
                style: TextStyle(
                  color: AppColors.neonGreen,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(
              painter: ChartPainter(
                gridColor: context.glassBorderColor,
                textColor: context.secondaryTextColor,
                bgColor: context.bgColor,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Divider(color: context.glassBorderColor),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Best Week', style: TextStyle(color: context.secondaryTextColor, fontSize: 13)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('Week 6 — ', style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('89%', style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Workouts', style: TextStyle(color: context.secondaryTextColor, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('27 sessions', style: TextStyle(color: context.textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievement(BuildContext context, String title, String subtitle, String date, IconData icon, Color badgeColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.glassBorderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: badgeColor.withOpacity(0.15),
              border: Border.all(color: badgeColor.withOpacity(0.3)),
            ),
            child: Icon(icon, color: badgeColor, size: 24),
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
                  style: TextStyle(color: context.secondaryTextColor, fontSize: 14),
                ),
              ],
            ),
          ),
          Text(
            date,
            style: TextStyle(color: context.secondaryTextColor.withOpacity(0.5), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class ChartPainter extends CustomPainter {
  final Color gridColor;
  final Color textColor;
  final Color bgColor;

  ChartPainter({
    required this.gridColor,
    required this.textColor,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Defines grid layout
    final paintGrid = Paint()
      ..color = gridColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw horizontal grid lines and Y-axis text
    final numHGrid = 3;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final yLabels = ['70', '77', '84', '95'];

    for (int i = 0; i <= numHGrid; i++) {
      double y = size.height - (i * (size.height / numHGrid));
      
      // Draw dashed line manually for horizontal grid
      for (double j = 40; j < size.width; j += 10) {
        canvas.drawLine(Offset(j, y), Offset(j + 5, y), paintGrid);
      }

      textPainter.text = TextSpan(
        text: yLabels[i],
        style: TextStyle(color: textColor, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(20, y - 6));
    }

    // Draw vertical grid lines and X-axis text
    final numVGrid = 5;
    final xLabels = ['W1', 'W2', 'W3', 'W4', 'W5', 'W6'];
    final dataPoints = [0.1, 0.25, 0.45, 0.55, 0.65, 0.75]; // normalized heights

    final startX = 60.0;
    final stepX = (size.width - startX) / numVGrid;

    final pathColor1 = AppColors.electricBlue;
    final pathColor2 = AppColors.neonGreen;

    final dataOffsets = <Offset>[];

    for (int i = 0; i <= numVGrid; i++) {
      double x = startX + (i * stepX);
      
      // Draw dashed vertical line
      for (double j = 0; j < size.height; j += 10) {
        canvas.drawLine(Offset(x, j), Offset(x, j + 5), paintGrid);
      }

      textPainter.text = TextSpan(
        text: xLabels[i],
        style: TextStyle(color: textColor, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, size.height + 10));

      final yPoint = size.height - (dataPoints[i] * size.height);
      dataOffsets.add(Offset(x, yPoint));
    }

    // Draw chart line
    final path = Path();
    path.moveTo(dataOffsets[0].dx, dataOffsets[0].dy);
    for (int i = 1; i < dataOffsets.length; i++) {
      path.lineTo(dataOffsets[i].dx, dataOffsets[i].dy);
    }

    final lineGradient = LinearGradient(
      colors: [pathColor1, pathColor2],
    ).createShader(Rect.fromPoints(dataOffsets.first, dataOffsets.last));

    final linePaint = Paint()
      ..shader = lineGradient
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, linePaint);

    // Draw data points (dots)
    final dotPaintOuter = Paint()..color = bgColor;
    final dotPaintInner = Paint()..shader = lineGradient;

    for (final offset in dataOffsets) {
      canvas.drawCircle(offset, 6, dotPaintInner);
    }
    
    // Fill color for specific dots (matching gradient manually slightly for dots based on x pos)
    for (int i = 0; i < dataOffsets.length; i++) {
      Color c = Color.lerp(pathColor1, pathColor2, i / (dataOffsets.length - 1))!;
      canvas.drawCircle(dataOffsets[i], 5, Paint()..color = c);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
