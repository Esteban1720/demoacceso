import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:uuid/uuid.dart';
import '../services/firestore_service.dart';
import '../models/usuario.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});
  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _cedulaCtrl = TextEditingController();
  final TextEditingController _codigoCtrl = TextEditingController();
  final TextEditingController _programaCtrl = TextEditingController();
  String _tipoUsuario = 'Estudiante';
  bool _cargando = false;

  final FirestoreService _svc = FirestoreService();

  Future<void> _guardar() async {
    // Programa académico solo necesario para Estudiantes. No obligatorio para Profesores.
    final necesitaPrograma = _tipoUsuario == 'Estudiante';
    final necesitaCodigo = _tipoUsuario.toLowerCase() != 'visitante';

    if (_nombreCtrl.text.isEmpty ||
        (necesitaCodigo && _codigoCtrl.text.isEmpty) ||
        _cedulaCtrl.text.isEmpty ||
        (necesitaPrograma && _programaCtrl.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete todos los campos obligatorios')),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _cargando = true);
    final id = const Uuid().v4();
    try {
      final usuario = Usuario(
        id: id,
        nombreCompleto: _nombreCtrl.text.trim(),
        cedula: _cedulaCtrl.text.trim(),
        codigoCarnet: _codigoCtrl.text.trim(),
        programaAcademico: necesitaPrograma ? _programaCtrl.text.trim() : '',
        tipoUsuario: _tipoUsuario,
        creadoEn: DateTime.now(),
      );
      await _svc.crearUsuario(usuario);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario registrado con éxito')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _scanCodigo() async {
    try {
      final result = await BarcodeScanner.scan();
      if (result.type == ResultType.Cancelled) return;
      final code = result.rawContent;
      if (code.isNotEmpty) {
        setState(() {
          _codigoCtrl.text = code.trim();
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al escanear código: ${e.toString()}')),
      );
    }
  }

  InputDecoration _inputDecoration(String label, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color.fromRGBO(255, 255, 255, 0.9)),
      filled: true,
      fillColor: const Color.fromRGBO(255, 255, 255, 0.06),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color.fromRGBO(255, 255, 255, 0.12),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color.fromRGBO(255, 255, 255, 0.08),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color.fromRGBO(255, 255, 255, 0.18),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Registrar usuario',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0FBF60), Color(0xFF1976D2), Color(0xFFFFFFFF)],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(255, 255, 255, 0.12),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromRGBO(0, 0, 0, 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(
                    color: const Color.fromRGBO(255, 255, 255, 0.09),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Datos del usuario',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nombreCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Nombre completo'),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _cedulaCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Cédula'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    if (_tipoUsuario.toLowerCase() != 'visitante')
                      TextField(
                        controller: _codigoCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration(
                          'Código del carnet (barcode)',
                          suffix: IconButton(
                            icon: const Icon(Icons.qr_code_scanner),
                            color: Colors.white,
                            onPressed: _scanCodigo,
                            tooltip: 'Escanear código',
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    if (_tipoUsuario == 'Estudiante')
                      TextField(
                        controller: _programaCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Programa académico'),
                        textCapitalization: TextCapitalization.words,
                      ),
                    const SizedBox(height: 18),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: _tipoUsuario,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de usuario',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Estudiante',
                          child: Text('Estudiante'),
                        ),
                        DropdownMenuItem(
                          value: 'Profesor',
                          child: Text('Profesor'),
                        ),
                        DropdownMenuItem(
                          value: 'Administrador',
                          child: Text('Administrador'),
                        ),
                        DropdownMenuItem(
                          value: 'serviciogeneral',
                          child: Text('Servicio general'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          _tipoUsuario = v;
                          // Nota: la opción 'Visitante' fue removida del formulario; ya no limpiamos el código aquí.
                          // Si el tipo es Profesor, limpiar programa académico para evitar valores residuales
                          if (_tipoUsuario.toLowerCase() == 'profesor' ||
                              _tipoUsuario == 'Profesor') {
                            _programaCtrl.clear();
                          }
                        });
                      },
                    ),
                    _cargando
                        ? const Center(
                            child: CircularProgressIndicator.adaptive(),
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _guardar,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade700,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Guardar usuario',
                                    style: TextStyle(fontSize: 15),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: const BorderSide(
                                    color: Color.fromRGBO(255, 255, 255, 0.14),
                                  ),
                                  backgroundColor: const Color.fromRGBO(
                                    255,
                                    255,
                                    255,
                                    0.03,
                                  ),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Cancelar'),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _cedulaCtrl.dispose();
    _codigoCtrl.dispose();
    _programaCtrl.dispose();
    super.dispose();
  }
}
