import 'package:flutter_test/flutter_test.dart';

import 'package:syncronize/features/producto/domain/entities/atributo_valor.dart';
import 'package:syncronize/features/producto/domain/entities/producto_list_item.dart';
import 'package:syncronize/features/producto/domain/entities/producto_variante.dart';
import 'package:syncronize/features/producto/presentation/widgets/producto_selector/busqueda_variantes.dart';

/// Buscar en Venta Rápida por una VARIANTE: "cristal" encuentra EDREDONES y el
/// selector abre ya filtrado.
const _mat = AtributoInfo(id: 'a-mat', nombre: 'Material', clave: 'material', tipo: 'SELECT');
const _col = AtributoInfo(id: 'a-col', nombre: 'Colección', clave: 'dise_o', tipo: 'SELECT');
const _dis = AtributoInfo(id: 'a-dis', nombre: 'Diseño', clave: 'diseno', tipo: 'TEXTO');

ProductoVariante _v(String id, String material, String coleccion,
    {String? diseno, bool activa = true}) {
  return ProductoVariante(
    id: id,
    productoId: 'p1',
    empresaId: 'e1',
    nombre: [material, coleccion, if (diseno != null) diseno].join(' / '),
    sku: id,
    codigoEmpresa: id,
    atributosValores: [
      AtributoValor(id: '$id-m', atributoId: _mat.id, valor: material, atributo: _mat),
      AtributoValor(id: '$id-c', atributoId: _col.id, valor: coleccion, atributo: _col),
      if (diseno != null)
        AtributoValor(id: '$id-d', atributoId: _dis.id, valor: diseno, atributo: _dis),
    ],
    isActive: activa,
    orden: 0,
    creadoEn: DateTime(2026),
    actualizadoEn: DateTime(2026),
  );
}

ProductoListItem _producto(List<ProductoVariante> variantes) => ProductoListItem(
      id: 'p1',
      nombre: 'EDREDONES',
      codigoEmpresa: 'PROD-1',
      destacado: false,
      isActive: true,
      tieneVariantes: true,
      variantes: variantes,
    );

void main() {
  final edredones = _producto([
    _v('d1', 'TELA', 'CRISTAL', diseno: 'D1'),
    _v('d2', 'TELA', 'CRISTAL', diseno: 'D2'),
    _v('carn', 'CARNERITO', 'CRISTAL'),
    _v('kitty', 'TELA', 'KITTY'),
    _v('vieja', 'TELA', 'ALIANZA', activa: false),
  ]);

  test('"cristal" encuentra el producto por sus variantes, con el chip', () {
    final c = coincidenciaPorVariantes(edredones, 'cristal');
    expect(c, isNotNull);
    expect(c!.variantes.map((v) => v.id), ['d1', 'd2', 'carn']);
    expect(c.consulta, 'cristal');
    // Dos colecciones: TELA (D1, D2 juntos) y CARNERITO.
    expect(c.etiqueta, 'CRISTAL · 2');
    // La card se titula con lo buscado y cuenta las colecciones.
    expect(c.valor, 'CRISTAL');
    expect(c.colecciones, 2);
  });

  test('por su nombre es la búsqueda de siempre: sin chip', () {
    expect(coincidenciaPorVariantes(edredones, 'edredones'), isNull);
  });

  test('mezclando producto y variante, al selector va solo la variante', () {
    final c = coincidenciaPorVariantes(edredones, 'edredones kitty');
    expect(c!.consulta, 'kitty');
    expect(c.etiqueta, 'KITTY');
  });

  test('sin tildes ni mayúsculas, y exige todas las palabras', () {
    expect(coincidenciaPorVariantes(edredones, 'Cristál carnerito')!.variantes.map((v) => v.id),
        ['carn']);
    expect(coincidenciaPorVariantes(edredones, 'cristal seda'), isNull);
  });

  test('🔴 el Diseño (D1) y las variantes inactivas no cuentan', () {
    expect(coincidenciaPorVariantes(edredones, 'd1'), isNull);
    expect(coincidenciaPorVariantes(edredones, 'alianza'), isNull);
  });
}
