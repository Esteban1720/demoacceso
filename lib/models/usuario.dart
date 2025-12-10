import 'package:cloud_firestore/cloud_firestore.dart';

class Usuario {
  final String id;
  final String nombreCompleto;
  final String cedula;
  final String codigoCarnet;
  final String programaAcademico;
  final String tipoUsuario;
  final DateTime creadoEn;

  Usuario({
    required this.id,
    required this.nombreCompleto,
    required this.cedula,
    required this.codigoCarnet,
    required this.programaAcademico,
    required this.tipoUsuario,
    required this.creadoEn,
  });

  factory Usuario.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Usuario(
      id: doc.id,
      nombreCompleto: d['nombreCompleto'] ?? '',
      cedula: d['cedula'] ?? '',
      codigoCarnet: d['codigoCarnet'] ?? '',
      programaAcademico: d['programaAcademico'] ?? '',
      tipoUsuario: d['tipodeusuario'] ?? d['tipoUsuario'] ?? 'Estudiante',
      creadoEn: (d['creadoEn'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'nombreCompleto': nombreCompleto,
    'cedula': cedula,
    'codigoCarnet': codigoCarnet,
    'programaAcademico': programaAcademico,
    'tipodeusuario': tipoUsuario,
    'creadoEn': Timestamp.fromDate(creadoEn),
  };
}
