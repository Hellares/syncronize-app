import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/usecases/get_categorias_empresa_usecase.dart';
import '../../../domain/usecases/activar_categoria_usecase.dart';
import '../../../domain/usecases/desactivar_categoria_usecase.dart';
import 'categorias_empresa_state.dart';

@injectable
class CategoriasEmpresaCubit extends Cubit<CategoriasEmpresaState> {
  final GetCategoriasEmpresaUseCase _getCategoriasEmpresaUseCase;
  final ActivarCategoriaUseCase _activarCategoriaUseCase;
  final DesactivarCategoriaUseCase _desactivarCategoriaUseCase;

  CategoriasEmpresaCubit(
    this._getCategoriasEmpresaUseCase,
    this._activarCategoriaUseCase,
    this._desactivarCategoriaUseCase,
  ) : super(const CategoriasEmpresaInitial());

  Future<void> loadCategorias(String empresaId) async {
    emit(const CategoriasEmpresaLoading());

    final result = await _getCategoriasEmpresaUseCase(empresaId);

    if (result is Success) {
      final success = result as Success;
      emit(CategoriasEmpresaLoaded(success.data));
    } else if (result is Error) {
      final error = result as Error;
      emit(CategoriasEmpresaError(error.message));
    }
  }

  Future<Resource<void>> activarCategoria({
    required String empresaId,
    String? categoriaMaestraId,
    String? nombrePersonalizado,
    String? descripcionPersonalizada,
    String? nombreLocal,
    int? orden,
  }) async {
    final result = await _activarCategoriaUseCase(
      empresaId: empresaId,
      categoriaMaestraId: categoriaMaestraId,
      nombrePersonalizado: nombrePersonalizado,
      descripcionPersonalizada: descripcionPersonalizada,
      nombreLocal: nombreLocal,
      orden: orden,
    );

    // Recargar lista de categorías si fue exitoso
    if (result is Success) {
      await loadCategorias(empresaId);
      return Success(null);
    } else if (result is Error) {
      final error = result as Error;
      return Error(error.message);
    }

    return Error('Error desconocido');
  }

  Future<Resource<void>> desactivarCategoria({
    required String empresaId,
    required String empresaCategoriaId,
  }) async {
    final result = await _desactivarCategoriaUseCase(
      empresaId: empresaId,
      empresaCategoriaId: empresaCategoriaId,
    );

    // Recargar lista de categorías si fue exitoso
    if (result is Success) {
      await loadCategorias(empresaId);
    }

    return result;
  }

  void reload(String empresaId) {
    loadCategorias(empresaId);
  }

  void clear() {
    emit(const CategoriasEmpresaInitial());
  }
}
