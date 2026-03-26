import 'angle_calculator.dart';
import 'models/exercise_feedback.dart';
import 'models/pose_result.dart';

/// Evaluates exercise form by analyzing joint angles from MoveNet keypoints.
///
/// Maintains internal state for rep counting via phase detection
/// (up/down transitions) and tracks accuracy across all frames.
class ExerciseEvaluator {
  // ── Internal state ──

  String _currentPhase = 'idle'; // 'idle', 'up', 'down'
  int _repCount = 0;
  int _correctFrames = 0;
  int _totalFrames = 0;

  int get repCount => _repCount;

  /// Live accuracy score (0.0 – 1.0).
  double get accuracyScore =>
      _totalFrames == 0 ? 0.0 : _correctFrames / _totalFrames;

  /// Resets all state when starting a new session.
  void reset() {
    _currentPhase = 'idle';
    _repCount = 0;
    _correctFrames = 0;
    _totalFrames = 0;
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
      case ExerciseType.bicepCurl:
        return _evaluateBicepCurl(poseResult);
    }
  }

  // ─────────────────────── SQUAT ───────────────────────

  ExerciseFeedback _evaluateSquat(PoseResult pose) {
    final angles = <String, double>{};

    // Knee angle (hip → knee → ankle)
    final leftKneeAngle = AngleCalculator.calculateAngle(
      pose.leftHip, pose.leftKnee, pose.leftAnkle,
    );
    final rightKneeAngle = AngleCalculator.calculateAngle(
      pose.rightHip, pose.rightKnee, pose.rightAnkle,
    );

    // Hip angle (shoulder → hip → knee)
    final leftHipAngle = AngleCalculator.calculateAngle(
      pose.leftShoulder, pose.leftHip, pose.leftKnee,
    );
    final rightHipAngle = AngleCalculator.calculateAngle(
      pose.rightShoulder, pose.rightHip, pose.rightKnee,
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
        accuracyScore: accuracyScore,
      );
    }

    final avgKneeAngle = _average(leftKneeAngle, rightKneeAngle);
    final avgHipAngle = _average(leftHipAngle, rightHipAngle);

    // ── Phase detection & rep counting ──
    // Standing: knees > 155°
    // Bottom: knees 65°–115° (proper parallel-or-below squat depth)
    if (avgKneeAngle != null) {
      if (avgKneeAngle > 155 && _currentPhase != 'up') {
        if (_currentPhase == 'down') _repCount++;
        _currentPhase = 'up';
      } else if (avgKneeAngle >= 65 && avgKneeAngle <= 115) {
        _currentPhase = 'down';
      }
    }

    // ── Form evaluation ──
    String message;
    bool isCorrect = true;

    if (avgKneeAngle != null && avgKneeAngle < 55) {
      message = 'Too deep — stop at parallel';
      isCorrect = false;
    } else if (avgHipAngle != null && avgHipAngle < 45) {
      message = 'Leaning too far forward — keep chest up';
      isCorrect = false;
    } else if (_currentPhase == 'down' &&
        avgKneeAngle != null &&
        avgKneeAngle >= 65 &&
        avgKneeAngle <= 115) {
      message = 'Great depth — push back up!';
    } else if (_currentPhase == 'up') {
      message = 'Standing — ready for next rep';
    } else {
      message = 'Keep going…';
    }

    _totalFrames++;
    if (isCorrect && _currentPhase != 'idle') _correctFrames++;

    return ExerciseFeedback(
      isCorrect: isCorrect,
      message: message,
      jointAngles: angles,
      repCount: _repCount,
      phase: _currentPhase,
      accuracyScore: accuracyScore,
    );
  }

  // ─────────────────────── PUSH-UP ───────────────────────

  ExerciseFeedback _evaluatePushUp(PoseResult pose) {
    final angles = <String, double>{};

    // Elbow angle (shoulder → elbow → wrist)
    final leftElbowAngle = AngleCalculator.calculateAngle(
      pose.leftShoulder, pose.leftElbow, pose.leftWrist,
    );
    final rightElbowAngle = AngleCalculator.calculateAngle(
      pose.rightShoulder, pose.rightElbow, pose.rightWrist,
    );

    // Body alignment: shoulder → hip → ankle
    final leftBodyAngle = AngleCalculator.calculateAngle(
      pose.leftShoulder, pose.leftHip, pose.leftAnkle,
    );
    final rightBodyAngle = AngleCalculator.calculateAngle(
      pose.rightShoulder, pose.rightHip, pose.rightAnkle,
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
        accuracyScore: accuracyScore,
      );
    }

    final avgElbowAngle = _average(leftElbowAngle, rightElbowAngle);
    final avgBodyAngle = _average(leftBodyAngle, rightBodyAngle);

    // ── Phase detection & rep counting ──
    if (avgElbowAngle != null) {
      if (avgElbowAngle > 155 && _currentPhase != 'up') {
        if (_currentPhase == 'down') _repCount++;
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

    _totalFrames++;
    if (isCorrect && _currentPhase != 'idle') _correctFrames++;

    return ExerciseFeedback(
      isCorrect: isCorrect,
      message: message,
      jointAngles: angles,
      repCount: _repCount,
      phase: _currentPhase,
      accuracyScore: accuracyScore,
    );
  }

  // ─────────────────────── BICEP CURL ───────────────────────

  ExerciseFeedback _evaluateBicepCurl(PoseResult pose) {
    final angles = <String, double>{};

    // Elbow angle (shoulder → elbow → wrist) — primary joint for curls
    final leftElbowAngle = AngleCalculator.calculateAngle(
      pose.leftShoulder, pose.leftElbow, pose.leftWrist,
    );
    final rightElbowAngle = AngleCalculator.calculateAngle(
      pose.rightShoulder, pose.rightElbow, pose.rightWrist,
    );

    // Shoulder angle (hip → shoulder → elbow) — detects swinging / cheating
    final leftShoulderAngle = AngleCalculator.calculateAngle(
      pose.leftHip, pose.leftShoulder, pose.leftElbow,
    );
    final rightShoulderAngle = AngleCalculator.calculateAngle(
      pose.rightHip, pose.rightShoulder, pose.rightElbow,
    );

    if (leftElbowAngle != null) angles['leftElbow'] = leftElbowAngle;
    if (rightElbowAngle != null) angles['rightElbow'] = rightElbowAngle;
    if (leftShoulderAngle != null) angles['leftShoulder'] = leftShoulderAngle;
    if (rightShoulderAngle != null) angles['rightShoulder'] = rightShoulderAngle;

    if (angles.isEmpty) {
      return ExerciseFeedback(
        isCorrect: false,
        message: 'Arms not fully visible — step back',
        jointAngles: angles,
        repCount: _repCount,
        phase: _currentPhase,
        accuracyScore: accuracyScore,
      );
    }

    final avgElbowAngle = _average(leftElbowAngle, rightElbowAngle);
    final avgShoulderAngle = _average(leftShoulderAngle, rightShoulderAngle);

    // ── Phase detection & rep counting ──
    // Extended (down): elbow > 150°
    // Curled (top):    elbow < 50°
    if (avgElbowAngle != null) {
      if (avgElbowAngle > 150 && _currentPhase != 'down') {
        if (_currentPhase == 'up') _repCount++;
        _currentPhase = 'down';
      } else if (avgElbowAngle < 50) {
        _currentPhase = 'up';
      }
    }

    // ── Form evaluation ──
    String message;
    bool isCorrect = true;

    if (avgShoulderAngle != null && avgShoulderAngle > 45) {
      message = 'Keep elbows pinned — don\'t swing';
      isCorrect = false;
    } else if (_currentPhase == 'up' &&
        avgElbowAngle != null &&
        avgElbowAngle < 50) {
      message = 'Good squeeze — lower slowly!';
    } else if (_currentPhase == 'down') {
      message = 'Arms extended — curl up!';
    } else {
      message = 'Keep curling…';
    }

    _totalFrames++;
    if (isCorrect && _currentPhase != 'idle') _correctFrames++;

    return ExerciseFeedback(
      isCorrect: isCorrect,
      message: message,
      jointAngles: angles,
      repCount: _repCount,
      phase: _currentPhase,
      accuracyScore: accuracyScore,
    );
  }

  // ── Helpers ──

  double? _average(double? a, double? b) {
    if (a != null && b != null) return (a + b) / 2;
    return a ?? b;
  }
}
