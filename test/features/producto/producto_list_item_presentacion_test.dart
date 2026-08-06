import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/features/producto/data/models/producto_list_item_model.dart';

/// Unidad de PRESENTACIÓN: cómo se le habla al usuario cuando la unidad de
/// venta es demasiado chica. Un alimento a granel se guarda en gramos —para
/// que el stock entero y la balanza funcionen— pero se cotiza y se cobra en
/// KILOS.
///
/// El catálogo se persiste en disco con `toJson`, así que si `toJson` no
/// devuelve lo que `fromJson` lee, los campos se pierden **en silencio** y el
/// producto vuelve a mostrarse en gramos sin que nadie se entere.
void main() {
  Map<String, dynamic> ricocan({
    String? simboloPresentacion = 'kg',
    Object? factorPresentacion = 1000,
  }) =>
      {
        'id': 'p1',
        'nombre': 'RICOCAN 22KG',
        'codigoEmpresa': 'PROD-001',
        'unidadMedida': {'simboloLocal': 'g'},
        if (simboloPresentacion != null)
          'unidadPresentacionSimbolo': simboloPresentacion,
        if (factorPresentacion != null)
          'factorPresentacion': factorPresentacion,
      };

  test('lee la presentación del shape plano que manda el backend', () {
    final p = ProductoListItemModel.fromJson(ricocan());

    expect(p.unidadPresentacionSimbolo, 'kg');
    expect(p.factorPresentacion, 1000);
    expect(p.unidadMedidaSimbolo, 'g');
  });

  test('sobrevive al ida y vuelta por JSON', () {
    final original = ProductoListItemModel.fromJson(ricocan());
    final ida = ProductoListItemModel.fromJson(original.toJson());

    expect(ida.unidadPresentacionSimbolo, 'kg');
    expect(ida.factorPresentacion, 1000);
  });

  test('el factor tolera que el backend lo mande como String', () {
    // Prisma serializa Decimal como String.
    final p = ProductoListItemModel.fromJson(
      ricocan(factorPresentacion: '1000.0000'),
    );

    expect(p.factorPresentacion, 1000);
  });

  test('sin presentación, el factor efectivo es 1 y se muestra la unidad de venta',
      () {
    final p = ProductoListItemModel.fromJson(
      ricocan(simboloPresentacion: null, factorPresentacion: null),
    );

    expect(p.unidadPresentacionSimbolo, isNull);
    expect(p.factorPresentacionEfectivo, 1);
    expect(p.simboloVisible, 'g');
  });

  test('un factor de 1 o menos no agrupa nada: se ignora', () {
    // Multiplicar o dividir por él tiene que ser inocuo.
    final p = ProductoListItemModel.fromJson(ricocan(factorPresentacion: 1));

    expect(p.factorPresentacionEfectivo, 1);
  });

  test('con presentación, el símbolo visible es el de presentación', () {
    final p = ProductoListItemModel.fromJson(ricocan());

    expect(p.simboloVisible, 'kg');
    // 9.00 por kg guardados como 0.009 por gramo.
    expect(9.00 / p.factorPresentacionEfectivo, closeTo(0.009, 1e-9));
  });
}
