import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';
import '../models/estudiante.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});
  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _codigoCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _imagenFoto;
  File? _imagenCarnet;
  // Allow selecting image from gallery or camera as carnet
  bool _cargando = false;

  final FirestoreService _svc = FirestoreService();
  final CloudinaryService _cloudinary = CloudinaryService();

  Future<void> _tomarFotoEstudiante() async {
    final foto = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (foto == null) {
      return;
    }
    setState(() => _imagenFoto = File(foto.path));
  }

  Future<void> _seleccionarFotoEstudianteDesdeGaleria() async {
    final foto = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (foto == null) return;
    setState(() => _imagenFoto = File(foto.path));
  }

  Future<void> _tomarFotoCarnet() async {
    final foto = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (foto == null) return;
    setState(() => _imagenCarnet = File(foto.path));
  }

  Future<void> _seleccionarFotoCarnetDesdeGaleria() async {
    final foto = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (foto == null) return;
    setState(() => _imagenCarnet = File(foto.path));
  }

  Future<void> _guardar() async {
    if (_nombreCtrl.text.isEmpty || _codigoCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete todos los campos obligatorios')),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _cargando = true);
    final id = const Uuid().v4();
    try {
      String? fotoUrl;
      String? fotoCarnetUrl;
      if (_imagenFoto != null) {
        fotoUrl = await _cloudinary.subirImagenNoFirmada(
          _imagenFoto!,
          folder: 'students',
        );
      }
      if (_imagenCarnet != null) {
        fotoCarnetUrl = await _cloudinary.subirImagenNoFirmada(
          _imagenCarnet!,
          folder: 'students/carnets',
        );
      }
      final est = Estudiante(
        id: id,
        nombreCompleto: _nombreCtrl.text,
        codigoCarnet: _codigoCtrl.text,
        fotoUrl: fotoUrl,
        fotoCarnetUrl: fotoCarnetUrl,
        creadoEn: DateTime.now(),
      );
      await _svc.crearEstudiante(est);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estudiante registrado con éxito')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar estudiante')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre completo'),
              ),
              TextField(
                controller: _codigoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Código del carnet (barcode)',
                ),
              ),
              const SizedBox(height: 10),
              // Foto del estudiante (selfie)
              const SizedBox(height: 6),
              const Text('Foto del estudiante (opcional)'),
              const SizedBox(height: 6),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _tomarFotoEstudiante,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Tomar foto'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _seleccionarFotoEstudianteDesdeGaleria,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Seleccionar'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_imagenFoto != null) Image.file(_imagenFoto!, height: 180),
              const SizedBox(height: 16),
              // Foto del carnet (ID)
              const Text('Foto del carnet (opcional)'),
              const SizedBox(height: 6),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _tomarFotoCarnet,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Tomar foto del carnet'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _seleccionarFotoCarnetDesdeGaleria,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Seleccionar carnet'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_imagenCarnet != null)
                Image.file(_imagenCarnet!, height: 180),
              const SizedBox(height: 16),
              _cargando
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _guardar,
                      child: const Text('Guardar estudiante'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
