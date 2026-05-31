import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../data/cache/producto_catalogo_local_store.dart';
import '../../../data/cache/producto_catalogo_memory_cache.dart';
import '../../../domain/entities/producto_filtros.dart';
import '../../../domain/entities/producto_list_item.dart';
import '../../../domain/entities/producto.dart';
import '../../../domain/entities/sync_deltas_result.dart';
import '../../../domain/repositories/producto_repository.dart';
import '../../../domain/usecases/get_productos_usecase.dart';
import 'producto_list_state.dart';

@injectable
class ProductoListCubit extends Cubit<ProductoListState> {
  final GetProductosUseCase _getProductosUseCase;
  final ProductoRepository _productoRepository;
  final ProductoCatalogoMemoryCache _memoryCache;
  final ProductoCatalogoLocalStore _localStore;

  ProductoListCubit(
    this._getProductosUseCase,
    this._productoRepository,
    this._memoryCache,
    this._localStore,
  ) : super(const ProductoListInitial());

  String? _currentEmpresaId;
  String? _currentSedeId;
  ProductoFiltros _currentFiltros = const ProductoFiltros();
  List<ProductoListItem> _allProductos = [];

  /// Token monotónico de request. Cada `loadProductos`/`applyFiltros` lo
  /// incrementa. Cuando llega una respuesta y el token capturado al inicio
  /// ya no coincide con el actual, se descarta — evita que respuestas
  /// obsoletas (ej. tipear rápido en el search) sobreescriban el estado
  /// de un request más reciente.
  int _requestSeq = 0;

  /// Cache de productos completos (para evitar peticiones duplicadas)
  final Map<String, Producto> _productosFullCache = {};

  /// Biblioteca acumulativa de TODOS los `ProductoListItem` que pasaron
  /// por este cubit (catálogo base + búsquedas server + paginación).
  /// Permite que el filtro local en VR encuentre productos que se
  /// trajeron en una búsqueda previa aunque ya no estén en el state
  /// actual (ej. el cajero buscó "xyzz", limpió y vuelve a buscar
  /// "xyzz" → ahora es instantáneo desde memoria).
  ///
  /// Se purga con `reload()` y al recibir FCM (vía cache invalidation
  /// del realtime sync) para no servir datos stale.
  final Map<String, ProductoListItem> _vistosCache = {};

  /// Vista inmodificable del acumulador. La UI puede iterar sin
  /// preocuparse por mutaciones concurrentes.
  Map<String, ProductoListItem> get vistosCache =>
      Map.unmodifiable(_vistosCache);

  // ─────────────────────────────────────────────────────────────────
  // Background prefetch del catálogo base
  // ─────────────────────────────────────────────────────────────────
  //
  // Tras el primer `loadProductos` exitoso del catálogo base, si quedan
  // páginas por descargar (`hasNext=true`) y el tamaño total no es
  // absurdo, descargamos el resto en background. Beneficios:
  //   • UX inmediata: el usuario ve los primeros 50 productos en
  //     ~200ms; las siguientes páginas aparecen solas en ~1-2s sin
  //     spinner intermedio.
  //   • Catálogo completo persistido → próxima apertura usa syncDeltas
  //     (~1 KB) en vez de fetch full (~200 KB).
  //   • Si el usuario scrolea más rápido que el prefetch, `loadMore`
  //     se ignora porque el prefetch ya está trayendo esa página.
  //
  // Cancelación: comparte `_requestSeq` con el flujo normal — cualquier
  // `applyFiltros`/`reload`/`revalidarSinDeltas` incrementa el seq y
  // el loop del prefetch detecta la divergencia y aborta. También se
  // cancela si el cubit se cierra (`isClosed`).

  /// Flag para no disparar dos prefetches en paralelo.
  bool _isPrefetching = false;

  /// Cap absoluto de páginas a prefetchar — protege contra catálogos
  /// muy grandes y contra loops por errores de paginación del backend.
  static const int _prefetchMaxPages = 100;

