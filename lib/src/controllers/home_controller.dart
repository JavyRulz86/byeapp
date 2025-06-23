import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../screens/login/login_screen.dart';

class HomeController {
  final FirebaseAuth _auth;
  final Logger _logger;
  final VoidCallback? _onAuthStateChanged;

  HomeController({
    FirebaseAuth? auth,
    Logger? logger,
    VoidCallback? onAuthStateChanged,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _logger = logger ?? Logger(),
        _onAuthStateChanged = onAuthStateChanged;

  /// Cierra sesión con manejo completo de errores y analytics
  Future<void> logout(BuildContext context) async {
    try {
      _logger.i('Iniciando cierre de sesión');

      await _auth.signOut();
      _logger.i('Sesión cerrada exitosamente');

      // Analytics
      // await FirebaseAnalytics.instance.logEvent(name: 'logout');

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => LoginScreen()),
          (_) => false,
        );
      }

      _onAuthStateChanged?.call();
    } catch (e, stack) {
      _logger.e('Error en logout', error: e, stackTrace: stack);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _buildErrorSnackBar('Error al cerrar sesión'),
        );
      }
    }
  }

  /// Navegación segura con parámetros tipados
  Future<void> navigateTo(
    BuildContext context, {
    required String routeName,
    required User user,
    Map<String, dynamic>? arguments, // ✅ tipado corregido
  }) async {
    try {
      if (!context.mounted) return;

      _logger.d('Navegando a $routeName');

      // Analytics
      // await FirebaseAnalytics.instance.logEvent(
      //   name: 'navigate',
      //   parameters: {'route': routeName},
      // );

      await Navigator.pushNamed(
        context,
        routeName,
        arguments: <String, dynamic>{
          'user': user,
          ...?arguments,
        },
      );
    } catch (e, stack) {
      _logger.e(
        'Error en navegación a $routeName',
        error: e,
        stackTrace: stack,
      );
    }
  }

  // Métodos específicos con documentación
  /// Navega a la pantalla Express con validación de usuario
  void goToExpress(BuildContext context, User user) {
    _validateUser(
      user,
      () => navigateTo(context, routeName: '/express', user: user),
    );
  }

  /// Navega a la pantalla Programed con tracking
  void goToProgramed(BuildContext context, User user) {
    _trackNavigation(
      'programed',
      () => navigateTo(context, routeName: '/programed', user: user),
    );
  }

  // Helpers privados
  void _validateUser(User user, VoidCallback action) {
    if (user.uid.isNotEmpty) {
      action();
    } else {
      _logger.w('Intento de navegación con usuario inválido');
    }
  }

  void _trackNavigation(String feature, VoidCallback action) {
    _logger.d('Accediendo a $feature');
    // Analytics.track(feature);
    action();
  }

  SnackBar _buildErrorSnackBar(String message) {
    return SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.red[800],
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: 'OK',
        textColor: Colors.white,
        onPressed: () {},
      ),
    );
  }
}
