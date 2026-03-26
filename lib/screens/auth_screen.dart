import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_trainer/theme/app_colors.dart';
import 'package:smart_trainer/widgets/glass_container.dart';
import 'package:smart_trainer/widgets/neon_button.dart';
import 'package:smart_trainer/widgets/custom_text_field.dart';
import 'package:smart_trainer/theme/theme_ext.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
        // Background pattern/color (Neon Grid could be an image or painter, simplified here)
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.5),
                radius: 1.2,
                colors: [
                  const Color.fromARGB(255, 10, 20, 36), // Subtler blue glow
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
                  // App Logo / Title
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
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your AI Fitness Coach',
                          style: TextStyle(
                            color: context.secondaryTextColor,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Auth Card
                  GlassContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Tabs
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF22222A),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => isLogin = true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    decoration: BoxDecoration(
                                      color: isLogin ? AppColors.electricBlue : Colors.transparent,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: isLogin
                                          ? [
                                              BoxShadow(
                                                color: AppColors.electricBlue.withOpacity(0.4),
                                                blurRadius: 12,
                                              )
                                            ]
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
                                child: GestureDetector(
                                  onTap: () => setState(() => isLogin = false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    decoration: BoxDecoration(
                                      color: !isLogin ? AppColors.electricBlue : Colors.transparent,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: !isLogin
                                          ? [
                                              BoxShadow(
                                                color: AppColors.electricBlue.withOpacity(0.4),
                                                blurRadius: 12,
                                              )
                                            ]
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

                        // Form
                        const CustomTextField(
                          label: 'Email',
                          hint: 'Enter your email',
                          prefixIcon: LucideIcons.mail,
                        ),
                        const SizedBox(height: 20),
                        const CustomTextField(
                          label: 'Password',
                          hint: 'Enter your password',
                          prefixIcon: LucideIcons.lock,
                          isPassword: true,
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: AppColors.electricBlue,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        NeonButton(
                          text: isLogin ? 'Login' : 'Create Account',
                          icon: LucideIcons.zap,
                          onPressed: () {
                            // Navigate to dashboard screen
                            context.go('/dashboard');
                          },
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
                        
                        // Google Sign In Button (Mock)
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

