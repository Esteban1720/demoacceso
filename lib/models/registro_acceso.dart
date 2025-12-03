import 'package:cloud_firestore/cloud_firestore.dart';

class RegistroAcceso {
  final String id;
  final String estudianteId;
  final DateTime entrada;
  final DateTime? salida;

  RegistroAcceso({
    required this.id,
    required this.estudianteId,
    required this.entrada,
    this.salida,
  });

  factory RegistroAcceso.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return RegistroAcceso(
      id: doc.id,
      estudianteId: d['estudianteId'],
      entrada: (d['entrada'] as Timestamp).toDate(),
      salida: d['salida'] != null ? (d['salida'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'estudianteId': estudianteId,
    'entrada': Timestamp.fromDate(entrada),
    'salida': salida != null ? Timestamp.fromDate(salida!) : null,
  };
}
