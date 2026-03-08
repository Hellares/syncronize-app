import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/aviso_mantenimiento.dart';
import '../../../domain/usecases/get_configuracion_aviso_usecase.dart';
import '../../../domain/usecases/update_configuracion_aviso_usecase.dart';
import 'aviso_configuracion_state.dart';

@injectable
class AvisoConfiguracionCubit extends Cubit<AvisoConfiguracionState> {
  final GetConfiguracionAvisoUseCase _getConfiguracionUseCase;
  final UpdateConfiguracionAvisoUseCase _updateConfiguracionUseCase;

  AvisoConfiguracionCubit(
    this._getConfiguracionUseCase,
    this._updateConfiguracionUseCase,
  ) : super(const AvisoConfiguracionInitial());

  Future<void> loadConfiguracion() async {
    emit(const AvisoConfiguracionLoading());

    final result = await _getConfiguracionUseCase();

    if (isClosed) return;

    if (result is Success<ConfiguracionAvisoMantenimiento>) {
      emit(AvisoConfiguracionLoaded(result.data));
    } else if (result is Error<ConfiguracionAvisoMantenimiento>) {
      emit(AvisoConfiguracionError(result.message));
    }
  }

  Future<bool> guardar({
    Map<String, int>? intervalos,
    int? diasAnticipacion,
    bool? habilitado,
  }) async {
    emit(const AvisoConfiguracionSaving());

    final result = await _updateConfiguracionUseCase(
      intervalos: intervalos,
      diasAnticipacion: diasAnticipacion,
      habilitado: habilitado,
    );

    if (isClosed) return false;

    if (result is Success<ConfiguracionAvisoMantenimiento>) {
      emit(AvisoConfiguracionSaved(result.data));
      return true;
    } else if (result is Error<ConfiguracionAvisoMantenimiento>) {
      emit(AvisoConfiguracionError(result.message));
      return false;
    }
    return false;
  }
}