  /// Cap por tamaño total: si el catálogo declara más productos que
  /// esto, NO hacemos prefetch automático — el cliente trabajará con
  /// paginación natural vía `loadMore` y nunca usará syncDeltas hasta
  /// que el usuario scrolee al final manualmente.
  static const int _prefetchTotalCap = 5000;

  /// Delay entre cada página del prefetch — da respiración a la red,
  /// permite render incremental fluido y deja ventana para que la
  /// cancelación (cambio de filtro, scroll manual) actúe antes del
  /// siguiente request.
  static const Duration _prefetchDelay = Duration(milliseconds: 200);

  /// Carga la lista de productos.
  ///
  /// Si ya hay productos cargados y `keepListWhileFiltering=true`, mantiene
  /// la lista visible y emite `Loaded(isFiltering: true)` en vez de Loading
  /// (evita parpadeo del grid al filtrar).
  Future<void> loadProductos({
    required String empresaId,
    String? sedeId,
    ProductoFiltros? filtros,
    bool keepListWhileFiltering = false,
  }) async {
    _currentEmpresaId = empresaId;
    _currentSedeId = sedeId;
    _currentFiltros = filtros ?? const ProductoFiltros();

    final mySeq = ++_requestSeq;

    // Fase 1: stale-while-revalidate.
    // Si tenemos un snapshot reciente del catálogo en memoria para esta
    // combinación (empresa+sede+filtros), lo emitimos INMEDIATO. Render
    // <50ms vs ~400-1000ms de la red. Después fetchamos en background y
    // emitimos otra vez con el dato fresco si cambió algo.
    final cached =
        _memoryCache.get(empresaId, sedeId, _currentFiltros);
    final currentState = state;
    final puedeHidratarDeCache = cached != null;

    final esCatalogoBase = _esCatalogoBase(_currentFiltros);

    // Si la biblioteca persistente está vacía pero hay datos en disco
    // (primer load tras reapertura), restaurarla. Hacemos esto antes
    // de emitir cualquier estado para que el filtro local del builder
    // tenga los datos disponibles desde el primer frame.
    if (_vistosCache.isEmpty) {
      await _hidratarLibreriaDeDisco(empresaId);
      if (isClosed) return;
      if (mySeq != _requestSeq) return;
    }

    if (puedeHidratarDeCache) {
      _allProductos = List.of(cached.productos);
      _productosFullCache
        ..clear()
        ..addAll(cached.productosFullCache);
      emit(ProductoListLoaded(
        productos: _allProductos,
        total: cached.total,
        currentPage: cached.currentPage,
        totalPages: cached.totalPages,
        hasMore: cached.hasMore,
        filtros: cached.filtros,
        // Marcamos isFiltering=true para que la UI muestre la barra
        // sutil mientras corre la revalidación en background, sin
        // bloquear la grilla.
        isFiltering: true,
      ));
    } else if (keepListWhileFiltering && currentState is ProductoListLoaded) {
      // Mantener la lista actual visible, solo marcar isFiltering=true.
      emit(currentState.copyWith(isFiltering: true));
    } else if (esCatalogoBase) {
      // Fase 2: cache memoria miss + catálogo base → intentar leer
      // disco. Sub-100ms vs 400-1000ms de red. Cubre el caso "app
      // cerrada y abierta de nuevo" — el primer render aparece
      // instantáneo sin esperar a la red.
      emit(const ProductoListLoading());
      final disco = await _localStore.read(
        empresaId: empresaId,
        sedeId: sedeId,
      );
      if (isClosed) return;
      if (mySeq != _requestSeq) return;
      if (disco != null && disco.productos.isNotEmpty) {
        _allProductos = List.of(disco.productos);
        for (final p in _allProductos) {
          _vistosCache[p.id] = p;
        }
        emit(ProductoListLoaded(
          productos: _allProductos,
          total: disco.total,
          currentPage: disco.currentPage,
          totalPages: disco.totalPages,
          hasMore: disco.hasMore,
          filtros: _currentFiltros,
          // Revalidando en background.
          isFiltering: true,
        ));
      }
    } else {
      _allProductos = [];
      _productosFullCache.clear();
      emit(const ProductoListLoading());
    }

    // Fase 3: si tenemos cache cargado (memoria o disco) y es catálogo
    // base, intentar revalidar con sync diferencial — solo viajan los
    // deltas (~1KB) en vez del catálogo completo (~200KB).
    final tieneCacheCargado = state is ProductoListLoaded;
    if (esCatalogoBase && tieneCacheCargado) {
      final aplicoDeltas = await _tryRevalidarConSyncDeltas(
        empresaId: empresaId,
        sedeId: sedeId,
        mySeq: mySeq,
      );
      if (aplicoDeltas) return; // ya emitimos el estado actualizado, fin
    }

    final result = await _getProductosUseCase(
      empresaId: empresaId,
      sedeId: sedeId,
      filtros: _currentFiltros,
    );

    if (isClosed) return;
    // Descartar si llegó otra request más reciente.
    if (mySeq != _requestSeq) return;

    if (result is Success<ProductosPaginados>) {
      final data = result.data;
      _allProductos = data.data.cast<ProductoListItem>();

      // Acumular en la biblioteca de productos vistos. Sirve al filtro
      // local en VR para encontrar productos que ya se trajeron en una
      // búsqueda anterior aunque ya no estén en `_allProductos`.
      for (final p in _allProductos) {
        _vistosCache[p.id] = p;
      }
      _recortarBiblioteca();
      // Persistir biblioteca en disco para que sobreviva al cierre.
      unawaited(
        _localStore.writeLibreria(
          empresaId: empresaId,
          productos: _vistosCache.values.toList(),
        ),
      );

      // Almacenar productos completos en cache (si existen)
      if (data.fullProductosCache != null) {
        _productosFullCache
          ..clear()
          ..addAll(data.fullProductosCache!);
      }

      // Fase 2: si el fetch corresponde al catálogo base, persistirlo
      // en disco para que la próxima apertura (incluso de app fría)
      // sea instantánea. Fire-and-forget — no bloqueamos el emit.
      if (esCatalogoBase) {
        final ahora = DateTime.now();
        unawaited(
          _localStore.write(
            empresaId: empresaId,
            sedeId: sedeId,
            snapshot: CatalogoLocalSnapshot(
              version: CatalogoLocalSnapshot.currentVersion,
              productos: List.of(_allProductos),
              total: data.total,
              currentPage: data.page,
              totalPages: data.totalPages,
              hasMore: data.hasNext,
              savedAt: ahora,
            ),
          ),
        );
        // Fase 3: el `lastSync` (punto de partida para deltas) SOLO se
        // persiste cuando el catálogo está COMPLETO (sin más páginas
        // pendientes). Si lo persistiéramos con `hasNext=true`, una
        // primera carga parcial (red lenta o el usuario abandona la
        // app antes de cargar todo) dejaría al cliente creyendo que
        // tiene todo el catálogo. Las próximas requests pedirían
        // deltas desde ese instante y el backend respondería "0
        // cambios" → los productos no descargados nunca llegarían
        // (no son deltas, son data vieja). El usuario quedaría con
        // un subset permanente hasta borrar datos de app.
        //
        // En caso de catálogo paginado, el `lastSync` se marca recién
        // en `loadMore` cuando se llega a la última página.
        if (!data.hasNext) {
          unawaited(
            _localStore.writeLastSync(
              empresaId: empresaId,
              sedeId: sedeId,
              serverTime: ahora.toIso8601String(),
            ),
          );
        }
      }

      // Guardar en cache de memoria para la próxima apertura.
      _memoryCache.put(
        empresaId,
        sedeId,
        _currentFiltros,
        CatalogoCacheEntry(
          productos: List.of(_allProductos),
          total: data.total,
          currentPage: data.page,
          totalPages: data.totalPages,
          hasMore: data.hasNext,
          filtros: _currentFiltros,
          productosFullCache: Map.of(_productosFullCache),
          timestamp: DateTime.now(),
        ),
      );

      emit(ProductoListLoaded(
        productos: _allProductos,
        total: data.total,
        currentPage: data.page,
        totalPages: data.totalPages,
        hasMore: data.hasNext,
        filtros: _currentFiltros,
        isFiltering: false,
      ));

      // Background prefetch: si quedan páginas y el catálogo no es
      // absurdamente grande, descargamos el resto sin bloquear UI.
      // Fire-and-forget — el método maneja su propia cancelación.
      if (esCatalogoBase &&
          data.hasNext &&
          !_isPrefetching &&
          data.total <= _prefetchTotalCap) {
        unawaited(_prefetchTodasLasPaginas(
          empresaId: empresaId,
          sedeId: sedeId,
          mySeq: mySeq,
          startPage: data.page + 1,
        ));
      }
    } else if (result is Error<ProductosPaginados>) {
      // Si tenemos cache hidratado, NO pisamos con error — mantenemos
      // los datos cacheados visibles y solo apagamos isFiltering.
      // El cajero ve productos reales en vez de pantalla de error.
      if (puedeHidratarDeCache && state is ProductoListLoaded) {
        final loaded = state as ProductoListLoaded;
        emit(loaded.copyWith(isFiltering: false));
      } else {
        emit(ProductoListError(result.message, errorCode: result.errorCode));
      }
    }
  }

