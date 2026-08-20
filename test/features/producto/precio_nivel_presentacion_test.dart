import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/core/utils/unidad_presentacion.dart';
import 'package:syncronize/features/producto/domain/entities/precio_nivel.dart';

/// Un nivel de precio se GUARDA en unidad de venta: `cantidadMinima` es el
/// entero contra el que el backend compara la cantidad de la línea, y `precio`
/// es por unidad de venta.
///
/// En un granel en gramos eso significa que "desde 3 kg a S/8.00/kg" vive en la
/// base como 3000 y 0.008. Mostrarlo crudo decía "3000+ unidades" a "S/0.01"
/// —un precio que ni siquiera existe, porque el redondeo a dos decimales se lo
/// come— y hacía pensar que el mayoreo arrancaba en tres mil kilos.
void main() {
  final kilos = UnidadPresentacion(factor: 1000, simbolo: 'kg');
  const porUnidad = UnidadPresentacion.ninguna();

  PrecioNivel nivel({
    int cantidadMinima = 3000,
    int? cantidadMaxima,
    double? precio = 0.008,
  }) =>
      PrecioNivel(
        id: 'n1',
        nombre: 'Por Mayor',
        cantidadMinima: cantidadMinima,
        cantidadMaxima: cantidadMaxima,
        tipoPrecio: TipoPrecioNivel.precioFijo,
        precio: precio,
        orden: 0,
        isActive: true,
        creadoEn: DateTime(2026),
        actualizadoEn: DateTime(2026),
      );

  group('rangoTexto', () {
    test('un granel se lee en kilos, no en gramos', () {
      expect(nivel().rangoTexto(kilos), '3 kg+');
      expect(
        nivel(cantidadMinima: 3000, cantidadMaxima: 10000).rangoTexto(kilos),
        '3 - 10 kg',
      );
    });

    test('sin presentación queda exactamente como estaba', () {
      expect(nivel(cantidadMinima: 3).rangoTexto(porUnidad), '3+ unidades');
      expect(
        nivel(cantidadMinima: 3, cantidadMaxima: 10).rangoTexto(porUnidad),
        '3 - 10 unidades',
      );
    });

    test('un mínimo que no es kilo redondo no se pierde', () {
      // 1500 g son 1.5 kg: con enteros se habría mostrado "1 kg" o "2 kg".
      expect(nivel(cantidadMinima: 1500).rangoTexto(kilos), '1.5 kg+');
    });
  });

  group('precioTexto', () {
    test('el precio por gramo se dice por kilo', () {
      expect(nivel().precioTexto(kilos), 'S/ 8.00/kg');
    });

    test('sin presentación no inventa sufijo', () {
      expect(nivel(precio: 75).precioTexto(porUnidad), 'S/ 75.00');
    });

    test('un nivel porcentual no tiene precio propio', () {
      expect(nivel(precio: null).precioTexto(kilos), isNull);
    });
  });

  test('el redondeo a dos decimales es justo lo que hacía ilegible el granel',
      () {
    // La lectura vieja: `precio.toStringAsFixed(2)` sobre 0.008.
    expect(nivel().precio!.toStringAsFixed(2), '0.01');
    // La nueva dice el número que el usuario reconoce.
    expect(nivel().precioTexto(kilos), 'S/ 8.00/kg');
  });
}
