import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/features/producto/data/models/producto_list_item_model.dart';

/// El catálogo local del POS se guarda con `fromEntity(p).toJson()` y se lee
/// con `fromJson`. Si `fromEntity` se come un campo, `toJson` no tiene qué
/// escribir y el producto vuelve de disco sin él — aunque `fromJson` y
/// `toJson` se vean simétricos.
///
/// Pasó con `tipoVencimiento`/`diasVidaUtil` (la línea de compra dejaba de
/// pedir la fecha) y habría pasado con `codigoBarras`/`sku`, que el escáner de
/// la venta rápida usa para resolver el código SIN red.
void main() {
  final json = {
    'id': 'p1',
    'nombre': 'COCA COLA 500ML',
    'codigoEmpresa': 'PROD-001',
    'codigoBarras': '7750182000123',
    'sku': 'CC-500',
    'tipoVencimiento': 'CADUCIDAD',
    'diasVidaUtil': 180,
  };

  test('lee el código de barras y el SKU que manda el backend', () {
    final p = ProductoListItemModel.fromJson(json);

    expect(p.codigoBarras, '7750182000123');
    expect(p.sku, 'CC-500');
  });

  test('sobreviven al camino del disco: fromEntity -> toJson -> fromJson', () {
    final deRed = ProductoListItemModel.fromJson(json);
    final deDisco = ProductoListItemModel.fromJson(
      ProductoListItemModel.fromEntity(deRed).toJson(),
    );

    expect(deDisco.codigoBarras, '7750182000123');
    expect(deDisco.sku, 'CC-500');
    expect(deDisco.tipoVencimiento, 'CADUCIDAD');
    expect(deDisco.diasVidaUtil, 180);
  });

  test('sin código de barras ni SKU quedan en null, no en vacío', () {
    final p = ProductoListItemModel.fromJson({
      'id': 'p2',
      'nombre': 'SIN CODIGO',
      'codigoEmpresa': 'PROD-002',
    });
    final deDisco = ProductoListItemModel.fromJson(
      ProductoListItemModel.fromEntity(p).toJson(),
    );

    expect(deDisco.codigoBarras, isNull);
    expect(deDisco.sku, isNull);
  });
}
