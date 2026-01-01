import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/usecases/get_marcas_empresa_usecase.dart';
import 'marcas_empresa_state.dart';

@injectable
class MarcasEmpresaCubit extends Cubit<MarcasEmpresaState> {
  final GetMarcasEmpresaUseCase _getMarcasEmpresaUseCase;

  MarcasEmpresaCubit(this._getMarcasEmpresaUseCase)
      : super(const MarcasEmpresaInitial());

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

  void reload(String empresaId) {
    loadMarcas(empresaId);
  }

  void clear() {
    emit(const MarcasEmpresaInitial());
  }
}
