import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_screen.dart';
import 'screens/registro_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/historial_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // If .env doesn't exist (development without dotenv), continue gracefully.
    debugPrint('No .env file found: $e');
  }
  // Only attempt to initialize Firebase if google-services.json exists (Android)
  // or GoogleService-Info.plist exists (iOS)
  final gsAndroid = File('android/app/google-services.json');
  final gsiOS = File('ios/Runner/GoogleService-Info.plist');
  if (gsAndroid.existsSync() || gsiOS.existsSync()) {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      // If Firebase configuration is missing or fails, continue gracefully.
      debugPrint('Firebase initialization failed: $e');
    }
  } else {
    debugPrint('No Firebase config found, skipping Firebase.initializeApp()');
  }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Control de Acceso - Universidad del Pacífico',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/registrar': (context) => const RegistroScreen(),
        '/historial': (context) => const HistorialScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/escanear') {
          final args = settings.arguments as ScanModo?;
          return MaterialPageRoute(
            builder: (_) => ScanScreen(modo: args ?? ScanModo.entrada),
          );
        }
        return null;
      },
    );
  }
}
