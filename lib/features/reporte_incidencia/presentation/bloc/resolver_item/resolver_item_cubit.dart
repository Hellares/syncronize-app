import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/reporte_incidencia.dart';
import '../../../domain/usecases/resolver_item_usecase.dart';

part 'resolver_item_state.dart';

@injectable
class ResolverItemCubit extends Cubit<ResolverItemState> {
  final ResolverItemUsecase _resolverItemUsecase;

  ResolverItemCubit(
    this._resolverItemUsecase,
  ) : super(const ResolverItemInitial());

  Future<void> resolverItem({
    required String reporteId,
    required String itemId,
    required AccionIncidenciaProducto accionTomada,
    String? observaciones,
    String? sedeDestinoId,
  }) async {
    emit(const ResolverItemLoading());

    final result = await _resolverItemUsecase(
      reporteId: reporteId,
      itemId: itemId,
      accionTomada: accionTomada,
      observaciones: observaciones,
      sedeDestinoId: sedeDestinoId,
    );

    if (isClosed) return;

    if (result is Success<ReporteIncidenciaItem>) {
      emit(ResolverItemSuccess(result.data));
    } else if (result is Error<ReporteIncidenciaItem>) {
      emit(ResolverItemError(result.message));
    }
  }
}
