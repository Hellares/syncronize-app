import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/configuracion_codigos.dart';
import '../../domain/usecases/get_configuracion_usecase.dart';
import '../../domain/usecases/update_config_productos_usecase.dart';
import '../../domain/usecases/update_config_variantes_usecase.dart';
import '../../domain/usecases/update_config_servicios_usecase.dart';
import '../../domain/usecases/update_config_ventas_usecase.dart';
import '../../domain/usecases/preview_codigo_usecase.dart';
import '../../domain/usecases/sincronizar_contador_usecase.dart';
import 'configuracion_codigos_state.dart';

@injectable
class ConfiguracionCodigosCubit extends Cubit<ConfiguracionCodigosState> {
  final GetConfiguracionUseCase _getConfiguracionUseCase;
  final UpdateConfigProductosUseCase _updateConfigProductosUseCase;
  final UpdateConfigVariantesUseCase _updateConfigVariantesUseCase;
  final UpdateConfigServiciosUseCase _updateConfigServiciosUseCase;
  final UpdateConfigVentasUseCase _updateConfigVentasUseCase;
  final PreviewCodigoUseCase _previewCodigoUseCase;
  final SincronizarContadorUseCase _sincronizarContadorUseCase;

  ConfiguracionCodigosCubit(
    this._getConfiguracionUseCase,
    this._updateConfigProductosUseCase,
    this._updateConfigVariantesUseCase,
    this._updateConfigServiciosUseCase,
    this._updateConfigVentasUseCase,
    this._previewCodigoUseCase,
    this._sincronizarContadorUseCase,
  ) : super(const ConfiguracionCodigosInitial());

  /// Carga la configuración de códigos de una empresa
  Future<void> loadConfiguracion(String empresaId) async {
    emit(const ConfiguracionCodigosLoading());

    final result = await _getConfiguracionUseCase(empresaId);

    if (result is Success<ConfiguracionCodigos>) {
      emit(ConfiguracionCodigosLoaded(configuracion: result.data));
    } else if (result is Error) {
      emit(ConfiguracionCodigosError((result as Error).message));
    }
  }

  /// Actualiza la configuración de productos
  Future<void> updateConfigProductos({
    required String empresaId,
    String? productoCodigo,
    String? productoSeparador,
    int? productoLongitud,
    bool? productoIncluirSede,
  }) async {
    final currentState = state;
    if (currentState is! ConfiguracionCodigosLoaded) return;

    emit(currentState.copyWith(isLoading: true));

    final result = await _updateConfigProductosUseCase(
      empresaId: empresaId,
      productoCodigo: productoCodigo,
      productoSeparador: productoSeparador,
      productoLongitud: productoLongitud,
      productoIncluirSede: productoIncluirSede,
    );

    if (result is Success<ConfiguracionCodigos>) {
      emit(ConfiguracionCodigosLoaded(configuracion: result.data));
    } else if (result is Error) {
      emit(currentState.copyWith(
        isLoading: false,
        errorMessage: (result as Error).message,
      ));
    }
  }

  /// Actualiza la configuración de variantes
  Future<void> updateConfigVariantes({
    required String empresaId,
    String? varianteCodigo,
    String? varianteSeparador,
    int? varianteLongitud,
  }) async {
    final currentState = state;
    if (currentState is! ConfiguracionCodigosLoaded) return;

    emit(currentState.copyWith(isLoading: true));

    final result = await _updateConfigVariantesUseCase(
      empresaId: empresaId,
      varianteCodigo: varianteCodigo,
      varianteSeparador: varianteSeparador,
      varianteLongitud: varianteLongitud,
    );

    if (result is Success<ConfiguracionCodigos>) {
      emit(ConfiguracionCodigosLoaded(configuracion: result.data));
    } else if (result is Error) {
      emit(currentState.copyWith(
        isLoading: false,
        errorMessage: (result as Error).message,
      ));
    }
  }

