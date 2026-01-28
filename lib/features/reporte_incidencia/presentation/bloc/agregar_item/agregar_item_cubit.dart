import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/reporte_incidencia.dart';
import '../../../domain/usecases/agregar_item_usecase.dart';

part 'agregar_item_state.dart';

@injectable
class AgregarItemCubit extends Cubit<AgregarItemState> {
  final AgregarItemUsecase _agregarItemUsecase;

  AgregarItemCubit(
    this._agregarItemUsecase,
  ) : super(const AgregarItemInitial());

  Future<void> agregarItem({
    required String reporteId,
    required String productoStockId,
    required TipoIncidenciaProducto tipo,
    required int cantidadAfectada,
    required String descripcion,
    String? observaciones,
  }) async {
    emit(const AgregarItemLoading());

    final result = await _agregarItemUsecase(
      reporteId: reporteId,
      productoStockId: productoStockId,
      tipo: tipo,
      cantidadAfectada: cantidadAfectada,
      descripcion: descripcion,
      observaciones: observaciones,
    );

    if (isClosed) return;

    if (result is Success<ReporteIncidenciaItem>) {
      emit(AgregarItemSuccess(result.data));
    } else if (result is Error<ReporteIncidenciaItem>) {
      emit(AgregarItemError(result.message));
    }
  }
}
