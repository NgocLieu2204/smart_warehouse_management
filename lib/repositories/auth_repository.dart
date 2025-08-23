// lib/repositories/auth_repository.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<String?> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final token = await userCredential.user!.getIdToken();
      if (token == null) {
        throw Exception('Failed to retrieve token');
      }
      return token;
    } on FirebaseAuthException catch (e) {
      throw Exception('Login failed: ${e.message}');
    }
  }

  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  Future<String?> register(String email, String password) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final token = await userCredential.user!.getIdToken();
      if (token == null) {
        throw Exception('Failed to retrieve token');
      }
      return token;
    } on FirebaseAuthException catch (e) {
      throw Exception('Registration failed: ${e.message}');
    }
  }

  Future<User?> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // Người dùng đã hủy quá trình đăng nhập
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception('Google login failed: ${e.message}');
    } catch (e) {
      throw Exception('An unknown error occurred during Google sign-in.');
    }
  }

  Future<String?> getCurrentUserToken() async {
    final user = _auth.currentUser;
    if (user != null) {
      return await user.getIdToken();
    }
    return null;
  }
}
