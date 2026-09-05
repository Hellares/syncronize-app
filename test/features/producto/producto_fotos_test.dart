/// 🔴 `imagenes` y `archivos` son LA MISMA foto por dos caminos.
///
/// `archivos` trae `url` + `urlThumbnail` —que apunta a
/// `/thumbnails/…-thumb.webp`— y `imagenes` la url plana. Mezclar las dos
/// listas **duplica cada foto**: un producto con una salía con dos, y con dos
/// ofrecía cuatro. Un `Set` no lo arregla porque las cadenas son distintas.
///
/// Lo reportó el user el 04-09 apenas salió el catálogo con una tarjeta por
/// diseño, que fue donde se hizo visible.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/features/producto/domain/entities/producto.dart';
import 'package:syncronize/features/producto/domain/entities/producto_variante.dart';

void main() {
  const url1 = 'https://x/productos/1788122307937-abc.webp';
  const thumb1 = 'https://x/productos/thumbnails/1788122307937-abc-thumb.webp';
  const url2 = 'https://x/productos/1788131122439-def.webp';
  const thumb2 = 'https://x/productos/thumbnails/1788131122439-def-thumb.webp';

  Producto conFotos({
    List<ProductoArchivo>? archivos,
    List<String>? imagenes,
  }) =>
      Producto(
        id: 'p1',
        empresaId: 'e1',
        nombre: 'EDREDON',
        codigoEmpresa: 'EDR-1',
        codigoSistema: 'SYS-1',
        visibleMarketplace: true,
        destacado: false,
        isActive: true,
        creadoEn: DateTime(2026),
        actualizadoEn: DateTime(2026),
        archivos: archivos,
        imagenes: imagenes,
      );

  ProductoArchivo archivo(String id, String url, String? thumb) =>
      ProductoArchivo(id: id, url: url, urlThumbnail: thumb, orden: 0);

  group('Producto.fotos', () {
    test('🔴 una foto en las DOS listas cuenta UNA sola vez', () {
      final p = conFotos(
        archivos: [archivo('a1', url1, thumb1)],
        imagenes: const [url1],
      );
      expect(p.fotos(), [url1]);
      expect(p.fotos(miniaturas: true), [thumb1]);
    });

    test('🔴 dos fotos no se convierten en cuatro', () {
      final p = conFotos(
        archivos: [archivo('a1', url1, thumb1), archivo('a2', url2, thumb2)],
        imagenes: const [url1, url2],
      );
      expect(p.fotos().length, 2);
      expect(p.fotos(miniaturas: true), [thumb1, thumb2]);
    });

    test('sin archivos se cae a `imagenes`, que es lo viejo', () {
      final p = conFotos(imagenes: const [url1, url2]);
      expect(p.fotos(), [url1, url2]);
      // Sin archivo no hay thumbnail: se devuelve lo que hay.
      expect(p.fotos(miniaturas: true), [url1, url2]);
    });

    test('un archivo sin thumbnail cae a su url', () {
      final p = conFotos(archivos: [archivo('a1', url1, null)]);
      expect(p.fotos(miniaturas: true), [url1]);
    });

    test('sin nada, lista vacía', () {
      expect(conFotos().fotos(), isEmpty);
    });
  });

  test('las fotos de una variante salen de sus archivos, sin repetir', () {
    final v = ProductoVariante(
      id: 'v1',
      productoId: 'p1',
      empresaId: 'e1',
      nombre: 'EDREDON ROSA',
      sku: 'SKU-1',
      codigoEmpresa: 'V-1',
      isActive: true,
      orden: 0,
      atributosValores: const [],
      creadoEn: DateTime(2026),
      actualizadoEn: DateTime(2026),
      archivos: const [
        ProductoVarianteArchivo(id: 'a1', url: url1, urlThumbnail: thumb1, orden: 0),
        ProductoVarianteArchivo(id: 'a2', url: url1, urlThumbnail: thumb1, orden: 1),
      ],
    );
    expect(v.fotos(), [url1]);
    expect(v.fotos(miniaturas: true), [thumb1]);
  });
}
