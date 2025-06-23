import 'package:firebase_auth/firebase_auth.dart';
import 'package:localstorage/localstorage.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocalStorage _storage = LocalStorage('goodbye_app_storage');

  /// Login con Google usando el ID Token (GIS moderno)
  Future<User?> signInWithGoogleIdToken() async {
    try {
      await _storage.ready;

      final String? idToken = _storage.getItem('google_id_token');
      if (idToken == null || idToken.isEmpty) {
        throw Exception('No Google ID Token found in storage');
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final userCredential = await _auth.signInWithCredential(credential);

      _storage.deleteItem('google_id_token'); // Limpieza segura
      return userCredential.user;
    } catch (e) {
      print('Google SignIn Error: ${e.toString()}');
      rethrow; // Permite manejar el error en el UI
    }
  }

  /// Login con email/password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print('Email SignIn Error: ${e.toString()}');
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
      return userCredential.user;
    } catch (e) {
      print('Registration Error: ${e.toString()}');
      rethrow;
    }
  }
}