  /// Carga más productos (paginación). No incrementa `_requestSeq` para no
  /// invalidar refrescos en curso, pero igualmente captura el seq actual y
  /// descarta si el usuario gatilló un nuevo filtro mientras tanto.
  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! ProductoListLoaded) return;
    if (!currentState.hasMore) return;
    if (currentState.isFiltering) return; // ya hay un filtro en curso
    if (_currentEmpresaId == null) return;
    // Si el prefetch está activo, no disparar otro request — el
    // prefetch ya está trayendo la siguiente página. Si el usuario
    // scrolea rápido los items van apareciendo solos.
    if (_isPrefetching) return;

    final mySeq = _requestSeq;
    emit(ProductoListLoadingMore(_allProductos));

    final nextPage = currentState.currentPage + 1;
    final nextFiltros = _currentFiltros.copyWith(page: nextPage);

    final result = await _getProductosUseCase(
      empresaId: _currentEmpresaId!,
      sedeId: _currentSedeId,
      filtros: nextFiltros,
    );

    if (isClosed) return;
    // Si entre tanto un filtro nuevo invalidó la lista, no agregamos esta
    // página (correspondería a otra búsqueda).
    if (mySeq != _requestSeq) return;

    if (result is Success<ProductosPaginados>) {
      final data = result.data;
      final nuevos = data.data.cast<ProductoListItem>();
      _allProductos.addAll(nuevos);
      // Acumular en biblioteca de vistos.
      for (final p in nuevos) {
        _vistosCache[p.id] = p;
      }
      _recortarBiblioteca();
      // Persistir tras paginación — los productos de página 2+ también
      // tienen que sobrevivir al cierre de la app.
      if (_currentEmpresaId != null) {
        unawaited(
          _localStore.writeLibreria(
            empresaId: _currentEmpresaId!,
            productos: _vistosCache.values.toList(),
          ),
        );
      }

      // Almacenar productos completos en cache (si existen)
      if (data.fullProductosCache != null) {
        _productosFullCache.addAll(data.fullProductosCache!);
      }

      // Snapshot incremental: tras cada `loadMore` exitoso con filtro
      // de catálogo base, persistimos la lista acumulada en disco.
      // Útil para catálogos grandes (total > 5000) donde el prefetch
      // no arranca — si el usuario scrolea, cierra la app, y vuelve a
      // abrir, el snapshot refleja todo lo que descargó manualmente.
      //
      // El `lastSync` SOLO se persiste cuando llegamos a la última
      // página (hasNext=false): recién ahí el cliente tiene el catálogo
      // COMPLETO y la próxima apertura puede usar syncDeltas. Ver
      // explicación detallada del bug en `loadProductos`.
      if (_esCatalogoBaseFiltros(nextFiltros)) {
        final ahora = DateTime.now();
        unawaited(
          _localStore.write(
            empresaId: _currentEmpresaId!,
            sedeId: _currentSedeId,
            snapshot: CatalogoLocalSnapshot(
              version: CatalogoLocalSnapshot.currentVersion,
              productos: List.of(_allProductos),
              total: data.total,
              currentPage: data.page,
              totalPages: data.totalPages,
              hasMore: data.hasNext,
              savedAt: ahora,
            ),
          ),
        );
        if (!data.hasNext) {
          unawaited(
            _localStore.writeLastSync(
              empresaId: _currentEmpresaId!,
              sedeId: _currentSedeId,
              serverTime: ahora.toIso8601String(),
            ),
          );
        }
      }

      emit(ProductoListLoaded(
        productos: _allProductos,
        total: data.total,
        currentPage: data.page,
        totalPages: data.totalPages,
        hasMore: data.hasNext,
        filtros: nextFiltros,
      ));
    } else if (result is Error<ProductosPaginados>) {
      // Volver al estado anterior en caso de error
      emit(currentState);
    }
  }

  /// Aplica filtros y recarga la lista. Mantiene la lista actual visible
  /// con un indicador de "filtrando" para evitar parpadeo (UX SaaS).
  Future<void> applyFiltros(ProductoFiltros filtros, {String? sedeId}) async {
    if (_currentEmpresaId == null) return;
    await loadProductos(
      empresaId: _currentEmpresaId!,
      sedeId: sedeId ?? _currentSedeId,
      filtros: filtros,
      keepListWhileFiltering: true,
    );
  }

  /// Resetea los filtros
  Future<void> resetFiltros({String? sedeId}) async {
    if (_currentEmpresaId == null) return;
    await loadProductos(
      empresaId: _currentEmpresaId!,
      sedeId: sedeId ?? _currentSedeId,
      filtros: const ProductoFiltros(),
      keepListWhileFiltering: true,
    );
  }

  /// Revalida con el servidor SIN descartar la cache local — descarta
  /// solo el `lastSync` para forzar fetch full (no usa syncDeltas) y
  /// que el backend re-aplique filtros (isActive, deletedAt, orden,
  /// etc). La lista actual se mantiene visible con la barra fina de
  /// `isFiltering` mientras revalida — UX sutil sin parpadeo de
  /// Loading completo.
  ///
  /// Usado por los listeners de FCM cuando llega PRODUCTO_CREADO o
  /// PRODUCTO_ACTUALIZADO: el delta no alcanza (producto nuevo iría al
  /// final del array, producto desactivado quedaría visible), pero
  /// tampoco queremos vaciar la grilla con `reload()`.
  Future<void> revalidarSinDeltas({String? sedeId}) async {
    if (_currentEmpresaId == null) return;
    final sedeIdReal = sedeId ?? _currentSedeId;
    _memoryCache.invalidateEmpresa(_currentEmpresaId!);
    unawaited(
      _localStore.clearLastSync(
        empresaId: _currentEmpresaId!,
        sedeId: sedeIdReal,
      ),
    );
    await loadProductos(
      empresaId: _currentEmpresaId!,
      sedeId: sedeIdReal,
      filtros: _currentFiltros,
      keepListWhileFiltering: true,
    );
  }

  /// Recarga la lista actual. Pull-to-refresh debe forzar fetch al
  /// server (intención explícita del usuario de ver datos frescos),
  /// por eso invalidamos memoria + biblioteca + disco antes.
  Future<void> reload({String? sedeId}) async {
    if (_currentEmpresaId == null) return;
    _memoryCache.invalidateEmpresa(_currentEmpresaId!);
    _vistosCache.clear();
    // Fire-and-forget: no bloqueamos la UI esperando al delete.
    unawaited(_localStore.clearEmpresa(_currentEmpresaId!));
    // Fase 3: pull-to-refresh tiene que forzar fetch full (intención
    // explícita del usuario), por eso descartamos el lastSync para
    // que la próxima request NO use deltas.
    unawaited(
      _localStore.clearLastSync(
        empresaId: _currentEmpresaId!,
        sedeId: _currentSedeId,
      ),
    );
    await loadProductos(
      empresaId: _currentEmpresaId!,
      sedeId: sedeId ?? _currentSedeId,
      filtros: _currentFiltros.copyWith(page: 1),
    );
  }

  /// Heurística para decidir si el filtro actual corresponde al
  /// "catálogo base" — el listado completo sin búsqueda ni filtros
  /// específicos. Solo el catálogo base se persiste en disco; las
  /// búsquedas puntuales viven en memoria + biblioteca acumulativa.
  bool _esCatalogoBase(ProductoFiltros f) {
    return _esCatalogoBaseFiltros(f) && f.page == 1;
  }

  /// Misma heurística pero ignorando el campo `page` — útil desde
  /// `loadMore` (que paginas > 1) para validar que el flujo sigue
  /// siendo del catálogo base antes de persistir el snapshot final.
  bool _esCatalogoBaseFiltros(ProductoFiltros f) {
    final searchVacio = f.search == null || f.search!.isEmpty;
    return searchVacio &&
        f.empresaCategoriaId == null &&
        f.empresaMarcaId == null &&
        // Filtros de TAB: insumos / solo-productos / solo-combos / liquidación
        // NO son el catálogo base (el vendible general que se persiste en
        // disco y se revalida con deltas). Sin esto, al entrar a esos tabs el
        // cubit leía del disco/deltas (todo el catálogo) y retornaba antes de
        // hacer el fetch filtrado → mostraba de más hasta hacer refresh.
        f.esInsumo != true &&
        f.soloProductos != true &&
        f.soloCombos != true &&
        f.enLiquidacion != true &&
        // Filtros avanzados (si están activos, tampoco es el catálogo base).
        f.visibleMarketplace == null &&
        f.destacado == null &&
        f.enOferta == null &&
        f.stockBajo == null;
  }

  /// Fase 3: revalida con sync diferencial. Solo se invoca si hay
  /// cache cargado y la query es catálogo base.
  ///
  /// Devuelve `true` si pudo aplicar deltas exitosamente (el estado
  /// ya quedó emitido con la versión fresca). `false` significa que
  /// el caller debe fallback al `getProductos` completo (cliente sin
  /// lastSync, server pidió fullSyncRequired, o fallo de red).
  Future<bool> _tryRevalidarConSyncDeltas({
    required String empresaId,
    String? sedeId,
    required int mySeq,
  }) async {
    final lastSync = await _localStore.readLastSync(
      empresaId: empresaId,
      sedeId: sedeId,
    );
    if (lastSync == null) return false;

    final result = await _productoRepository.syncDeltasProductos(
      lastSync: lastSync,
      sedeId: sedeId,
    );
    if (isClosed) return true; // ya no nos importa lo que llegó
    if (mySeq != _requestSeq) return true;

    if (result is! Success<SyncDeltasResult>) return false;
    final deltas = result.data;
    if (deltas.fullSyncRequired) return false;

    // Aplicar deltas sobre cache local, contando los cambios REALES al total:
    // `deltas.updated` incluye productos MODIFICADOS (no solo nuevos), así que
    // sumar `updated.length` infla el contador en cada edición. Solo cuenta como
    // nuevo el que no existía (idx < 0); modificar uno existente no cambia el total.
    var nuevos = 0;
    var eliminados = 0;
    for (final id in deltas.deleted) {
      _vistosCache.remove(id);
      final antes = _allProductos.length;
      _allProductos.removeWhere((p) => p.id == id);
      if (_allProductos.length < antes) eliminados++;
    }
    for (final p in deltas.updated) {
      _vistosCache[p.id] = p;
      final idx = _allProductos.indexWhere((x) => x.id == p.id);
      if (idx >= 0) {
        _allProductos[idx] = p;
      } else {
        _allProductos.add(p);
        nuevos++;
      }
    }
    _recortarBiblioteca();

    // Persistir: nuevo lastSync + biblioteca + snapshot base.
    unawaited(
      _localStore.writeLastSync(
        empresaId: empresaId,
        sedeId: sedeId,
        serverTime: deltas.serverTime,
      ),
    );
    unawaited(
      _localStore.writeLibreria(
        empresaId: empresaId,
        productos: _vistosCache.values.toList(),
      ),
    );
    final current = state;
    if (current is ProductoListLoaded) {
      // Total autoritativo del server si el delta lo trae; si no, el conteo
      // corregido (nuevos reales - eliminados reales).
      final nuevoTotal = deltas.total ?? (current.total + nuevos - eliminados);
      unawaited(
        _localStore.write(
          empresaId: empresaId,
          sedeId: sedeId,
          snapshot: CatalogoLocalSnapshot(
            version: CatalogoLocalSnapshot.currentVersion,
            productos: List.of(_allProductos),
            total: nuevoTotal,
            currentPage: current.currentPage,
            totalPages: current.totalPages,
            hasMore: current.hasMore,
            savedAt: DateTime.now(),
          ),
        ),
      );
      // También actualizar memory cache.
      _memoryCache.put(
        empresaId,
        sedeId,
        _currentFiltros,
        CatalogoCacheEntry(
          productos: List.of(_allProductos),
          total: nuevoTotal,
          currentPage: current.currentPage,
          totalPages: current.totalPages,
          hasMore: current.hasMore,
          filtros: _currentFiltros,
          productosFullCache: Map.of(_productosFullCache),
          timestamp: DateTime.now(),
        ),
      );

      emit(
        current.copyWith(
          productos: _allProductos,
          total: nuevoTotal,
          isFiltering: false,
        ),
      );
    }
    return true;
  }

  /// Descarga las páginas restantes del catálogo base en background y
  /// las agrega al state sin spinner intermedio. Si llega a la última
  /// página, persiste snapshot completo + lastSync para que las
  /// próximas aperturas usen syncDeltas en vez de fetch full.
  ///
  /// Cancelación: el loop chequea `_requestSeq != mySeq` (usuario
  /// cambió filtros/tabs/scrolló a otro lado) o `isClosed` (cubit
  /// cerrado por logout/switch). Cualquiera de los dos rompe el loop
  /// silenciosamente — lo descargado hasta el momento queda persistido
  /// en la biblioteca acumulativa.
  Future<void> _prefetchTodasLasPaginas({
    required String empresaId,
    String? sedeId,
    required int mySeq,
    required int startPage,
  }) async {
    if (_isPrefetching) return;
    _isPrefetching = true;
    try {
      var page = startPage;
      var hasNext = true;
      var lastTotal = 0;
      var lastTotalPages = 0;

      while (hasNext && page <= _prefetchMaxPages) {
        // Throttle entre requests — alivio para red/backend + ventana
        // para que la cancelación actúe antes del próximo request.
        await Future.delayed(_prefetchDelay);

        if (isClosed) return;
        if (mySeq != _requestSeq) return; // canceló otro flujo
        // El estado debe seguir siendo Loaded para que tenga sentido
        // emitir actualizaciones — si el usuario navegó y el state es
        // Initial/Loading/Error abortamos.
        if (state is! ProductoListLoaded) return;

        final pageFiltros = _currentFiltros.copyWith(page: page);
        final result = await _getProductosUseCase(
          empresaId: empresaId,
          sedeId: sedeId,
          filtros: pageFiltros,
        );

        if (isClosed) return;
        if (mySeq != _requestSeq) return;
        if (state is! ProductoListLoaded) return;

        if (result is! Success<ProductosPaginados>) {
          // Error de red en esta página — abortamos en silencio. Lo
          // descargado hasta ahora queda en biblioteca y en memoria.
          // El usuario puede seguir haciendo loadMore manualmente.
          return;
        }

        final data = result.data;
        final nuevos = data.data.cast<ProductoListItem>();
        _allProductos.addAll(nuevos);
        for (final p in nuevos) {
          _vistosCache[p.id] = p;
        }
        _recortarBiblioteca();
        if (data.fullProductosCache != null) {
          _productosFullCache.addAll(data.fullProductosCache!);
        }

        // Persistir biblioteca para que sobreviva cierre — si el
        // usuario cierra antes de que termine el prefetch, lo
        // descargado sigue disponible para búsquedas locales.
        unawaited(
          _localStore.writeLibreria(
            empresaId: empresaId,
            productos: _vistosCache.values.toList(),
          ),
        );

        // Emit transparente — `isFiltering: false`, sin spinner.
        // La grilla crece de forma natural.
        final loaded = state as ProductoListLoaded;
        emit(loaded.copyWith(
          productos: _allProductos,
          total: data.total,
          currentPage: data.page,
          totalPages: data.totalPages,
          hasMore: data.hasNext,
          isFiltering: false,
        ));

        lastTotal = data.total;
        lastTotalPages = data.totalPages;
        hasNext = data.hasNext;
        page = data.page + 1;
      }

      // Al terminar exitosamente (no quedan páginas), persistir
      // snapshot completo + lastSync. Recién ahora la próxima apertura
      // podrá usar syncDeltas (~1 KB) en vez de fetch full (~200 KB).
      if (!hasNext &&
          mySeq == _requestSeq &&
          !isClosed &&
          _esCatalogoBaseFiltros(_currentFiltros)) {
        final ahora = DateTime.now();
        unawaited(
          _localStore.write(
            empresaId: empresaId,
            sedeId: sedeId,
            snapshot: CatalogoLocalSnapshot(
              version: CatalogoLocalSnapshot.currentVersion,
              productos: List.of(_allProductos),
              total: lastTotal,
              currentPage: page - 1,
              totalPages: lastTotalPages,
              hasMore: false,
              savedAt: ahora,
            ),
          ),
        );
        unawaited(
          _localStore.writeLastSync(
            empresaId: empresaId,
            sedeId: sedeId,
            serverTime: ahora.toIso8601String(),
          ),
        );
      }
    } finally {
      _isPrefetching = false;
    }
  }

  /// Restaura la biblioteca acumulativa desde disco. Se invoca antes
  /// del primer fetch para que el filtro local del builder tenga
  /// datos disponibles desde el primer frame (sobreviven cierres).
  Future<void> _hidratarLibreriaDeDisco(String empresaId) async {
    final persistida =
        await _localStore.readLibreria(empresaId: empresaId);
    if (persistida.isEmpty) return;
    for (final p in persistida) {
      _vistosCache[p.id] = p;
    }
  }

  /// Recorta la biblioteca al tope configurado (LRU implícito por
  /// orden de inserción del LinkedHashMap — los más viejos al frente).
  /// Evita que clientes con catálogos grandes hagan crecer el archivo
  /// indefinidamente.
  void _recortarBiblioteca() {
    final tope = ProductoCatalogoLocalStore.librariaMaxProductos;
    if (_vistosCache.length <= tope) return;
    final excedente = _vistosCache.length - tope;
    final keys = _vistosCache.keys.take(excedente).toList();
    for (final k in keys) {
      _vistosCache.remove(k);
    }
  }

  /// Limpia el estado
  void clear() {
    _currentEmpresaId = null;
    _currentSedeId = null;
    _currentFiltros = const ProductoFiltros();
    _allProductos = [];
    _productosFullCache.clear();
    _vistosCache.clear();
    emit(const ProductoListInitial());
  }

  /// Invalida el cache local (llamar cuando se crea/actualiza/elimina producto)
  /// Esto sincroniza con la invalidación de cache de Redis en el backend
  void invalidateCache() {
    _productosFullCache.clear();
  }

  /// Elimina un producto específico del cache (invalidación selectiva)
  /// Usado cuando se crea/edita un producto para que el detalle haga una petición fresca
  void removeFromCache(String productoId) {
    _productosFullCache.remove(productoId);
  }

  /// Almacena un producto completo en el cache
  void cacheProductoCompleto(Producto producto) {
    _productosFullCache[producto.id] = producto;
  }

  /// Obtiene un producto completo del cache (si existe)
  Producto? getProductoFromCache(String productoId) {
    return _productosFullCache[productoId];
  }
}
