import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/estudiante.dart';
import '../models/registro_acceso.dart';

class FirestoreService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  FirestoreService() {
    // If Firebase was initialized, enable local persistence.
    if (Firebase.apps.isNotEmpty) {
      _db.settings = const Settings(persistenceEnabled: true);
    }
  }

  Future<Estudiante?> obtenerEstudiantePorCodigo(String codigo) async {
    final snap = await _db
        .collection('students')
        .where('codigoCarnet', isEqualTo: codigo)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return Estudiante.fromDoc(snap.docs.first);
  }

  Future<void> crearEstudiante(Estudiante e) async {
    await _db.collection('students').doc(e.id).set(e.toMap());
  }

  Future<void> crearEntrada(String estudianteDocId) async {
    final docRef = _db.collection('access_records').doc();
    await docRef.set({
      'estudianteId': estudianteDocId,
      'entrada': Timestamp.fromDate(DateTime.now()),
      'salida': null,
    });
  }

  Future<RegistroAcceso?> obtenerUltimaEntradaActiva(
    String estudianteDocId,
  ) async {
    final q = await _db
        .collection('access_records')
        .where('estudianteId', isEqualTo: estudianteDocId)
        .where('salida', isNull: true)
        .orderBy('entrada', descending: true)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return RegistroAcceso.fromDoc(q.docs.first);
  }

  Future<void> registrarSalida(String estudianteDocId) async {
    final q = await _db
        .collection('access_records')
        .where('estudianteId', isEqualTo: estudianteDocId)
        .where('salida', isNull: true)
        .orderBy('entrada', descending: true)
        .limit(1)
        .get();

    if (q.docs.isEmpty) throw Exception('No se encontró entrada activa');

    final doc = q.docs.first;
    await doc.reference.update({'salida': Timestamp.fromDate(DateTime.now())});
  }
}
