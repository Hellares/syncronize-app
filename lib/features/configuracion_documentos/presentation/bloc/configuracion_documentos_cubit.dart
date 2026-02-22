import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/usecases/get_configuracion_completa_usecase.dart';
import '../../domain/usecases/get_configuracion_documentos_usecase.dart';
import '../../domain/usecases/update_configuracion_documentos_usecase.dart';
import '../../domain/usecases/get_plantillas_usecase.dart';
import '../../domain/usecases/get_plantilla_by_tipo_usecase.dart';
import '../../domain/usecases/update_plantilla_usecase.dart';
import 'configuracion_documentos_state.dart';

@injectable
class ConfiguracionDocumentosCubit
    extends Cubit<ConfiguracionDocumentosState> {
  final GetConfiguracionDocumentosUseCase _getConfiguracionUseCase;
  final UpdateConfiguracionDocumentosUseCase _updateConfiguracionUseCase;
  final GetPlantillasUseCase _getPlantillasUseCase;
  final GetPlantillaByTipoUseCase _getPlantillaByTipoUseCase;
  final UpdatePlantillaUseCase _updatePlantillaUseCase;
  final GetConfiguracionCompletaUseCase _getCompletaUseCase;

  ConfiguracionDocumentosCubit({
    required GetConfiguracionDocumentosUseCase getConfiguracionUseCase,
    required UpdateConfiguracionDocumentosUseCase updateConfiguracionUseCase,
    required GetPlantillasUseCase getPlantillasUseCase,
    required GetPlantillaByTipoUseCase getPlantillaByTipoUseCase,
    required UpdatePlantillaUseCase updatePlantillaUseCase,
    required GetConfiguracionCompletaUseCase getCompletaUseCase,
  })  : _getConfiguracionUseCase = getConfiguracionUseCase,
        _updateConfiguracionUseCase = updateConfiguracionUseCase,
        _getPlantillasUseCase = getPlantillasUseCase,
        _getPlantillaByTipoUseCase = getPlantillaByTipoUseCase,
        _updatePlantillaUseCase = updatePlantillaUseCase,
        _getCompletaUseCase = getCompletaUseCase,
        super(const ConfiguracionDocumentosInitial());

  /// Cargar configuracion global + lista de plantillas
  Future<void> cargarConfiguracion() async {
    emit(const ConfiguracionDocumentosLoading());

    final configResult = await _getConfiguracionUseCase();
    if (isClosed) return;

    if (configResult is Error) {
      emit(ConfiguracionDocumentosError(
        (configResult as Error).message,
      ));
      return;
    }

    final plantillasResult = await _getPlantillasUseCase();
    if (isClosed) return;

    if (plantillasResult is Error) {
      emit(ConfiguracionDocumentosError(
        (plantillasResult as Error).message,
      ));
      return;
    }

    emit(ConfiguracionDocumentosLoaded(
      configuracion: (configResult as Success).data,
      plantillas: (plantillasResult as Success).data,
    ));
  }

  /// Cargar configuracion completa para un tipo de documento (para PDF)
  Future<void> cargarCompleta(String tipo, {String? formato, String? sedeId}) async {
    emit(const ConfiguracionDocumentosLoading());

    final result = await _getCompletaUseCase(tipo: tipo, formato: formato, sedeId: sedeId);
    if (isClosed) return;

    if (result is Success) {
      emit(ConfiguracionDocumentosCompletaLoaded(
        completa: (result as Success).data,
      ));
    } else if (result is Error) {
      emit(ConfiguracionDocumentosError((result as Error).message));
    }
  }

  /// Cargar una plantilla por tipo y formato (crea con defaults si no existe)
  Future<void> cargarPlantilla(String tipo, {String? formato}) async {
    final result = await _getPlantillaByTipoUseCase(tipo: tipo, formato: formato);
    if (isClosed) return;

    if (result is Success) {
      emit(PlantillaCargada(plantilla: (result as Success).data));
    } else if (result is Error) {
      emit(ConfiguracionDocumentosError((result as Error).message));
    }
  }

  /// Actualizar configuracion global
  Future<void> actualizarConfiguracion(Map<String, dynamic> data) async {
    emit(const ConfiguracionDocumentosLoading());

    final result = await _updateConfiguracionUseCase(data: data);
    if (isClosed) return;

    if (result is Success) {
      emit(ConfiguracionDocumentosUpdated(
        configuracion: (result as Success).data,
      ));
    } else if (result is Error) {
      emit(ConfiguracionDocumentosError((result as Error).message));
    }
  }

  /// Actualizar plantilla por tipo
  Future<void> actualizarPlantilla(
    String tipo,
    Map<String, dynamic> data,
  ) async {
    emit(const ConfiguracionDocumentosLoading());

    final result = await _updatePlantillaUseCase(tipo: tipo, data: data);
    if (isClosed) return;

    if (result is Success) {
      emit(PlantillaDocumentoUpdated(
        plantilla: (result as Success).data,
      ));
    } else if (result is Error) {
      emit(ConfiguracionDocumentosError((result as Error).message));
    }
  }
}
