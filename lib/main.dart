import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

import 'auth/auth_landing.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const VoyagePHApp());
}

class VoyagePHApp extends StatelessWidget {
  const VoyagePHApp({super.key});

  static const Color primaryBlue = Color(0xFF4B7B9A);
  static const Color softGray = Color(0xFFF3F6F8);

  @override
  Widget build(BuildContext context) {
    return Provider<FirebaseAuth>(
      create: (_) => FirebaseAuth.instance,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'VoyagePH',
        theme: ThemeData(
          primaryColor: primaryBlue,
          colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue),
          scaffoldBackgroundColor: softGray,
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(),
          ),
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<FirebaseAuth>(context, listen: false);
    return StreamBuilder<User?>(
      stream: auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        final user = snapshot.data;
        if (user == null) {
          return const AuthLanding();
        } else {
          return HomeScreen(user: user);
        }
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
