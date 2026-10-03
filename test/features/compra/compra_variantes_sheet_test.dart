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
    expect(find.byIcon(Icons.add), findsNWidgets(2));
  });

  testWidgets('sumar un saco lo reporta en unidades atómicas', (tester) async {
    final elegidas = await abrir(tester);
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();

    expect(elegidas.length, 1);
    expect(elegidas.first.$1.id, 'saco15');
    // Un saco es 1 unidad: la presentación en kg es del granel, no de él.
    expect(elegidas.first.$2, 1);
  });

  testWidgets('la cantidad se escribe en el stepper y el + la sigue',
      (tester) async {
    final elegidas = await abrir(tester);
    // El primer campo es el buscador; después, un stepper por saco.
    await tester.enterText(find.byType(TextField).at(1), '24');
    await tester.pumpAndSettle();
    expect(elegidas.last.$1.id, 'saco15');
    expect(elegidas.last.$2, 24);

    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();
    expect(elegidas.last.$2, 25);
    expect(find.text('25'), findsOneWidget);

    // Borrar para reescribir no saca la línea de la compra.
    final antes = elegidas.length;
    await tester.enterText(find.byType(TextField).at(1), '');
    await tester.pumpAndSettle();
    expect(elegidas.length, antes);
  });

  testWidgets('el buscador no resucita un granel a la lista comprable',
      (tester) async {
    await abrir(tester);
    await tester.enterText(find.byType(TextFormField).first, 'granel');
    await tester.pumpAndSettle();

    // Queda solo la sección bloqueada: nada que comprar con ese término.
    expect(find.textContaining('No se compran'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsNothing);
  });

  group('diseños de una colección', () {
    Map<String, dynamic> atributo(
            String id, String clave, String nombre, String valor) =>
        {
          'id': '$id-$clave',
          'atributoId': 'a-$clave',
          'valor': valor,
          'atributo': {
            'id': 'a-$clave',
            'nombre': nombre,
            'clave': clave,
            'tipo': 'SELECT',
          },
        };

    Map<String, dynamic> edredon(String id, String material, {String? diseno}) =>
        {
          ...variante(id, [
            '2 PLAZAS',
            material,
            'CRISTAL',
            if (diseno != null) diseno,
          ].join(' / ')),
          'atributosValores': [
            atributo(id, 'material', 'Material', material),
            atributo(id, 'dise_o', 'Colección', 'CRISTAL'),
            if (diseno != null) atributo(id, 'diseno', 'Diseño', diseno),
          ],
          if (id == 'd1')
            'stocksPorSede': [
              {
                'sedeId': 'sede1',
                'sedeNombre': 'Principal',
                'sedeCodigo': 'S1',
                'cantidad': 3,
                'precio': 75,
                'precioCosto': 45,
                'precioConfigurado': true,
              },
            ],
        };

    final edredones = ProductoListItemModel.fromJson({
      'id': 'p2',
      'nombre': 'EDREDONES',
      'codigoEmpresa': 'PROD-002',
      'tieneVariantes': true,
      'variantes': [
        edredon('d2', 'TELA', diseno: 'D2'),
        edredon('carn', 'CARNERITO'),
        edredon('d1', 'TELA', diseno: 'D1'),
      ],
    });

    Future<List<(ProductoVariante, int)>> abrirEdredones(
      WidgetTester tester, {
      Map<String, int> cantidades = const {},
      void Function(ProductoVariante, double?)? onCosto,
      void Function(ProductoVariante, double?)? onVenta,
    }) async {
      final elegidas = <(ProductoVariante, int)>[];
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showCompraVariantesSheet(
                context: context,
                producto: edredones,
                sedeId: 'sede1',
                cantidades: cantidades,
                onCantidad: (v, c) => elegidas.add((v, c)),
                onCosto: onCosto,
                onVenta: onVenta,
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

    testWidgets('van plegados en un renglón; al abrirlo se compra cada uno',
        (tester) async {
      final elegidas = await abrirEdredones(tester);

      expect(find.text('CRISTAL'), findsOneWidget);
      expect(find.text('2 PLAZAS / TELA / CRISTAL · 2 diseños'), findsOneWidget);
      // La variante sin diseño sigue suelta, con su nombre completo.
      expect(find.text('2 PLAZAS / CARNERITO / CRISTAL'), findsOneWidget);
      expect(find.text('D1'), findsNothing);

      await tester.tap(find.text('CRISTAL'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('D1'), findsWidgets);
      expect(find.text('D2'), findsWidgets);
      // Costo y venta juntos, para ver el margen al comprar.
      expect(find.textContaining('Costo S/'), findsOneWidget);
      expect(find.textContaining('Venta S/'), findsOneWidget);

      // La colección va donde aparece su primer diseño (D2 viene antes que
      // CARNERITO): steppers D1, D2, CARNERITO.
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();
      expect(elegidas.single.$1.id, 'd1');
      // El renglón de la colección dice lo que ya se compra de ella.
      expect(find.text('1 u'), findsOneWidget);
    });

    testWidgets('costo y venta se cargan en la misma fila, sin overflow',
        (tester) async {
      final costos = <String, double?>{};
      final ventas = <String, double?>{};
      await abrirEdredones(
        tester,
        cantidades: const {'d1': 2},
        onCosto: (v, c) => costos[v.id] = c,
        onVenta: (v, p) => ventas[v.id] = p,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Costo'), findsOneWidget);
      expect(find.text('Venta'), findsOneWidget);
      // La venta de hoy va de hint: vacío se mantiene.
      expect(find.text('75.00'), findsOneWidget);

      final campos = find.byType(TextFormField);
      // 0 buscador · 1 costo · 2 venta (el stepper es un TextField a secas).
      await tester.enterText(campos.at(2), '89.90');
      await tester.pumpAndSettle();
      expect(ventas['d1'], 89.90);

      await tester.tap(find.textContaining('usar costo anterior'));
      await tester.pumpAndSettle();
      expect(costos['d1'], 45);

      // Vaciar uno de los dos = el de hoy: el costo vuelve al actual y la
      // venta vacía se manda como null (el backend mantiene la de hoy).
      await tester.enterText(campos.at(1), '50');
      await tester.pumpAndSettle();
      expect(costos['d1'], 50);
      await tester.enterText(campos.at(1), '');
      await tester.pumpAndSettle();
      expect(costos['d1'], 45);
      await tester.enterText(campos.at(2), '');
      await tester.pumpAndSettle();
      expect(ventas['d1'], isNull);
    });

    testWidgets('si ya se compraba un diseño, la colección arranca abierta',
        (tester) async {
      await abrirEdredones(tester, cantidades: const {'d2': 3});

      expect(find.text('3 u'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsNWidgets(3));
    });

    testWidgets('filtrando, la colección queda plegada y se abre a mano',
        (tester) async {
      await abrirEdredones(tester);
      await tester.enterText(find.byType(TextFormField).first, 'd2');
      await tester.pumpAndSettle();

      expect(find.text('CRISTAL'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsNothing);

      await tester.tap(find.text('CRISTAL'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });
}
