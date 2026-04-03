import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream لمراقبة حالة تسجيل الدخول للمستخدم
  Stream<User?> get userStream => _auth.authStateChanges();

  // الحصول على المستخدم الحالي
  User? get currentUser => _auth.currentUser;

  /// وظيفة تسجيل مستخدم جديد (Sign Up)
  Future<UserCredential?> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    required int age,
    required double weight,
    required double height,
    required String gender,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // حفظ بيانات المستخدم الإضافية في Firestore
      if (credential.user != null) {
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'uid': credential.user!.uid,
          'name': name,
          'email': email,
          'phone': phone,
          'age': age,
          'weight': weight,
          'height': height,
          'gender': gender,
          'createdAt': FieldValue.serverTimestamp(),
          'profileCompleted': true,
        });
      }


      return credential;
    } on FirebaseAuthException catch (e) {
      dev.log("Error during Sign Up: ${e.message}");
      rethrow;
    } catch (e) {
      dev.log("Generic error during Sign Up: $e");
      rethrow;
    }
  }

  /// الحصول على بيانات المستخدم من Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      dev.log("Error fetching user data: $e");
      return null;
    }
  }

  /// تحديث بيانات المستخدم في Firestore
  Future<void> updateUserData(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update(data);
        dev.log("User data updated successfully in Firestore");
      } catch (e) {
        dev.log("Error updating user data: $e");
        rethrow;
      }
    }
  }

  /// وظيفة تسجيل الدخول (Login)
  Future<UserCredential?> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      dev.log("Error during Login: ${e.message}");
      rethrow;
    } catch (e) {
      dev.log("Generic error during Login: $e");
      rethrow;
    }
  }

  /// وظيفة تسجيل الخروج (Sign Out)
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      dev.log("Error during Sign Out: $e");
      rethrow;
    }
  }

  /// إرسال رابط استعادة كلمة المرور
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      dev.log("Error sending password reset email: $e");
      rethrow;
    }
  }
}

