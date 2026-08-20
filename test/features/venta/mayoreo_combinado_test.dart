import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/features/producto/domain/entities/precio_nivel.dart';
import 'package:syncronize/features/venta/domain/entities/venta_detalle_input.dart';

/// MAYOREO COMBINADO en el carrito — espejo del backend
/// (`precio-nivel-mayoreo-combinado.spec.ts`).
///
/// El caso real (JAYLI FLORES, producto EDREDONES): el cliente se lleva
/// 1 ALIANZA + 1 RONALDO + 1 SNOOPY. Las tres son `2 PLAZAS / TELA / 3 PZS`,
/// las tres valen S/75 y las tres tienen `Por Mayor ≥ 3 → S/72`. Son tres
/// edredones, así que va precio por mayor; el POS veía tres líneas de una
/// unidad y cobraba S/225 en vez de S/216.
///
/// 🔴 Estas cuentas tienen que dar EXACTAMENTE lo mismo que las del backend:
/// si el app manda un precio que el servidor no calcula, la venta rebota con
/// 409 PRECIO_DESACTUALIZADO y no se puede cobrar.

const _edredones = 'prod-edredones';

PrecioNivel _nivel({
  required String varianteId,
  required double precio,
  int min = 3,
  int? max,
  String nombre = 'Por Mayor',
  bool isActive = true,
}) =>
    PrecioNivel(
      id: 'nivel-$varianteId-$min',
      varianteId: varianteId,
      nombre: nombre,
      cantidadMinima: min,
      cantidadMaxima: max,
      tipoPrecio: TipoPrecioNivel.precioFijo,
      precio: precio,
      orden: 0,
      isActive: isActive,
      creadoEn: DateTime.utc(2026, 8, 19),
      actualizadoEn: DateTime.utc(2026, 8, 19),
    );

VentaDetalleInput _linea({
  required String varianteId,
  required String descripcion,
  double cantidad = 1,
  double precio = 75,
  String? productoId = _edredones,
  List<PrecioNivel> niveles = const [],
  String? origenComboId,
  bool enLiquidacion = false,
}) =>
    VentaDetalleInput(
      productoId: productoId,
      varianteId: varianteId,
      descripcion: descripcion,
      cantidad: cantidad,
      precioUnitario: precio,
      precioBase: precio,
      niveles: niveles,
      origenComboId: origenComboId,
      enLiquidacion: enLiquidacion,
    );

/// Las tres del caso real, cada una con su `Por Mayor ≥ 3 → S/72`.
List<VentaDetalleInput> _carritoJayli({double cantidad = 1}) => [
      _linea(
        varianteId: 'v-alianza',
        descripcion: 'EDREDONES - 2 PLAZAS / TELA / 3 PZS / HOMBRE / ALIANZA',
        cantidad: cantidad,
        niveles: [_nivel(varianteId: 'v-alianza', precio: 72)],
      ),
      _linea(
        varianteId: 'v-ronaldo',
        descripcion: 'EDREDONES - 2 PLAZAS / TELA / 3 PZS / HOMBRE / RONALDO',
        cantidad: cantidad,
        niveles: [_nivel(varianteId: 'v-ronaldo', precio: 72)],
      ),
      _linea(
        varianteId: 'v-snoopy',
        descripcion: 'EDREDONES - 2 PLAZAS / TELA / 3 PZS / NIÑA / SNOOPY',
        cantidad: cantidad,
        niveles: [_nivel(varianteId: 'v-snoopy', precio: 72)],
      ),
    ];

double _totalCarrito(List<VentaDetalleInput> items) =>
    items.fold(0.0, (acc, i) => acc + i.cantidad * i.precioUnitario);

