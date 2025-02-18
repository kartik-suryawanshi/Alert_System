import 'package:alert_system/UI/screens/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:alert_system/UI/auth/login_screen.dart';
import 'package:alert_system/UI/register_page.dart';
import 'package:alert_system/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';  // Import FirebaseAuth for user session check

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "SafeGuardHer",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
      ),
      initialRoute: FirebaseAuth.instance.currentUser == null ? '/login' : '/home', // Check if the user is logged in
      routes: {
        '/register': (context) => const RegisterPage(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => HomeScreen(), // HomeScreen if user is logged in
      },
    );
  }
}
