import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo/screens/registro_screen.dart';

void main() {
  testWidgets('Registro screen has expected fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegistroScreen()));

    expect(find.text('Nombre completo'), findsOneWidget);
    expect(find.text('Cédula'), findsOneWidget);
    expect(find.text('Código del carnet (barcode)'), findsOneWidget);
    expect(find.text('Programa académico'), findsOneWidget);
    expect(find.text('Foto del carnet (opcional)'), findsNothing);
    expect(find.text('Foto del estudiante (opcional)'), findsNothing);
    expect(find.text('Tipo de usuario'), findsOneWidget);

    expect(find.text('Guardar usuario'), findsOneWidget);
  });
}
