import 'dart:async';
import 'package:camera/camera.dart';

/// Manages the device camera lifecycle and provides a frame stream
/// for real-time pose detection.
class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;

  CameraController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  /// Initializes the back camera at medium resolution.
  Future<void> initialize() async {
    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) {
      throw Exception('No cameras available on this device.');
    }

    // Prefer the back camera for workout tracking.
    final camera = _cameras!.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras!.first,
    );

    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _controller!.initialize();
  }

  /// Starts streaming camera frames. [onFrame] is called for each image.
  ///
  /// Only processes every Nth frame (controlled by [skipFrames]) to avoid
  /// overwhelming the inference pipeline.
  Future<void> startImageStream(
    void Function(CameraImage image) onFrame, {
    int skipFrames = 2,
  }) async {
    if (_controller == null || !isInitialized) return;

    int frameCount = 0;
    await _controller!.startImageStream((CameraImage image) {
      frameCount++;
      if (frameCount % (skipFrames + 1) == 0) {
        onFrame(image);
      }
    });
  }

  /// Stops the image stream.
  Future<void> stopImageStream() async {
    if (_controller == null || !isInitialized) return;
    try {
      await _controller!.stopImageStream();
    } catch (_) {
      // Stream may already be stopped.
    }
  }

  /// Releases all camera resources.
  Future<void> dispose() async {
    await stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }
}
