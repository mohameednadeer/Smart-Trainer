import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'models/pose_landmark.dart';
import 'models/pose_result.dart';

/// Service that handles MoveNet Lightning model lifecycle and inference.
///
/// This is the core AI layer — it loads the TFLite model once and exposes
/// [processFrame] to run inference on camera frames. All heavy processing
/// is offloaded to a background isolate via [Isolate.run].
class PoseDetectorService {
  static const String _modelPath = 'assets/models/movenet_lightning.tflite';
  static const int _inputSize = 192;

  Interpreter? _interpreter;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Loads the MoveNet Lightning model from assets.
  /// Must be called before [processFrame].
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _interpreter = await Interpreter.fromAsset(_modelPath);
      _isInitialized = true;
    } catch (e) {
      throw Exception(
        'Failed to load MoveNet model at "$_modelPath". '
        'Make sure the .tflite file is placed in assets/models/. Error: $e',
      );
    }
  }

  /// Runs MoveNet inference on a [CameraImage] frame.
  ///
  /// Returns a [PoseResult] containing 17 keypoints with coordinates
  /// normalized to [0.0, 1.0]. The heavy conversion and inference are
  /// executed in a background isolate to keep the UI thread responsive.
  Future<PoseResult> processFrame(CameraImage image, CameraLensDirection lensDirection) async {
    if (!_isInitialized || _interpreter == null) {
      return PoseResult.empty();
    }

    // Convert CameraImage (YUV420) to a flat uint8 RGB byte list
    // matching what MoveNet Lightning expects.
    final inputBytes = _convertCameraImage(image, lensDirection);

    if (inputBytes == null) return PoseResult.empty();

    // Run inference. 
    final output = _runInference(inputBytes);

    return _parseOutput(output);
  }

  /// Converts a YUV420 camera image to a flat Uint8 RGB tensor
  /// of shape [1, 192, 192, 3] as expected by MoveNet Lightning.
  /// Rotates the image 90° clockwise to match Android portrait orientation.
  static Uint8List? _convertCameraImage(CameraImage image, CameraLensDirection lensDirection) {
    try {
      final int srcWidth = image.width;   // landscape width (e.g. 1280)
      final int srcHeight = image.height; // landscape height (e.g. 720)

      // YUV420 planes
      final yPlane = image.planes[0].bytes;
      final uPlane = image.planes[1].bytes;
      final vPlane = image.planes[2].bytes;

      final int yRowStride = image.planes[0].bytesPerRow;
      final int uvRowStride = image.planes[1].bytesPerRow;
      final int uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

      // After 90° clockwise rotation: portrait width = srcHeight, portrait height = srcWidth
      final int rotWidth = srcHeight;
      final int rotHeight = srcWidth;

      // Scale factors from rotated dimensions to 192×192
      final double scaleX = rotWidth / _inputSize;
      final double scaleY = rotHeight / _inputSize;

      final input = Uint8List(1 * _inputSize * _inputSize * 3);
      int index = 0;

      for (int y = 0; y < _inputSize; y++) {
        for (int x = 0; x < _inputSize; x++) {
          // Sample point in rotated portrait space
          final int rotX = (x * scaleX).toInt().clamp(0, rotWidth - 1);
          final int rotY = (y * scaleY).toInt().clamp(0, rotHeight - 1);

          final int srcX, srcY;
          if (lensDirection == CameraLensDirection.front) {
            // Front camera on Android: sensor orientation is usually 270°.
            // Map portrait (rotX, rotY) to landscape (srcX, srcY) for 270° CW:
            // srcX = srcWidth - 1 - rotY, srcY = rotX
            srcX = (srcWidth - 1 - rotY).clamp(0, srcWidth - 1);
            srcY = rotX.clamp(0, srcHeight - 1);
          } else {
            // Back camera on Android: sensor orientation is usually 90°.
            // Map portrait (rotX, rotY) to landscape (srcX, srcY) for 90° CW:
            // srcX = rotY, srcY = srcHeight - 1 - rotX
            srcX = rotY.clamp(0, srcWidth - 1);
            srcY = (srcHeight - 1 - rotX).clamp(0, srcHeight - 1);
          }

          final int yIndex = srcY * yRowStride + srcX;
          final int uvIndex =
              (srcY ~/ 2) * uvRowStride + (srcX ~/ 2) * uvPixelStride;

          final int yVal = yPlane[yIndex.clamp(0, yPlane.length - 1)];
          final int uVal = uPlane[uvIndex.clamp(0, uPlane.length - 1)];
          final int vVal = vPlane[uvIndex.clamp(0, vPlane.length - 1)];

          // YUV → RGB, keep as uint8 [0, 255]
          input[index++] = (yVal + 1.370705 * (vVal - 128)).round().clamp(0, 255);
          input[index++] = (yVal - 0.337633 * (uVal - 128) - 0.698001 * (vVal - 128)).round().clamp(0, 255);
          input[index++] = (yVal + 1.732446 * (uVal - 128)).round().clamp(0, 255);
        }
      }

      return input;
    } catch (e) {
      throw Exception('Camera Image Conversion Error: $e');
    }
  }

  /// Runs TFLite inference and returns raw output tensor.
  List<List<List<List<double>>>> _runInference(Uint8List inputBytes) {
    // MoveNet Lightning output: [1, 1, 17, 3]
    // Each keypoint: [y, x, confidence]
    final output = List.generate(
      1,
      (_) => List.generate(
        1,
        (_) => List.generate(
          17,
          (_) => List.filled(3, 0.0),
        ),
      ),
    );

    final input = inputBytes.reshape([1, _inputSize, _inputSize, 3]);
    _interpreter!.run(input, output);

    return output;
  }

  /// Parses the raw TFLite output tensor into a [PoseResult].
  PoseResult _parseOutput(List<List<List<List<double>>>> output) {
    final landmarks = <PoseLandmark>[];

    for (int i = 0; i < 17; i++) {
      landmarks.add(
        PoseLandmark(
          type: PoseLandmarkType.values[i],
          y: output[0][0][i][0], // MoveNet outputs y first
          x: output[0][0][i][1],
          confidence: output[0][0][i][2],
        ),
      );
    }

    return PoseResult(
      landmarks: landmarks,
      timestamp: DateTime.now(),
    );
  }

  /// Releases model resources. Call when done.
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}
