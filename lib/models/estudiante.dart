import 'package:cloud_firestore/cloud_firestore.dart';

class Estudiante {
  final String id;
  final String nombreCompleto;
  final String codigoCarnet;
  final String? fotoUrl;
  final DateTime creadoEn;

  Estudiante({
    required this.id,
    required this.nombreCompleto,
    required this.codigoCarnet,
    this.fotoUrl,
    required this.creadoEn,
  });

  factory Estudiante.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Estudiante(
      id: doc.id,
      nombreCompleto: d['nombreCompleto'] ?? '',
      codigoCarnet: d['codigoCarnet'] ?? '',
      fotoUrl: d['fotoUrl'],
      creadoEn: (d['creadoEn'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'nombreCompleto': nombreCompleto,
    'codigoCarnet': codigoCarnet,
    'fotoUrl': fotoUrl,
    'creadoEn': Timestamp.fromDate(creadoEn),
  };
}
