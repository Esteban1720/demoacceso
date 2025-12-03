import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/registro_acceso.dart';

class HistorialScreen extends StatelessWidget {
  const HistorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (Firebase.apps.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Historial de accesos')),
        body: const Center(
          child: Text(
            'Firebase no está configurado. Active Firestore para ver registros.',
          ),
        ),
      );
    }
    final coll = FirebaseFirestore.instance
        .collection('access_records')
        .orderBy('entrada', descending: true);
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de accesos')),
      body: StreamBuilder<QuerySnapshot>(
        stream: coll.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay registros'));
          }
          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final reg = RegistroAcceso.fromDoc(docs[index]);
              final salida = reg.salida != null
                  ? reg.salida!.toLocal().toString()
                  : '-';
              final duracion = reg.salida != null
                  ? '${reg.salida!.difference(reg.entrada).inMinutes} min'
                  : '-';
              return ListTile(
                title: Text('Estudiante: ${reg.estudianteId}'),
                subtitle: Text(
                  'Entrada: ${reg.entrada.toLocal()}\nSalida: $salida\nDuración: $duracion',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
