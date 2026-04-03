import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:smart_trainer/core/providers.dart';
import 'package:smart_trainer/services/auth_service.dart';
import 'package:smart_trainer/theme/app_colors.dart';
import 'package:smart_trainer/theme/theme_ext.dart';
import 'package:smart_trainer/widgets/custom_text_field.dart';
import 'package:smart_trainer/widgets/neon_button.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late String _gender;
  bool _isSaving = false;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider);
    _nameController = TextEditingController(text: user.name);
    _emailController = TextEditingController(text: user.email);
    _phoneController = TextEditingController(text: user.phone);
    _ageController = TextEditingController(text: user.age.toString());
    _weightController = TextEditingController(text: user.weight.toString());
    _heightController = TextEditingController(text: user.height.toString());
    _gender = user.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    
    try {
      final updatedData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 25,
        'weight': double.tryParse(_weightController.text.trim()) ?? 70.0,
        'height': double.tryParse(_heightController.text.trim()) ?? 170.0,
        'gender': _gender,
      };

      // 1. تحديث Firestore
      await _authService.updateUserData(updatedData);

      // 2. تحديث Local State
      ref.read(userProvider.notifier).updateProfile(
        name: updatedData['name'] as String,
        email: updatedData['email'] as String,
        phone: updatedData['phone'] as String,
        age: updatedData['age'] as int,
        weight: updatedData['weight'] as double,
        height: updatedData['height'] as double,
        gender: updatedData['gender'] as String,
      );

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating profile: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.electricBlue),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: context.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Picture
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.electricBlue, width: 2),
                      color: AppColors.electricBlue.withAlpha(25),
                    ),
                    child: const Icon(LucideIcons.user, color: AppColors.electricBlue, size: 60),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppColors.electricBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.camera, color: Colors.white, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // Form Fields
              CustomTextField(
                label: 'FULL NAME',
                hint: 'Enter your name',
                prefixIcon: LucideIcons.user,
                controller: _nameController,
              ),
              const SizedBox(height: 24),
              CustomTextField(
                label: 'EMAIL ADDRESS',
                hint: 'Enter your email',
                prefixIcon: LucideIcons.mail,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              CustomTextField(
                label: 'PHONE NUMBER',
                hint: 'Enter your phone number',
                prefixIcon: LucideIcons.phone,
                controller: _phoneController,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'AGE',
                      hint: 'e.g. 26',
                      prefixIcon: LucideIcons.calendar,
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      label: 'WEIGHT (KG)',
                      hint: 'e.g. 75',
                      prefixIcon: LucideIcons.activity,
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              CustomTextField(
                label: 'HEIGHT (CM)',
                hint: 'e.g. 180',
                prefixIcon: LucideIcons.arrowUp,
                controller: _heightController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GENDER',
                    style: TextStyle(
                      color: context.secondaryTextColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildGenderOption('male', 'Male', LucideIcons.user),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildGenderOption('female', 'Female', LucideIcons.user),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // Save Button
              NeonButton(
                text: _isSaving ? 'Saving...' : 'Save Changes',
                icon: _isSaving ? Icons.hourglass_empty : LucideIcons.check,
                onPressed: _isSaving ? null : () => _saveProfile(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderOption(String value, String label, IconData icon) {
    final isSelected = _gender == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _gender = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.electricBlue.withOpacity(0.15) : const Color(0xFF1E1F2A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.electricBlue : context.glassBorderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.electricBlue : context.secondaryTextColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.electricBlue : context.textColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
