import 'package:flutter/material.dart';
import '../widgets/boton_grande.dart';
import '../widgets/app_logo.dart';
import 'scan_screen.dart';
import 'registro_screen.dart';
import 'historial_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Para que el gradiente llegue detrás del AppBar
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors
            .transparent, // AppBar transparente para mostrar el gradiente de fondo
        elevation: 0,
        title: const Text(
          'Control de Acceso',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          // Botón pequeño en la esquina superior derecha para registrar
          Padding(
            padding: const EdgeInsets.only(right: 12.0, top: 6.0),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                backgroundColor: const Color.fromRGBO(255, 255, 255, 0.15),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('', style: TextStyle(fontSize: 13)),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegistroScreen()),
                );
              },
            ),
          ),
        ],
      ),
      body: Container(
        // Fondo con gradiente verde -> azul -> blanco
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0FBF60), // verde vibrante
              Color(0xFF1976D2), // azul moderno
              Color(0xFFFFFFFF), // blanco al final
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo arriba
                  const AppLogo(size: 86, title: 'UP'),
                  const SizedBox(height: 18),
                  // Card central con estilo moderno
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18.0),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(255, 255, 255, 0.12),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromRGBO(0, 0, 0, 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(
                        color: const Color.fromRGBO(255, 255, 255, 0.10),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Espacio superior con un título destacado
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Selecciona el modo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Botones grandes (usa tu widget BotonGrande)
                        BotonGrande(
                          label: 'Entrada',
                          color: Colors.green.shade600,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const ScanScreen(modo: ScanModo.entrada),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        BotonGrande(
                          label: 'Salida',
                          color: Colors.blue.shade700,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const ScanScreen(modo: ScanModo.salida),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        // Botón para historial dentro de la card (más discreto)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(
                                color: Color.fromRGBO(255, 255, 255, 0.18),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: const Color.fromRGBO(
                                255,
                                255,
                                255,
                                0.03,
                              ),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const HistorialScreen(),
                                ),
                              );
                            },
                            child: const Text('Ver historial'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
