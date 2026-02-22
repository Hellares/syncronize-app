import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/configuracion_empresa.dart';
import '../../../domain/repositories/empresa_repository.dart';
import 'configuracion_empresa_state.dart';

@injectable
class ConfiguracionEmpresaCubit extends Cubit<ConfiguracionEmpresaState> {
  final EmpresaRepository _empresaRepository;

  ConfiguracionEmpresaCubit(this._empresaRepository)
      : super(const ConfiguracionEmpresaInitial());

  /// Carga la configuración de la empresa
  Future<void> cargar(String empresaId) async {
    emit(const ConfiguracionEmpresaLoading());

    final result = await _empresaRepository.getConfiguracion(empresaId);

    if (result is Success<ConfiguracionEmpresa>) {
      emit(ConfiguracionEmpresaLoaded(result.data));
    } else if (result is Error<ConfiguracionEmpresa>) {
      emit(ConfiguracionEmpresaError(
        result.message,
        errorCode: result.errorCode,
      ));
    }
  }

  /// Actualiza la configuración de la empresa
  Future<void> actualizar(
    String empresaId,
    ConfiguracionEmpresa configuracion,
  ) async {
    emit(const ConfiguracionEmpresaLoading());

    final result = await _empresaRepository.updateConfiguracion(
      empresaId,
      configuracion,
    );

    if (result is Success<ConfiguracionEmpresa>) {
      emit(ConfiguracionEmpresaLoaded(result.data));
    } else if (result is Error<ConfiguracionEmpresa>) {
      emit(ConfiguracionEmpresaError(
        result.message,
        errorCode: result.errorCode,
      ));
    }
  }
}
