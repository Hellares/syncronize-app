import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:syncronize/core/utils/resource.dart';
import 'package:syncronize/features/compra/domain/entities/lote.dart';
import 'package:syncronize/features/compra/domain/repositories/compra_repository.dart';
import 'package:syncronize/features/compra/domain/usecases/get_lotes_proximos_vencer_usecase.dart';
import 'package:syncronize/features/compra/domain/usecases/get_lotes_usecase.dart';
import 'package:syncronize/features/compra/domain/usecases/marcar_lotes_vencidos_usecase.dart';
import 'package:syncronize/features/compra/presentation/bloc/lote_list/lote_list_cubit.dart';
import 'package:syncronize/features/compra/presentation/bloc/lote_list/lote_list_state.dart';

/// El listado de lotes: pagina y filtra en el BACKEND.
///
/// 🔴 Antes pedía sin `limit` (el backend devolvía 10), filtraba en el app
/// sobre esos 10, y "Todos" / borrar la búsqueda no limpiaban el filtro.
///
/// El repositorio falso usa `noSuchMethod`: el repo no tiene librería de
/// mocking.
class _RepoFalso implements CompraRepository {
  final List<Map<String, dynamic>> pedidos = [];
  final Future<Resource<LotesPagina>> Function(Map<String, dynamic> pedido)
      responder;

  _RepoFalso(this.responder);

  @override
  Future<Resource<LotesPagina>> getLotes({
    required String empresaId,
    String? sedeId,
    String? productoStockId,
    String? estado,
    String? search,
    int limit = 50,
    String? cursor,
  }) {
    final pedido = {
      'estado': estado,
      'search': search,
      'limit': limit,
      'cursor': cursor,
    };
    pedidos.add(pedido);
    return responder(pedido);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Lote _lote(String id) {
  final fecha = DateTime.utc(2026, 9, 1);
  return Lote(
    id: id,
    empresaId: 'emp',
    sedeId: 'sede',
    productoStockId: 'ps',
    codigo: 'LOTE-$id',
    precioCosto: 10,
    cantidadInicial: 1,
    cantidadActual: 1,
    fechaIngreso: fecha,
    creadoPor: 'usr',
    creadoEn: fecha,
    actualizadoEn: fecha,
  );
}

List<Lote> _lotes(String prefijo, int n) =>
    List.generate(n, (i) => _lote('$prefijo$i'));

Future<Resource<LotesPagina>> _pagina(
  List<Lote> lotes, {
  bool hasNext = false,
  String? cursor,
  int total = 0,
}) async =>
    Success(LotesPagina(
      lotes: lotes,
      hasNext: hasNext,
      nextCursor: cursor,
      total: total,
    ));

LoteListCubit _cubit(_RepoFalso repo) => LoteListCubit(
      GetLotesUseCase(repo),
      GetLotesProximosVencerUseCase(repo),
      MarcarLotesVencidosUseCase(repo),
    );

void main() {
  test('pide de a 50 y "Cargar más" trae la página siguiente con el cursor', () async {
    final repo = _RepoFalso((p) => p['cursor'] == null
        ? _pagina(_lotes('a', 50), hasNext: true, cursor: 'c1', total: 120)
        : _pagina(_lotes('b', 50), hasNext: true, cursor: 'c2', total: 120));
    final cubit = _cubit(repo);

    await cubit.loadLotes(empresaId: 'emp');
    var s = cubit.state as LoteListLoaded;
    expect(repo.pedidos.single['limit'], 50);
    expect(s.lotes, hasLength(50));
    expect(s.total, 120);
    expect(s.hasNext, isTrue);

    await cubit.loadMore();
    s = cubit.state as LoteListLoaded;
    expect(repo.pedidos.last['cursor'], 'c1');
    expect(s.lotes, hasLength(100));
    expect(s.cargandoMas, isFalse);
    await cubit.close();
  });

  test('si la página siguiente viene vacía, ya no hay más', () async {
    final repo = _RepoFalso((p) => p['cursor'] == null
        ? _pagina(_lotes('a', 50), hasNext: true, cursor: 'c1', total: 50)
        : _pagina(const [], hasNext: true, cursor: null, total: 50));
    final cubit = _cubit(repo);

    await cubit.loadLotes(empresaId: 'emp');
    await cubit.loadMore();

    final s = cubit.state as LoteListLoaded;
    expect(s.lotes, hasLength(50));
    expect(s.hasNext, isFalse);
    await cubit.close();
  });

  test('🔴 "Todos" limpia el filtro de estado (antes lo conservaba)', () async {
    final repo = _RepoFalso((_) => _pagina(_lotes('a', 3), total: 3));
    final cubit = _cubit(repo);

    await cubit.loadLotes(empresaId: 'emp');
    await cubit.filterByEstado('ACTIVO');
    expect(repo.pedidos.last['estado'], 'ACTIVO');
    expect((cubit.state as LoteListLoaded).estadoFilter, 'ACTIVO');

    await cubit.filterByEstado(null);
    expect(repo.pedidos.last['estado'], isNull);
    expect((cubit.state as LoteListLoaded).estadoFilter, isNull);
    await cubit.close();
  });

  test('🔴 la búsqueda va al backend, y vaciarla la limpia', () async {
    final repo = _RepoFalso((_) => _pagina(_lotes('a', 1), total: 1));
    final cubit = _cubit(repo);

    await cubit.loadLotes(empresaId: 'emp');
    await cubit.search('peter');
    expect(repo.pedidos.last['search'], 'peter');

    await cubit.search('');
    expect(repo.pedidos.last['search'], isNull);
    expect((cubit.state as LoteListLoaded).searchQuery, isNull);
    await cubit.close();
  });

  test('una respuesta vieja no pisa el filtro nuevo', () async {
    final lenta = Completer<Resource<LotesPagina>>();
    final repo = _RepoFalso((p) => p['estado'] == null
        ? lenta.future
        : _pagina(_lotes('agotado', 2), total: 2));
    final cubit = _cubit(repo);

    // La carga inicial queda colgada; mientras, se filtra por AGOTADO.
    final inicial = cubit.loadLotes(empresaId: 'emp');
    await cubit.filterByEstado('AGOTADO');
    lenta.complete(Success(LotesPagina(
      lotes: _lotes('todos', 50),
      hasNext: true,
      total: 388,
    )));
    await inicial;

    final s = cubit.state as LoteListLoaded;
    expect(s.estadoFilter, 'AGOTADO');
    expect(s.lotes, hasLength(2));
    await cubit.close();
  });
}
