import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/usecases/get_categorias_empresa_usecase.dart';
import 'categorias_empresa_state.dart';

@injectable
class CategoriasEmpresaCubit extends Cubit<CategoriasEmpresaState> {
  final GetCategoriasEmpresaUseCase _getCategoriasEmpresaUseCase;

  CategoriasEmpresaCubit(this._getCategoriasEmpresaUseCase)
      : super(const CategoriasEmpresaInitial());

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

  void reload(String empresaId) {
    loadCategorias(empresaId);
  }

  void clear() {
    emit(const CategoriasEmpresaInitial());
  }
}
