import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/features/producto/domain/entities/producto_filtros.dart';

/// `producto_list_cubit` copia los filtros para paginar
/// (`_currentFiltros.copyWith(page: nextPage)`). Todo lo que `copyWith` no
/// propague se pierde en silencio a partir de la página 2: la primera tanda
/// sale bien filtrada y la siguiente no, que es lo más difícil de ver.
void main() {
  test('paginar conserva isActive', () {
    // Sin esto, Venta Rápida volvía a ofrecer productos DADOS DE BAJA al
    // scrollear: el default null es "activos y desactivados".
    const filtros = ProductoFiltros(isActive: true, esInsumo: false);

    final pagina2 = filtros.copyWith(page: 2);

    expect(pagina2.isActive, isTrue);
    expect(pagina2.toQueryParams()['isActive'], 'true');
  });

  test('paginar conserva los filtros de una COMPRA', () {
    // `mostrarTodos` es lo que deja comprar algo que todavía no vive en la
    // sede; perderlo en la página 2 hace desaparecer justo esos productos.
    const filtros = ProductoFiltros(
      isActive: true,
      mostrarTodos: true,
      soloProductos: true,
    );

    final pagina2 = filtros.copyWith(page: 2);

    expect(pagina2.mostrarTodos, isTrue);
    expect(pagina2.soloProductos, isTrue);
    expect(pagina2.isActive, isTrue);
    expect(pagina2.esInsumo, isNull);
  });

  test('conserva soloEliminados (la papelera no deja de ser papelera)', () {
    const filtros = ProductoFiltros(soloEliminados: true);

    expect(filtros.copyWith(page: 3).soloEliminados, isTrue);
  });

  test('se pueden cambiar explícitamente', () {
    const filtros = ProductoFiltros(isActive: true);

    expect(filtros.copyWith(isActive: false).isActive, isFalse);
  });

  test('los clear siguen funcionando', () {
    const filtros = ProductoFiltros(
      search: 'arroz',
      isActive: true,
      esInsumo: false,
    );

    final limpio = filtros.copyWith(clearSearch: true, clearEsInsumo: true);

    expect(limpio.search, isNull);
    expect(limpio.esInsumo, isNull);
    expect(limpio.isActive, isTrue);
  });
}
