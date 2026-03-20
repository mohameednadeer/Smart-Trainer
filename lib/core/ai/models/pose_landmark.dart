/// Enum representing all 17 MoveNet keypoints.
enum PoseLandmarkType {
  nose,
  leftEye,
  rightEye,
  leftEar,
  rightEar,
  leftShoulder,
  rightShoulder,
  leftElbow,
  rightElbow,
  leftWrist,
  rightWrist,
  leftHip,
  rightHip,
  leftKnee,
  rightKnee,
  leftAnkle,
  rightAnkle,
}

/// A single body keypoint detected by MoveNet.
///
/// Coordinates [x] and [y] are normalized to [0.0, 1.0] relative to the
/// input image dimensions. [confidence] ranges from 0.0 to 1.0.
class PoseLandmark {
  final PoseLandmarkType type;
  final double x;
  final double y;
  final double confidence;

  const PoseLandmark({
    required this.type,
    required this.x,
    required this.y,
    required this.confidence,
  });

  /// A keypoint is considered reliably detected above this threshold.
  static const double confidenceThreshold = 0.3;

  bool get isVisible => confidence >= confidenceThreshold;

  @override
  String toString() =>
      'PoseLandmark(${type.name}: x=$x, y=$y, conf=$confidence)';
}
