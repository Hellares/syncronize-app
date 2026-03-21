import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/libro_contable.dart';
import '../../domain/usecases/get_libro_contable_usecase.dart';
import 'libro_contable_state.dart';

@injectable
class LibroContableCubit extends Cubit<LibroContableState> {
  final GetLibroContableUseCase _getLibroContableUseCase;

  LibroContableCubit(this._getLibroContableUseCase)
      : super(const LibroContableInitial());

  Future<void> loadLibro({
    required int mes,
    required int anio,
  }) async {
    emit(const LibroContableLoading());

    final result = await _getLibroContableUseCase(mes: mes, anio: anio);
    if (isClosed) return;

    if (result is Success<LibroContable>) {
      emit(LibroContableLoaded(libro: result.data));
    } else if (result is Error<LibroContable>) {
      emit(LibroContableError(result.message));
    }
  }
}
