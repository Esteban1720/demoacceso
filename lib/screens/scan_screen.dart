import 'dart:async';
import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import '../services/firestore_service.dart';

enum ScanModo { entrada, salida }

class ScanScreen extends StatefulWidget {
  final ScanModo modo;
  const ScanScreen({super.key, required this.modo});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final FirestoreService _svc = FirestoreService();
  bool processing = false;
  String mensaje = '';

  Future<void> _onDetectCodigo(String codigo) async {
    if (processing) {
      return;
    }
    if (codigo.isEmpty) return;
    setState(() {
      processing = true;
      mensaje = 'Procesando...';
    });
    try {
      final estudiante = await _svc.obtenerEstudiantePorCodigo(codigo);
      if (estudiante == null) {
        setState(() => mensaje = 'Estudiante no registrado');
      } else {
        if (widget.modo == ScanModo.entrada) {
          await _svc.crearEntrada(estudiante.id);
          setState(() => mensaje = 'SIGA');
        } else {
          final activo = await _svc.obtenerUltimaEntradaActiva(estudiante.id);
          if (activo == null) {
            setState(() => mensaje = 'No se encontró entrada previa');
          } else {
            await _svc.registrarSalida(estudiante.id);
            final duracion = DateTime.now().difference(activo.entrada);
            final minutos = duracion.inMinutes;
            setState(() => mensaje = 'Salida registrada: $minutos min');
          }
        }
      }
    } catch (e) {
      setState(() => mensaje = 'Error: ${e.toString()}');
    } finally {
      Timer(const Duration(seconds: 2), () {
        setState(() {
          processing = false;
          mensaje = '';
        });
      });
    }
  }

  Future<void> _startScan() async {
    if (processing) {
      return;
    }
    setState(() {
      processing = true;
      mensaje = 'Escaneando...';
    });
    try {
      var result = await BarcodeScanner.scan();
      if (result.type == ResultType.Cancelled) {
        setState(() => mensaje = 'Escaneo cancelado');
        return;
      }
      final code = result.rawContent;
      if (code.isNotEmpty) await _onDetectCodigo(code);
    } catch (e) {
      setState(() => mensaje = 'Error: ${e.toString()}');
    } finally {
      Timer(const Duration(seconds: 2), () {
        setState(() {
          processing = false;
          mensaje = '';
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.modo == ScanModo.entrada ? 'Entrada' : 'Salida'),
      ),
      body: Stack(
        children: [
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Iniciar escaneo'),
              onPressed: _startScan,
            ),
          ),
          if (mensaje.isNotEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: mensaje == 'SIGA'
                      ? const Color.fromRGBO(76, 175, 80, 0.9)
                      : Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  mensaje,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (processing)
            const Positioned(
              top: 16,
              right: 16,
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
