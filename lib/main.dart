import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:goodbye_app/src/screens/login/login_screen.dart'; // <- este es tu LoginScreen separado

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyCYGOOo-RncP1uSYvY-F5tqXWO39o3ngyI",
      appId: "1:1003537024990:web:77b8d3170c23ba296f3f4f",
      messagingSenderId: "1003537024990",
      projectId: "goodbye-ae882",
      authDomain: "goodbye-ae882.firebaseapp.com",
      storageBucket: "goodbye-ae882.appspot.com",
      measurementId: "G-LVXCN2PE2H",
    ),
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GoodBye App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginScreen(),
      // Si tienes rutas definidas, agrégalas aquí:
      // initialRoute: '/',
      // routes: routes,
      // onGenerateRoute: onGenerateRoute,
    );
  }
}
