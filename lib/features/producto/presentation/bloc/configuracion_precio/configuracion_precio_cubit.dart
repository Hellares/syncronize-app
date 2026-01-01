import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../data/models/configuracion_precio_model.dart';
import '../../../domain/entities/configuracion_precio.dart';
import '../../../domain/repositories/configuracion_precio_repository.dart';
import 'configuracion_precio_state.dart';

@injectable
class ConfiguracionPrecioCubit extends Cubit<ConfiguracionPrecioState> {
  final ConfiguracionPrecioRepository _repository;

  ConfiguracionPrecioCubit(this._repository)
      : super(const ConfiguracionPrecioInitial());

  /// Carga todas las configuraciones de precios
  Future<void> loadConfiguraciones() async {
    emit(const ConfiguracionPrecioLoading());

    final result = await _repository.obtenerTodas();

    if (result is Success<List<ConfiguracionPrecio>>) {
      emit(ConfiguracionPrecioLoaded(configuraciones: result.data));
    } else if (result is Error) {
      emit(ConfiguracionPrecioError((result as Error).message));
    }
  }

  /// Crea una nueva configuración
  Future<void> crear(ConfiguracionPrecioDto dto) async {
    final currentState = state;
    if (currentState is! ConfiguracionPrecioLoaded) return;

    emit(currentState.copyWith(isLoading: true));

    final result = await _repository.crear(dto);

    if (result is Success<ConfiguracionPrecio>) {
      final updatedList = [...currentState.configuraciones, result.data];
      emit(ConfiguracionPrecioLoaded(configuraciones: updatedList));
    } else if (result is Error) {
      emit(currentState.copyWith(
        isLoading: false,
        errorMessage: (result as Error).message,
      ));
    }
  }

  /// Actualiza una configuración
  Future<void> actualizar(
    String configuracionId,
    ConfiguracionPrecioDto dto,
  ) async {
    final currentState = state;
    if (currentState is! ConfiguracionPrecioLoaded) return;

    emit(currentState.copyWith(isLoading: true));

    final result = await _repository.actualizar(configuracionId, dto);

    if (result is Success<ConfiguracionPrecio>) {
      final updatedList = currentState.configuraciones.map((config) {
        return config.id == configuracionId ? result.data : config;
      }).toList();
      emit(ConfiguracionPrecioLoaded(configuraciones: updatedList));
    } else if (result is Error) {
      emit(currentState.copyWith(
        isLoading: false,
        errorMessage: (result as Error).message,
      ));
    }
  }

  /// Elimina una configuración
  Future<void> eliminar(String configuracionId) async {
    final currentState = state;
    if (currentState is! ConfiguracionPrecioLoaded) return;

    emit(currentState.copyWith(isLoading: true));

    final result = await _repository.eliminar(configuracionId);

    if (result is Success) {
      final updatedList = currentState.configuraciones
          .where((config) => config.id != configuracionId)
          .toList();
      emit(ConfiguracionPrecioLoaded(configuraciones: updatedList));
    } else if (result is Error) {
      emit(currentState.copyWith(
        isLoading: false,
        errorMessage: result.message,
      ));
    }
  }

  /// Limpia el estado de error
  void clearError() {
    final currentState = state;
    if (currentState is ConfiguracionPrecioLoaded) {
      emit(currentState.copyWith(errorMessage: null));
    }
  }
}