void main() {
  group('recalcularNivelesEnLote — el caso JAYLI', () {
    test('1 + 1 + 1 de tres diseños distintos cobran por mayor', () {
      final repreciado =
          VentaDetalleInput.recalcularNivelesEnLote(_carritoJayli());

      expect(repreciado.map((i) => i.precioUnitario), everyElement(72.0));
      expect(_totalCarrito(repreciado), 216.0);
      expect(repreciado.map((i) => i.nivelAplicado), everyElement('Por Mayor'));
    });

    test('sin el lote, cada línea sola sigue en precio de lista', () {
      // Regresión de lo que hacía el POS antes: repreciar línea por línea.
      final sueltas = _carritoJayli()
          .map((i) => i.recalcularPrecioPorNiveles(i.cantidad))
          .toList();

      expect(sueltas.map((i) => i.precioUnitario), everyElement(75.0));
      expect(_totalCarrito(sueltas), 225.0);
    });

    test('con 2 de 3 líneas nadie baja', () {
      final dos = _carritoJayli().take(2).toList();
      final repreciado = VentaDetalleInput.recalcularNivelesEnLote(dos);

      expect(repreciado.map((i) => i.precioUnitario), everyElement(75.0));
      expect(repreciado.every((i) => i.nivelAplicado == null), isTrue);
    });

    test('una sola línea con 3 unidades sigue bajando, como siempre', () {
      final una = [_carritoJayli(cantidad: 3).first];
      final repreciado = VentaDetalleInput.recalcularNivelesEnLote(una);

      expect(repreciado.single.precioUnitario, 72.0);
    });
  });

  group('recalcularNivelesEnLote — los bordes', () {
    test('familias con distinto precio por mayor no suman entre sí', () {
      // Real en prod: S/83 aparece dos veces, una baja a 76 y la otra a 79.
      final items = [
        _linea(
          varianteId: 'v-py-tela-5',
          descripcion: 'PLAZA Y MEDIA / TELA / 5 PZS',
          precio: 83,
          niveles: [_nivel(varianteId: 'v-py-tela-5', precio: 76)],
        ),
        _linea(
          varianteId: 'v-2p-carnerito-3',
          descripcion: '2 PLAZAS / CARNERITO / 3 PZS',
          precio: 83,
          niveles: [_nivel(varianteId: 'v-2p-carnerito-3', precio: 79)],
        ),
        _linea(
          varianteId: 'v-2p-tela-3',
          descripcion: '2 PLAZAS / TELA / 3 PZS',
          niveles: [_nivel(varianteId: 'v-2p-tela-3', precio: 72)],
        ),
      ];
      final repreciado = VentaDetalleInput.recalcularNivelesEnLote(items);

      // Tres edredones en el carrito, pero de tres grupos distintos: cada uno
      // suma 1 y ninguno llega a su mínimo de 3.
      expect(repreciado.map((i) => i.precioUnitario), [83.0, 83.0, 75.0]);
    });

    test('el mayoreo no cruza productos', () {
      final items = [
        _linea(
          varianteId: 'v-edredon',
          descripcion: 'EDREDON',
          niveles: [_nivel(varianteId: 'v-edredon', precio: 72)],
        ),
        _linea(
          varianteId: 'v-almohada',
          descripcion: 'ALMOHADA',
          productoId: 'prod-almohadas',
          niveles: [_nivel(varianteId: 'v-almohada', precio: 72)],
        ),
        _linea(
          varianteId: 'v-sabana',
          descripcion: 'SABANA',
          productoId: 'prod-sabanas',
          niveles: [_nivel(varianteId: 'v-sabana', precio: 72)],
        ),
      ];
      final repreciado = VentaDetalleInput.recalcularNivelesEnLote(items);

      expect(repreciado.map((i) => i.precioUnitario), everyElement(75.0));
    });

    test('el nombre del nivel no separa el grupo', () {
      final items = _carritoJayli();
      final conOtroNombre = [
        items[0],
        items[1],
        items[2].copyWith(niveles: [
          _nivel(varianteId: 'v-snoopy', precio: 72, nombre: 'Mayorista'),
        ]),
      ];
      final repreciado =
          VentaDetalleInput.recalcularNivelesEnLote(conOtroNombre);

      expect(repreciado.map((i) => i.precioUnitario), everyElement(72.0));
    });

    test('un componente de combo no empuja el mayoreo del resto', () {
      final items = _carritoJayli();
      final conCombo = [
        items[0],
        items[1],
        items[2].copyWith(origenComboId: 'combo-1'),
      ];
      final repreciado = VentaDetalleInput.recalcularNivelesEnLote(conCombo);

      expect(repreciado[0].precioUnitario, 75.0);
      expect(repreciado[1].precioUnitario, 75.0);
      // Y su propio precio queda intacto: lo fija el prorrateo del combo.
      expect(repreciado[2].precioUnitario, 75.0);
    });

    test('la misma variante en dos líneas también suma', () {
      final items = [
        _linea(
          varianteId: 'v-alianza',
          descripcion: 'ALIANZA',
          niveles: [_nivel(varianteId: 'v-alianza', precio: 72)],
        ),
        _linea(
          varianteId: 'v-alianza',
          descripcion: 'ALIANZA',
          cantidad: 2,
          niveles: [_nivel(varianteId: 'v-alianza', precio: 72)],
        ),
      ];
      final repreciado = VentaDetalleInput.recalcularNivelesEnLote(items);

      expect(repreciado.map((i) => i.precioUnitario), everyElement(72.0));
    });

    test('una variante sin nivel cargado nunca baja', () {
      // Las tres huérfanas de prod (FROZEN, MINIE, KITTY) no tienen nivel.
      final items = [
        ..._carritoJayli(),
        _linea(varianteId: 'v-frozen', descripcion: 'FROZEN', precio: 60),
      ];
      final repreciado = VentaDetalleInput.recalcularNivelesEnLote(items);

      expect(repreciado.last.precioUnitario, 60.0);
      expect(repreciado.take(3).map((i) => i.precioUnitario),
          everyElement(72.0));
    });

    test('la liquidación sigue ganando sobre el mayoreo combinado', () {
      final items = _carritoJayli();
      final conLiquidacion = [
        items[0].copyWith(
          enLiquidacion: true,
          precioUnitario: 40,
          precioBase: 40,
        ),
        items[1],
        items[2],
      ];
      final repreciado =
          VentaDetalleInput.recalcularNivelesEnLote(conLiquidacion);

      // La liquidada se queda en su remate...
      expect(repreciado[0].precioUnitario, 40.0);
      // ...pero sus unidades sí cuentan para que las otras lleguen al mínimo.
      expect(repreciado[1].precioUnitario, 72.0);
      expect(repreciado[2].precioUnitario, 72.0);
    });

    test('un nivel inactivo no arma grupo', () {
      final items = _carritoJayli()
          .map((i) => i.copyWith(niveles: [
                _nivel(
                  varianteId: i.varianteId!,
                  precio: 72,
                  isActive: false,
                ),
              ]))
          .toList();
      final repreciado = VentaDetalleInput.recalcularNivelesEnLote(items);

      expect(repreciado.map((i) => i.precioUnitario), everyElement(75.0));
    });

    test('el nivel nunca sube un precio ya más barato', () {
      // Línea de 5 unidades cuyo grupo suma menos: se mide por sus 5.
      final items = [
        _linea(
          varianteId: 'v-alianza',
          descripcion: 'ALIANZA',
          cantidad: 5,
          niveles: [_nivel(varianteId: 'v-alianza', precio: 72)],
        ),
        _linea(
          varianteId: 'v-otra-familia',
          descripcion: 'OTRA',
          niveles: [_nivel(varianteId: 'v-otra-familia', precio: 60)],
        ),
      ];
      final repreciado = VentaDetalleInput.recalcularNivelesEnLote(items);

      expect(repreciado[0].precioUnitario, 72.0);
      expect(repreciado[1].precioUnitario, 75.0);
    });
  });

  group('MayoreoCombinado — el chip del carrito', () {
    test('alcanzado: dice cuántas juntó el grupo', () {
      final repreciado =
          VentaDetalleInput.recalcularNivelesEnLote(_carritoJayli());

      final mayoreo = repreciado.first.mayoreo;
      expect(mayoreo, isNotNull);
      expect(mayoreo!.alcanzado, isTrue);
      expect(mayoreo.unidadesGrupo, 3);
      expect(mayoreo.minimo, 3);
      expect(mayoreo.etiqueta, 'Mayoreo: 3 de 3');
    });

    test('por alcanzar: dice cuánto falta y a cuánto quedaría', () {
      final dos = _carritoJayli().take(2).toList();
      final repreciado = VentaDetalleInput.recalcularNivelesEnLote(dos);

      final mayoreo = repreciado.first.mayoreo;
      expect(mayoreo, isNotNull);
      expect(mayoreo!.alcanzado, isFalse);
      expect(mayoreo.faltan, 1);
      expect(mayoreo.etiqueta, 'Falta 1 para S/ 72.00');
    });

    test('sin aporte de las otras líneas no hay chip que mostrar', () {
      // Una línea sola de 3 unidades ya bajaba antes: el chip sería ruido.
      final una = [_carritoJayli(cantidad: 3).first];
      final repreciado = VentaDetalleInput.recalcularNivelesEnLote(una);

      expect(repreciado.single.precioUnitario, 72.0);
      expect(repreciado.single.mayoreo, isNull);
    });

    test('el plural se escribe bien', () {
      final una = [
        _linea(
          varianteId: 'v-a',
          descripcion: 'A',
          niveles: [_nivel(varianteId: 'v-a', precio: 72, min: 6)],
        ),
        _linea(
          varianteId: 'v-b',
          descripcion: 'B',
          niveles: [_nivel(varianteId: 'v-b', precio: 72, min: 6)],
        ),
      ];
      final repreciado = VentaDetalleInput.recalcularNivelesEnLote(una);

      expect(repreciado.first.mayoreo!.etiqueta, 'Faltan 4 para S/ 72.00');
    });
  });
}
