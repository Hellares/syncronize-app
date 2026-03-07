import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/usecases/get_compra_analytics_usecase.dart';
import 'compra_analytics_state.dart';

@injectable
class CompraAnalyticsCubit extends Cubit<CompraAnalyticsState> {
  final GetCompraAnalyticsUseCase _getCompraAnalyticsUseCase;

  CompraAnalyticsCubit(this._getCompraAnalyticsUseCase)
      : super(const CompraAnalyticsInitial());

  String? _currentEmpresaId;
  String? _sedeId;
  String? _fechaInicio;
  String? _fechaFin;
  String? _periodo;

  Future<void> loadAnalytics({
    required String empresaId,
    String? sedeId,
    String? fechaInicio,
    String? fechaFin,
    String? periodo,
  }) async {
    if (empresaId.isEmpty) {
      emit(const CompraAnalyticsError('ID de empresa no valido'));
      return;
    }

    _currentEmpresaId = empresaId;
    _sedeId = sedeId;
    _fechaInicio = fechaInicio;
    _fechaFin = fechaFin;
    _periodo = periodo;

    emit(const CompraAnalyticsLoading());

    final result = await _getCompraAnalyticsUseCase(
      empresaId: empresaId,
      sedeId: sedeId,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      periodo: periodo,
    );

    if (result is Success<CompraAnalyticsData>) {
      emit(CompraAnalyticsLoaded(
        data: result.data,
        sedeId: sedeId,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        periodo: periodo,
      ));
    } else if (result is Error<CompraAnalyticsData>) {
      emit(CompraAnalyticsError(result.message));
    }
  }

  Future<void> reload() async {
    if (_currentEmpresaId == null) return;
    await loadAnalytics(
      empresaId: _currentEmpresaId!,
      sedeId: _sedeId,
      fechaInicio: _fechaInicio,
      fechaFin: _fechaFin,
      periodo: _periodo,
    );
  }

  void updateFilters({
    String? sedeId,
    String? fechaInicio,
    String? fechaFin,
    String? periodo,
  }) {
    if (_currentEmpresaId == null) return;
    loadAnalytics(
      empresaId: _currentEmpresaId!,
      sedeId: sedeId ?? _sedeId,
      fechaInicio: fechaInicio ?? _fechaInicio,
      fechaFin: fechaFin ?? _fechaFin,
      periodo: periodo ?? _periodo,
    );
  }
}
