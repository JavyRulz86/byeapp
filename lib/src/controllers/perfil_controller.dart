import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PerfilController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Actualiza nombre, imagen y contactos
  Future<void> actualizarPerfil({
    required String nombre,
    File? nuevaImagen,
    required List<Map<String, String>> contactos,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Usuario no autenticado");

    String? nuevaUrl;

    // Subir imagen si se seleccionó una nueva
    if (nuevaImagen != null) {
      final ref = _storage.ref().child('perfiles/${user.uid}/avatar.jpg');
      await ref.putFile(nuevaImagen);
      nuevaUrl = await ref.getDownloadURL();
    }

    // Actualizar displayName y photoURL en Firebase Auth
    await user.updateDisplayName(nombre);
    if (nuevaUrl != null) {
      await user.updatePhotoURL(nuevaUrl);
    }

    // Guardar contactos en Firestore
    final datos = {
      "contactos": contactos
          .where((c) => c["nombre"]!.isNotEmpty || c["email"]!.isNotEmpty)
          .toList(),
    };

    await _firestore
        .collection('usuarios')
        .doc(user.uid)
        .set(datos, SetOptions(merge: true));
  }

  /// Obtener contactos guardados (si se quiere mostrar al iniciar)
  Future<List<Map<String, String>>> obtenerContactosGuardados() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Usuario no autenticado");

    final doc = await _firestore.collection('usuarios').doc(user.uid).get();
    if (doc.exists && doc.data()?["contactos"] != null) {
      return List<Map<String, String>>.from(doc["contactos"]);
    } else {
      return List.generate(5, (_) => {"nombre": "", "email": ""});
    }
  }
}
