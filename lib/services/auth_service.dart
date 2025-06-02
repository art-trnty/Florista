import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static Future<bool> checkIfAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (snapshot.exists) {
        final data = snapshot.data();
        return data?['role'] == 'Admin';
      }
    }
    return false;
  }

  static Future<void> updateProfilePicture(String imageUrl) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'profile_picture': imageUrl},
      );
    }
  }

  static Future<String> getProfilePicture() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (snapshot.exists) {
        final data = snapshot.data();
        return data?['profile_picture'] ?? "";
      }
    }
    return "";
  }

  static String? get currentUserUid => FirebaseAuth.instance.currentUser?.uid;
}
