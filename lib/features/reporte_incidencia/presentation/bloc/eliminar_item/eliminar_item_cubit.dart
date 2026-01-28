import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/usecases/eliminar_item_usecase.dart';

part 'eliminar_item_state.dart';

@injectable
class EliminarItemCubit extends Cubit<EliminarItemState> {
  final EliminarItemUsecase _eliminarItemUsecase;

  EliminarItemCubit(
    this._eliminarItemUsecase,
  ) : super(const EliminarItemInitial());

  Future<void> eliminarItem({
    required String reporteId,
    required String itemId,
  }) async {
    emit(const EliminarItemLoading());

    final result = await _eliminarItemUsecase(
      reporteId: reporteId,
      itemId: itemId,
    );

    if (isClosed) return;

    if (result is Success<void>) {
      emit(const EliminarItemSuccess());
    } else if (result is Error<void>) {
      emit(EliminarItemError(result.message));
    }
  }
}
