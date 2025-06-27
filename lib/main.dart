import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:logger/logger.dart';
import 'package:goodbye_app/src/screens/login/login_screen.dart';
import 'firebase_options.dart'; // Asegúrate de que este archivo existe

// Configuración global
final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
final FirebaseAnalyticsObserver observer =
    FirebaseAnalyticsObserver(analytics: analytics);
final Logger logger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
  ),
);

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options:
          DefaultFirebaseOptions.currentPlatform, // Usa las opciones generadas
    );

    // Configura Crashlytics
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

    // Configura Analytics
    await analytics.setAnalyticsCollectionEnabled(true);
    await analytics.setUserId(id: 'pre_login_user');
    await analytics.setUserProperty(name: 'app_version', value: '1.0.0');

    logger.i('Firebase inicializado correctamente');
  } catch (e, stack) {
    logger.e('Error al inicializar Firebase', error: e, stackTrace: stack);
    FirebaseCrashlytics.instance.recordError(e, stack);
    rethrow;
  }
}

Future<void> _logAppStart() async {
  try {
    await analytics.logAppOpen();
    await analytics.logEvent(
      name: 'app_start',
      parameters: {'time': DateTime.now().toIso8601String()},
    );
    logger.d('Evento de inicio registrado');
  } catch (e, stack) {
    logger.e('Error registrando inicio', error: e, stackTrace: stack);
    FirebaseCrashlytics.instance.recordError(e, stack);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configuración global de manejo de errores
  FlutterError.onError = (details) {
    logger.e('Error no capturado',
        error: details.exception, stackTrace: details.stack);
    FirebaseCrashlytics.instance.recordFlutterError(details);
  };

  try {
    await _initializeFirebase();
    await _logAppStart();
    runApp(const GoodbyeApp());
  } catch (e, stack) {
    logger.e('Error crítico en la inicialización', error: e, stackTrace: stack);
    FirebaseCrashlytics.instance.recordError(e, stack);
    runApp(const ErrorApp());
  }
}

class GoodbyeApp extends StatelessWidget {
  const GoodbyeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GoodBye App',
      debugShowCheckedModeBanner: false,
      theme: _buildAppTheme(),
      home: const LoginScreen(),
      navigatorObservers: [observer],
      builder: (context, child) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: child,
        );
      },
    );
  }

  ThemeData _buildAppTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 2,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.grey[100],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/error_icon.png', height: 120),
                const SizedBox(height: 24),
                Text(
                  '¡Ups! Algo salió mal',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.red[700],
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No pudimos iniciar la aplicación correctamente. '
                  'Por favor, inténtalo nuevamente.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                      onPressed: () => main(),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 16),
                    TextButton.icon(
                      icon: const Icon(Icons.email),
                      label: const Text('Reportar'),
                      onPressed: _sendErrorReport,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _sendErrorReport() {
    logger.i('Reporte de error enviado');
    // Implementar lógica de reporte si es necesario
  }
}

extension AnalyticsLogging on BuildContext {
  Future<void> logScreenView(String screenName) async {
    try {
      await analytics.logScreenView(screenName: screenName);
      logger.d('Vista registrada: $screenName');
    } catch (e, stack) {
      logger.e('Error registrando vista', error: e, stackTrace: stack);
      FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }

  Future<void> logCustomEvent(String name,
      {Map<String, Object>? parameters}) async {
    try {
      await analytics.logEvent(name: name, parameters: parameters);
      logger.d('Evento registrado: $name');
    } catch (e, stack) {
      logger.e('Error registrando evento', error: e, stackTrace: stack);
      FirebaseCrashlytics.instance.recordError(e, stack);
    }
  }
}
