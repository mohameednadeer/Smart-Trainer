/// Supported exercise types for posture evaluation.
enum ExerciseType {
  squat,
  pushUp,
}

/// The result of evaluating a single frame's pose against an exercise.
class ExerciseFeedback {
  /// Whether the current posture is within acceptable form.
  final bool isCorrect;

  /// Human-readable feedback message (e.g., "Keep your back straight").
  final String message;

  /// Named joint angles used in the evaluation (e.g., {"leftKnee": 95.3}).
  final Map<String, double> jointAngles;

  /// Total repetitions counted so far.
  final int repCount;

  /// Current phase of the movement (e.g., "down", "up", "idle").
  final String phase;

  const ExerciseFeedback({
    required this.isCorrect,
    required this.message,
    this.jointAngles = const {},
    this.repCount = 0,
    this.phase = 'idle',
  });

  /// Default feedback when no pose is detected yet.
  factory ExerciseFeedback.initial() => const ExerciseFeedback(
        isCorrect: false,
        message: 'Position yourself in front of the camera',
        phase: 'idle',
      );
}
