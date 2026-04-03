import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_trainer/services/auth_service.dart';
import 'package:smart_trainer/services/workout_service.dart';
import 'step_counter_service.dart';


import 'ai/exercise_evaluator.dart';
import 'ai/models/exercise_feedback.dart';
import 'ai/models/pose_result.dart';
import 'ai/pose_detector_service.dart';
import 'camera_service.dart';

// ─────────────────── Camera ───────────────────

/// Provides a singleton [CameraService] instance.
final cameraServiceProvider = Provider<CameraService>((ref) {
  final service = CameraService();
  ref.onDispose(() => service.dispose());
  return service;
});

// ─────────────────── Pose Detection ───────────────────

/// Provides a singleton [PoseDetectorService] instance.
final poseDetectorProvider = Provider<PoseDetectorService>((ref) {
  final service = PoseDetectorService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// The latest pose result from MoveNet inference.
/// Updated every frame by the active workout screen.
class PoseResultNotifier extends Notifier<PoseResult> {
  @override
  PoseResult build() => PoseResult.empty();
  set state(PoseResult value) => super.state = value;
}

final poseResultProvider =
    NotifierProvider<PoseResultNotifier, PoseResult>(PoseResultNotifier.new);

// ─────────────────── Exercise ───────────────────

/// Currently selected exercise type.
class SelectedExerciseNotifier extends Notifier<ExerciseType> {
  @override
  ExerciseType build() => ExerciseType.squat;
  set state(ExerciseType value) => super.state = value;
}

final selectedExerciseProvider =
    NotifierProvider<SelectedExerciseNotifier, ExerciseType>(
        SelectedExerciseNotifier.new);

/// Provides a singleton [ExerciseEvaluator] instance.
final exerciseEvaluatorProvider = Provider<ExerciseEvaluator>((ref) {
  return ExerciseEvaluator();
});

/// Derived feedback built from the latest pose result + selected exercise.
final exerciseFeedbackProvider = Provider<ExerciseFeedback>((ref) {
  final poseResult = ref.watch(poseResultProvider);
  final exerciseType = ref.watch(selectedExerciseProvider);
  final evaluator = ref.read(exerciseEvaluatorProvider);

  return evaluator.evaluate(poseResult, exerciseType);
});

// ─────────────────── Theme ───────────────────

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.dark;
  set state(ThemeMode value) => super.state = value;
}

/// Provides the current application theme mode.
final themeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

// ─────────────────── User Profile ───────────────────

class UserProfile {
  final String name;
  final String email;
  final String phone;
  final String joinDate;
  final int age;
  final double weight; // kg
  final double height; // cm
  final String gender; // 'male' or 'female'

  const UserProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.joinDate,
    required this.age,
    required this.weight,
    required this.height,
    required this.gender,
  });


  /// Calculates Daily Caloric Needs (TDEE) based on the Mifflin-St Jeor equation.
  /// Assuming a 'Lightly Active' multiplier of 1.375 for standard users of this fitness app.
  int get dailyCalories {
    if (weight == 0 || height == 0 || age == 0) return 2000; // placeholder default

    double bmr;
    if (gender == 'male') {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }

    final tdee = bmr * 1.375;
    return tdee.round();
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? joinDate,
    int? age,
    double? weight,
    double? height,
    String? gender,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      joinDate: joinDate ?? this.joinDate,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      gender: gender ?? this.gender,
    );
  }
}

class UserProfileNotifier extends Notifier<UserProfile> {
  final _authService = AuthService();

  @override
  UserProfile build() {
    // مراقبة حالة المصادقة
    auth.FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _loadUserData(user.uid);
      }
    });

    return const UserProfile(
      name: 'Loading...',
      email: '',
      phone: '',
      joinDate: '',
      age: 0,
      weight: 0,
      height: 0,
      gender: 'male',
    );
  }

  Future<void> _loadUserData(String uid) async {
    final data = await _authService.getUserData(uid);
    if (data != null) {
      state = UserProfile(
        name: data['name'] ?? 'User',
        email: data['email'] ?? '',
        phone: data['phone'] ?? '',
        joinDate: 'Since 2026',
        age: data['age'] ?? 25,
        weight: (data['weight'] as num?)?.toDouble() ?? 70.0,
        height: (data['height'] as num?)?.toDouble() ?? 170.0,
        gender: data['gender'] ?? 'male',
      );
    }
  }

  void updateProfile({
    String? name,
    String? email,
    String? phone,
    int? age,
    double? weight,
    double? height,
    String? gender,
  }) {
    state = state.copyWith(
      name: name,
      email: email,
      phone: phone,
      age: age,
      weight: weight,
      height: height,
      gender: gender,
    );
  }
}


final userProvider = NotifierProvider<UserProfileNotifier, UserProfile>(UserProfileNotifier.new);

// ─────────────────── Step Counter ───────────────────

class StepCounterNotifier extends Notifier<int> {
  final _service = StepCounterService();
  StreamSubscription<int>? _subscription;

  @override
  int build() {
    ref.onDispose(() {
      _subscription?.cancel();
      _service.dispose();
    });
    _init();
    return 0;
  }

  Future<void> _init() async {
    // Request permission for activity recognition (Android 10+)
    final status = await Permission.activityRecognition.request();
    if (!status.isGranted) {
      debugPrint('Step Counter: Permission denied.');
      return;
    }

    await _service.initialize();

    // Emit persisted steps immediately on load
    state = _service.currentSteps;

    // Subscribe to live updates
    _subscription = _service.stepStream.listen((steps) {
      state = steps;
    });
  }
}

final stepsProvider = NotifierProvider<StepCounterNotifier, int>(StepCounterNotifier.new);

// ─────────────────── Workout History ───────────────────

class WorkoutSessionStats {
  final ExerciseType exerciseType;
  final Duration duration;
  final int calories;
  final int reps;
  final int accuracy;
  final DateTime date;

  const WorkoutSessionStats({
    required this.exerciseType,
    this.duration = Duration.zero,
    this.calories = 0,
    this.reps = 0,
    this.accuracy = 0,
    required this.date,
  });
}

class WorkoutHistoryNotifier extends Notifier<List<WorkoutSessionStats>> {
  final _workoutService = WorkoutService();
  StreamSubscription<List<WorkoutSessionStats>>? _subscription;

  @override
  List<WorkoutSessionStats> build() {
    // مراقبة سجل التمارين في Firestore
    _subscription?.cancel();
    _subscription = _workoutService.getWorkoutHistory().listen((sessions) {
      state = sessions;
    });

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return []; // حالة مبدئية فارغة
  }

  Future<void> addSession(WorkoutSessionStats session) async {
    // حفظ الجلسة في فايربيز (ستقوم الـ Build بتحديث القائمة تلقائياً بسبب الـ Stream)
    try {
      await _workoutService.saveWorkoutSession(session);
    } catch (e) {
      debugPrint("Error adding session to state/firestore: $e");
    }
  }
}


final workoutHistoryProvider = NotifierProvider<WorkoutHistoryNotifier, List<WorkoutSessionStats>>(WorkoutHistoryNotifier.new);
