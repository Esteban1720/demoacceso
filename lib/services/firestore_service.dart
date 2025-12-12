import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/usuario.dart';
import '../models/registro_acceso.dart';

class FirestoreService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  FirestoreService() {
    if (Firebase.apps.isNotEmpty) {
      _db.settings = const Settings(persistenceEnabled: true);
    }
  }

  Future<Usuario?> obtenerUsuarioPorCodigo(String codigo) async {
    final raw = codigo.trim();
    final normalized = raw.toLowerCase();
    final digits = raw.replaceAll(RegExp(r'\D'), '');

    // 1) Normalizado
    var snap = await _db.collection('Usuario').where('codigoCarnetNormalized', isEqualTo: normalized).limit(1).get();
    if (snap.docs.isNotEmpty) return Usuario.fromDoc(snap.docs.first);

    // 2) Exacto
    snap = await _db.collection('Usuario').where('codigoCarnet', isEqualTo: raw).limit(1).get();
    if (snap.docs.isNotEmpty) return Usuario.fromDoc(snap.docs.first);

    // 3) Solo dígitos
    if (digits.isNotEmpty) {
      // si guardaste codigoCarnetDigits
      snap = await _db.collection('Usuario').where('codigoCarnetDigits', isEqualTo: digits).limit(1).get();
      if (snap.docs.isNotEmpty) return Usuario.fromDoc(snap.docs.first);

      // compatibilidad si solo está en codigoCarnet
      snap = await _db.collection('Usuario').where('codigoCarnet', isEqualTo: digits).limit(1).get();
      if (snap.docs.isNotEmpty) return Usuario.fromDoc(snap.docs.first);
    }
    return null;
  }

  /// NUEVO: obtener usuario por document id
  Future<Usuario?> obtenerUsuarioPorId(String id) async {
    try {
      final doc = await _db.collection('Usuario').doc(id).get();
      if (!doc.exists) return null;
      return Usuario.fromDoc(doc);
    } catch (e) {
      // opcional: loggear error
      return null;
    }
  }

  Future<void> crearUsuario(Usuario e) async {
    final data = e.toMap();
    data['codigoCarnetNormalized'] = e.codigoCarnet.trim().toLowerCase();
    data['codigoCarnetDigits'] = e.codigoCarnet.trim().replaceAll(RegExp(r'\D'), '');
    await _db.collection('Usuario').doc(e.id).set(data);
  }

  Future<void> crearEntrada(String usuarioDocId) async {
    final docRef = _db.collection('accesos').doc();
    await docRef.set({'usuarioId': usuarioDocId, 'entrada': Timestamp.fromDate(DateTime.now()), 'salida': null});
  }

  /// Obtiene la última entrada activa (sin salida) — independiente de la fecha.
  Future<RegistroAcceso?> obtenerUltimaEntradaActiva(String usuarioDocId) async {
    final q = await _db
        .collection('accesos')
        .where('usuarioId', isEqualTo: usuarioDocId)
        .where('salida', isNull: true)
        .orderBy('entrada', descending: true)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return RegistroAcceso.fromDoc(q.docs.first);
  }

  /// NUEVA: Obtiene la última entrada activa del DÍA ACTUAL (inicio -> fin del día local)
  Future<RegistroAcceso?> obtenerEntradaActivaHoy(String usuarioDocId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfNextDay = startOfDay.add(const Duration(days: 1));

    final q = await _db
        .collection('accesos')
        .where('usuarioId', isEqualTo: usuarioDocId)
        .where('salida', isNull: true)
        .where('entrada', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('entrada', isLessThan: Timestamp.fromDate(startOfNextDay))
        .orderBy('entrada', descending: true)
        .limit(1)
        .get();

    if (q.docs.isEmpty) return null;
    return RegistroAcceso.fromDoc(q.docs.first);
  }

  /// NUEVO: Obtiene la PRIMERA (más antigua) entrada activa para un usuario tipo Visitante.
  /// Busca accesos sin salida ordenados por entrada ascendente y devuelve el primero
  /// cuyo usuario tenga `tipoUsuario == 'Visitante'`.
  Future<RegistroAcceso?> obtenerPrimerEntradaActivaVisitante({int limit = 100}) async {
    final q = await _db
        .collection('accesos')
        .where('salida', isNull: true)
        .orderBy('entrada', descending: false)
        .limit(limit)
        .get();

    if (q.docs.isEmpty) return null;
    for (final doc in q.docs) {
      final reg = RegistroAcceso.fromDoc(doc);
      final user = await obtenerUsuarioPorId(reg.usuarioId);
      if (user != null && user.tipoUsuario.toLowerCase() == 'visitante') {
        return reg;
      }
    }
    return null;
  }

  /// Registra la salida en el registro cuyo ID se pasa (actualiza campo 'salida').
  Future<void> registrarSalidaParaRegistro(String registroId) async {
    final docRef = _db.collection('accesos').doc(registroId);
    await docRef.update({'salida': Timestamp.fromDate(DateTime.now())});
  }

  /// Borra todos los documentos de la colección 'accesos' en lotes de 500.
  Future<void> vaciarHistorial() async {
    const int batchSize = 500;
    try {
      while (true) {
        final snap = await _db.collection('accesos').limit(batchSize).get();
        if (snap.docs.isEmpty) break;
        final batch = _db.batch();
        for (final doc in snap.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        // un pequeño delay NO es obligatorio, pero puede ayudar a no saturar la red:
        await Future.delayed(const Duration(milliseconds: 200));
      }
    } catch (e) {
      // relanza para que la UI pueda mostrar el error si lo requiere
      rethrow;
    }
  }

  /// Mantengo la función original por compatibilidad: registra la última entrada activa global.
  Future<void> registrarSalida(String usuarioDocId) async {
    final q = await _db
        .collection('accesos')
        .where('usuarioId', isEqualTo: usuarioDocId)
        .where('salida', isNull: true)
        .orderBy('entrada', descending: true)
        .limit(1)
        .get();

    if (q.docs.isEmpty) throw Exception('No se encontró entrada activa');

    final doc = q.docs.first;
    await doc.reference.update({'salida': Timestamp.fromDate(DateTime.now())});
  }
}
