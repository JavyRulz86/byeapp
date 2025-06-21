import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/login/login_screen.dart'; // Ajustá el path si tu LoginScreen está en otro archivo

class HomeController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void logout(BuildContext context) async {
    await _auth.signOut();

    // Limpia el stack de navegación y va a la pantalla de login
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  void exploreConnections() {
    print('Explorando conexiones...');
  }

  void goToExpress(BuildContext context, User user) {
    print('Navegar a Express');
    // Ejemplo: Navigator.pushNamed(context, '/express');
  }

  void goToProgramed(BuildContext context, User user) {
    print('Navegar a Programed');
    // Ejemplo: Navigator.pushNamed(context, '/programed');
  }

  void goToLastVibe(BuildContext context, User user) {
    print('Navegar a Last Vibe');
    // Ejemplo: Navigator.pushNamed(context, '/lastVibe');
  }

  void goToUpVibe(BuildContext context, User user) {
    print('Navegar a Up Vibe');
    // Ejemplo: Navigator.pushNamed(context, '/upVibe');
  }

  void goToFriendsScreen(BuildContext context, User user) {
    print('Navegar a Friends Screen');
    // Ejemplo: Navigator.pushNamed(context, '/friends');
  }

  void goToConnectionsScreen(BuildContext context, User user) {
    print('Navegar a Connections Screen');
    // Ejemplo: Navigator.pushNamed(context, '/connections');
  }
}
