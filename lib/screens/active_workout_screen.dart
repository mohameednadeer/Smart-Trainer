import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import 'package:smart_trainer/core/ai/models/pose_result.dart';
import 'package:smart_trainer/core/providers.dart';
import 'package:smart_trainer/theme/app_colors.dart';
import 'package:smart_trainer/screens/training_screen.dart';
import 'package:smart_trainer/widgets/skeleton_painter.dart';
import 'package:smart_trainer/widgets/pose_feedback_overlay.dart';

import 'package:smart_trainer/core/ai/models/exercise_feedback.dart' show ExerciseType;
export 'package:smart_trainer/core/ai/models/exercise_feedback.dart'
    show ExerciseType;
class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen>
    with WidgetsBindingObserver {
  bool _isInitializing = true;
  String? _errorMessage;

  // Timer
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _uiTimer;
  String _elapsedTime = '00:00';

  // Inference throttle — avoid queuing up frames while one is processing.
  bool _isProcessingFrame = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      final cameraService = ref.read(cameraServiceProvider);
      final poseDetector = ref.read(poseDetectorProvider);

      // Reset exercise evaluator for a fresh session.
      ref.read(exerciseEvaluatorProvider).reset();

      // Initialize camera and model in parallel.
      await Future.wait([
        cameraService.initialize(),
        poseDetector.initialize(),
      ]);

      // Start frame stream → inference pipeline.
      await cameraService.startImageStream(
        (image) => _onCameraFrame(image),
        skipFrames: 2, // Process every 3rd frame.
      );

      // Start elapsed time timer.
      _stopwatch.start();
      _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {
            final elapsed = _stopwatch.elapsed;
            _elapsedTime =
                '${elapsed.inMinutes.toString().padLeft(2, '0')}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
          });
        }
      });

      if (mounted) setState(() => _isInitializing = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _onCameraFrame(CameraImage image) async {
    if (_isProcessingFrame) return;
    _isProcessingFrame = true;

    try {
      final poseDetector = ref.read(poseDetectorProvider);
      final result = await poseDetector.processFrame(image);

      if (mounted) {
        ref.read(poseResultProvider.notifier).state = result;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "AI Error: $e";
        });
      }
    } finally {
      _isProcessingFrame = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraService = ref.read(cameraServiceProvider);

    if (state == AppLifecycleState.inactive) {
      _stopwatch.stop();
      cameraService.stopImageStream();
    } else if (state == AppLifecycleState.resumed) {
      _stopwatch.start();
      cameraService.startImageStream(
        (image) => _onCameraFrame(image),
        skipFrames: 2,
      );
    }
  }

  Future<void> _handleStop() async {
    _stopwatch.stop();
    _uiTimer?.cancel();

    final cameraService = ref.read(cameraServiceProvider);
    await cameraService.stopImageStream();

    if (mounted) context.go('/workout_result');
  }

  Future<void> _switchCamera() async {
    if (_isInitializing) return;
    
    setState(() => _isInitializing = true);
    
    try {
      final cameraService = ref.read(cameraServiceProvider);
      await cameraService.switchCamera(
        (image) => _onCameraFrame(image),
        skipFrames: 2,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to switch camera: $e";
        });
      }
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopwatch.stop();
    _uiTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final poseResult = ref.watch(poseResultProvider);
    final feedback = ref.watch(exerciseFeedbackProvider);
    final cameraService = ref.watch(cameraServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Preview / Loading / Error
          if (_isInitializing)
            _buildLoadingState()
          else if (_errorMessage != null)
            _buildErrorState()
          else if (cameraService.controller != null &&
              cameraService.isInitialized)
            _buildCameraPreview(cameraService.controller!, poseResult),

          // 2. Background Grid (semi-transparent over camera)
          CustomPaint(
            size: Size.infinite,
            painter: GridPainter(),
          ),

          // 3. Corner Brackets
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: CustomPaint(
                painter: CornerBracketsPainter(
                  color: AppColors.electricBlue,
                  length: 32.0,
                  strokeWidth: 2.0,
                ),
                child: Container(),
              ),
            ),
          ),

          // 4. UI Overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ── Top Section ──
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Side (Close + Switch Camera)
                          Row(
                            children: [
                              // Close Button
                              Container(
                                margin: const EdgeInsets.only(top: 4, left: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(LucideIcons.x,
                                      color: Colors.white, size: 24),
                                  onPressed: () => context.go('/dashboard'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Switch Camera Button
                              Container(
                                margin: const EdgeInsets.only(top: 4, left: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.cameraswitch,
                                      color: Colors.white, size: 24),
                                  onPressed: _switchCamera,
                                ),
                              ),
                            ],
                          ),

                          // Heart Rate Indicator
                          Container(
                            margin: const EdgeInsets.only(top: 4, right: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: AppColors.biometricRed
                                    .withValues(alpha: 0.5),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.biometricRed
                                      .withValues(alpha: 0.3),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.heart,
                                    color: AppColors.biometricRed, size: 18),
                                const SizedBox(width: 8),
                                const Text(
                                  '68 BPM',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Stats Row (Time, Reps, Accuracy)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStatBox('TIME', _elapsedTime, Colors.white),
                          const SizedBox(width: 16),
                          _buildStatBox('REPS', '${feedback.repCount}',
                              AppColors.electricBlue),
                          const SizedBox(width: 16),
                          _buildStatBox(
                            'ACCURACY',
                            feedback.isCorrect ? '✓' : '✗',
                            feedback.isCorrect
                                ? AppColors.neonGreen
                                : AppColors.biometricRed,
                          ),
                        ],
                      ),
                    ],
                  ),

                  // ── Center: Feedback Banner ──
                  PoseFeedbackOverlay(feedback: feedback),

                  // ── Bottom Content ──
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Stop & View Results Button
                      SizedBox(
                        width: 280,
                        child: ElevatedButton(
                          onPressed: _handleStop,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.biometricRed,
                            shadowColor:
                                AppColors.biometricRed.withValues(alpha: 0.5),
                            elevation: 16,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'Stop & View Results',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Exercise Pill (read-only display)
                      Consumer(
                        builder: (context, ref, _) {
                          final exercise = ref.watch(selectedExerciseProvider);
                          final label = exercise == ExerciseType.squat
                              ? 'Squat Exercise'
                              : 'Push-up Exercise';
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                color: AppColors.electricBlue
                                    .withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.activity,
                                    color: AppColors.electricBlue, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  label,
                                  style: const TextStyle(
                                    color: AppColors.electricBlue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(LucideIcons.zap,
                                    color: AppColors.neonGreen, size: 18),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────── Camera Preview + Skeleton ───────────────────

  Widget _buildCameraPreview(
      CameraController controller, PoseResult poseResult) {
    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.previewSize?.height ?? 1,
            height: controller.value.previewSize?.width ?? 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(controller),
                // Skeleton overlay
                if (poseResult.isNotEmpty)
                  CustomPaint(
                    painter: SkeletonPainter(
                      poseResult: poseResult,
                      imageSize: Size(
                        controller.value.previewSize?.height ?? 1,
                        controller.value.previewSize?.width ?? 1,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────── Loading State ───────────────────

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: AppColors.electricBlue,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Initializing camera & AI model…',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────── Error State ───────────────────

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.alertTriangle,
                color: AppColors.biometricRed, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Failed to initialize',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isInitializing = true;
                  _errorMessage = null;
                });
                _initializeServices();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.electricBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Retry',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────── Stat Box ───────────────────

  Widget _buildStatBox(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.8),
              fontSize: 10,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

