import 'package:flutter/material.dart';
import '../widgets/boton_grande.dart';
import 'scan_screen.dart';
import 'registro_screen.dart';
import 'historial_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Control de Acceso - UP')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BotonGrande(
              label: 'Entrada',
              color: Colors.green,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ScanScreen(modo: ScanModo.entrada),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            BotonGrande(
              label: 'Salida',
              color: Colors.red,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ScanScreen(modo: ScanModo.salida),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegistroScreen()),
                );
              },
              child: const Text('Registrar estudiante'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HistorialScreen()),
                );
              },
              child: const Text('Ver historial'),
            ),
          ],
        ),
      ),
    );
  }
}
