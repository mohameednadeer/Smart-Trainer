import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pedometer/pedometer.dart';

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

  const UserProfile({
    required this.name,
    required this.email,
    required this.joinDate,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    String? joinDate,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      joinDate: joinDate ?? this.joinDate,
    );
  }
}

class UserProfileNotifier extends Notifier<UserProfile> {
  @override
  UserProfile build() => const UserProfile(
        name: 'Alex Johnson',
        email: 'alex.johnson@email.com',
        joinDate: 'January 2026',
      );

  void updateProfile({String? name, String? email}) {
    state = state.copyWith(name: name, email: email);
  }
}

final userProvider = NotifierProvider<UserProfileNotifier, UserProfile>(UserProfileNotifier.new);

// ─────────────────── Step Counter ───────────────────

class StepCounterNotifier extends Notifier<int> {
  int _initialSteps = -1;
  DateTime _lastResetDate = DateTime.now();

  @override
  int build() {
    _startListening();
    return 0;
  }

  void _startListening() {
    Pedometer.stepCountStream.listen((event) {
      final now = DateTime.now();
      // Reset at midnight (new day)
      if (now.day != _lastResetDate.day ||
          now.month != _lastResetDate.month ||
          now.year != _lastResetDate.year) {
        _initialSteps = event.steps;
        _lastResetDate = now;
      }

      if (_initialSteps == -1) {
        _initialSteps = event.steps;
      }

      state = event.steps - _initialSteps;
    }, onError: (_) {
      // Pedometer not available on this device
      state = 0;
    });
  }
}

final stepsProvider = NotifierProvider<StepCounterNotifier, int>(StepCounterNotifier.new);
