// import 'package:firebase_auth/firebase_auth.dart';

// class AuthService {
//   final _auth = FirebaseAuth.instance;

//   Future<String?> signIn(String email, String password) async {
//     try {
//       await _auth.signInWithEmailAndPassword(email: email, password: password);
//       return null;
//     } on FirebaseAuthException catch (e) {
//       return e.message;
//     }
//   }

//   Future<String?> signUp(String email, String password) async {
//     try {
//       await _auth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//       return null;
//     } on FirebaseAuthException catch (e) {
//       return e.message;
//     }
//   }

//   Future<void> signOut() async => _auth.signOut();
// }

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signIn(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return result.user;
  }

  Future<User?> signUp(String email, String password) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return result.user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
