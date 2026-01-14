import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/usecases/get_marcas_maestras_usecase.dart';
import 'marcas_maestras_state.dart';

/// Cubit para gestionar el catálogo de marcas maestras disponibles
@injectable
class MarcasMaestrasCubit extends Cubit<MarcasMaestrasState> {
  final GetMarcasMaestrasUseCase _getMarcasMaestrasUseCase;

  MarcasMaestrasCubit(this._getMarcasMaestrasUseCase)
      : super(const MarcasMaestrasInitial());

  /// Carga el catálogo completo de marcas maestras
  ///
  /// [soloPopulares]: Si filtrar solo las marcas populares
  Future<void> loadMarcasMaestras({
    bool soloPopulares = false,
  }) async {
    emit(const MarcasMaestrasLoading());

    final result = await _getMarcasMaestrasUseCase(
      soloPopulares: soloPopulares,
    );

    if (result is Success) {
      final success = result as Success;
      emit(MarcasMaestrasLoaded(success.data));
    } else if (result is Error) {
      final error = result as Error;
      emit(MarcasMaestrasError(error.message));
    }
  }

  void clear() {
    emit(const MarcasMaestrasInitial());
  }
}
