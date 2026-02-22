import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/cotizacion.dart';
import '../../../domain/usecases/crear_cotizacion_usecase.dart';
import '../../../domain/usecases/actualizar_cotizacion_usecase.dart';
import '../../../domain/usecases/cambiar_estado_cotizacion_usecase.dart';
import '../../../domain/usecases/duplicar_cotizacion_usecase.dart';
import '../../../domain/usecases/eliminar_cotizacion_usecase.dart';
import '../../../domain/usecases/validar_compatibilidad_cotizacion_usecase.dart';
import 'cotizacion_form_state.dart';

@injectable
class CotizacionFormCubit extends Cubit<CotizacionFormState> {
  final CrearCotizacionUseCase _crearCotizacionUseCase;
  final ActualizarCotizacionUseCase _actualizarCotizacionUseCase;
  final CambiarEstadoCotizacionUseCase _cambiarEstadoUseCase;
  final DuplicarCotizacionUseCase _duplicarCotizacionUseCase;
  final EliminarCotizacionUseCase _eliminarCotizacionUseCase;
  final ValidarCompatibilidadCotizacionUseCase _validarCompatibilidadUseCase;

  CotizacionFormCubit({
    required CrearCotizacionUseCase crearCotizacionUseCase,
    required ActualizarCotizacionUseCase actualizarCotizacionUseCase,
    required CambiarEstadoCotizacionUseCase cambiarEstadoUseCase,
    required DuplicarCotizacionUseCase duplicarCotizacionUseCase,
    required EliminarCotizacionUseCase eliminarCotizacionUseCase,
    required ValidarCompatibilidadCotizacionUseCase
        validarCompatibilidadUseCase,
  })  : _crearCotizacionUseCase = crearCotizacionUseCase,
        _actualizarCotizacionUseCase = actualizarCotizacionUseCase,
        _cambiarEstadoUseCase = cambiarEstadoUseCase,
        _duplicarCotizacionUseCase = duplicarCotizacionUseCase,
        _eliminarCotizacionUseCase = eliminarCotizacionUseCase,
        _validarCompatibilidadUseCase = validarCompatibilidadUseCase,
        super(const CotizacionFormInitial());

  /// Crear cotizacion
  Future<void> crearCotizacion(Map<String, dynamic> data) async {
    emit(const CotizacionFormLoading());

    final result = await _crearCotizacionUseCase(data: data);
    if (isClosed) return;

    if (result is Success<Cotizacion>) {
      emit(CotizacionFormSuccess(
        cotizacion: result.data,
        message: 'Cotizacion creada exitosamente',
      ));
    } else if (result is Error<Cotizacion>) {
      emit(CotizacionFormError(result.message));
    }
  }

  /// Actualizar cotizacion
  Future<void> actualizarCotizacion(
    String id,
    Map<String, dynamic> data,
  ) async {
    emit(const CotizacionFormLoading());

    final result = await _actualizarCotizacionUseCase(
      cotizacionId: id,
      data: data,
    );
    if (isClosed) return;

    if (result is Success<Cotizacion>) {
      emit(CotizacionFormSuccess(
        cotizacion: result.data,
        message: 'Cotizacion actualizada exitosamente',
      ));
    } else if (result is Error<Cotizacion>) {
      emit(CotizacionFormError(result.message));
    }
  }

  /// Cambiar estado de cotizacion
  Future<void> cambiarEstado(
    String id,
    EstadoCotizacion nuevoEstado, {
    String? comprobanteId,
  }) async {
    emit(const CotizacionFormLoading());

    final data = <String, dynamic>{
      'estado': nuevoEstado.apiValue,
    };
    if (comprobanteId != null) data['comprobanteId'] = comprobanteId;

    final result = await _cambiarEstadoUseCase(
      cotizacionId: id,
      data: data,
    );
    if (isClosed) return;

    if (result is Success<Cotizacion>) {
      emit(CotizacionEstadoUpdated(result.data));
    } else if (result is Error<Cotizacion>) {
      emit(CotizacionFormError(result.message));
    }
  }

  /// Duplicar cotizacion
  Future<void> duplicarCotizacion(String id) async {
    emit(const CotizacionFormLoading());

    final result = await _duplicarCotizacionUseCase(cotizacionId: id);
    if (isClosed) return;

    if (result is Success<Cotizacion>) {
      emit(CotizacionFormSuccess(
        cotizacion: result.data,
        message: 'Cotizacion duplicada exitosamente',
      ));
    } else if (result is Error<Cotizacion>) {
      emit(CotizacionFormError(result.message));
    }
  }

  /// Eliminar cotizacion
  Future<void> eliminarCotizacion(String id) async {
    emit(const CotizacionFormLoading());

    final result = await _eliminarCotizacionUseCase(cotizacionId: id);
    if (isClosed) return;

    if (result is Success<void>) {
      emit(const CotizacionFormDeleted(
        message: 'Cotizacion eliminada exitosamente',
      ));
    } else if (result is Error<void>) {
      emit(CotizacionFormError(result.message));
    }
  }

  /// Validar compatibilidad de items
  Future<void> validarCompatibilidad(
    List<Map<String, dynamic>> detalles,
  ) async {
    final result = await _validarCompatibilidadUseCase(detalles: detalles);
    if (isClosed) return;

    if (result is Success<Map<String, dynamic>>) {
      final data = result.data;
      final compatible = data['compatible'] as bool? ?? true;
      final conflictos = data['conflictos'] != null
          ? (data['conflictos'] as List)
              .map((e) => e as Map<String, dynamic>)
              .toList()
          : <Map<String, dynamic>>[];

      emit(CotizacionCompatibilidadResult(
        compatible: compatible,
        conflictos: conflictos,
      ));
    } else if (result is Error<Map<String, dynamic>>) {
      emit(CotizacionFormError(result.message));
    }
  }

  /// Reset al estado inicial
  void reset() {
    emit(const CotizacionFormInitial());
  }
}
