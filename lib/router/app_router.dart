import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_trainer/screens/auth_screen.dart';
import 'package:smart_trainer/screens/training_screen.dart';
import 'package:smart_trainer/screens/analytics_screen.dart';
import 'package:smart_trainer/screens/dashboard_screen.dart';
import 'package:smart_trainer/screens/profile_screen.dart';
import 'package:smart_trainer/screens/settings_screen.dart';
import 'package:smart_trainer/screens/active_workout_screen.dart';
import 'package:smart_trainer/screens/workout_result_screen.dart';
import 'package:smart_trainer/screens/edit_profile_screen.dart';
import 'package:smart_trainer/screens/privacy_screen.dart';
import 'package:smart_trainer/screens/help_support_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/auth',
  refreshListenable: AuthListenable(),
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final bool loggingIn = state.matchedLocation == '/auth';

    if (user != null) {
      if (loggingIn) return '/dashboard';
    } else {
      if (!loggingIn) return '/auth';
    }
    
    return null;
  },
  routes: [
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: '/training',
      builder: (context, state) => const TrainingScreen(),
    ),
    GoRoute(
      path: '/active_workout',
      builder: (context, state) => const ActiveWorkoutScreen(),
    ),
    GoRoute(
      path: '/workout_result',
      builder: (context, state) => const WorkoutResultScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/analytics',
      builder: (context, state) => const AnalyticsScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/privacy',
      builder: (context, state) => const PrivacySecurityScreen(),
    ),
    GoRoute(
      path: '/help-support',
      builder: (context, state) => const HelpSupportScreen(),
    ),
  ],
);

class AuthListenable extends ChangeNotifier {
  AuthListenable() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      notifyListeners();
    });
  }
}


