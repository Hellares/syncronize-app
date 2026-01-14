import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/usecases/get_marcas_empresa_usecase.dart';
import '../../../domain/usecases/activar_marca_usecase.dart';
import '../../../domain/usecases/desactivar_marca_usecase.dart';
import 'marcas_empresa_state.dart';

@injectable
class MarcasEmpresaCubit extends Cubit<MarcasEmpresaState> {
  final GetMarcasEmpresaUseCase _getMarcasEmpresaUseCase;
  final ActivarMarcaUseCase _activarMarcaUseCase;
  final DesactivarMarcaUseCase _desactivarMarcaUseCase;

  MarcasEmpresaCubit(
    this._getMarcasEmpresaUseCase,
    this._activarMarcaUseCase,
    this._desactivarMarcaUseCase,
  ) : super(const MarcasEmpresaInitial());

  Future<void> loadMarcas(String empresaId) async {
    emit(const MarcasEmpresaLoading());

    final result = await _getMarcasEmpresaUseCase(empresaId);

    if (result is Success) {
      final success = result as Success;
      emit(MarcasEmpresaLoaded(success.data));
    } else if (result is Error) {
      final error = result as Error;
      emit(MarcasEmpresaError(error.message));
    }
  }

  Future<Resource<void>> activarMarca({
    required String empresaId,
    String? marcaMaestraId,
    String? nombrePersonalizado,
    String? descripcionPersonalizada,
    String? nombreLocal,
    int? orden,
  }) async {
    final result = await _activarMarcaUseCase(
      empresaId: empresaId,
      marcaMaestraId: marcaMaestraId,
      nombrePersonalizado: nombrePersonalizado,
      descripcionPersonalizada: descripcionPersonalizada,
      nombreLocal: nombreLocal,
      orden: orden,
    );

    // Recargar lista de marcas si fue exitoso
    if (result is Success) {
      await loadMarcas(empresaId);
      return Success(null);
    } else if (result is Error) {
      final error = result as Error;
      return Error(error.message);
    }

    return Error('Error desconocido');
  }

  Future<Resource<void>> desactivarMarca({
    required String empresaId,
    required String empresaMarcaId,
  }) async {
    final result = await _desactivarMarcaUseCase(
      empresaId: empresaId,
      empresaMarcaId: empresaMarcaId,
    );

    // Recargar lista de marcas si fue exitoso
    if (result is Success) {
      await loadMarcas(empresaId);
    }

    return result;
  }

  void reload(String empresaId) {
    loadMarcas(empresaId);
  }

  void clear() {
    emit(const MarcasEmpresaInitial());
  }
}
