import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/core/utils/unidad_presentacion.dart';
import 'package:syncronize/features/balanza/presentation/widgets/balanza_visor_sheet.dart';

/// Decide si el ícono de la balanza aparece al lado del campo de cantidad.
///
/// Importa porque "a granel" NO es lo mismo que "se pesa": una tela se vende
/// por metro y tiene presentación igual, y ahí una balanza no pinta.
void main() {
  UnidadPresentacion pres(String simbolo) =>
      UnidadPresentacion(factor: 1000, simbolo: simbolo, simboloVenta: 'g');

  test('las unidades de peso ofrecen la balanza', () {
    for (final s in ['kg', 'KG', 'g', ' gr ', 'lb', 'oz']) {
      expect(presentacionEsPesable(pres(s)), isTrue, reason: s);
    }
  });

  test('lo que no se pesa, no', () {
    for (final s in ['m', 'cm', 'L', 'ml', 'm2', 'unid', 'rollo']) {
      expect(presentacionEsPesable(pres(s)), isFalse, reason: s);
    }
  });

  test('sin presentación configurada no se ofrece', () {
    expect(presentacionEsPesable(const UnidadPresentacion.ninguna()), isFalse);
  });

  test('un producto en gramos SIN presentación igual se pesa', () {
    // `simboloVisible` cae al símbolo de venta cuando no hay presentación
    // activa: un granel cargado sin la capa de kilos sigue siendo pesable.
    const enGramos =
        UnidadPresentacion(factor: 1, simbolo: null, simboloVenta: 'g');
    expect(presentacionEsPesable(enGramos), isTrue);
  });
}
