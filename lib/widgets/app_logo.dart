import 'package:flutter/material.dart';

/// AppLogo: widget simple y vectorial para el home.
/// Muestra un círculo con gradiente, un ícono de candado y las letras "UP".
class AppLogo extends StatelessWidget {
  final double size;
  final String title; // opcional, p.ej. 'UP'

  const AppLogo({super.key, this.size = 84, this.title = 'UP'});

  @override
  Widget build(BuildContext context) {
    final double inner = size * 0.64;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // círculo con gradiente
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0FBF60), Color(0xFF1976D2)],
              ),
              boxShadow: [
                BoxShadow(color: const Color.fromRGBO(0, 0, 0, 0.18), blurRadius: 8, offset: const Offset(0, 4)),
              ],
            ),
          ),

          // círculo interior claro
          Container(
            width: inner,
            height: inner,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.06)),
          ),

          // contenido: candado + texto
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // lock icon dentro de un pequeño círculo blanco
              Container(
                width: inner * 0.6,
                height: inner * 0.6,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                child: Icon(Icons.lock, color: const Color(0xFF1976D2), size: inner * 0.36),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: size * 0.20,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
