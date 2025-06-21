import 'package:firebase_auth/firebase_auth.dart';
import 'package:localstorage/localstorage.dart';

/// Controlador de autenticación para separar la lógica de login del widget UI.
class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocalStorage localStorage = LocalStorage('goodbye_app_storage');

  /// Nueva función: Login con Google usando el id_token capturado en index.html
  Future<User?> signInWithGoogleIdToken() async {
    try {
      await localStorage.ready; // Espera a que el storage esté listo

      // Leemos el token guardado por index.html
      final String? idToken = localStorage.getItem('google_id_token');

      if (idToken == null || idToken.isEmpty) {
        print('No se encontró un token válido en localStorage.');
        return null;
      }

      // Creamos credencial con el token
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // Limpieza del token si se desea
      localStorage.deleteItem('google_id_token');

      return userCredential.user;
    } catch (e) {
      print("Error durante el login con GoogleIdToken: $e");
      return null;
    }
  }

  /// Login con correo y contraseña
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } catch (e) {
      print("Error durante el login con correo: $e");
      return null;
    }
  }

  /// Registro con correo y contraseña
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } catch (e) {
      print("Error durante el registro con correo: $e");
      return null;
    }
  }
}
