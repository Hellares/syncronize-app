import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../../core/utils/resource.dart';
import '../../../data/models/transferencia_incidencia_model.dart';
import '../../../domain/usecases/listar_incidencias_usecase.dart';
import 'listar_incidencias_state.dart';

@injectable
class ListarIncidenciasCubit extends Cubit<ListarIncidenciasState> {
  final ListarIncidenciasUseCase _useCase;

  // Estado interno para mantener filtros
  String? _currentEmpresaId;
  bool? _currentResuelto;
  String? _currentTipo;
  String? _currentSedeId;
  String? _currentTransferenciaId;

  ListarIncidenciasCubit(this._useCase)
      : super(const ListarIncidenciasInitial());

  /// Carga incidencias con filtros
  Future<void> loadIncidencias({
    required String empresaId,
    bool? resuelto,
    String? tipo,
    String? sedeId,
    String? transferenciaId,
  }) async {
    // Guardar filtros actuales
    _currentEmpresaId = empresaId;
    _currentResuelto = resuelto;
    _currentTipo = tipo;
    _currentSedeId = sedeId;
    _currentTransferenciaId = transferenciaId;

    emit(const ListarIncidenciasLoading());

    final result = await _useCase(
      empresaId: empresaId,
      resuelto: resuelto,
      tipo: tipo,
      sedeId: sedeId,
      transferenciaId: transferenciaId,
    );

    if (isClosed) return;

    if (result is Success<List<dynamic>>) {
      final incidencias = (result.data)
          .map((json) =>
              TransferenciaIncidenciaModel.fromJson(json as Map<String, dynamic>))
          .toList();

      final totalPendientes =
          incidencias.where((i) => i.estaPendiente).length;
      final totalResueltas = incidencias.where((i) => i.resuelto).length;

      emit(ListarIncidenciasLoaded(
        incidencias: incidencias,
        totalPendientes: totalPendientes,
        totalResueltas: totalResueltas,
      ));
    } else if (result is Error<List<dynamic>>) {
      emit(ListarIncidenciasError(
        result.message,
        errorCode: result.errorCode,
      ));
    }
  }

  /// Recarga con los filtros actuales
  Future<void> reload() async {
    if (_currentEmpresaId != null) {
      await loadIncidencias(
        empresaId: _currentEmpresaId!,
        resuelto: _currentResuelto,
        tipo: _currentTipo,
        sedeId: _currentSedeId,
        transferenciaId: _currentTransferenciaId,
      );
    }
  }

  /// Carga solo incidencias pendientes
  Future<void> loadPendientes({required String empresaId}) async {
    await loadIncidencias(empresaId: empresaId, resuelto: false);
  }

  /// Carga solo incidencias resueltas
  Future<void> loadResueltas({required String empresaId}) async {
    await loadIncidencias(empresaId: empresaId, resuelto: true);
  }

  /// Filtra por tipo de incidencia
  Future<void> filterByTipo({
    required String empresaId,
    required String tipo,
  }) async {
    await loadIncidencias(empresaId: empresaId, tipo: tipo);
  }

  /// Filtra por sede
  Future<void> filterBySede({
    required String empresaId,
    required String sedeId,
  }) async {
    await loadIncidencias(empresaId: empresaId, sedeId: sedeId);
  }

  /// Filtra por transferencia específica
  Future<void> filterByTransferencia({
    required String empresaId,
    required String transferenciaId,
  }) async {
    await loadIncidencias(
      empresaId: empresaId,
      transferenciaId: transferenciaId,
    );
  }

  /// Reinicia filtros y muestra todas las incidencias
  Future<void> resetFilters({required String empresaId}) async {
    await loadIncidencias(empresaId: empresaId);
  }

  /// Limpia el estado
  void reset() {
    if (isClosed) return;
    _currentEmpresaId = null;
    _currentResuelto = null;
    _currentTipo = null;
    _currentSedeId = null;
    _currentTransferenciaId = null;
    emit(const ListarIncidenciasInitial());
  }
}
