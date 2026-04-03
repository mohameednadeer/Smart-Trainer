import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_trainer/theme/app_colors.dart';
import 'package:smart_trainer/widgets/glass_container.dart';
import 'package:smart_trainer/widgets/neon_button.dart';
import 'package:smart_trainer/widgets/custom_text_field.dart';
import 'package:smart_trainer/theme/theme_ext.dart';
import 'package:smart_trainer/services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool isLoading = false;
  final AuthService _authService = AuthService();
  
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  String _gender = 'male';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _clearControllers() {
    _emailController.clear();
    _passwordController.clear();
    _nameController.clear();
    _phoneController.clear();
    _ageController.clear();
    _weightController.clear();
    _heightController.clear();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('يرجى ملء جميع الخانات');
      return;
    }

    setState(() => isLoading = true);

    try {
      if (isLogin) {
        await _authService.login(email: email, password: password);
      } else {
        final name = _nameController.text.trim();
        final phone = _phoneController.text.trim();
        final ageStr = _ageController.text.trim();
        final weightStr = _weightController.text.trim();
        final heightStr = _heightController.text.trim();

        if (name.isEmpty || phone.isEmpty || ageStr.isEmpty || weightStr.isEmpty || heightStr.isEmpty) {
          _showError('يرجى ملء جميع البيانات');
          return;
        }

        final age = int.tryParse(ageStr) ?? 0;
        final weight = double.tryParse(weightStr) ?? 0;
        final height = double.tryParse(heightStr) ?? 0;

        await _authService.signUp(
          name: name,
          email: email,
          phone: phone,
          password: password,
          age: age,
          weight: weight,
          height: height,
          gender: _gender,
        );
      }

      
      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        // تنظيف رسالة الخطأ لتكون مقروءة بالعربي أو الإنجليزية بوضوح
        String errorMessage = e.toString().contains(']') 
            ? e.toString().split(']').last.trim() 
            : e.toString();
        _showError(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.5),
                radius: 1.2,
                colors: [
                  const Color.fromARGB(255, 10, 20, 36),
                  context.bgColor,
                ],
              ),
            ),
            child: CustomPaint(
              size: Size.infinite,
              painter: GridPainter(),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.electricBlue, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.electricBlue.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            LucideIcons.activity,
                            size: 40,
                            color: AppColors.electricBlue,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: 'Smart', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32, color: context.textColor)),
                              TextSpan(text: 'Trainer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32, color: AppColors.electricBlue)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isLogin ? 'Welcome Back!' : 'Start Your Journey',
                          style: TextStyle(
                            color: context.secondaryTextColor,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  GlassContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Tabs Section
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF22222A),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    if (!isLogin) {
                                      _clearControllers();
                                      setState(() => isLogin = true);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    decoration: BoxDecoration(
                                      color: isLogin ? AppColors.electricBlue : Colors.transparent,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: isLogin
                                          ? [BoxShadow(color: AppColors.electricBlue.withOpacity(0.4), blurRadius: 12)]
                                          : [],
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Login',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isLogin ? Colors.white : context.secondaryTextColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    if (isLogin) {
                                      _clearControllers();
                                      setState(() => isLogin = false);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    decoration: BoxDecoration(
                                      color: !isLogin ? AppColors.electricBlue : Colors.transparent,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: !isLogin
                                          ? [BoxShadow(color: AppColors.electricBlue.withOpacity(0.4), blurRadius: 12)]
                                          : [],
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Sign Up',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: !isLogin ? Colors.white : context.secondaryTextColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        if (!isLogin) ...[
                          CustomTextField(
                            label: 'Full Name',
                            hint: 'Enter your full name',
                            prefixIcon: LucideIcons.user,
                            controller: _nameController,
                          ),
                          const SizedBox(height: 20),
                          CustomTextField(
                            label: 'Phone Number',
                            hint: 'Enter your phone number',
                            prefixIcon: LucideIcons.phone,
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  label: 'Age',
                                  hint: 'e.g. 25',
                                  prefixIcon: LucideIcons.calendar,
                                  controller: _ageController,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Gender', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Container(
                                      height: 56,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF22222A),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.white10),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _gender,
                                          dropdownColor: const Color(0xFF1A1B2E),
                                          style: const TextStyle(color: Colors.white),
                                          items: ['male', 'female'].map((g) => DropdownMenuItem(
                                            value: g,
                                            child: Text(g[0].toUpperCase() + g.substring(1)),
                                          )).toList(),
                                          onChanged: (val) => setState(() => _gender = val!),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  label: 'Weight (kg)',
                                  hint: 'e.g. 70',
                                  prefixIcon: LucideIcons.activity,
                                  controller: _weightController,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: CustomTextField(
                                  label: 'Height (cm)',
                                  hint: 'e.g. 175',
                                  prefixIcon: LucideIcons.arrowUp,
                                  controller: _heightController,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],


                        CustomTextField(
                          label: 'Email',
                          hint: 'Enter your email',
                          prefixIcon: LucideIcons.mail,
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          label: 'Password',
                          hint: 'Enter your password',
                          prefixIcon: LucideIcons.lock,
                          isPassword: true,
                          controller: _passwordController,
                        ),
                        const SizedBox(height: 12),
                        
                        if (isLogin)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                if (_emailController.text.isNotEmpty) {
                                  _authService.sendPasswordResetEmail(_emailController.text.trim());
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('تم إرسال تعليمات إعادة تعيين كلمة المرور'))
                                  );
                                } else {
                                  _showError('أدخل البريد الإلكتروني أولاً');
                                }
                              },
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(color: AppColors.electricBlue, fontSize: 13),
                              ),
                            ),
                          ),

                        const SizedBox(height: 24),

                        isLoading 
                        ? const Center(child: CircularProgressIndicator(color: AppColors.electricBlue))
                        : NeonButton(
                          text: isLogin ? 'Login' : 'Create Account',
                          icon: LucideIcons.zap,
                          onPressed: () => _handleAuth(),
                        ),
                        const SizedBox(height: 24),
                        
                        Row(
                          children: [
                            Expanded(child: Divider(color: context.glassBorderColor)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Or continue with',
                                style: TextStyle(color: context.secondaryTextColor, fontSize: 14),
                              ),
                            ),
                            Expanded(child: Divider(color: context.glassBorderColor)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        Container(
                          decoration: BoxDecoration(
                            color: context.surfaceColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: context.glassBorderColor),
                          ),
                          child: InkWell(
                            onTap: () {},
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.network(
                                    'https://img.icons8.com/color/48/000000/google-logo.png',
                                    width: 24,
                                    height: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Sign in with Google',
                                    style: TextStyle(
                                      color: context.textColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
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
