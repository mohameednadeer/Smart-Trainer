import 'angle_calculator.dart';
import 'models/exercise_feedback.dart';
import 'models/pose_landmark.dart';
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
      case ExerciseType.tricepExtension:
        return _evaluateTricepExtension(poseResult);
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

    // Elbow angle (shoulder → elbow → wrist)
    final leftElbowAngle = AngleCalculator.calculateAngle(
      pose.leftShoulder, pose.leftElbow, pose.leftWrist,
    );
    final rightElbowAngle = AngleCalculator.calculateAngle(
      pose.rightShoulder, pose.rightElbow, pose.rightWrist,
    );
    // Shoulder swing (hip → shoulder → elbow) — detects cheating
    final leftSwingAngle = AngleCalculator.calculateAngle(
      pose.leftHip, pose.leftShoulder, pose.leftElbow,
    );
    final rightSwingAngle = AngleCalculator.calculateAngle(
      pose.rightHip, pose.rightShoulder, pose.rightElbow,
    );

    if (leftElbowAngle != null) angles['leftElbow'] = leftElbowAngle;
    if (rightElbowAngle != null) angles['rightElbow'] = rightElbowAngle;
    if (leftSwingAngle != null) angles['leftShoulder'] = leftSwingAngle;
    if (rightSwingAngle != null) angles['rightShoulder'] = rightSwingAngle;

    // Need at least one elbow angle to proceed
    if (leftElbowAngle == null && rightElbowAngle == null) {
      return ExerciseFeedback(
        isCorrect: false,
        message: 'Arms not visible — face the camera or turn to the side',
        jointAngles: angles,
        repCount: _repCount,
        phase: _currentPhase,
        accuracyScore: accuracyScore,
      );
    }

    // ── Active angle: use the MOST CURLED arm (lowest angle). ──
    // This lets ANY single arm trigger a rep — works for:
    //   • front view one arm  • front view both arms  • side view
    // No need to detect which view we're in at all.
    final double activeAngle;
    if (leftElbowAngle != null && rightElbowAngle != null) {
      // both visible → whichever arm is more curled leads
      activeAngle = leftElbowAngle < rightElbowAngle
          ? leftElbowAngle
          : rightElbowAngle;
    } else {
      // only one arm visible → use it directly
      activeAngle = (leftElbowAngle ?? rightElbowAngle)!;
    }

    // ── Phase detection & rep counting ──
    // Extended (bottom): angle > 150° — arm nearly straight
    // Curled   (top):    angle < 50°  — a proper deep curl, not just a slight raise
    if (activeAngle > 150 && _currentPhase != 'down') {
      if (_currentPhase == 'up') _repCount++;
      _currentPhase = 'down';
    } else if (activeAngle < 50) {
      _currentPhase = 'up';
    }

    // ── Form evaluation ──
    final swingAngle = leftSwingAngle ?? rightSwingAngle;
    final bothVisible =
        leftElbowAngle != null && rightElbowAngle != null;

    String message;
    bool isCorrect = true;

    if (swingAngle != null && swingAngle > 45) {
      message = 'Keep elbow pinned — don\'t swing';
      isCorrect = false;
    } else if (_currentPhase == 'up') {
      message = bothVisible
          ? 'Good curl — lower both arms slowly!'
          : 'Good squeeze — lower slowly!';
    } else if (_currentPhase == 'down') {
      message = bothVisible
          ? 'Arms extended — curl up!'
          : 'Arm extended — curl up!';
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

  // ─────────────────────── TRICEP EXTENSION ───────────────────────


  // ─────────────────────── TRICEP EXTENSION ───────────────────────

  ExerciseFeedback _evaluateTricepExtension(PoseResult pose) {
    final angles = <String, double>{};

    // ── Compute angles for each side independently ──
    // Elbow angle (shoulder → elbow → wrist) — primary joint for the extension
    final leftElbowAngle = AngleCalculator.calculateAngle(
      pose.leftShoulder, pose.leftElbow, pose.leftWrist,
    );
    final rightElbowAngle = AngleCalculator.calculateAngle(
      pose.rightShoulder, pose.rightElbow, pose.rightWrist,
    );

    // Upper-arm angle (hip → shoulder → elbow) — detects if the upper arm
    // stays locked overhead or drifts forward/back
    final leftUpperArmAngle = AngleCalculator.calculateAngle(
      pose.leftHip, pose.leftShoulder, pose.leftElbow,
    );
    final rightUpperArmAngle = AngleCalculator.calculateAngle(
      pose.rightHip, pose.rightShoulder, pose.rightElbow,
    );

    if (leftElbowAngle != null) angles['leftElbow'] = leftElbowAngle;
    if (rightElbowAngle != null) angles['rightElbow'] = rightElbowAngle;
    if (leftUpperArmAngle != null) angles['leftUpperArm'] = leftUpperArmAngle;
    if (rightUpperArmAngle != null) angles['rightUpperArm'] = rightUpperArmAngle;

    if (angles.isEmpty) {
      return ExerciseFeedback(
        isCorrect: false,
        message: 'Arm not visible — face the camera or turn to the side',
        jointAngles: angles,
        repCount: _repCount,
        phase: _currentPhase,
        accuracyScore: accuracyScore,
      );
    }

    // ── Pick the best visible side ──
    // Priority: prefer the side where BOTH elbow AND upper-arm angles are
    // available (gives us full form checking). Fall back to elbow-only if
    // the camera is at an angle where the hip landmark is occluded.
    double? workingElbowAngle;
    double? workingUpperArmAngle;

    final leftFullyVisible =
        leftElbowAngle != null && leftUpperArmAngle != null;
    final rightFullyVisible =
        rightElbowAngle != null && rightUpperArmAngle != null;

    if (leftFullyVisible && rightFullyVisible) {
      // Front view — average both sides for a stable reading
      workingElbowAngle = (leftElbowAngle! + rightElbowAngle!) / 2;
      workingUpperArmAngle = (leftUpperArmAngle! + rightUpperArmAngle!) / 2;
    } else if (leftFullyVisible) {
      // Left-side or left-arm view
      workingElbowAngle = leftElbowAngle;
      workingUpperArmAngle = leftUpperArmAngle;
    } else if (rightFullyVisible) {
      // Right-side or right-arm view
      workingElbowAngle = rightElbowAngle;
      workingUpperArmAngle = rightUpperArmAngle;
    } else {
      // Only elbow is visible (extreme angle) — still count reps, skip form check
      workingElbowAngle = leftElbowAngle ?? rightElbowAngle;
    }

    // ── Phase detection & rep counting ──
    // Extended (lockout):   elbow > 155° — arm fully straight
    // Contracted (loaded):  elbow < 80°  — arm bent behind head
    if (workingElbowAngle != null) {
      if (workingElbowAngle > 155 && _currentPhase != 'up') {
        if (_currentPhase == 'down') _repCount++;
        _currentPhase = 'up';
      } else if (workingElbowAngle < 80) {
        _currentPhase = 'down';
      }
    }

    // ── Form evaluation ──
    String message;
    bool isCorrect = true;

    if (workingUpperArmAngle != null && workingUpperArmAngle < 130) {
      // Upper arm has moved away from vertical — elbow is flaring
      message = 'Keep upper arm still — don\'t let elbow drift';
      isCorrect = false;
    } else if (workingElbowAngle != null && workingElbowAngle < 55) {
      message = 'Too far down — control the descent';
      isCorrect = false;
    } else if (_currentPhase == 'up') {
      message = 'Full lockout — bend arms back down';
    } else if (_currentPhase == 'down') {
      message = 'Arms loaded — press up and extend!';
    } else {
      message = 'Position arm overhead and start extending…';
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
