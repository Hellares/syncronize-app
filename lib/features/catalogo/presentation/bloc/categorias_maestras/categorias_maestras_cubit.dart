import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/usecases/get_categorias_maestras_usecase.dart';
import 'categorias_maestras_state.dart';

@injectable
class CategoriasMaestrasCubit extends Cubit<CategoriasMaestrasState> {
  final GetCategoriasMaestrasUseCase _getCategoriasMaestrasUseCase;

  CategoriasMaestrasCubit(this._getCategoriasMaestrasUseCase)
      : super(const CategoriasMaestrasInitial());

  Future<void> loadCategoriasMaestras({
    bool incluirHijos = false,
    bool soloPopulares = false,
  }) async {
    emit(const CategoriasMaestrasLoading());

    final result = await _getCategoriasMaestrasUseCase(
      incluirHijos: incluirHijos,
      soloPopulares: soloPopulares,
    );

    if (result is Success) {
      final success = result as Success;
      emit(CategoriasMaestrasLoaded(success.data));
    } else if (result is Error) {
      final error = result as Error;
      emit(CategoriasMaestrasError(error.message));
    }
  }

  void reload({bool incluirHijos = false, bool soloPopulares = false}) {
    loadCategoriasMaestras(
      incluirHijos: incluirHijos,
      soloPopulares: soloPopulares,
    );
  }

  void clear() {
    emit(const CategoriasMaestrasInitial());
  }
}
