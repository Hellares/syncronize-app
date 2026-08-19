import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/features/compra/presentation/widgets/compra_variantes_sheet.dart';
import 'package:syncronize/features/producto/data/models/producto_list_item_model.dart';
import 'package:syncronize/features/producto/domain/entities/producto_variante.dart';

/// El sheet de compra no puede ofrecer los graneles: entran al stock ABRIENDO
/// un saco, y esa apertura es la que les calcula el costo.
void main() {
  Map<String, dynamic> variante(String id, String nombre,
          {String? abreHacia, Object? rendimiento}) =>
      {
        'id': id,
        'nombre': nombre,
        'sku': 'SKU-$id',
        'codigoEmpresa': 'VAR-$id',
        'isActive': true,
        if (abreHacia != null) 'varianteAperturaId': abreHacia,
        if (rendimiento != null) 'rendimientoApertura': rendimiento,
      };

  final raton = ProductoListItemModel.fromJson({
    'id': 'p1',
    'nombre': 'ALIMENTO PARA RATON',
    'codigoEmpresa': 'PROD-001',
    'tieneVariantes': true,
    'unidadMedida': {'simboloLocal': 'g'},
    'variantes': [
      variante('saco15', 'ADULTO / POLLO / SACO 15KG',
          abreHacia: 'granel', rendimiento: 15000),
      variante('saco25', 'ADULTO / POLLO / SACO 25KG',
          abreHacia: 'granel', rendimiento: 25000),
      variante('granel', 'ADULTO / POLLO / GRANEL'),
    ],
  });

  Future<List<(ProductoVariante, int)>> abrir(WidgetTester tester) async {
    final elegidas = <(ProductoVariante, int)>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showCompraVariantesSheet(
              context: context,
              producto: raton,
              sedeId: 'sede1',
              cantidades: const {},
              onCantidad: (v, c) => elegidas.add((v, c)),
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return elegidas;
  }

  testWidgets('arranca mostrando solo los sacos, con los graneles plegados',
      (tester) async {
    await abrir(tester);

    expect(find.text('ADULTO / POLLO / SACO 15KG'), findsOneWidget);
    expect(find.text('ADULTO / POLLO / SACO 25KG'), findsOneWidget);
    // Plegado: el granel existe como sección, pero no como fila.
    expect(find.text('ADULTO / POLLO / GRANEL'), findsNothing);
    expect(find.textContaining('No se compran'), findsOneWidget);
  });

  testWidgets('el contador del encabezado cuenta las que se COMPRAN',
      (tester) async {
    // Decir "3 variantes" y ofrecer 2 se lee como si faltara una.
    await abrir(tester);

    expect(find.text('2 se compran'), findsOneWidget);
  });

  testWidgets('desplegado, el granel se ve pero no se puede sumar',
      (tester) async {
    await abrir(tester);
    await tester.tap(find.textContaining('No se compran'));
    await tester.pumpAndSettle();

    expect(find.text('ADULTO / POLLO / GRANEL'), findsOneWidget);
    expect(find.text('sale de abrir un saco'), findsOneWidget);
    // La fila del granel no trae stepper: siguen siendo los 2 de los sacos.
    expect(find.byIcon(Icons.add_circle_outline), findsNWidgets(2));
  });

  testWidgets('sumar un saco lo reporta en unidades atómicas', (tester) async {
    final elegidas = await abrir(tester);
    await tester.tap(find.byIcon(Icons.add_circle_outline).first);
    await tester.pumpAndSettle();

    expect(elegidas.length, 1);
    expect(elegidas.first.$1.id, 'saco15');
    // Un saco es 1 unidad: la presentación en kg es del granel, no de él.
    expect(elegidas.first.$2, 1);
  });

  testWidgets('el buscador no resucita un granel a la lista comprable',
      (tester) async {
    await abrir(tester);
    await tester.enterText(find.byType(TextFormField).first, 'granel');
    await tester.pumpAndSettle();

    // Queda solo la sección bloqueada: nada que comprar con ese término.
    expect(find.textContaining('No se compran'), findsOneWidget);
    expect(find.byIcon(Icons.add_circle_outline), findsNothing);
  });
}
