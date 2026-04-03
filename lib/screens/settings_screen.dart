import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_trainer/theme/app_colors.dart';
import 'package:smart_trainer/core/providers.dart';
import 'package:smart_trainer/services/auth_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool workoutReminders = true;
  String _selectedLanguage = 'English';

  static const _languages = [
    {'label': 'English', 'flag': '🇬🇧'},
    {'label': 'العربية', 'flag': '🇸🇦'},
  ];

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Language',
                  style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ..._languages.map((lang) {
                final isSelected = _selectedLanguage == lang['label'];
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() => _selectedLanguage = lang['label']!);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.electricBlue.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.electricBlue
                            : glassBorderColor,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 16),
                        Text(lang['label']!,
                            style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                        const Spacer(),
                        if (isSelected)
                          const Icon(Icons.check_circle,
                              color: AppColors.electricBlue, size: 22),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  bool get isLight => ref.watch(themeProvider) == ThemeMode.light;
  Color get bgColor => isLight ? const Color(0xFFF5F7FA) : AppColors.background;
  Color get surfaceColor => isLight ? Colors.white : AppColors.surface;
  Color get textColor => isLight ? Colors.black87 : Colors.white;
  Color get secondaryTextColor => isLight ? Colors.black54 : AppColors.textSecondary;
  Color get glassBorderColor => isLight ? Colors.grey.withOpacity(0.2) : AppColors.glassBorder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 32),
              
              _buildSectionHeader('APPEARANCE'),
              _buildCard(
                child: _buildSwitchTile(
                  title: 'Dark Mode',
                  icon: LucideIcons.moon,
                  iconColor: AppColors.electricBlue,
                  value: !isLight,
                  onChanged: (val) {
                    ref.read(themeProvider.notifier).state = val ? ThemeMode.dark : ThemeMode.light;
                  },
                ),
              ),
              
              _buildSectionHeader('DEVICE'),
              _buildCard(
                child: _buildNavigationTile(
                  title: 'Connect Bluetooth Sensor',
                  subtitle: 'MAX30102 Heart Rate Monitor',
                  icon: LucideIcons.bluetooth,
                  iconColor: AppColors.neonGreen,
                  onTap: () {},
                ),
              ),
              
              _buildSectionHeader('NOTIFICATIONS'),
              _buildCard(
                child: _buildSwitchTile(
                  title: 'Workout Reminders',
                  icon: LucideIcons.bell,
                  iconColor: Colors.orangeAccent,
                  value: workoutReminders,
                  onChanged: (val) => setState(() => workoutReminders = val),
                  showBorder: false,
                ),
              ),
              
              _buildSectionHeader('GENERAL'),
              _buildCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildNavigationTile(
                      title: 'Language',
                      subtitle: _selectedLanguage,
                      icon: LucideIcons.globe,
                      iconColor: AppColors.electricBlue,
                      onTap: _showLanguagePicker,
                      showBorder: true,
                    ),
                    _buildNavigationTile(
                      title: 'Privacy & Security',
                      icon: LucideIcons.shield,
                      iconColor: AppColors.electricBlue,
                      onTap: () => context.push('/privacy'),
                      showBorder: true,
                    ),
                    _buildNavigationTile(
                      title: 'Help & Support',
                      icon: LucideIcons.helpCircle,
                      iconColor: AppColors.electricBlue,
                      onTap: () => context.push('/help-support'),
                      showBorder: false,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              _buildAppInfo(),
              const SizedBox(height: 24),
              _buildSignOutButton(context),
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
            color: surfaceColor,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(LucideIcons.arrowLeft, color: AppColors.electricBlue, size: 24),
            onPressed: () => context.pop(),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          'Settings',
          style: TextStyle(
            color: textColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        title,
        style: TextStyle(
          color: secondaryTextColor.withOpacity(0.5),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
      padding: padding ?? const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: glassBorderColor),
      ),
      child: child,
    );
  }

  Widget _buildIconContainer(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool showBorder = false,
  }) {
    return Column(
      children: [
        Row(
          children: [
            _buildIconContainer(icon, iconColor),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: AppColors.electricBlue,
              inactiveThumbColor: AppColors.textSecondary,
              inactiveTrackColor: surfaceColor,
            ),
          ],
        ),
        if (showBorder) ...[
          const SizedBox(height: 16),
          Divider(color: glassBorderColor, height: 1),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildNavigationTile({
    required String title,
    String? subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    bool showBorder = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                _buildIconContainer(icon, iconColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(LucideIcons.chevronRight, color: secondaryTextColor.withOpacity(0.5), size: 20),
              ],
            ),
            if (showBorder) ...[
              const SizedBox(height: 16),
              Divider(color: glassBorderColor, height: 1),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: surfaceColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: glassBorderColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.zap, color: AppColors.electricBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Smart Trainer',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Version 1.0.0',
            style: TextStyle(color: secondaryTextColor, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'AI Fitness Assistant with MediaPipe & MoveNet',
            style: TextStyle(color: secondaryTextColor.withOpacity(0.5), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return InkWell(
      onTap: () async {
        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Sign Out?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: const Text('Are you sure you want to sign out of your account?', style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel', style: TextStyle(color: AppColors.electricBlue)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.biometricRed,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );

        if (shouldLogout == true) {
          await AuthService().signOut();
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.biometricRed.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.biometricRed.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.logOut, color: AppColors.biometricRed.withOpacity(0.8), size: 20),
            const SizedBox(width: 12),
            Text(
              'Sign Out',
              style: TextStyle(
                color: AppColors.biometricRed.withOpacity(0.8),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
