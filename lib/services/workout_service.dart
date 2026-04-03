import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as dev;
import 'package:smart_trainer/core/providers.dart';
import 'package:smart_trainer/core/ai/models/exercise_feedback.dart';

class WorkoutService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  /// حفظ جلسة تمرين جديدة في Firestore
  Future<void> saveWorkoutSession(WorkoutSessionStats session) async {
    if (_uid == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('workouts')
          .add({
        'exerciseType': session.exerciseType.name,
        'durationSeconds': session.duration.inSeconds,
        'calories': session.calories,
        'reps': session.reps,
        'accuracy': session.accuracy,
        'date': Timestamp.fromDate(session.date),
      });
      dev.log("Workout session saved successfully!");
    } catch (e) {
      dev.log("Error saving workout session: $e");
      rethrow;
    }
  }

  /// الحصول على سجل التمارين الخاص بالمستخدم
  Stream<List<WorkoutSessionStats>> getWorkoutHistory() {
    if (_uid == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('workouts')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return WorkoutSessionStats(
          exerciseType: _parseExerciseType(data['exerciseType']),
          duration: Duration(seconds: data['durationSeconds'] ?? 0),
          calories: data['calories'] ?? 0,
          reps: data['reps'] ?? 0,
          accuracy: data['accuracy'] ?? 0,
          date: (data['date'] as Timestamp).toDate(),
        );
      }).toList();
    });
  }

  ExerciseType _parseExerciseType(String? type) {
    return ExerciseType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => ExerciseType.squat,
    );
  }
}
