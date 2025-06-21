import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:goodbye_app/src/controllers/login_controller.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final authController = AuthController();

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  Future<void> _handleGoogleLogin() async {
    // Nueva implementación: login por ID Token capturado desde index.html
    User? user = await authController.signInWithGoogleIdToken();
    if (user != null) {
      _goToHome(user);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo iniciar sesión con Google.')),
      );
    }
  }

  Future<void> _handleEmailLogin() async {
    User? user = await authController.signInWithEmail(
      emailController.text.trim(),
      passwordController.text,
    );
    if (user != null) {
      _goToHome(user);
    }
  }

  Future<void> _handleEmailRegister() async {
    if (emailController.text.isEmpty || passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ingrese un correo válido y una contraseña de al menos 6 caracteres.',
          ),
        ),
      );
      return;
    }

    User? user = await authController.registerWithEmail(
      emailController.text.trim(),
      passwordController.text,
    );

    if (user != null) {
      _goToHome(user);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al registrarse')));
    }
  }

  void _goToHome(User user) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen(user: user)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset('assets/logo.png', height: 150),
            SizedBox(height: 40),

            _buildGradientButton(
              'Iniciar sesión con Google',
              _handleGoogleLogin,
            ),
            SizedBox(height: 20),

            _buildTextField(emailController, 'Correo Electrónico'),
            _buildTextField(
              passwordController,
              'Contraseña',
              obscureText: true,
            ),
            SizedBox(height: 20),

            _buildGradientButton(
              'Iniciar sesión con Correo Electrónico',
              _handleEmailLogin,
            ),
            SizedBox(height: 15),

            _buildGradientButton(
              'Registrarse con Correo Electrónico',
              _handleEmailRegister,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientButton(String text, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(255, 51, 129, 244),
              Colors.lightBlue,
              Colors.cyan,
              Colors.white,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool obscureText = false,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(64),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.blueAccent,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        ),
      ),
    );
  }
}
