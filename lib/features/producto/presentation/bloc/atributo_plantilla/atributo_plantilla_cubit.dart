import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:syncronize/core/utils/resource.dart';
import 'package:syncronize/features/producto/domain/entities/atributo_plantilla.dart';
import '../../../domain/repositories/plantilla_repository.dart';
import 'atributo_plantilla_state.dart';

@injectable
class AtributoPlantillaCubit extends Cubit<AtributoPlantillaState> {
  final PlantillaRepository _repository;

  AtributoPlantillaCubit(this._repository) : super(AtributoPlantillaInitial());

  /// Cargar todas las plantillas de la empresa
  Future<void> loadPlantillas({String? categoriaId}) async {
    try {
      emit(AtributoPlantillaLoading());

      // Cargar plantillas y límites en paralelo
      final results = await Future.wait([
        _repository.getPlantillas(categoriaId: categoriaId),
        _repository.getLimitsInfo(),
      ]);

      final plantillasResult = results[0];
      final limitsResult = results[1];

      if (plantillasResult is Success<List<AtributoPlantilla>>) {
        emit(AtributoPlantillaLoaded(
          plantillas: plantillasResult.data,
          limitsInfo: limitsResult is Success<PlanLimitsInfo> ? limitsResult.data : null,
        ));
      } else if (plantillasResult is Error<List<AtributoPlantilla>>) {
        emit(AtributoPlantillaError(plantillasResult.message));
      }
    } catch (e) {
      emit(AtributoPlantillaError(_getErrorMessage(e)));
    }
  }

  /// Obtener una plantilla específica por ID
  Future<void> getPlantilla(String plantillaId) async {
    try {
      emit(AtributoPlantillaLoading());

      final result = await _repository.getPlantilla(plantillaId: plantillaId);

      if (result is Success<AtributoPlantilla>) {
        emit(AtributoPlantillaDetail(plantilla: result.data));
      } else if (result is Error<AtributoPlantilla>) {
        emit(AtributoPlantillaError(result.message));
      }
    } catch (e) {
      emit(AtributoPlantillaError(_getErrorMessage(e)));
    }
  }

  /// Crear una nueva plantilla
  Future<void> crearPlantilla({
    required String nombre,
    String? descripcion,
    String? icono,
    String? categoriaId,
    int? orden,
    required List<PlantillaAtributoCreate> atributos,
  }) async {
    try {

      emit(const AtributoPlantillaSubmitting(message: 'Creando plantilla...'));

      final result = await _repository.crearPlantilla(
        nombre: nombre,
        descripcion: descripcion,
        icono: icono,
        categoriaId: categoriaId,
        orden: orden,
        atributos: atributos,
      );

      if (result is Success<AtributoPlantilla>) {
        emit(AtributoPlantillaSuccess(
          message: 'Plantilla "$nombre" creada exitosamente',
          plantilla: result.data,
        ));
        // Recargar lista
        await loadPlantillas();
      } else if (result is Error<AtributoPlantilla>) {
        emit(AtributoPlantillaError(result.message));
      }
    } catch (e) {
      emit(AtributoPlantillaError(_getErrorMessage(e)));
    }
  }

  /// Actualizar una plantilla existente
  Future<void> actualizarPlantilla({
    required String plantillaId,
    String? nombre,
    String? descripcion,
    String? icono,
    String? categoriaId,
    int? orden,
    List<PlantillaAtributoCreate>? atributos,
  }) async {
    try {
      emit(const AtributoPlantillaSubmitting(message: 'Actualizando plantilla...'));

      final result = await _repository.actualizarPlantilla(
        plantillaId: plantillaId,
        nombre: nombre,
        descripcion: descripcion,
        icono: icono,
        categoriaId: categoriaId,
        orden: orden,
        atributos: atributos,
      );

      if (result is Success<AtributoPlantilla>) {
        emit(AtributoPlantillaSuccess(
          message: 'Plantilla actualizada exitosamente',
          plantilla: result.data,
        ));
        // Recargar lista
        await loadPlantillas();
      } else if (result is Error<AtributoPlantilla>) {
        emit(AtributoPlantillaError(result.message));
      }
    } catch (e) {
      emit(AtributoPlantillaError(_getErrorMessage(e)));
    }
  }

  /// Eliminar una plantilla
  Future<void> eliminarPlantilla(String plantillaId, String nombrePlantilla) async {
    try {
      emit(const AtributoPlantillaSubmitting(message: 'Eliminando plantilla...'));

      final result = await _repository.eliminarPlantilla(plantillaId: plantillaId);

      if (result is Success<void>) {
        emit(AtributoPlantillaSuccess(
          message: 'Plantilla "$nombrePlantilla" eliminada',
        ));
        // Recargar lista
        await loadPlantillas();
      } else if (result is Error<void>) {
        emit(AtributoPlantillaError(result.message));
      }
    } catch (e) {
      emit(AtributoPlantillaError(_getErrorMessage(e)));
    }
  }

  /// Aplicar una plantilla a un producto o variante
  /// Crea la estructura de atributos vacía para que el usuario los llene
  Future<void> aplicarPlantilla({
    required String plantillaId,
    required String plantillaNombre,
    String? productoId,
    String? varianteId,
  }) async {
    try {
      emit(AtributoPlantillaAplicando(plantillaNombre: plantillaNombre));

      final result = await _repository.aplicarPlantilla(
        plantillaId: plantillaId,
        productoId: productoId,
        varianteId: varianteId,
      );

      if (result is Success<AplicarPlantillaResult>) {
        final data = result.data;
        emit(AtributoPlantillaAplicada(
          message: 'Plantilla "$plantillaNombre" aplicada exitosamente. '
              'Se crearon ${data.atributosCreados} campos de atributos.',
          atributosCreados: data.atributosCreados,
        ));
      } else if (result is Error<AplicarPlantillaResult>) {
        emit(AtributoPlantillaError(result.message));
      }
    } catch (e) {
      emit(AtributoPlantillaError(_getErrorMessage(e)));
    }
  }

  /// Obtener información de límites del plan
  Future<void> loadLimitsInfo() async {
    try {
      final result = await _repository.getLimitsInfo();

      if (result is Success<PlanLimitsInfo> && state is AtributoPlantillaLoaded) {
        emit((state as AtributoPlantillaLoaded).copyWith(
          limitsInfo: result.data,
        ));
      }
    } catch (e) {
      // No emitir error, solo no actualizar los límites
    }
  }

  /// Resetear al estado inicial
  void reset() {
    emit(AtributoPlantillaInitial());
  }

  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString();
    if (errorStr.contains('Exception:')) {
      return errorStr.replaceFirst('Exception:', '').trim();
    }
    return 'Error inesperado: $errorStr';
  }
}
