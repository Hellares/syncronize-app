import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/features/producto/data/models/producto_model.dart';

/// `fromJson` leía diez relaciones que `toJson` no devolvía: marca, categoría,
/// sede, unidades, imágenes, archivos, atributos, variantes y stock por sede.
/// Cualquier ida y vuelta por JSON las perdía **en silencio** — el producto
/// seguía siendo válido, solo que sin marca ni variantes.
///
/// Estas pruebas fijan la simetría: lo que entra tiene que salir.
void main() {
  Map<String, dynamic> productoCompleto() => {
        'id': 'p1',
        'empresaId': 'e1',
        'codigoEmpresa': 'PROD-001',
        'codigoSistema': 'SYS-001',
        'nombre': 'GALAXY S26 ULTRA',
        'creadoEn': '2026-08-01T10:00:00.000Z',
        'actualizadoEn': '2026-08-02T10:00:00.000Z',
        'visibleMarketplace': true,
        'destacado': false,
        'isActive': true,
        'categoria': {'id': 'c1', 'nombre': 'CELULARES'},
        'marca': {'id': 'm1', 'nombre': 'SAMSUNG', 'logo': 'https://x/l.png'},
        'sede': {'id': 's1', 'nombre': 'Sede Principal'},
        'imagenes': ['https://x/1.jpg', 'https://x/2.jpg'],
      };

  test('la marca sobrevive a un ida y vuelta por JSON', () {
    final original = ProductoModel.fromJson(productoCompleto());
    expect(original.marca?.nombre, 'SAMSUNG');

    final revivido = ProductoModel.fromJson(original.toJson());

    expect(revivido.marca?.nombre, 'SAMSUNG');
    expect(revivido.marca?.id, 'm1');
    expect(revivido.marca?.logo, 'https://x/l.png');
  });

  test('la categoría, la sede y las imágenes también sobreviven', () {
    final revivido = ProductoModel.fromJson(
      ProductoModel.fromJson(productoCompleto()).toJson(),
    );

    expect(revivido.categoria?.nombre, 'CELULARES');
    expect(revivido.sede?.nombre, 'Sede Principal');
    expect(revivido.imagenes, hasLength(2));
  });

  test('los escalares no se alteran en el viaje', () {
    final revivido = ProductoModel.fromJson(
      ProductoModel.fromJson(productoCompleto()).toJson(),
    );

    expect(revivido.id, 'p1');
    expect(revivido.nombre, 'GALAXY S26 ULTRA');
    expect(revivido.codigoEmpresa, 'PROD-001');
    expect(revivido.visibleMarketplace, isTrue);
  });

  test('la unidad de presentación sobrevive al ida y vuelta', () {
    // Es lo que el formulario relee al editar: si se pierde acá, la sección
    // aparece apagada y guardar el producto BORRA la presentación.
    final revivido = ProductoModel.fromJson(
      ProductoModel.fromJson({
        ...productoCompleto(),
        'unidadPresentacionId': 'um-kg',
        'factorPresentacion': 1000,
        'unidadPresentacionSimbolo': 'kg',
      }).toJson(),
    );

    expect(revivido.unidadPresentacionId, 'um-kg');
    expect(revivido.factorPresentacion, 1000);
    expect(revivido.unidadPresentacionSimbolo, 'kg');
    // El traductor que usan las pantallas de captura sale de acá.
    expect(revivido.presentacion.activa, isTrue);
    expect(revivido.presentacion.cantidadAUnidadDeVenta(22), 22000);
    expect(revivido.presentacion.precioAUnidadDeVenta(8), closeTo(0.008, 1e-9));
  });

  test('sin presentación el traductor no altera ningún número', () {
    final p = ProductoModel.fromJson(productoCompleto());

    expect(p.presentacion.activa, isFalse);
    expect(p.presentacion.cantidadAUnidadDeVenta(22), 22);
    expect(p.presentacion.precioAUnidadDeVenta(8), 8);
  });

  test('el factor tolera que el backend lo mande como String', () {
    // Prisma serializa Decimal como String.
    final p = ProductoModel.fromJson({
      ...productoCompleto(),
      'unidadPresentacionId': 'um-kg',
      'factorPresentacion': '1000',
    });

    expect(p.factorPresentacion, 1000);
  });

  test('un producto sin relaciones no inventa claves vacías', () {
    final minimo = ProductoModel.fromJson({
      'id': 'p2',
      'empresaId': 'e1',
      'codigoEmpresa': 'PROD-002',
      'codigoSistema': 'SYS-002',
      'nombre': 'PRODUCTO PELADO',
      'creadoEn': '2026-08-01T10:00:00.000Z',
      'actualizadoEn': '2026-08-01T10:00:00.000Z',
      'visibleMarketplace': true,
      'destacado': false,
      'isActive': true,
    });

    final json = minimo.toJson();

    // Sin esto la caché guardaría `"marca": null` y al leerlo daría lo mismo,
    // pero infla el payload y confunde al depurar.
    expect(json.containsKey('marca'), isFalse);
    expect(json.containsKey('categoria'), isFalse);
    expect(json.containsKey('variantes'), isFalse);
    expect(ProductoModel.fromJson(json).marca, isNull);
  });
}
