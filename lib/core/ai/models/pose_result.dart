import 'pose_landmark.dart';

/// The complete pose estimation result from a single frame.
///
/// Contains all 17 MoveNet keypoints with their positions and confidence
/// scores, plus a [timestamp] for frame tracking.
class PoseResult {
  final List<PoseLandmark> landmarks;
  final DateTime timestamp;

  const PoseResult({
    required this.landmarks,
    required this.timestamp,
  });

  /// Creates an empty result (no detection).
  factory PoseResult.empty() => PoseResult(
        landmarks: [],
        timestamp: DateTime.now(),
      );

  bool get isEmpty => landmarks.isEmpty;
  bool get isNotEmpty => landmarks.isNotEmpty;

  // ── Convenience getters for key body parts ──

  PoseLandmark? _landmarkOf(PoseLandmarkType type) {
    try {
      return landmarks.firstWhere((l) => l.type == type);
    } catch (_) {
      return null;
    }
  }

  PoseLandmark? get nose => _landmarkOf(PoseLandmarkType.nose);

  PoseLandmark? get leftShoulder =>
      _landmarkOf(PoseLandmarkType.leftShoulder);
  PoseLandmark? get rightShoulder =>
      _landmarkOf(PoseLandmarkType.rightShoulder);

  PoseLandmark? get leftElbow => _landmarkOf(PoseLandmarkType.leftElbow);
  PoseLandmark? get rightElbow => _landmarkOf(PoseLandmarkType.rightElbow);

  PoseLandmark? get leftWrist => _landmarkOf(PoseLandmarkType.leftWrist);
  PoseLandmark? get rightWrist => _landmarkOf(PoseLandmarkType.rightWrist);

  PoseLandmark? get leftHip => _landmarkOf(PoseLandmarkType.leftHip);
  PoseLandmark? get rightHip => _landmarkOf(PoseLandmarkType.rightHip);

  PoseLandmark? get leftKnee => _landmarkOf(PoseLandmarkType.leftKnee);
  PoseLandmark? get rightKnee => _landmarkOf(PoseLandmarkType.rightKnee);

  PoseLandmark? get leftAnkle => _landmarkOf(PoseLandmarkType.leftAnkle);
  PoseLandmark? get rightAnkle => _landmarkOf(PoseLandmarkType.rightAnkle);
}
