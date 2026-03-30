import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
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
  final String joinDate;
  final int age;
  final double weight; // kg
  final double height; // cm
  final String gender; // 'male' or 'female'

  const UserProfile({
    required this.name,
    required this.email,
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
    String? joinDate,
    int? age,
    double? weight,
    double? height,
    String? gender,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      joinDate: joinDate ?? this.joinDate,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      gender: gender ?? this.gender,
    );
  }
}

class UserProfileNotifier extends Notifier<UserProfile> {
  @override
  UserProfile build() => const UserProfile(
        name: 'Mohamed',
        email: 'mohamed@email.com',
        joinDate: 'January 2026',
        age: 26,
        weight: 75.0,
        height: 180.0,
        gender: 'male',
      );

  void updateProfile({
    String? name,
    String? email,
    int? age,
    double? weight,
    double? height,
    String? gender,
  }) {
    state = state.copyWith(
      name: name,
      email: email,
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
  @override
  List<WorkoutSessionStats> build() {
    return [
      WorkoutSessionStats(
        exerciseType: ExerciseType.squat,
        duration: const Duration(minutes: 12),
        calories: 85,
        reps: 45,
        accuracy: 92,
        date: DateTime.now().subtract(const Duration(days: 2)),
      ),
      WorkoutSessionStats(
        exerciseType: ExerciseType.pushUp,
        duration: const Duration(minutes: 8),
        calories: 60,
        reps: 30,
        accuracy: 88,
        date: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];
  }

  void addSession(WorkoutSessionStats session) {
    state = [...state, session];
  }
}

final workoutHistoryProvider = NotifierProvider<WorkoutHistoryNotifier, List<WorkoutSessionStats>>(WorkoutHistoryNotifier.new);
