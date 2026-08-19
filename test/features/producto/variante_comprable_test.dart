import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/features/producto/data/models/producto_list_item_model.dart';

/// Qué variante se COMPRA y cuál no.
///
/// Un par SACO→GRANEL tiene dos stocks reales: el saco cerrado se le compra al
/// proveedor, y el granel aparece ABRIENDO un saco. Esa apertura es la que le
/// calcula el costo al granel por promedio ponderado (S/160 que rinden 15 000 g
/// ⇒ 0.010667/g). Comprar el granel directo mete un costo tecleado en ese
/// promedio —el margen queda mintiendo, sin ningún síntoma visible— y suma
/// gramos sin descontar ningún saco, con lo que "5 cerrados / 5 abiertos" deja
/// de significar algo.
///
/// La regla no necesita ningún campo nuevo: sale del vínculo de apertura que ya
/// está cargado. En beta, ALIMENTO PARA RATON parte 16/12 sin sobrantes.
void main() {
  Map<String, dynamic> variante(
    String id,
    String nombre, {
    String? abreHacia,
    Object? rendimiento,
    bool isActive = true,
  }) =>
      {
        'id': id,
        'nombre': nombre,
        'sku': 'SKU-$id',
        'codigoEmpresa': 'VAR-$id',
        'isActive': isActive,
        if (abreHacia != null) 'varianteAperturaId': abreHacia,
        if (rendimiento != null) 'rendimientoApertura': rendimiento,
      };

  Map<String, dynamic> producto(List<Map<String, dynamic>> variantes) => {
        'id': 'p1',
        'nombre': 'ALIMENTO PARA RATON',
        'codigoEmpresa': 'PROD-001',
        'tieneVariantes': true,
        'unidadMedida': {'simboloLocal': 'g'},
        'variantes': variantes,
      };

  group('el vínculo de apertura dice qué se compra', () {
    test('el saco se compra y el granel al que abre, no', () {
      final p = ProductoListItemModel.fromJson(producto([
        variante('saco', 'ADULTO / POLLO / SACO 15KG',
            abreHacia: 'granel', rendimiento: 15000),
        variante('granel', 'ADULTO / POLLO / GRANEL'),
      ]));

      expect(p.destinosDeApertura, {'granel'});
      expect(p.esVarianteComprable(p.variantes![0]), isTrue);
      expect(p.esVarianteComprable(p.variantes![1]), isFalse);
      expect(p.seCompraPorBulto, isTrue);
    });

    test('dos tamaños de saco que abren al MISMO granel: los dos se compran',
        () {
      // El caso real: un sabor viene en 15 y en 25 kg y los dos van al mismo
      // granel. El destino no se puede contar dos veces ni bloquear un saco.
      final p = ProductoListItemModel.fromJson(producto([
        variante('saco15', 'POLLO / SACO 15KG',
            abreHacia: 'granel', rendimiento: 15000),
        variante('saco25', 'POLLO / SACO 25KG',
            abreHacia: 'granel', rendimiento: 25000),
        variante('granel', 'POLLO / GRANEL'),
      ]));

      expect(p.destinosDeApertura, {'granel'});
      expect(p.variantes!.where(p.esVarianteComprable).length, 2);
    });

    test('un producto sin apertura tiene TODAS sus variantes comprables', () {
      // EDREDONES: 91 variantes, ninguna es un bulto. La regla no lo toca.
      final p = ProductoListItemModel.fromJson(producto([
        variante('v1', 'ROJO / 2 PZS'),
        variante('v2', 'AZUL / 2 PZS'),
      ]));

      expect(p.destinosDeApertura, isEmpty);
      expect(p.variantes!.every(p.esVarianteComprable), isTrue);
      expect(p.seCompraPorBulto, isFalse);
    });

    test('un producto sin variantes no rompe ni se declara por bulto', () {
      final p = ProductoListItemModel.fromJson({
        'id': 'p2',
        'nombre': 'GASEOSA',
        'codigoEmpresa': 'PROD-002',
      });

      expect(p.destinosDeApertura, isEmpty);
      expect(p.seCompraPorBulto, isFalse);
    });
  });

  group('falla hacia el lado que no traba a nadie', () {
    test('un vínculo a medias (sin rendimiento) no bloquea el destino', () {
      // `sePuedeAbrir` exige rendimiento > 0: sin él la apertura no se puede
      // ejecutar, así que el granel quedaría inalcanzable por las DOS puertas.
      final p = ProductoListItemModel.fromJson(producto([
        variante('saco', 'SACO 15KG', abreHacia: 'granel'),
        variante('granel', 'GRANEL'),
      ]));

      expect(p.destinosDeApertura, isEmpty);
      expect(p.variantes!.every(p.esVarianteComprable), isTrue);
    });

    test('rendimiento en 0 tampoco alcanza para bloquear', () {
      final p = ProductoListItemModel.fromJson(producto([
        variante('saco', 'SACO 15KG', abreHacia: 'granel', rendimiento: 0),
        variante('granel', 'GRANEL'),
      ]));

      expect(p.destinosDeApertura, isEmpty);
    });

    test('el rendimiento tolera que Prisma lo mande como String', () {
      // Decimal serializa como String: si no se parsea, `sePuedeAbrir` da
      // false y el granel se vuelve comprable sin que nadie lo note.
      final p = ProductoListItemModel.fromJson(producto([
        variante('saco', 'SACO 15KG',
            abreHacia: 'granel', rendimiento: '15000.0000'),
        variante('granel', 'GRANEL'),
      ]));

      expect(p.destinosDeApertura, {'granel'});
    });

    test('el vínculo sobrevive al ida y vuelta por JSON del caché', () {
      // El catálogo se persiste con toJson. Si no lo devuelve, al releer del
      // disco los graneles vuelven a aparecer comprables.
      final original = ProductoListItemModel.fromJson(producto([
        variante('saco', 'SACO 15KG',
            abreHacia: 'granel', rendimiento: 15000),
        variante('granel', 'GRANEL'),
      ]));
      final ida = ProductoListItemModel.fromJson(original.toJson());

      expect(ida.destinosDeApertura, {'granel'});
      expect(ida.seCompraPorBulto, isTrue);
    });
  });
}
