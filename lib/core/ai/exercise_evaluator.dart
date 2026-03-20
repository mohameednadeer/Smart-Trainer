import 'angle_calculator.dart';
import 'models/exercise_feedback.dart';
import 'models/pose_result.dart';

/// Evaluates exercise form by analyzing joint angles from MoveNet keypoints.
///
/// Maintains internal state for rep counting via phase detection
/// (up/down transitions).
class ExerciseEvaluator {
  // ── Internal state for rep counting ──

  String _currentPhase = 'idle'; // 'idle', 'up', 'down'
  int _repCount = 0;

  int get repCount => _repCount;

  /// Resets rep count and phase when switching exercises.
  void reset() {
    _currentPhase = 'idle';
    _repCount = 0;
  }

  /// Evaluates the given [poseResult] against the selected [exerciseType].
  ExerciseFeedback evaluate(PoseResult poseResult, ExerciseType exerciseType) {
    if (poseResult.isEmpty) {
      return ExerciseFeedback.initial();
    }

    switch (exerciseType) {
      case ExerciseType.squat:
        return _evaluateSquat(poseResult);
      case ExerciseType.pushUp:
        return _evaluatePushUp(poseResult);
    }
  }

  // ─────────────────────── SQUAT ───────────────────────

  ExerciseFeedback _evaluateSquat(PoseResult pose) {
    final angles = <String, double>{};

    // Calculate knee angles (hip → knee → ankle)
    final leftKneeAngle = AngleCalculator.calculateAngle(
      pose.leftHip,
      pose.leftKnee,
      pose.leftAnkle,
    );
    final rightKneeAngle = AngleCalculator.calculateAngle(
      pose.rightHip,
      pose.rightKnee,
      pose.rightAnkle,
    );

    // Calculate hip angles (shoulder → hip → knee)
    final leftHipAngle = AngleCalculator.calculateAngle(
      pose.leftShoulder,
      pose.leftHip,
      pose.leftKnee,
    );
    final rightHipAngle = AngleCalculator.calculateAngle(
      pose.rightShoulder,
      pose.rightHip,
      pose.rightKnee,
    );

    if (leftKneeAngle != null) angles['leftKnee'] = leftKneeAngle;
    if (rightKneeAngle != null) angles['rightKnee'] = rightKneeAngle;
    if (leftHipAngle != null) angles['leftHip'] = leftHipAngle;
    if (rightHipAngle != null) angles['rightHip'] = rightHipAngle;

    if (angles.isEmpty) {
      return ExerciseFeedback(
        isCorrect: false,
        message: 'Body not fully visible — step back',
        jointAngles: angles,
        repCount: _repCount,
        phase: _currentPhase,
      );
    }

    // Use the average of both sides for evaluation
    final avgKneeAngle = _average(leftKneeAngle, rightKneeAngle);
    final avgHipAngle = _average(leftHipAngle, rightHipAngle);

    // ── Phase detection & rep counting ──
    // Standing: knees > 160°
    // Descending/bottom: knees 70°–100°
    if (avgKneeAngle != null) {
      if (avgKneeAngle > 160 && _currentPhase != 'up') {
        if (_currentPhase == 'down') {
          _repCount++;
        }
        _currentPhase = 'up';
      } else if (avgKneeAngle >= 70 && avgKneeAngle <= 100) {
        _currentPhase = 'down';
      }
    }

    // ── Form evaluation ──
    String message;
    bool isCorrect = true;

    if (avgKneeAngle != null && avgKneeAngle < 60) {
      message = 'Too deep — stop at parallel';
      isCorrect = false;
    } else if (avgHipAngle != null && avgHipAngle < 50) {
      message = 'Leaning too far forward — keep chest up';
      isCorrect = false;
    } else if (_currentPhase == 'down' &&
        avgKneeAngle != null &&
        avgKneeAngle >= 70 &&
        avgKneeAngle <= 100) {
      message = 'Great depth — push back up!';
    } else if (_currentPhase == 'up') {
      message = 'Standing — ready for next rep';
    } else {
      message = 'Keep going…';
    }

    return ExerciseFeedback(
      isCorrect: isCorrect,
      message: message,
      jointAngles: angles,
      repCount: _repCount,
      phase: _currentPhase,
    );
  }

  // ─────────────────────── PUSH-UP ───────────────────────

  ExerciseFeedback _evaluatePushUp(PoseResult pose) {
    final angles = <String, double>{};

    // Elbow angle (shoulder → elbow → wrist)
    final leftElbowAngle = AngleCalculator.calculateAngle(
      pose.leftShoulder,
      pose.leftElbow,
      pose.leftWrist,
    );
    final rightElbowAngle = AngleCalculator.calculateAngle(
      pose.rightShoulder,
      pose.rightElbow,
      pose.rightWrist,
    );

    // Body alignment: shoulder → hip → ankle
    final leftBodyAngle = AngleCalculator.calculateAngle(
      pose.leftShoulder,
      pose.leftHip,
      pose.leftAnkle,
    );
    final rightBodyAngle = AngleCalculator.calculateAngle(
      pose.rightShoulder,
      pose.rightHip,
      pose.rightAnkle,
    );

    if (leftElbowAngle != null) angles['leftElbow'] = leftElbowAngle;
    if (rightElbowAngle != null) angles['rightElbow'] = rightElbowAngle;
    if (leftBodyAngle != null) angles['leftBody'] = leftBodyAngle;
    if (rightBodyAngle != null) angles['rightBody'] = rightBodyAngle;

    if (angles.isEmpty) {
      return ExerciseFeedback(
        isCorrect: false,
        message: 'Body not fully visible — adjust camera',
        jointAngles: angles,
        repCount: _repCount,
        phase: _currentPhase,
      );
    }

    final avgElbowAngle = _average(leftElbowAngle, rightElbowAngle);
    final avgBodyAngle = _average(leftBodyAngle, rightBodyAngle);

    // ── Phase detection & rep counting ──
    if (avgElbowAngle != null) {
      if (avgElbowAngle > 160 && _currentPhase != 'up') {
        if (_currentPhase == 'down') {
          _repCount++;
        }
        _currentPhase = 'up';
      } else if (avgElbowAngle < 90) {
        _currentPhase = 'down';
      }
    }

    // ── Form evaluation ──
    String message;
    bool isCorrect = true;

    if (avgBodyAngle != null && avgBodyAngle < 150) {
      message = 'Hips sagging — keep body straight';
      isCorrect = false;
    } else if (avgElbowAngle != null && avgElbowAngle < 60) {
      message = 'Too low — don\'t over-extend';
      isCorrect = false;
    } else if (_currentPhase == 'down') {
      message = 'Good descent — push up now!';
    } else if (_currentPhase == 'up') {
      message = 'Arms extended — ready for next rep';
    } else {
      message = 'Get into plank position…';
    }

    return ExerciseFeedback(
      isCorrect: isCorrect,
      message: message,
      jointAngles: angles,
      repCount: _repCount,
      phase: _currentPhase,
    );
  }

  // ── Helpers ──

  double? _average(double? a, double? b) {
    if (a != null && b != null) return (a + b) / 2;
    return a ?? b;
  }
}
