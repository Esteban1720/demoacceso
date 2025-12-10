import 'dart:async';
import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import '../services/firestore_service.dart';
import '../models/usuario.dart';

enum ScanModo { entrada, salida }

class ScanScreen extends StatefulWidget {
  final ScanModo modo;
  const ScanScreen({super.key, required this.modo});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final FirestoreService _svc = FirestoreService();

  bool processing = false; // indicador general
  bool handlingCodigo = false; // evita procesar dos códigos al tiempo

  String mensaje = '';

  // datos del usuario y tiempos para mostrar en la parte inferior tras un escaneo exitoso
  Usuario? _usuarioDatos;
  String? _entradaHoraTexto;
  String? _salidaHoraTexto;
  String? _duracionTexto;

  String _formatHora(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _onDetectCodigo(String codigo) async {
    if (handlingCodigo) {
      debugPrint('[scan] _onDetectCodigo: ya se está procesando otro código');
      return;
    }

    final code = codigo.trim();
    if (code.isEmpty) {
      debugPrint('[scan] código vacío recibido');
      setState(() => mensaje = 'No se detectó código');
      return;
    }

    setState(() {
      handlingCodigo = true;
      mensaje = 'Procesando...';
      _entradaHoraTexto = null;
      _salidaHoraTexto = null;
      _duracionTexto = null;
    });

    try {
      debugPrint('[scan] buscando usuario por código: $code');
      final estudiante = await _svc.obtenerUsuarioPorCodigo(code);

      if (estudiante == null) {
        debugPrint('[scan] usuario no registrado');
        setState(() {
          mensaje = 'Usuario no registrado';
          _usuarioDatos = null;
        });
      } else {
        setState(() {
          _usuarioDatos = estudiante;
        });

        if (widget.modo == ScanModo.entrada) {
          // ENTRADA
          debugPrint('[scan] registrando entrada para: ${estudiante.id}');
          await _svc.crearEntrada(estudiante.id);
          setState(() => mensaje = 'SIGA');
        } else {
          // SALIDA -> BUSCAR ENTRADA ACTIVA HOY
          debugPrint(
            '[scan] buscando entrada ACTIVA HOY para: ${estudiante.id}',
          );
          final activoHoy = await _svc.obtenerEntradaActivaHoy(estudiante.id);

          if (activoHoy == null) {
            debugPrint('[scan] no hay entrada activa hoy');
            setState(() {
              mensaje = 'No se encontró entrada previa (hoy)';
              _usuarioDatos = null;
              _entradaHoraTexto = null;
              _salidaHoraTexto = null;
              _duracionTexto = null;
            });
          } else {
            debugPrint(
              '[scan] entrada activa hoy encontrada id:${activoHoy.id} entrada:${activoHoy.entrada}',
            );
            // registrar salida en el registro específico
            await _svc.registrarSalidaParaRegistro(activoHoy.id);

            final horaSalida = DateTime.now();
            final duracion = horaSalida.difference(activoHoy.entrada);

            final horas = duracion.inHours;
            final minutos = duracion.inMinutes % 60;
            String duracionStr = horas > 0
                ? '${horas}h ${minutos}m'
                : '${duracion.inMinutes} min';

            setState(() {
              mensaje = 'SALGA';
              _entradaHoraTexto = _formatHora(activoHoy.entrada);
              _salidaHoraTexto = _formatHora(horaSalida);
              _duracionTexto = duracionStr;
            });

            debugPrint('[scan] salida registrada. Duración: $duracionStr');
          }
        }

        // mostramos la info del usuario en la parte inferior durante 4 segundos (o hasta el siguiente escaneo)
        Timer(const Duration(seconds: 4), () {
          if (!mounted) return;
          setState(() {
            _usuarioDatos = null;
            _entradaHoraTexto = null;
            _salidaHoraTexto = null;
            _duracionTexto = null;
          });
        });
      }
    } catch (e, st) {
      debugPrint('[scan] error procesando código: $e\n$st');
      setState(() {
        mensaje = 'Error: ${e.toString()}';
        _usuarioDatos = null;
        _entradaHoraTexto = null;
        _salidaHoraTexto = null;
        _duracionTexto = null;
      });
    } finally {
      Timer(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() {
          handlingCodigo = false;
          mensaje = '';
        });
      });
    }
  }

  Future<void> _startScan() async {
    if (processing || handlingCodigo) {
      debugPrint(
        '[scan] intento de iniciar scan ignorado: processing=$processing handlingCodigo=$handlingCodigo',
      );
      return;
    }

    setState(() {
      processing = true;
      mensaje = 'Escaneando...';
    });

    try {
      debugPrint('[scan] antes de BarcodeScanner.scan()');

      var result = await BarcodeScanner.scan().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Tiempo de escaneo agotado');
        },
      );

      debugPrint(
        '[scan] después de scan -> type=${result.type} raw="${result.rawContent}"',
      );

      if (result.type == ResultType.Cancelled) {
        setState(() {
          mensaje = 'Escaneo cancelado';
        });
        return;
      } else if (result.type == ResultType.Error) {
        setState(() {
          mensaje = 'Error de escaneo';
        });
        return;
      }

      final raw = result.rawContent;
      final code = raw.trim();
      if (code.isEmpty) {
        setState(() => mensaje = 'No se detectó código');
        return;
      }

      await _onDetectCodigo(code);
    } on TimeoutException catch (_) {
      debugPrint('[scan] TimeoutException: tiempo agotado en el escaneo');
      setState(() => mensaje = 'Tiempo de escaneo agotado');
    } catch (e, st) {
      debugPrint('[scan] excepción en _startScan: $e\n$st');
      setState(() => mensaje = 'Error: ${e.toString()}');
    } finally {
      Timer(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        setState(() {
          processing = false;
          if (mensaje.startsWith('Error') ||
              mensaje == 'Escaneo cancelado' ||
              mensaje == 'Tiempo de escaneo agotado') {
            mensaje = '';
          }
        });
      });
    }
  }

  Color _messageColor(String msg) {
    if (msg == 'SIGA') return Colors.green.shade600;
    if (msg == 'SALGA') return Colors.blue.shade700;
    return Colors.black87;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.modo == ScanModo.entrada ? 'Entrada' : 'Salida'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0FBF60), // verde vibrante
              Color(0xFF1976D2), // azul moderno
              Color(0xFFFFFFFF), // blanco
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Centro: card con instrucción y botón grande
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 720),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(255, 255, 255, 0.10),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color.fromRGBO(255, 255, 255, 0.08),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromRGBO(0, 0, 0, 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.modo == ScanModo.entrada
                              ? 'Escanea el carnet para registrar la entrada'
                              : 'Escanea el carnet para registrar la salida',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: 220,
                          height: 54,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.qr_code_scanner, size: 22),
                            label: Text(
                              processing ? 'Escaneando...' : 'Iniciar escaneo',
                              style: const TextStyle(fontSize: 16),
                            ),
                            onPressed: processing ? null : _startScan,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.modo == ScanModo.entrada
                                  ? Colors.green.shade600
                                  : Colors.blue.shade700,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Presiona el botón y acerca el código al lector.',
                          style: const TextStyle(
                            color: Color.fromRGBO(255, 255, 255, 0.85),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Mensaje temporal: SIGA o SALGA se muestran un poco arriba del centro
              if (mensaje.isNotEmpty)
                Align(
                  alignment: (mensaje == 'SIGA' || mensaje == 'SALGA')
                      ? const Alignment(0, -0.20)
                      : Alignment.center,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: _messageColor(mensaje),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromRGBO(0, 0, 0, 0.18),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
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

              // Indicador de procesamiento (pequeño) arriba a la derecha
              if (processing || handlingCodigo)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(255, 255, 255, 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),

              // Mostrar datos del usuario y tiempos en la parte inferior cuando estén disponibles
              if (_usuarioDatos != null)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 14.0,
                    ),
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 760),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(255, 255, 255, 0.12),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromRGBO(0, 0, 0, 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: const Color.fromRGBO(255, 255, 255, 0.06),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _usuarioDatos!.nombreCompleto,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Código: ${_usuarioDatos!.codigoCarnet}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color.fromRGBO(255, 255, 255, 0.9),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Programa: ${_usuarioDatos!.programaAcademico}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color.fromRGBO(255, 255, 255, 0.9),
                            ),
                          ),
                          if (_entradaHoraTexto != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Entrada: $_entradaHoraTexto',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color.fromRGBO(255, 255, 255, 0.9),
                              ),
                            ),
                          ],
                          if (_salidaHoraTexto != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Salida: $_salidaHoraTexto',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color.fromRGBO(255, 255, 255, 0.9),
                              ),
                            ),
                          ],
                          if (_duracionTexto != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Duración: $_duracionTexto',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
