import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../data/models/precio_nivel_model.dart';
import '../../../domain/entities/precio_nivel.dart';
import '../../../domain/repositories/precio_nivel_repository.dart';
import 'precio_nivel_state.dart';

@injectable
class PrecioNivelCubit extends Cubit<PrecioNivelState> {
  final PrecioNivelRepository _repository;

  PrecioNivelCubit(this._repository) : super(const PrecioNivelInitial());

  /// Inicializa con niveles vacíos
  void initialize() {
    emit(const PrecioNivelLoaded(niveles: []));
  }

  /// Carga los niveles de precio de un producto
  Future<void> loadNivelesProducto(String productoId) async {
    emit(const PrecioNivelLoading());

    final result = await _repository.getPreciosNivelProducto(
      productoId: productoId,
    );

    if (result is Success<List<PrecioNivel>>) {
      emit(PrecioNivelLoaded(niveles: result.data));
    } else if (result is Error) {
      emit(PrecioNivelError((result as Error).message));
    }
  }

  /// Carga los niveles de precio de una variante
  Future<void> loadNivelesVariante(String varianteId) async {
    emit(const PrecioNivelLoading());

    final result = await _repository.getPreciosNivelVariante(
      varianteId: varianteId,
    );

    if (result is Success<List<PrecioNivel>>) {
      emit(PrecioNivelLoaded(niveles: result.data));
    } else if (result is Error) {
      emit(PrecioNivelError((result as Error).message));
    }
  }

  /// Crea un nivel de precio para un producto
  Future<void> crearNivelProducto({
    required String productoId,
    required PrecioNivelDto dto,
  }) async {
    final currentState = state;
    if (currentState is! PrecioNivelLoaded) return;

    // Marcar como cargando
    emit(currentState.copyWith(isLoading: true));

    final result = await _repository.crearPrecioNivelProducto(
      productoId: productoId,
      dto: dto,
    );

    if (result is Success<PrecioNivel>) {
      // Agregar el nuevo nivel a la lista
      final updatedNiveles = [...currentState.niveles, result.data];
      emit(PrecioNivelLoaded(niveles: updatedNiveles));
    } else if (result is Error) {
      emit(currentState.copyWith(
        isLoading: false,
        errorMessage: (result as Error).message,
      ));
    }
  }

  /// Crea un nivel de precio para una variante
  Future<void> crearNivelVariante({
    required String varianteId,
    required PrecioNivelDto dto,
  }) async {
    final currentState = state;
    if (currentState is! PrecioNivelLoaded) return;

    emit(currentState.copyWith(isLoading: true));

    final result = await _repository.crearPrecioNivelVariante(
      varianteId: varianteId,
      dto: dto,
    );

    if (result is Success<PrecioNivel>) {
      final updatedNiveles = [...currentState.niveles, result.data];
      emit(PrecioNivelLoaded(niveles: updatedNiveles));
    } else if (result is Error) {
      emit(currentState.copyWith(
        isLoading: false,
        errorMessage: (result as Error).message,
      ));
    }
  }

  /// Actualiza un nivel de precio
  Future<void> actualizarNivel({
    required String nivelId,
    required PrecioNivelDto dto,
  }) async {
    final currentState = state;
    if (currentState is! PrecioNivelLoaded) return;

    emit(currentState.copyWith(isLoading: true));

    final result = await _repository.actualizarPrecioNivel(
      nivelId: nivelId,
      data: dto.toJson(),
    );

    if (result is Success<PrecioNivel>) {
      // Reemplazar el nivel actualizado en la lista
      final updatedNiveles = currentState.niveles.map((nivel) {
        return nivel.id == nivelId ? result.data : nivel;
      }).toList();
      emit(PrecioNivelLoaded(niveles: updatedNiveles));
    } else if (result is Error) {
      emit(currentState.copyWith(
        isLoading: false,
        errorMessage: (result as Error).message,
      ));
    }
  }

  /// Elimina un nivel de precio
  Future<void> eliminarNivel(String nivelId) async {
    final currentState = state;
    if (currentState is! PrecioNivelLoaded) return;

    emit(currentState.copyWith(isLoading: true));

    final result = await _repository.eliminarPrecioNivel(nivelId: nivelId);

    if (result is Success) {
      // Eliminar el nivel de la lista
      final updatedNiveles = currentState.niveles
          .where((nivel) => nivel.id != nivelId)
          .toList();
      emit(PrecioNivelLoaded(niveles: updatedNiveles));
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
    if (currentState is PrecioNivelLoaded) {
      emit(currentState.copyWith(errorMessage: null));
    }
  }

  /// Limpia todos los niveles
  void clear() {
    emit(const PrecioNivelLoaded(niveles: []));
  }
}
