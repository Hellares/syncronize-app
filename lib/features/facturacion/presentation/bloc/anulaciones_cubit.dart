import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/anulacion.dart';
import '../../domain/entities/comunicacion_baja.dart';
import '../../domain/entities/resumen_diario.dart';
import '../../domain/usecases/listar_anulaciones_usecase.dart';
import 'anulaciones_state.dart';

class AnulacionesCubit extends Cubit<AnulacionesState> {
  final ListarCDBsUseCase _listarCDBs;
  final ListarRCsUseCase _listarRCs;
  final ConsultarCDBUseCase _consultarCDB;
  final ConsultarRCUseCase _consultarRC;

  FiltroTipoAnulacion _filtroTipo = FiltroTipoAnulacion.todas;
  String? _filtroEstado;
  String? _fechaDesde;
  String? _fechaHasta;
  int _currentPage = 1;
  static const int _limit = 20;

  AnulacionesCubit(
    this._listarCDBs,
    this._listarRCs,
    this._consultarCDB,
    this._consultarRC,
  ) : super(AnulacionesInitial());

  /// Carga la página actual aplicando los filtros vigentes.
  /// - tipo == cdb → solo `/comunicaciones-baja`.
  /// - tipo == rc  → solo `/resumenes-diarios`.
  /// - tipo == todas → ambos endpoints en paralelo, mergeo por fechaEmision desc.
  Future<void> cargar({int page = 1}) async {
    _currentPage = page;
    emit(AnulacionesLoading());

    try {
      final List<Anulacion> items;
      int total;
      int totalPages;

      switch (_filtroTipo) {
        case FiltroTipoAnulacion.cdb:
          final r = await _listarCDBs(
            estadoSunat: _filtroEstado,
            fechaDesde: _fechaDesde,
            fechaHasta: _fechaHasta,
            page: page,
            limit: _limit,
          );
          if (r is Error<AnulacionesPaginadas<ComunicacionBaja>>) {
            emit(AnulacionesError(r.message));
            return;
          }
          final p = (r as Success<AnulacionesPaginadas<ComunicacionBaja>>).data;
          items = p.data.map((e) => Anulacion.fromCDB(e)).toList();
          total = p.total;
          totalPages = p.totalPages;
          break;

        case FiltroTipoAnulacion.rc:
          final r = await _listarRCs(
            estadoSunat: _filtroEstado,
            fechaDesde: _fechaDesde,
            fechaHasta: _fechaHasta,
            page: page,
            limit: _limit,
          );
          if (r is Error<AnulacionesPaginadas<ResumenDiario>>) {
            emit(AnulacionesError(r.message));
            return;
          }
          final p = (r as Success<AnulacionesPaginadas<ResumenDiario>>).data;
          items = p.data.map((e) => Anulacion.fromRC(e)).toList();
          total = p.total;
          totalPages = p.totalPages;
          break;

        case FiltroTipoAnulacion.todas:
          final results = await Future.wait([
            _listarCDBs(
              estadoSunat: _filtroEstado,
              fechaDesde: _fechaDesde,
              fechaHasta: _fechaHasta,
              page: page,
              limit: _limit,
            ),
            _listarRCs(
              estadoSunat: _filtroEstado,
              fechaDesde: _fechaDesde,
              fechaHasta: _fechaHasta,
              page: page,
              limit: _limit,
            ),
          ]);
          final cdbResult = results[0];
          final rcResult = results[1];

          if (cdbResult is Error) {
            emit(AnulacionesError((cdbResult as Error).message));
            return;
          }
          if (rcResult is Error) {
            emit(AnulacionesError((rcResult as Error).message));
            return;
          }
          final cdbs = (cdbResult as Success).data
              as AnulacionesPaginadas<ComunicacionBaja>;
          final rcs = (rcResult as Success).data
              as AnulacionesPaginadas<ResumenDiario>;

          final mergedRaw = <Anulacion>[
            ...cdbs.data.map((e) => Anulacion.fromCDB(e)),
            ...rcs.data.map((e) => Anulacion.fromRC(e)),
          ];
          mergedRaw.sort((a, b) => b.fechaEmision.compareTo(a.fechaEmision));
          items = mergedRaw;
          total = cdbs.total + rcs.total;
          // En modo combinado tomamos el máximo de páginas como referencia
          totalPages = cdbs.totalPages > rcs.totalPages
              ? cdbs.totalPages
              : rcs.totalPages;
          break;
      }

      emit(AnulacionesLoaded(
        items: items,
        total: total,
        currentPage: page,
        totalPages: totalPages,
        filtroTipo: _filtroTipo,
        filtroEstado: _filtroEstado,
        fechaDesde: _fechaDesde,
        fechaHasta: _fechaHasta,
      ));
    } catch (e) {
      emit(AnulacionesError(e.toString()));
    }
  }

  void setFiltroTipo(FiltroTipoAnulacion tipo) {
    if (_filtroTipo == tipo) return;
    _filtroTipo = tipo;
    cargar();
  }

  void setFiltroEstado(String? estado) {
    _filtroEstado = estado;
    cargar();
  }

  void setFechas(String? desde, String? hasta) {
    _fechaDesde = desde;
    _fechaHasta = hasta;
    cargar();
  }

  void limpiarFiltros() {
    _filtroTipo = FiltroTipoAnulacion.todas;
    _filtroEstado = null;
    _fechaDesde = null;
    _fechaHasta = null;
    cargar();
  }

  Future<void> refrescar() => cargar(page: _currentPage);

  Future<void> irAPagina(int page) => cargar(page: page);

  /// Re-consulta una anulación contra el proveedor para refrescar su estado.
  /// Bifurca por tipo. Recarga el listado al terminar.
  Future<String?> reConsultar(Anulacion anulacion) async {
    final result = anulacion.tipo == TipoAnulacion.cdb
        ? await _consultarCDB(anulacion.id)
        : await _consultarRC(anulacion.id);

    if (result is Error) {
      return (result as Error).message;
    }
    await cargar(page: _currentPage);
    return null;
  }
}
