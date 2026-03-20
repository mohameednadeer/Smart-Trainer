import 'dart:math';
import 'models/pose_landmark.dart';

/// Pure math utility for computing angles between body joints.
class AngleCalculator {
  const AngleCalculator._();

  /// Computes the angle (in degrees) at joint [b], formed by segments
  /// [a]→[b] and [b]→[c].
  ///
  /// Returns a value between 0° and 180°.
  /// Returns `null` if any landmark has low confidence.
  static double? calculateAngle(
    PoseLandmark? a,
    PoseLandmark? b,
    PoseLandmark? c,
  ) {
    if (a == null || b == null || c == null) return null;
    if (!a.isVisible || !b.isVisible || !c.isVisible) return null;

    final radians = atan2(c.y - b.y, c.x - b.x) -
        atan2(a.y - b.y, a.x - b.x);

    var degrees = (radians * 180.0 / pi).abs();
    if (degrees > 180.0) {
      degrees = 360.0 - degrees;
    }
    return degrees;
  }
}
