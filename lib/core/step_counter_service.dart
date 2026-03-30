import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Step counter that communicates with native Android TYPE_STEP_DETECTOR
/// via Platform Channels for real-time, per-step updates.
///
/// TYPE_STEP_DETECTOR fires immediately for each individual step,
/// unlike TYPE_STEP_COUNTER which Samsung batches aggressively.
class StepCounterService {
  static const _methodChannel = MethodChannel('com.smart_trainer/steps');
  static const _eventChannel = EventChannel('com.smart_trainer/steps_stream');

  static const String _keyTodayDate = 'step_date';
  static const String _keyTodaySteps = 'step_today_count';

  final _stepController = StreamController<int>.broadcast();
  StreamSubscription? _nativeSubscription;

  int _baselineSteps = 0;  // Steps loaded from disk (before this session)
  int _lastPersisted = 0;

  Stream<int> get stepStream => _stepController.stream;
  int get currentSteps => _baselineSteps;

  /// Initialize: load today's persisted count, reset native counter, start stream.
  Future<void> initialize() async {
    await _loadTodaySteps();
    await _resetNativeCounter();
    _startNativeStream();
  }

  /// Load persisted step count for today (survives app restart).
  Future<void> _loadTodaySteps() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(_keyTodayDate) ?? '';
    final today = _dayKey();

    if (savedDate == today) {
      _baselineSteps = prefs.getInt(_keyTodaySteps) ?? 0;
    } else {
      _baselineSteps = 0;
      await prefs.setString(_keyTodayDate, today);
      await prefs.setInt(_keyTodaySteps, 0);
    }
    _lastPersisted = _baselineSteps;
  }

  /// Reset the native step counter to 0 so it counts fresh from now.
  Future<void> _resetNativeCounter() async {
    try {
      await _methodChannel.invokeMethod('resetSteps');
    } catch (e) {
      debugPrint('[StepCounter] Reset error: $e');
    }
  }

  /// Listen to per-step events from native Android.
  void _startNativeStream() {
    _nativeSubscription?.cancel();
    _nativeSubscription = _eventChannel.receiveBroadcastStream().listen(
      (event) {
        if (event is int) {
          // event = steps counted by native since resetSteps()
          // total today = baseline (from disk) + native session steps
          final total = _baselineSteps + event;

          // Persist every 5 steps to avoid excessive disk writes
          if (total - _lastPersisted >= 5) {
            _persistSteps(total);
            _lastPersisted = total;
          }

          _stepController.add(total);
        }
      },
      onError: (error) {
        debugPrint('[StepCounter] Stream error: $error');
      },
    );
  }

  Future<void> _persistSteps(int steps) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTodayDate, _dayKey());
    await prefs.setInt(_keyTodaySteps, steps);
  }

  String _dayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  Future<void> dispose() async {
    // Persist final count before shutting down
    try {
      final nativeSteps = await _methodChannel.invokeMethod<int>('getSteps') ?? 0;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyTodaySteps, _baselineSteps + nativeSteps);
    } catch (_) {}

    await _nativeSubscription?.cancel();
    await _stepController.close();
  }
}
