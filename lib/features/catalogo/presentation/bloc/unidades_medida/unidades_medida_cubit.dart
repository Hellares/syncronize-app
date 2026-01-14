import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../domain/usecases/activar_unidad_usecase.dart';
import '../../../domain/usecases/activar_unidades_populares_usecase.dart';
import '../../../domain/usecases/desactivar_unidad_usecase.dart';
import '../../../domain/usecases/get_unidades_empresa_usecase.dart';
import '../../../domain/usecases/get_unidades_maestras_usecase.dart';
import 'unidades_medida_state.dart';

/// Cubit para gestionar el estado de las unidades de medida
@injectable
class UnidadMedidaCubit extends Cubit<UnidadMedidaState> {
  final GetUnidadesMaestrasUseCase _getUnidadesMaestrasUseCase;
  final GetUnidadesEmpresaUseCase _getUnidadesEmpresaUseCase;
  final ActivarUnidadUseCase _activarUnidadUseCase;
  final DesactivarUnidadUseCase _desactivarUnidadUseCase;
  final ActivarUnidadesPopularesUseCase _activarUnidadesPopularesUseCase;

  UnidadMedidaCubit(
    this._getUnidadesMaestrasUseCase,
    this._getUnidadesEmpresaUseCase,
    this._activarUnidadUseCase,
    this._desactivarUnidadUseCase,
    this._activarUnidadesPopularesUseCase,
  ) : super(UnidadMedidaInitial());

  /// Obtiene las unidades de medida maestras del catálogo SUNAT
  ///
  /// [categoria] - Filtrar por categoría (CANTIDAD, MASA, LONGITUD, etc.)
  /// [soloPopulares] - Si es true, solo devuelve las unidades populares
  Future<void> getUnidadesMaestras({
    String? categoria,
    bool soloPopulares = false,
  }) async {
    try {
      emit(UnidadesMaestrasLoading());

      final unidades = await _getUnidadesMaestrasUseCase(
        categoria: categoria,
        soloPopulares: soloPopulares,
      );

      emit(UnidadesMaestrasLoaded(unidades));
    } catch (e) {
      emit(UnidadMedidaError(e.toString()));
    }
  }

  /// Obtiene las unidades de medida activadas para una empresa
  ///
  /// [empresaId] - ID de la empresa
  Future<void> getUnidadesEmpresa(String empresaId) async {
    try {
      emit(UnidadesEmpresaLoading());

      final unidades = await _getUnidadesEmpresaUseCase(empresaId);

      emit(UnidadesEmpresaLoaded(unidades));
    } catch (e) {
      emit(UnidadMedidaError(e.toString()));
    }
  }

  /// Activa una unidad de medida para una empresa
  ///
  /// Puede activar una unidad maestra existente o crear una personalizada
  Future<void> activarUnidad({
    required String empresaId,
    String? unidadMaestraId,
    String? nombrePersonalizado,
    String? simboloPersonalizado,
    String? codigoPersonalizado,
    String? descripcion,
    String? nombreLocal,
    String? simboloLocal,
    int? orden,
  }) async {
    try {
      emit(ActivandoUnidad());

      final unidad = await _activarUnidadUseCase(
        empresaId: empresaId,
        unidadMaestraId: unidadMaestraId,
        nombrePersonalizado: nombrePersonalizado,
        simboloPersonalizado: simboloPersonalizado,
        codigoPersonalizado: codigoPersonalizado,
        descripcion: descripcion,
        nombreLocal: nombreLocal,
        simboloLocal: simboloLocal,
        orden: orden,
      );

      emit(UnidadActivada(unidad));
    } catch (e) {
      emit(UnidadMedidaError(e.toString()));
    }
  }

  /// Desactiva una unidad de medida de una empresa
  ///
  /// [empresaId] - ID de la empresa
  /// [unidadId] - ID de la unidad a desactivar
  Future<void> desactivarUnidad({
    required String empresaId,
    required String unidadId,
  }) async {
    try {
      emit(DesactivandoUnidad());

      await _desactivarUnidadUseCase(
        empresaId: empresaId,
        unidadId: unidadId,
      );

      emit(UnidadDesactivada());
    } catch (e) {
      emit(UnidadMedidaError(e.toString()));
    }
  }

  /// Activa las unidades de medida populares automáticamente
  ///
  /// Activa las 9 unidades más comunes (Unidad, Kilogramo, Metro, Litro, etc.)
  /// [empresaId] - ID de la empresa
  Future<void> activarUnidadesPopulares(String empresaId) async {
    try {
      emit(ActivandoUnidadesPopulares());

      final unidades = await _activarUnidadesPopularesUseCase(empresaId);

      emit(UnidadesPopularesActivadas(unidades));
    } catch (e) {
      emit(UnidadMedidaError(e.toString()));
    }
  }

  /// Reinicia el estado a inicial
  void reset() {
    emit(UnidadMedidaInitial());
  }
}
