import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_screen.dart';
import 'screens/registro_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/historial_screen.dart';

/// The main entry point of the application.
///
/// This function:
/// - Ensures Flutter widgets are bound to a build context.
/// - Loads environment variables from a `.env` file.
/// - Initializes Firebase with the default options for the current platform.
/// - Runs the application with a `ProviderScope` to enable global access
///   to provider state.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Control de Acceso - Universidad del Pacífico',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/registrar': (context) => const RegistroScreen(),
        '/historial': (context) => const HistorialScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/escanear') {
          final args = settings.arguments as ScanModo?;
          return MaterialPageRoute(builder: (_) => ScanScreen(modo: args ?? ScanModo.entrada));
        }
        return null;
      },
    );
  }
}
