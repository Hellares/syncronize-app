import 'package:flutter_test/flutter_test.dart';

import 'package:syncronize/features/producto/data/variante_plantilla_api.dart';

/// El JSON de `/variante-plantillas`: lo que manda el backend y lo que se le
/// devuelve al guardar.
void main() {
  test('lee una plantilla con sus combinaciones y niveles', () {
    final p = VariantePlantilla.fromJson({
      'id': 'pl-1',
      'nombre': 'Edredones',
      'descripcion': null,
      'atributoColeccion': {'id': 'a-col', 'nombre': 'Colección', 'clave': 'dise_o', 'activo': true},
      'atributos': [
        {'id': 'a-tam', 'nombre': 'Tamaño', 'activo': true},
        {'id': 'a-mat', 'nombre': 'Material', 'activo': true},
      ],
      'combinaciones': [
        {
          'id': 'c1',
          'valores': [
            {'atributoId': 'a-tam', 'valor': '2 PLAZAS'},
            {'atributoId': 'a-mat', 'valor': 'TELA'},
          ],
          'precio': 75,
          'precioCosto': 60.5,
          'niveles': [
            {'nombre': 'Por Mayor', 'cantidadMinima': 3, 'tipoPrecio': 'PRECIO_FIJO', 'precio': 72},
          ],
          'orden': 0,
        },
        {'id': 'c2', 'valores': [{'atributoId': 'a-tam', 'valor': '2 PLAZAS'}], 'precio': null, 'precioCosto': null, 'niveles': []},
      ],
    });

    expect(p.atributoColeccion.nombre, 'Colección');
    expect(p.atributos.map((a) => a.id), ['a-tam', 'a-mat']);
    expect(p.combinaciones.first.etiqueta, '2 PLAZAS · TELA');
    expect(p.combinaciones.first.precio, 75.0);
    expect(p.combinaciones.first.precioCosto, 60.5);
    expect(p.combinaciones.first.niveles.single['precio'], 72);
    expect(p.combinaciones.last.precio, isNull);
  });

  test('al guardar no manda precios vacíos ni niveles vacíos', () {
    const c = CombinacionPlantilla(valores: [ValorPlantilla('a-tam', '2 PLAZAS')], precio: 80);
    expect(c.toJson(), {
      'valores': [
        {'atributoId': 'a-tam', 'valor': '2 PLAZAS'},
      ],
      'precio': 80,
    });
  });
}
