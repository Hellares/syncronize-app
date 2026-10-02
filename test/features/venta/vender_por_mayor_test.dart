import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/features/producto/domain/entities/precio_nivel.dart';
import 'package:syncronize/features/venta/domain/entities/venta_detalle_input.dart';

/// VENDER POR MAYOR en el carrito — espejo del backend
/// (`precio-nivel-vender-por-mayor.spec.ts`).
///
/// El cajero marca una línea "por mayor" y se cobra su precio por mayor aunque
/// la cantidad no llegue al mínimo: se precia como si llevara el mínimo del
/// escalón (el elegido, o el primero).
///
/// 🔴 Estas cuentas tienen que dar EXACTAMENTE lo mismo que las del backend:
/// acá el precio SÍ se valida, y si el app manda otro número la venta rebota
/// con 409 PRECIO_DESACTUALIZADO.

PrecioNivel _nivel({
  required String id,
  required double precio,
  required int min,
  int? max,
  String nombre = 'Por Mayor',
}) =>
    PrecioNivel(
      id: id,
      varianteId: 'v-alianza',
      nombre: nombre,
      cantidadMinima: min,
      cantidadMaxima: max,
      tipoPrecio: TipoPrecioNivel.precioFijo,
      precio: precio,
      orden: 0,
      isActive: true,
      creadoEn: DateTime.utc(2026, 10, 2),
      actualizadoEn: DateTime.utc(2026, 10, 2),
    );

final _dosEscalones = [
  _nivel(id: 'n-3', precio: 72, min: 3),
  _nivel(id: 'n-6', precio: 70, min: 6, nombre: 'Mayorista'),
];

VentaDetalleInput _linea({
  double cantidad = 1,
  List<PrecioNivel>? niveles,
  bool precioPorMayor = false,
  String? precioNivelId,
  bool enLiquidacion = false,
  String? precioModo,
}) =>
    VentaDetalleInput(
      productoId: 'prod-edredones',
      varianteId: 'v-alianza',
      descripcion: 'EDREDON ALIANZA',
      cantidad: cantidad,
      precioUnitario: 75,
      precioBase: 75,
      niveles: niveles ?? _dosEscalones,
      precioPorMayor: precioPorMayor,
      precioNivelId: precioNivelId,
      enLiquidacion: enLiquidacion,
      precioModo: precioModo,
    );

VentaDetalleInput _repreciar(VentaDetalleInput l) =>
    VentaDetalleInput.recalcularNivelesEnLote([l]).single;

void main() {
  test('sin marca, 1 unidad paga lista', () {
    final r = _repreciar(_linea());
    expect(r.precioUnitario, 75);
    expect(r.nivelAplicado, isNull);
    expect(r.nivelForzado, isFalse);
  });

  test('marcada sin nivel elegido: paga el PRIMER escalón, forzado', () {
    final r = _repreciar(_linea(precioPorMayor: true));
    expect(r.precioUnitario, 72);
    expect(r.nivelAplicado, 'Por Mayor');
    expect(r.nivelForzado, isTrue);
    expect(r.toMap()['precioPorMayor'], isTrue);
    expect(r.toMap().containsKey('precioNivelId'), isFalse);
  });

  test('con nivel elegido: paga ese escalón y el id viaja', () {
    final r = _repreciar(_linea(precioPorMayor: true, precioNivelId: 'n-6'));
    expect(r.precioUnitario, 70);
    expect(r.nivelAplicado, 'Mayorista');
    expect(r.toMap()['precioNivelId'], 'n-6');
  });

  test('quien ya llega por cantidad a un escalón mejor lo conserva, sin forzado',
      () {
    final r = _repreciar(_linea(precioPorMayor: true, cantidad: 6));
    expect(r.precioUnitario, 70);
    expect(r.nivelForzado, isFalse);
  });

  test('escalones con tope (3–5 y 6+): forzar el de 6 no cae en el de 3–5', () {
    final niveles = [
      _nivel(id: 'n-3', precio: 72, min: 3, max: 5),
      _nivel(id: 'n-6', precio: 70, min: 6),
    ];
    expect(
      _repreciar(_linea(precioPorMayor: true, niveles: niveles)).precioUnitario,
      72,
    );
    expect(
      _repreciar(_linea(
        precioPorMayor: true,
        precioNivelId: 'n-6',
        niveles: niveles,
      )).precioUnitario,
      70,
    );
  });

  test('un nivel elegido que ya no existe cae al primero y SUELTA el id', () {
    final r =
        _repreciar(_linea(precioPorMayor: true, precioNivelId: 'n-borrado'));
    expect(r.precioUnitario, 72);
    expect(r.precioNivelId, isNull);
  });

  test('en liquidación la marca no tiene efecto, y la línea lo dice', () {
    final r = _repreciar(_linea(precioPorMayor: true, enLiquidacion: true));
    expect(r.precioUnitario, 75);
    expect(r.porMayorSinEfecto, isNotNull);
  });

  test('sin escalones por mayor queda a su precio, y la línea lo dice', () {
    final r = _repreciar(_linea(precioPorMayor: true, niveles: const []));
    expect(r.precioUnitario, 75);
    expect(r.porMayorSinEfecto, contains('Sin precio por mayor'));
  });

  test('una línea a costo manda: no viaja como por mayor', () {
    final r = _linea(precioPorMayor: true, precioModo: 'COSTO_LOTE');
    expect(r.esPorMayor, isFalse);
    expect(r.toMap().containsKey('precioPorMayor'), isFalse);
  });

  test('mixto: solo la línea marcada baja', () {
    final otra = VentaDetalleInput(
      productoId: 'prod-almohadas',
      varianteId: 'v-almohada',
      descripcion: 'ALMOHADA',
      cantidad: 1,
      precioUnitario: 30,
      precioBase: 30,
      niveles: [_nivel(id: 'a-3', precio: 25, min: 3)],
    );
    final r = VentaDetalleInput.recalcularNivelesEnLote(
        [_linea(precioPorMayor: true), otra]);
    expect(r[0].precioUnitario, 72);
    expect(r[1].precioUnitario, 30);
  });
}
