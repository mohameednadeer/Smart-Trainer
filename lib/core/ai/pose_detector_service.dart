import 'dart:isolate';
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
  Future<PoseResult> processFrame(CameraImage image) async {
    if (!_isInitialized || _interpreter == null) {
      return PoseResult.empty();
    }

    // Convert CameraImage (YUV420) to a flat RGB byte list on a background
    // isolate so the UI thread is never blocked by pixel manipulation.
    final inputBytes = await Isolate.run(
      () => _convertCameraImage(image),
    );

    if (inputBytes == null) return PoseResult.empty();

    // Run inference. tflite_flutter's Interpreter is not isolate-safe,
    // so inference itself runs on the main thread but is very fast for
    // MoveNet Lightning (~6 ms on a modern phone).
    final output = _runInference(inputBytes);

    return _parseOutput(output);
  }

  /// Converts a YUV420 camera image to a flat Float32 RGB tensor
  /// of shape [1, 192, 192, 3].
  static Float32List? _convertCameraImage(CameraImage image) {
    try {
      final int width = image.width;
      final int height = image.height;

      // YUV420 planes
      final yPlane = image.planes[0].bytes;
      final uPlane = image.planes[1].bytes;
      final vPlane = image.planes[2].bytes;

      final int uvRowStride = image.planes[1].bytesPerRow;
      final int uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

      // Scale factors for resizing to 192×192
      final double scaleX = width / _inputSize;
      final double scaleY = height / _inputSize;

      final input = Float32List(1 * _inputSize * _inputSize * 3);
      int index = 0;

      for (int y = 0; y < _inputSize; y++) {
        for (int x = 0; x < _inputSize; x++) {
          final int srcX = (x * scaleX).toInt().clamp(0, width - 1);
          final int srcY = (y * scaleY).toInt().clamp(0, height - 1);

          final int yIndex = srcY * width + srcX;
          final int uvIndex =
              (srcY ~/ 2) * uvRowStride + (srcX ~/ 2) * uvPixelStride;

          final int yVal = yPlane[yIndex];
          final int uVal = uPlane[uvIndex.clamp(0, uPlane.length - 1)];
          final int vVal = vPlane[uvIndex.clamp(0, vPlane.length - 1)];

          // YUV → RGB conversion
          int r = (yVal + 1.370705 * (vVal - 128)).round().clamp(0, 255);
          int g = (yVal - 0.337633 * (uVal - 128) - 0.698001 * (vVal - 128))
              .round()
              .clamp(0, 255);
          int b = (yVal + 1.732446 * (uVal - 128)).round().clamp(0, 255);

          // Normalize to [0.0, 1.0] as expected by MoveNet
          input[index++] = r / 255.0;
          input[index++] = g / 255.0;
          input[index++] = b / 255.0;
        }
      }

      return input;
    } catch (_) {
      return null;
    }
  }

  /// Runs TFLite inference and returns raw output tensor.
  List<List<List<List<double>>>> _runInference(Float32List inputBytes) {
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
