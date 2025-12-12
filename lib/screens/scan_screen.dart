import 'dart:async';
import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:mobile_scanner/mobile_scanner.dart' as ms;
import 'package:uuid/uuid.dart';
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

  // Crea un usuario tipo visitante y registra entrada o entrada+salida según el modo
  Future<Usuario> _crearVisitanteYRegistrar(
    String? codigo, {
    String? visitanteNombre,
  }) async {
    final uuid = const Uuid();
    final id = 'visitante_${uuid.v4()}';
    final nombre =
        visitanteNombre ??
        'Visitante ${DateTime.now().millisecondsSinceEpoch % 100000}';
    final codigoCarnet = (codigo != null && codigo.trim().isNotEmpty)
        ? codigo.trim()
        : (visitanteNombre == 'Visitante NN' ? 'NN' : id);

    final visitante = Usuario(
      id: id,
      nombreCompleto: nombre,
      cedula: '',
      codigoCarnet: codigoCarnet,
      programaAcademico: 'Visitante',
      tipoUsuario: 'Visitante',
      creadoEn: DateTime.now(),
    );

    // guardar usuario
    try {
      await _svc.crearUsuario(visitante);
    } catch (e) {
      debugPrint('[scan] error creando visitante: $e');
    }

    // registrar entrada
    try {
      await _svc.crearEntrada(visitante.id);
    } catch (e) {
      debugPrint('[scan] error registrando entrada para visitante: $e');
    }

    // Si estamos en Modo Salida, inmediatamente registramos salida para evitar entrada activa
    if (widget.modo == ScanModo.salida) {
      try {
        final activoHoy = await _svc.obtenerEntradaActivaHoy(visitante.id);
        if (activoHoy != null) {
          await _svc.registrarSalidaParaRegistro(activoHoy.id);
        }
      } catch (e) {
        debugPrint('[scan] error registrando salida visitante: $e');
      }
    }

    return visitante;
  }

  Future<void> _onDetectCodigo(String codigo, {bool forceNN = false}) async {
    if (handlingCodigo) {
      debugPrint('[scan] _onDetectCodigo: ya se está procesando otro código');
      return;
    }

    final code = codigo.trim();
    // Si se fuerza NN, tratamos como si el código estuviera vacío
    final isEmptyCode = forceNN ? true : code.isEmpty;

    setState(() {
      handlingCodigo = true;
      mensaje = 'Procesando...';
      _entradaHoraTexto = null;
      _salidaHoraTexto = null;
      _duracionTexto = null;
    });

    try {
      if (isEmptyCode) {
        debugPrint('[scan] código vacío recibido -> tratar como visitante');
      }
      debugPrint('[scan] buscando usuario por código: $code');
      final estudiante = isEmptyCode
          ? null
          : await _svc.obtenerUsuarioPorCodigo(code);

      if (estudiante == null) {
        debugPrint('[scan] usuario no registrado');

        if (widget.modo == ScanModo.salida) {
          debugPrint(
            '[scan] modo SALIDA y usuario no registrado -> buscar primera entrada activa visitante',
          );
          final primerActivo = await _svc.obtenerPrimerEntradaActivaVisitante();
          if (primerActivo == null) {
            debugPrint(
              '[scan] no se encontró visitante activo para registrar salida',
            );
            setState(() {
              mensaje = 'No hay visitantes activos';
              _usuarioDatos = null;
              _entradaHoraTexto = null;
              _salidaHoraTexto = null;
              _duracionTexto = null;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'No se encontró visitante activo para registrar salida',
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } else {
            // registramos salida para ese registro y mostramos la info correspondiente
            await _svc.registrarSalidaParaRegistro(primerActivo.id);
            final usuarioVisitante = await _svc.obtenerUsuarioPorId(
              primerActivo.usuarioId,
            );
            final horaSalida = DateTime.now();
            final duracion = horaSalida.difference(primerActivo.entrada);
            final horas = duracion.inHours;
            final minutos = duracion.inMinutes % 60;
            final String duracionStr = horas > 0
                ? '${horas}h ${minutos}m'
                : '${duracion.inMinutes} min';

            setState(() {
              _usuarioDatos =
                  usuarioVisitante ??
                  Usuario(
                    id: 'visitante_unknown',
                    nombreCompleto: 'Visitante',
                    cedula: '',
                    codigoCarnet: 'NN',
                    programaAcademico: 'Visitante',
                    tipoUsuario: 'Visitante',
                    creadoEn: DateTime.now(),
                  );
              mensaje = 'SALGA';
              _entradaHoraTexto = _formatHora(primerActivo.entrada);
              _salidaHoraTexto = _formatHora(horaSalida);
              _duracionTexto = duracionStr;
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Salida registrada para ${_usuarioDatos!.nombreCompleto}',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        } else {
          // crear visitante y registrar según modo (entrada)
          debugPrint('[scan] crear visitante por código vacío/NN');
          final visitante = await _crearVisitanteYRegistrar(
            forceNN || isEmptyCode ? null : codigo,
            visitanteNombre: 'Visitante NN',
          );

          setState(() {
            _usuarioDatos = visitante;
            mensaje = 'SIGA (Visitante NN)';
          });
          // Mostrar una notificación breve para confirmar la creación del visitante
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Entrada registrada para Visitante NN'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
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
            // Si el usuario es tipo Visitante y no tiene entrada hoy, intentamos
            // cerrar (Fifo) la primera entrada activa de visitantes en la cola.
            if (estudiante.tipoUsuario.toLowerCase() == 'visitante') {
              final primerActivo = await _svc
                  .obtenerPrimerEntradaActivaVisitante();
              if (primerActivo == null) {
                debugPrint(
                  '[scan] no hay entrada activa hoy para este visitante ni visitantes en cola',
                );
                setState(() {
                  mensaje = 'No se encontró entrada previa (hoy)';
                  _usuarioDatos = null;
                  _entradaHoraTexto = null;
                  _salidaHoraTexto = null;
                  _duracionTexto = null;
                });
              } else {
                await _svc.registrarSalidaParaRegistro(primerActivo.id);
                final usuarioVisitante = await _svc.obtenerUsuarioPorId(
                  primerActivo.usuarioId,
                );
                final horaSalida = DateTime.now();
                final duracion = horaSalida.difference(primerActivo.entrada);
                final horas = duracion.inHours;
                final minutos = duracion.inMinutes % 60;
                String duracionStr = horas > 0
                    ? '${horas}h ${minutos}m'
                    : '${duracion.inMinutes} min';

                setState(() {
                  _usuarioDatos = usuarioVisitante ?? estudiante;
                  mensaje = 'SALGA';
                  _entradaHoraTexto = _formatHora(primerActivo.entrada);
                  _salidaHoraTexto = _formatHora(horaSalida);
                  _duracionTexto = duracionStr;
                });

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Salida registrada para ${_usuarioDatos!.nombreCompleto}',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            } else {
              debugPrint('[scan] no hay entrada activa hoy');
              setState(() {
                mensaje = 'No se encontró entrada previa (hoy)';
                _usuarioDatos = null;
                _entradaHoraTexto = null;
                _salidaHoraTexto = null;
                _duracionTexto = null;
              });
            }
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

      // Queremos un escaneo super rápido: 3s por defecto
      var result = await BarcodeScanner.scan().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          throw TimeoutException('Tiempo de escaneo agotado');
        },
      );

      debugPrint(
        '[scan] después de scan -> type=${result.type} raw="${result.rawContent}"',
      );

      if (result.type == ResultType.Cancelled) {
        // El usuario canceló: no hacer nada (no crear visitante automáticamente)
        setState(() {
          mensaje = 'Escaneo cancelado';
        });
        return;
      } else if (result.type == ResultType.Error) {
        // En caso de error de escaneo, tratamos como visitante NN para permitir
        // la entrada/salida manualmente sin código identificado.
        debugPrint('[scan] Error de escaneo -> tratar como visitante NN');
        await _onDetectCodigo('', forceNN: true);
        return;
      }

      final raw = result.rawContent;
      final code = raw.trim();
      // Si no se detectó código, lo tratamos como visitante automáticamente (NN)
      if (code.isEmpty) {
        debugPrint('[scan] código vacío -> crear visitante NN');
        await _onDetectCodigo('', forceNN: true);
        return;
      }

      // Si se leyó un código, revisamos si pertenece a un usuario registrado.
      final estudiante = await _svc.obtenerUsuarioPorCodigo(code);
      if (estudiante == null) {
        // Si el código no coincide con usuarios registrados, tratamos como "Visitante NN"
        debugPrint('[scan] código no registrado -> crear visitante NN');
        await _onDetectCodigo('', forceNN: true);
        return;
      }

      await _onDetectCodigo(code);
    } on TimeoutException catch (_) {
      debugPrint(
        '[scan] TimeoutException: tiempo agotado en el escaneo - tratar como Visitante NN',
      );
      // Si el escaneo no devuelve resultados en 3s, lo tratamos como Visitante NN
      await _onDetectCodigo('', forceNN: true);
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

  // Nueva implementación usando MobileScanner (soporta PDF417 y otras simbologías 2D)
  Future<void> _startScanMobileScanner() async {
    if (processing || handlingCodigo) {
      debugPrint(
        '[scan] intento de iniciar scan MobileScanner ignorado: processing=$processing handlingCodigo=$handlingCodigo',
      );
      return;
    }

    setState(() {
      processing = true;
      mensaje = 'Escaneando...';
    });

    final controller = ms.MobileScannerController(
      formats: const [
        ms.BarcodeFormat.pdf417,
        ms.BarcodeFormat.code128,
        ms.BarcodeFormat.qrCode,
        ms.BarcodeFormat.code39,
        ms.BarcodeFormat.code93,
      ],
    );

    try {
      bool torchOn = false;
      bool didDetect = false; // para evitar dobles acciones
      Timer? fallbackTimer;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Escanear cédula'),
                backgroundColor: Colors.black,
                actions: [
                  StatefulBuilder(
                    builder: (context, setStateSB) {
                      return IconButton(
                        icon: Icon(torchOn ? Icons.flash_on : Icons.flash_off),
                        onPressed: () async {
                          torchOn = !torchOn;
                          setStateSB(() {});
                          try {
                            await controller.toggleTorch();
                          } catch (_) {}
                        },
                      );
                    },
                  ),
                ],
              ),
              body: StatefulBuilder(
                builder: (contextSB, setStateSB) {
                  // iniciar fallback de 3 segundos: si no se detecta usuario registrado, tratamos como Visitante NN
                  if (fallbackTimer == null) {
                    fallbackTimer = Timer(const Duration(seconds: 3), () {
                      if (didDetect) return;
                      didDetect = true;
                      try {
                        Navigator.of(contextSB).pop();
                      } catch (_) {}
                      _onDetectCodigo('', forceNN: true);
                    });
                  }
                  return ms.MobileScanner(
                    controller: controller,
                    onDetect: (capture) async {
                      final barcodes = capture.barcodes;
                      if (barcodes.isEmpty) return;
                      if (didDetect) return;
                      didDetect = true;
                      fallbackTimer?.cancel();
                      final raw = barcodes.first.rawValue ?? '';
                      // Cerrar la pantalla de escaneo y procesar el resultado.
                      try {
                        Navigator.of(contextSB).pop();
                      } catch (_) {}

                      final trimmed = raw.trim();
                      if (trimmed.isEmpty) {
                        // No se pudo leer bien -> visitante NN
                        await _onDetectCodigo('', forceNN: true);
                        return;
                      }

                      try {
                        // Intentamos consultar si el código pertenece a un usuario registrado.
                        final estudiante = await _svc.obtenerUsuarioPorCodigo(
                          trimmed,
                        );
                        if (estudiante == null) {
                          // Si no hay coincidencia, lo tratamos como visitante NN según la petición.
                          await _onDetectCodigo('', forceNN: true);
                          return;
                        }
                        // Si el usuario existe, procesamos normalmente
                        await _onDetectCodigo(trimmed);
                      } catch (e) {
                        debugPrint(
                          '[scan] error comprobando usuario por código: $e',
                        );
                        // En caso de error al consultar, tratamos como Visitante NN para no bloquear el flujo.
                        await _onDetectCodigo('', forceNN: true);
                      }
                    },
                  );
                },
              ),
            );
          },
        ),
      );
      // Al volver de la pantalla de escaneo, cancelamos el fallback en caso de que aún esté corriendo
      fallbackTimer?.cancel();
    } catch (e, st) {
      debugPrint('[scan] excepción en _startScanMobileScanner: $e\n$st');
      setState(() => mensaje = 'Error: ${e.toString()}');
    } finally {
      Timer(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        setState(() {
          processing = false;
          if (mensaje.startsWith('Error') || mensaje == 'Escaneo cancelado') {
            mensaje = '';
          }
        });
      });
    }
  }

  Color _messageColor(String msg) {
    if (msg.startsWith('SIGA')) return Colors.green.shade600;
    if (msg.startsWith('SALGA')) return Colors.blue.shade700;
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
                            onPressed: processing
                                ? null
                                : _startScanMobileScanner,
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
