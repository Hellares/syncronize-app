import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/usecases/get_reglas_compatibilidad_usecase.dart';
import '../../../domain/usecases/crear_regla_compatibilidad_usecase.dart';
import '../../../domain/usecases/actualizar_regla_compatibilidad_usecase.dart';
import '../../../domain/usecases/eliminar_regla_compatibilidad_usecase.dart';
import '../../../domain/usecases/validar_compatibilidad_usecase.dart';
import 'compatibilidad_state.dart';

@injectable
class CompatibilidadCubit extends Cubit<CompatibilidadState> {
  final GetReglasCompatibilidadUseCase _getReglasUseCase;
  final CrearReglaCompatibilidadUseCase _crearReglaUseCase;
  final ActualizarReglaCompatibilidadUseCase _actualizarReglaUseCase;
  final EliminarReglaCompatibilidadUseCase _eliminarReglaUseCase;
  final ValidarCompatibilidadUseCase _validarUseCase;

  CompatibilidadCubit(
    this._getReglasUseCase,
    this._crearReglaUseCase,
    this._actualizarReglaUseCase,
    this._eliminarReglaUseCase,
    this._validarUseCase,
  ) : super(const CompatibilidadInitial());

  /// Cargar reglas de compatibilidad
  Future<void> loadReglas({String? categoriaId}) async {
    try {
      emit(const CompatibilidadLoading());

      final result = await _getReglasUseCase(categoriaId: categoriaId);

      if (isClosed) return;

      if (result is Success) {
        emit(CompatibilidadReglasLoaded((result as Success).data));
      } else if (result is Error) {
        emit(CompatibilidadError((result as Error).message));
      }
    } catch (e) {
      if (isClosed) return;
      emit(CompatibilidadError(_getErrorMessage(e)));
    }
  }

  /// Crear una nueva regla
  Future<void> crearRegla(Map<String, dynamic> data) async {
    try {
      emit(const CompatibilidadLoading());

      final result = await _crearReglaUseCase(data);

      if (isClosed) return;

      if (result is Success) {
        // Recargar la lista
        final listResult = await _getReglasUseCase();
        if (isClosed) return;

        if (listResult is Success) {
          emit(CompatibilidadOperationSuccess(
            'Regla creada exitosamente',
            (listResult as Success).data,
          ));
        }
      } else if (result is Error) {
        emit(CompatibilidadError((result as Error).message));
      }
    } catch (e) {
      if (isClosed) return;
      emit(CompatibilidadError(_getErrorMessage(e)));
    }
  }

  /// Actualizar una regla existente
  Future<void> actualizarRegla(String id, Map<String, dynamic> data) async {
    try {
      emit(const CompatibilidadLoading());

      final result = await _actualizarReglaUseCase(id, data);

      if (isClosed) return;

      if (result is Success) {
        // Recargar la lista
        final listResult = await _getReglasUseCase();
        if (isClosed) return;

        if (listResult is Success) {
          emit(CompatibilidadOperationSuccess(
            'Regla actualizada exitosamente',
            (listResult as Success).data,
          ));
        }
      } else if (result is Error) {
        emit(CompatibilidadError((result as Error).message));
      }
    } catch (e) {
      if (isClosed) return;
      emit(CompatibilidadError(_getErrorMessage(e)));
    }
  }

  /// Eliminar una regla
  Future<void> eliminarRegla(String id) async {
    try {
      emit(const CompatibilidadLoading());

      final result = await _eliminarReglaUseCase(id);

      if (isClosed) return;

      if (result is Success) {
        // Recargar la lista
        final listResult = await _getReglasUseCase();
        if (isClosed) return;

        if (listResult is Success) {
          emit(CompatibilidadOperationSuccess(
            'Regla eliminada exitosamente',
            (listResult as Success).data,
          ));
        }
      } else if (result is Error) {
        emit(CompatibilidadError((result).message));
      }
    } catch (e) {
      if (isClosed) return;
      emit(CompatibilidadError(_getErrorMessage(e)));
    }
  }

  /// Validar compatibilidad entre productos
  Future<void> validarCompatibilidad(
      List<Map<String, String?>> productos) async {
    try {
      emit(const CompatibilidadLoading());

      final result = await _validarUseCase(productos);

      if (isClosed) return;

      if (result is Success) {
        emit(CompatibilidadValidacionResult((result as Success).data));
      } else if (result is Error) {
        emit(CompatibilidadError((result as Error).message));
      }
    } catch (e) {
      if (isClosed) return;
      emit(CompatibilidadError(_getErrorMessage(e)));
    }
  }

  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString();
    if (errorStr.contains('Exception:')) {
      return errorStr.replaceFirst('Exception:', '').trim();
    }
    return 'Error inesperado: $errorStr';
  }
}
