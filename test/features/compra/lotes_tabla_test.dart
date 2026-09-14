import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:syncronize/features/compra/domain/entities/lote.dart';
import 'package:syncronize/features/compra/presentation/widgets/lotes_tabla.dart';

/// La tabla de lotes (tipo Excel, como el kardex).
///
/// 🔴 Test de MONTAJE: `flutter analyze` no ve el layout. Se monta en el mismo
/// árbol que la página (`Column > Expanded > tabla`).
Lote _lote(
  String id, {
  int actual = 5,
  int inicial = 10,
  EstadoLote estado = EstadoLote.ACTIVO,
  DateTime? vence,
  String? proveedor,
}) {
  final fecha = DateTime.utc(2026, 9, 1);
  return Lote(
    id: id,
    empresaId: 'emp',
    sedeId: 'sede',
    productoStockId: 'ps-$id',
    codigo: 'LOTE-$id',
    precioCosto: 12.5,
    cantidadInicial: inicial,
    cantidadActual: actual,
    fechaIngreso: fecha,
    fechaVencimiento: vence,
    estado: estado,
    nombreProveedor: proveedor,
    creadoPor: 'usr',
    creadoEn: fecha,
    actualizadoEn: fecha,
    productoStock: {
      'producto': {'nombre': 'PETER PORKER $id'},
    },
  );
}

void main() {
  Future<void> montar(
    WidgetTester tester, {
    required List<Lote> lotes,
    bool hasNext = false,
    bool cargandoMas = false,
    ValueChanged<Lote>? onTap,
    VoidCallback? onCargarMas,
  }) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: LotesTabla(
                lotes: lotes,
                hasNext: hasNext,
                cargandoMas: cargandoMas,
                onTap: onTap ?? (_) {},
                onCargarMas: onCargarMas ?? () {},
              ),
            ),
          ],
        ),
      ),
    ));
  }

  testWidgets('se monta sin reventar: encabezado y una fila por lote', (tester) async {
    await montar(tester, lotes: [_lote('1'), _lote('2')]);

    expect(tester.takeException(), isNull);
    expect(find.text('Código'), findsOneWidget);
    expect(find.text('Proveedor'), findsOneWidget);
    expect(find.text('LOTE-1'), findsOneWidget);
    expect(find.text('PETER PORKER 2'), findsOneWidget);
    expect(find.text('5/10'), findsNWidgets(2));
  });

  testWidgets('el valor es lo que QUEDA del lote por su costo', (tester) async {
    await montar(tester, lotes: [_lote('1', actual: 5)]);

    expect(find.text('S/ 12.50'), findsOneWidget); // costo
    expect(find.text('S/ 62.50'), findsOneWidget); // 5 × 12.50
  });

  testWidgets('un lote vencido lo dice en la columna Vence', (tester) async {
    await montar(tester, lotes: [
      _lote('1', vence: DateTime.utc(2020, 1, 15)),
      _lote('2'),
    ]);

    expect(find.textContaining('VENCIDO'), findsOneWidget);
    expect(find.text('—'), findsWidgets); // el que no vence y sin proveedor
  });

  testWidgets('con más páginas aparece "Cargar más" y lo dispara', (tester) async {
    var cargas = 0;
    await montar(
      tester,
      lotes: [_lote('1')],
      hasNext: true,
      onCargarMas: () => cargas++,
    );

    await tester.tap(find.text('Cargar más'));
    await tester.pump();
    expect(cargas, 1);
  });

  testWidgets('sin más páginas no hay "Cargar más"', (tester) async {
    await montar(tester, lotes: [_lote('1')]);

    expect(find.text('Cargar más'), findsNothing);
  });

  testWidgets('tocar una fila entrega ESE lote', (tester) async {
    Lote? tocado;
    await montar(
      tester,
      lotes: [_lote('1'), _lote('2')],
      onTap: (l) => tocado = l,
    );

    await tester.tap(find.text('PETER PORKER 2'));
    await tester.pump();
    expect(tocado?.id, '2');
  });
}
