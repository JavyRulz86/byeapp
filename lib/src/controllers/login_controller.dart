import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  late final SharedPreferences _prefs;

  AuthController() {
    _initPreferences();
  }

  Future<void> _initPreferences() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Login con Google
  Future<User?> signInWithGoogleIdToken() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (googleAuth.idToken != null) {
        await _prefs.setString('google_id_token', googleAuth.idToken!);
      }

      return userCredential.user;
    } catch (e) {
      print('Google SignIn Error: $e');
      rethrow;
    }
  }

  /// Login con email/password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await _prefs.setString('user_email', email.trim());

      return userCredential.user;
    } catch (e) {
      print('Email SignIn Error: $e');
      rethrow;
    }
  }

  /// Registro con email/password
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await _prefs.setString('user_email', email.trim());

      return userCredential.user;
    } catch (e) {
      print('Registration Error: $e');
      rethrow;
    }
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();

      await _prefs.remove('google_id_token');
      await _prefs.remove('user_email');
    } catch (e) {
      print('SignOut Error: $e');
      rethrow;
    }
  }
}
