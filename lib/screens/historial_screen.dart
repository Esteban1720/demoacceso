import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/registro_acceso.dart';
import '../models/usuario.dart';
import '../services/firestore_service.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final FirestoreService _svc = FirestoreService();
  bool _isDeleting = false;

  // cache local para evitar múltiples lecturas del mismo usuario
  final Map<String, Usuario?> _userCache = {};

  Future<void> _confirmYVaciar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Vaciar historial'),
        content: const Text(
          'Se eliminarán todos los registros de acceso. Esta acción es irreversible. ¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Borrar todo'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      await _svc.vaciarHistorial();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Historial vaciado correctamente')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al vaciar historial: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  String _formatDateTime(DateTime dt) {
    final d = dt.toLocal();
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  // método que usa la cache y consulta el servicio si es necesario
  Future<Usuario?> _fetchUsuarioIfNeeded(String id) async {
    if (_userCache.containsKey(id)) return _userCache[id];
    final s = await _svc.obtenerUsuarioPorId(id);
    // guardar en cache (incluso si es null)
    _userCache[id] = s;
    // no hacemos setState aquí para evitar rebuilds masivos; la UI usará FutureBuilder
    return s;
  }

  @override
  Widget build(BuildContext context) {
    // Gradiente y estilo similar a las otras pantallas
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Historial de accesos',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              tooltip: 'Vaciar historial',
              icon: const Icon(Icons.delete_forever),
              onPressed: _isDeleting ? null : _confirmYVaciar,
            ),
          ),
        ],
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
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Firebase.apps.isEmpty
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(255, 255, 255, 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color.fromRGBO(255, 255, 255, 0.08),
                        ),
                      ),
                      child: const Text(
                        'Firebase no está configurado. Active Firestore para ver registros.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                : _buildRecordsList(),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordsList() {
    final coll = FirebaseFirestore.instance
        .collection('accesos')
        .orderBy('entrada', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: coll.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 255, 255, 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'No hay registros',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;
        final regs = docs.map((d) => RegistroAcceso.fromDoc(d)).toList();

        final futures = regs
            .map((r) => _fetchUsuarioIfNeeded(r.usuarioId))
            .toList();

        return FutureBuilder<List<Usuario?>>(
          future: Future.wait(futures),
          builder: (context, usersSnap) {
            if (usersSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final users =
                usersSnap.data ?? List<Usuario?>.filled(regs.length, null);

            final combined = List.generate(
              regs.length,
              (i) => {'reg': regs[i], 'user': users[i]},
            );

            bool isTipo(dynamic user, String tipo) {
              if (user == null) return false;
              final t = (user.tipoUsuario ?? '').toString().toLowerCase();
              return t.contains(tipo.toLowerCase());
            }

            final all = combined;
            final estudiantes = combined
                .where((e) => isTipo(e['user'], 'estudiante'))
                .toList();
            final admins = combined
                .where(
                  (e) =>
                      isTipo(e['user'], 'administrador') ||
                      isTipo(e['user'], 'admin'),
                )
                .toList();
            final visitantes = combined
                .where(
                  (e) =>
                      isTipo(e['user'], 'visitante') ||
                      isTipo(e['user'], 'invitado'),
                )
                .toList();

            final servicios = combined
                .where(
                  (e) =>
                      isTipo(e['user'], 'serviciogeneral') ||
                      isTipo(e['user'], 'servicio') ||
                      isTipo(e['user'], 'servicio general'),
                )
                .toList();

            final tabs = [all, estudiantes, admins, visitantes, servicios];

            return DefaultTabController(
              length: 5,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(255, 255, 255, 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      isScrollable: true,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color.fromRGBO(255, 255, 255, 0.12),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      tabs: [
                        Tab(text: 'Todos (${all.length})'),
                        Tab(text: 'Estudiantes (${estudiantes.length})'),
                        Tab(text: 'Administradores (${admins.length})'),
                        Tab(text: 'Visitantes (${visitantes.length})'),
                        Tab(text: 'Servicio general (${servicios.length})'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TabBarView(
                      children: tabs.map((list) {
                        if (list.isEmpty) {
                          return Center(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(
                                  255,
                                  255,
                                  255,
                                  0.08,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'No hay registros (${list.length})',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(top: 8, bottom: 24),
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final reg = list[index]['reg'] as RegistroAcceso;
                            final usuario = list[index]['user'] as Usuario?;

                            final entradaStr = _formatDateTime(reg.entrada);
                            final salidaStr = reg.salida != null
                                ? _formatDateTime(reg.salida!)
                                : '-';
                            final duracion = reg.salida != null
                                ? '${reg.salida!.difference(reg.entrada).inMinutes} min'
                                : '-';

                            final contadorTexto = (index + 1)
                                .toString()
                                .padLeft(2, '0');
                            final nombreMostrado =
                                usuario?.nombreCompleto ?? reg.usuarioId;
                            final tipo = usuario?.tipoUsuario ?? 'Desconocido';

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: Card(
                                color: const Color.fromRGBO(
                                  255,
                                  255,
                                  255,
                                  0.10,
                                ),
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                    color: const Color.fromRGBO(
                                      255,
                                      255,
                                      255,
                                      0.06,
                                    ),
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: const Color.fromRGBO(
                                      255,
                                      255,
                                      255,
                                      0.14,
                                    ),
                                    child: Text(
                                      contadorTexto,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    nombreMostrado,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 6.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Entrada: $entradaStr',
                                          style: const TextStyle(
                                            color: Color.fromRGBO(
                                              255,
                                              255,
                                              255,
                                              0.9,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          'Salida: $salidaStr',
                                          style: const TextStyle(
                                            color: Color.fromRGBO(
                                              255,
                                              255,
                                              255,
                                              0.9,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          'Duración: $duracion',
                                          style: const TextStyle(
                                            color: Color.fromRGBO(
                                              255,
                                              255,
                                              255,
                                              0.9,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Tipo: $tipo',
                                          style: const TextStyle(
                                            color: Color.fromRGBO(
                                              255,
                                              255,
                                              255,
                                              0.85,
                                            ),
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                        if (usuario != null &&
                                            usuario.tipoUsuario
                                                .toLowerCase()
                                                .contains('estudiante'))
                                          Text(
                                            'Programa: ${usuario.programaAcademico}',
                                            style: const TextStyle(
                                              color: Color.fromRGBO(
                                                255,
                                                255,
                                                255,
                                                0.85,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      Icons.more_vert,
                                      color: const Color.fromRGBO(
                                        255,
                                        255,
                                        255,
                                        0.9,
                                      ),
                                    ),
                                    onPressed: () =>
                                        _showRegistroDetails(reg, usuario),
                                  ),
                                  onTap: () =>
                                      _showRegistroDetails(reg, usuario),
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  // overlay de borrado en progreso
                  if (_isDeleting)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black45,
                        child: Center(
                          child: Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  SizedBox(
                                    height: 28,
                                    width: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Text('Borrando historial...'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showRegistroDetails(RegistroAcceso reg, Usuario? usuario) {
    final entradaStr = _formatDateTime(reg.entrada);
    final salidaStr = reg.salida != null ? _formatDateTime(reg.salida!) : '-';
    final duracion = reg.salida != null
        ? '${reg.salida!.difference(reg.entrada).inMinutes} min'
        : '-';
    final nombre = usuario?.nombreCompleto ?? reg.usuarioId;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Detalle del registro'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Usuario: $nombre'),
            const SizedBox(height: 8),
            Text('Entrada: $entradaStr'),
            const SizedBox(height: 4),
            Text('Salida: $salidaStr'),
            const SizedBox(height: 4),
            Text('Duración: $duracion'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