  /// Actualiza la configuración de servicios
  Future<void> updateConfigServicios({
    required String empresaId,
    String? servicioCodigo,
    String? servicioSeparador,
    int? servicioLongitud,
    bool? servicioIncluirSede,
  }) async {
    final currentState = state;
    if (currentState is! ConfiguracionCodigosLoaded) return;

    emit(currentState.copyWith(isLoading: true));

    final result = await _updateConfigServiciosUseCase(
      empresaId: empresaId,
      servicioCodigo: servicioCodigo,
      servicioSeparador: servicioSeparador,
      servicioLongitud: servicioLongitud,
      servicioIncluirSede: servicioIncluirSede,
    );

    if (result is Success<ConfiguracionCodigos>) {
      emit(ConfiguracionCodigosLoaded(configuracion: result.data));
    } else if (result is Error) {
      emit(currentState.copyWith(
        isLoading: false,
        errorMessage: (result as Error).message,
      ));
    }
  }

  /// Actualiza la configuración de ventas (Notas de Venta)
  Future<void> updateConfigVentas({
    required String empresaId,
    String? ventaCodigo,
    String? ventaSeparador,
    int? ventaLongitud,
    bool? ventaIncluirSede,
  }) async {
    final currentState = state;
    if (currentState is! ConfiguracionCodigosLoaded) return;

    emit(currentState.copyWith(isLoading: true));

    final result = await _updateConfigVentasUseCase(
      empresaId: empresaId,
      ventaCodigo: ventaCodigo,
      ventaSeparador: ventaSeparador,
      ventaLongitud: ventaLongitud,
      ventaIncluirSede: ventaIncluirSede,
    );

    if (result is Success<ConfiguracionCodigos>) {
      emit(ConfiguracionCodigosLoaded(configuracion: result.data));
    } else if (result is Error) {
      emit(currentState.copyWith(
        isLoading: false,
        errorMessage: (result as Error).message,
      ));
    }
  }

  /// Obtiene una vista previa de un código
  Future<void> previewCodigo({
    required String empresaId,
    required TipoCodigo tipo,
    String? sedeId,
    int? numero,
  }) async {
    final currentState = state;
    if (currentState is! ConfiguracionCodigosLoaded) return;

    emit(currentState.copyWith(isLoading: true));

    final result = await _previewCodigoUseCase(
      empresaId: empresaId,
      tipo: tipo,
      sedeId: sedeId,
      numero: numero,
    );

    if (result is Success<PreviewCodigo>) {
      emit(currentState.copyWith(
        isLoading: false,
        preview: result.data,
      ));
    } else if (result is Error) {
      emit(currentState.copyWith(
        isLoading: false,
        errorMessage: (result as Error).message,
      ));
    }
  }

  /// Sincroniza el contador con el estado real de la BD
  Future<void> sincronizarContador({
    required String empresaId,
    required String tipo,
  }) async {
    final currentState = state;
    if (currentState is! ConfiguracionCodigosLoaded) return;

    emit(currentState.copyWith(isLoading: true));

    final result = await _sincronizarContadorUseCase(
      empresaId: empresaId,
      tipo: tipo,
    );

    if (result is Success<Map<String, dynamic>>) {
      // Recargar la configuración después de sincronizar
      await loadConfiguracion(empresaId);
    } else if (result is Error) {
      emit(currentState.copyWith(
        isLoading: false,
        errorMessage: (result as Error).message,
      ));
    }
  }

  /// Limpia el estado de error
  void clearError() {
    final currentState = state;
    if (currentState is ConfiguracionCodigosLoaded) {
      emit(currentState.copyWith(errorMessage: null));
    }
  }

  /// Limpia la vista previa
  void clearPreview() {
    final currentState = state;
    if (currentState is ConfiguracionCodigosLoaded) {
      emit(currentState.copyWith(clearPreview: true));
    }
  }
}
