import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
