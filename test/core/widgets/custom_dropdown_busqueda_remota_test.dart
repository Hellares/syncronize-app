import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/core/widgets/custom_dropdown.dart';

/// El filtro local del dropdown NO debe pisar una búsqueda remota.
///
/// El backend busca por palabras sobre `textoBusqueda` (nombre + marca +
/// categoría + códigos, normalizado sin tildes). El label del item suele
/// traer solo el nombre, así que volver a filtrar por substring del label
/// descartaba resultados legítimos: buscar "samsung" (la marca) devolvía
/// vacío aunque el backend hubiera encontrado el producto.
void main() {
  /// Abre el dropdown y escribe [texto] en su caja de búsqueda.
  Future<void> buscar(WidgetTester tester, String texto) async {
    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), texto);
    await tester.pumpAndSettle();
  }

  Widget montar({
    required List<DropdownItem<String>> items,
    ValueChanged<String>? onSearchChanged,
  }) {
    return MaterialApp(
      home: Scaffold(
        // Alto acotado a propósito: el panel se abre en el espacio LIBRE
        // debajo del campo. Si el dropdown ocupa toda la pantalla ese
        // espacio es 0 y la lista no llega a construir sus items.
        body: SizedBox(
          width: 300,
          height: 60,
          child: CustomDropdown<String>(
            hintText: 'Buscar producto...',
            items: items,
            dropdownStyle: DropdownStyle.searchable,
            showSearchBox: true,
            searchDebounceMs: 0,
            onSearchChanged: onSearchChanged,
            onChanged: (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets(
      'con onSearchChanged muestra el resultado remoto aunque el texto no '
      'esté en el label', (tester) async {
    final consultas = <String>[];
    // Lo que devolvería el backend para "samsung": la marca no está en el
    // label, solo el nombre.
    final items = [
      const DropdownItem(value: 'p1', label: 'Televisor LED 55 | Stock: 4'),
    ];

    await tester.pumpWidget(
      montar(items: items, onSearchChanged: consultas.add),
    );

    await buscar(tester, 'samsung');

    expect(find.text('Televisor LED 55 | Stock: 4'), findsOneWidget);
    expect(find.text('Sin resultados'), findsNothing);
    expect(consultas, contains('samsung'));
  });

  testWidgets('con onSearchChanged tolera palabras separadas y tildes',
      (tester) async {
    final items = [
      const DropdownItem(value: 'p1', label: 'Monitor Samsung 24 pulgadas'),
      const DropdownItem(value: 'p2', label: 'Café Molido 500g'),
    ];

    await tester.pumpWidget(montar(items: items, onSearchChanged: (_) {}));

    // "monitor 24" no existe como substring; "cafe" tampoco (el label
    // tiene tilde). Ambos los resuelve el backend.
    await buscar(tester, 'monitor 24');
    expect(find.text('Monitor Samsung 24 pulgadas'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'cafe');
    await tester.pumpAndSettle();
    expect(find.text('Café Molido 500g'), findsOneWidget);
  });

  testWidgets('sin onSearchChanged sigue filtrando localmente',
      (tester) async {
    final items = [
      const DropdownItem(value: 'p1', label: 'Televisor LED 55'),
      const DropdownItem(value: 'p2', label: 'Lavadora 12kg'),
    ];

    await tester.pumpWidget(montar(items: items));

    await buscar(tester, 'lavadora');

    expect(find.text('Lavadora 12kg'), findsOneWidget);
    expect(find.text('Televisor LED 55'), findsNothing);

    await tester.enterText(find.byType(TextField), 'samsung');
    await tester.pumpAndSettle();
    expect(find.text('Sin resultados'), findsOneWidget);
  });
}
