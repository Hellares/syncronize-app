import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/core/widgets/producto_sede_selector/producto_sede_selector.dart';

/// `soloVariantesComprables` esconde los GRANEL del dropdown de variantes.
///
/// El selector lo comparten diez pantallas (venta, merma, transferencia,
/// kardex, combos…), así que el flag nace APAGADO: vender o mermar un granel
/// es de todos los días. Solo lo prenden las recepciones.
void main() {
  test('el default no esconde nada: venta y merma siguen viendo los graneles',
      () {
    const selector = ProductoSedeSelector(empresaId: 'e1');

    expect(selector.soloVariantesComprables, isFalse);
  });

  test('se puede prender sin tocar el resto de la configuración', () {
    const selector = ProductoSedeSelector(
      empresaId: 'e1',
      mostrarTodos: true,
      soloVariantesComprables: true,
    );

    expect(selector.soloVariantesComprables, isTrue);
    // Una recepción necesita las dos cosas a la vez: ver productos que aún no
    // viven en la sede, y NO ver los graneles.
    expect(selector.mostrarTodos, isTrue);
  });
}
