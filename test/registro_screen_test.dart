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

  testWidgets('No hay opción Visitante en Tipo de usuario', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegistroScreen()));

    // open dropdown
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();

    // Visitante should not be in the dropdown
    expect(find.text('Visitante'), findsNothing);

    // Barcode should still be visible after choosing other types
    await tester.tap(find.text('Profesor').last);
    await tester.pumpAndSettle();
    expect(find.text('Código del carnet (barcode)'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Administrador').last);
    await tester.pumpAndSettle();
    expect(find.text('Código del carnet (barcode)'), findsOneWidget);
  });

  testWidgets('Programa académico hidden when Tipo de usuario is Profesor', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegistroScreen()));

    // Initially Estudiante -> programa visible
    expect(find.text('Programa académico'), findsOneWidget);

    // Enter a value then switch to Profesor to ensure it's cleared/hidden
    await tester.enterText(find.byType(TextField).at(3), 'Ingeniería');
    await tester.pumpAndSettle();

    // open dropdown and select Profesor
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profesor').last);
    await tester.pumpAndSettle();

    // programa should not be present for Profesor
    expect(find.text('Programa académico'), findsNothing);

    // switch back to Estudiante
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Estudiante').last);
    await tester.pumpAndSettle();

    // programa visible again but empty (previous value cleared)
    expect(find.text('Programa académico'), findsOneWidget);
    expect(find.text('Ingeniería'), findsNothing);
  });
}
