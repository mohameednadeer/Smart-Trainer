/// Supported exercise types for posture evaluation.
enum ExerciseType {
  squat,
  pushUp,
}

/// The result of evaluating a single frame's pose against an exercise.
class ExerciseFeedback {
  /// Whether the current posture is within acceptable form.
  final bool isCorrect;

  /// Human-readable feedback message.
  final String message;

  /// Named joint angles used in the evaluation.
  final Map<String, double> jointAngles;

  /// Total repetitions counted so far.
  final int repCount;

  /// Current phase of the movement.
  final String phase;

  /// Real-time posture accuracy score (0.0 – 1.0).
  /// Computed as correctFrames / totalEvaluatedFrames.
  final double accuracyScore;

  const ExerciseFeedback({
    required this.isCorrect,
    required this.message,
    this.jointAngles = const {},
    this.repCount = 0,
    this.phase = 'idle',
    this.accuracyScore = 0.0,
  });

  /// Default feedback when no pose is detected yet.
  factory ExerciseFeedback.initial() => const ExerciseFeedback(
        isCorrect: false,
        message: 'Position yourself in front of the camera',
        phase: 'idle',
        accuracyScore: 0.0,
      );
}
