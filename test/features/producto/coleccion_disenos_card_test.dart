import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:syncronize/features/producto/domain/entities/atributo_valor.dart';
import 'package:syncronize/features/producto/domain/entities/producto_variante.dart';
import 'package:syncronize/features/producto/domain/entities/stock_por_sede_info.dart';
import 'package:syncronize/features/producto/presentation/widgets/coleccion_disenos_card.dart';

/// La hoja de Variantes junta los diseños de una colección en una card.
///
/// 🔴 Lo de abajo de todo es un test de MONTAJE: `flutter analyze` no ve el
/// layout. La card vive en la hoja con 12 de margen por lado: en un teléfono
/// de 360 px le quedan 336.
const _tam = AtributoInfo(id: 'a-tam', nombre: 'Tamaño', clave: 'tamano', tipo: 'SELECT');
const _mat = AtributoInfo(id: 'a-mat', nombre: 'Material', clave: 'material', tipo: 'SELECT');
const _col = AtributoInfo(id: 'a-col', nombre: 'Colección', clave: 'dise_o', tipo: 'SELECT');
const _dis = AtributoInfo(id: 'a-dis', nombre: 'Diseño', clave: 'diseno', tipo: 'TEXTO');

ProductoVariante _v(String id, {required String material, String coleccion = 'CRISTAL', String? diseno}) {
  final valores = [
    AtributoValor(id: '$id-1', atributoId: _tam.id, valor: '2 PLAZAS', atributo: _tam),
    AtributoValor(id: '$id-2', atributoId: _mat.id, valor: material, atributo: _mat),
    AtributoValor(id: '$id-3', atributoId: _col.id, valor: coleccion, atributo: _col),
    if (diseno != null)
      AtributoValor(id: '$id-4', atributoId: _dis.id, valor: diseno, atributo: _dis),
  ];
  return ProductoVariante(
    id: id,
    productoId: 'p1',
    empresaId: 'e1',
    nombre: [
      '2 PLAZAS',
      material,
      coleccion,
      if (diseno != null) diseno,
    ].join(' / '),
    sku: id,
    codigoEmpresa: id,
    atributosValores: valores,
    isActive: true,
    orden: 0,
    creadoEn: DateTime(2026),
    actualizadoEn: DateTime(2026),
  );
}

void main() {
  group('agruparPorColeccion', () {
    test('los diseños de CRISTAL TELA van juntos, CARNERITO queda suelta', () {
      final filas = agruparPorColeccion([
        _v('d2', material: 'TELA', diseno: 'D2'),
        _v('carn', material: 'CARNERITO'),
        _v('d1', material: 'TELA', diseno: 'D1'),
        _v('d3', material: 'TELA', diseno: 'D3'),
      ]);

      expect(filas, hasLength(2));
      // El grupo va donde aparece el primer diseño, y por número.
      final grupo = filas[0] as FilaColeccion;
      expect(grupo.disenos.map((d) => d.id), ['d1', 'd2', 'd3']);
      expect((filas[1] as FilaVariante).variante.id, 'carn');
    });

    test('otra colección u otro material es otro grupo', () {
      final filas = agruparPorColeccion([
        _v('c1', material: 'TELA', diseno: 'D1'),
        _v('k1', material: 'TELA', coleccion: 'KITTY', diseno: 'D1'),
        _v('cc1', material: 'CARNERITO', diseno: 'D1'),
      ]);
      expect(filas.whereType<FilaColeccion>(), hasLength(3));
    });

    test('D10 va después de D9 (orden numérico, no de texto)', () {
      final filas = agruparPorColeccion([
        _v('a', material: 'TELA', diseno: 'D10'),
        _v('b', material: 'TELA', diseno: 'D9'),
      ]);
      expect((filas.single as FilaColeccion).disenos.map((d) => valorDiseno(d)), ['D9', 'D10']);
    });

    test('el nombre corto es el valor de la Colección', () {
      expect(nombreColeccion(_v('d1', material: 'TELA', diseno: 'D1')), 'CRISTAL');
    });

    test('el título de la colección es el nombre sin el diseño', () {
      expect(tituloColeccion(_v('d1', material: 'TELA', diseno: 'D1')), '2 PLAZAS / TELA / CRISTAL');
    });
  });

  testWidgets('la fila compacta de "Variantes" entra en 336 px y dice "desde"', (tester) async {
    var toques = 0;
    var agregar = 0;
    final caro = _v('d2', material: 'TELA', diseno: 'D2');
    // Precio por sede: D2 exclusivo más caro.
    ProductoVariante conPrecio(ProductoVariante v, double precio) => ProductoVariante(
          id: v.id,
          productoId: v.productoId,
          empresaId: v.empresaId,
          nombre: v.nombre,
          sku: v.sku,
          codigoEmpresa: v.codigoEmpresa,
          atributosValores: v.atributosValores,
          isActive: true,
          orden: 0,
          stocksPorSede: [
            StockPorSedeInfo(
              sedeId: 's1',
              sedeNombre: 'Principal',
              sedeCodigo: 'S1',
              cantidad: 2,
              precio: precio,
              precioConfigurado: true,
            ),
          ],
          creadoEn: DateTime(2026),
          actualizadoEn: DateTime(2026),
        );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 336,
            child: ColeccionFilaCompacta(
              disenos: [
                conPrecio(_v('d1', material: 'TELA', diseno: 'D1'), 75),
                conPrecio(caro, 95),
                conPrecio(_v('d3', material: 'TELA', diseno: 'D3'), 75),
              ],
              abierta: false,
              ultima: true,
              onTap: () => toques++,
              onAgregar: () => agregar++,
            ),
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(find.text('desde S/75.00'), findsOneWidget);
    expect(find.text('6 u'), findsOneWidget);
    expect(find.text('2 PLAZAS / TELA / CRISTAL · 3 diseños'), findsOneWidget);
    await tester.tap(find.text('CRISTAL'));
    await tester.tap(find.byIcon(Icons.add_photo_alternate_outlined));
    expect(toques, 1);
    expect(agregar, 1);
  });

  testWidgets('la card entra en 336 px, toca cada diseño y "Agregar"', (tester) async {
    final tocados = <String>[];
    final fotos = <String>[];
    var agregar = 0;
    final disenos = [
      _v('d1', material: 'TELA', diseno: 'D1'),
      _v('d2', material: 'TELA', diseno: 'D2'),
      _v('d3', material: 'TELA', diseno: 'D3'),
    ];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 336,
            child: ColeccionDisenosCard(
              disenos: disenos,
              onTapDiseno: (d) => tocados.add(d.id),
              onFotosDiseno: (d) => fotos.add(d.id),
              onAgregar: () => agregar++,
            ),
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
    // Título: la colección; debajo, chico, el nombre completo.
    expect(find.text('CRISTAL'), findsOneWidget);
    expect(find.text('2 PLAZAS / TELA / CRISTAL'), findsOneWidget);
    expect(find.text('3 diseños'), findsOneWidget);
    expect(find.text('D2 · 0'), findsOneWidget);

    await tester.tap(find.text('D2 · 0'));
    await tester.tap(find.byIcon(Icons.image_not_supported_outlined).at(1));
    await tester.tap(find.byIcon(Icons.attach_file).first);
    await tester.tap(find.byKey(ColeccionDisenosCard.keyAgregar));
    expect(tocados, ['d2']);
    expect(fotos, ['d1']);
    expect(agregar, 1);
  });
}
