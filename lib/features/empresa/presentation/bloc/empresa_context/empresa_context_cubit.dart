import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/storage/local_storage_service.dart';
import '../../../../../core/constants/storage_constants.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/empresa_context.dart';
import '../../../domain/usecases/get_empresa_context_usecase.dart';
import 'empresa_context_state.dart';

@injectable
class EmpresaContextCubit extends Cubit<EmpresaContextState> {
  final GetEmpresaContextUseCase _getEmpresaContextUseCase;
  final LocalStorageService _localStorage;

  EmpresaContextCubit(
    this._getEmpresaContextUseCase,
    this._localStorage,
  ) : super(const EmpresaContextInitial());

  /// Carga el contexto de la empresa actualmente seleccionada
  Future<void> loadEmpresaContext() async {

    // Obtener el ID de la empresa seleccionada desde el storage
    final empresaId = _localStorage.getString(StorageConstants.tenantId);

    if (empresaId == null || empresaId.isEmpty) {
      emit(const EmpresaContextError(
        'No hay empresa seleccionada',
        errorCode: 'NO_EMPRESA_SELECTED',
      ));
      return;
    }

    await loadEmpresaContextById(empresaId);
  }

  /// Carga el contexto de una empresa específica
  Future<void> loadEmpresaContextById(String empresaId) async {
    emit(const EmpresaContextLoading());

    final result = await _getEmpresaContextUseCase(empresaId);

    if (result is Success<EmpresaContext>) {
      // Guardar el tenantId en localStorage para que el AuthInterceptor lo use
      await _localStorage.setString(StorageConstants.tenantId, empresaId);
      await _localStorage.setString(
        StorageConstants.tenantName,
        result.data.empresa.nombre,
      );

      // Debug: Verificar que se guardó correctamente
      // final savedTenantId = _localStorage.getString(StorageConstants.tenantId);
      // print('🔑 TenantId guardado en localStorage: $savedTenantId');

      emit(EmpresaContextLoaded(result.data));
    } else if (result is Error<EmpresaContext>) {
      emit(EmpresaContextError(result.message, errorCode: result.errorCode));
    }
  }

  /// Recarga el contexto de la empresa actual
  Future<void> reloadContext() async {
    if (state is EmpresaContextLoaded) {
      final currentContext = (state as EmpresaContextLoaded).context;
      await loadEmpresaContextById(currentContext.empresa.id);
    } else {
      await loadEmpresaContext();
    }
  }

  /// Limpia el estado del contexto
  void clearContext() {
    emit(const EmpresaContextInitial());
  }
}
