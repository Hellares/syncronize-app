import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/features/compra/domain/entities/compra_analytics.dart';
import 'package:syncronize/features/compra/presentation/widgets/analytics/gastos_factura_card.dart';

/// 🔴 La tarjeta vive dentro de un `SingleChildScrollView > Column`, o sea con
/// altura LIBRE. Un `Row(crossAxisAlignment: stretch)` ahí adentro le pasa
/// h=Infinity a sus hijos y revienta en performLayout — pasó al entrar a
/// Analytics de Compras, y `dart analyze` no lo ve porque es un error de
/// layout en runtime. Estos tests montan la tarjeta en ese mismo contexto.
void main() {
  GastosFacturaReporte reporte({
    double total = 40,
    double alCosto = 40,
    double financiero = 0,
    List<GastoAgrupado> porCategoria = const [],
    List<GastoAgrupado> porPeriodo = const [],
    List<GastoAgrupado> porProveedor = const [],
  }) {
    return GastosFacturaReporte(
      resumen: GastosFacturaResumen(
        total: total,
        alCosto: alCosto,
        financiero: financiero,
        cantidadGastos: 3,
        comprasConGasto: 2,
        totalComprado: 1904.5,
        porcentajeSobreCompras: 2.1,
      ),
      porCategoria: porCategoria,
      porPeriodo: porPeriodo,
      porProveedor: porProveedor,
    );
  }

  /// El mismo árbol que arma `CompraAnalyticsPage`: scroll vertical con la
  /// tarjeta adentro de una Column.
  Future<void> montar(
    WidgetTester tester,
    GastosFacturaReporte r, {
    VoidCallback? onVerDetalle,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                GastosFacturaCard(reporte: r, onVerDetalle: onVerDetalle),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('se dibuja con altura libre sin romper el layout', (tester) async {
    await montar(
      tester,
      reporte(
        porCategoria: [
          const GastoAgrupado(
            id: 'cat-1',
            nombre: 'MOVILIDAD',
            total: 30,
            alCosto: 30,
            cantidad: 2,
          ),
          const GastoAgrupado(nombre: 'Sin categoría', total: 10, cantidad: 1),
        ],
        porPeriodo: [
          const GastoAgrupado(nombre: '2026-08', total: 40, cantidad: 3),
        ],
        porProveedor: [
          const GastoAgrupado(id: 'p-1', nombre: 'ARCA', total: 40, cantidad: 3),
        ],
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Gastos de factura'), findsOneWidget);
    expect(find.text('MOVILIDAD'), findsOneWidget);
  });

  testWidgets('el balde sin categoría avisa cuánto falta clasificar',
      (tester) async {
    await montar(
      tester,
      reporte(
        porCategoria: [
          const GastoAgrupado(nombre: 'Sin categoría', total: 40, cantidad: 3),
        ],
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      find.textContaining('sin categoría', findRichText: true),
      findsWidgets,
    );
  });

  testWidgets('sin gastos muestra el vacío y no los cortes', (tester) async {
    await montar(tester, reporte(total: 0, alCosto: 0));

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Todavía no hay gastos'), findsOneWidget);
    expect(find.text('Al costo'), findsNothing);
  });

  testWidgets('"Ver detalle" solo aparece si hay a dónde ir', (tester) async {
    await montar(tester, reporte());
    expect(tester.takeException(), isNull);
    expect(find.text('Ver detalle'), findsNothing);

    var tocado = false;
    await montar(tester, reporte(), onVerDetalle: () => tocado = true);
    expect(tester.takeException(), isNull);
    expect(find.text('Ver detalle'), findsOneWidget);

    await tester.tap(find.text('Ver detalle'));
    expect(tocado, isTrue);
  });

  testWidgets('los dos cortes conviven en la misma fila', (tester) async {
    await montar(tester, reporte(total: 50, alCosto: 40, financiero: 10));

    expect(tester.takeException(), isNull);
    expect(find.text('Al costo'), findsOneWidget);
    expect(find.text('Financiero'), findsOneWidget);
  });
}
