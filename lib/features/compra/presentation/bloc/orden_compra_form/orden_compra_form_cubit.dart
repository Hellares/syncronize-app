import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/orden_compra.dart';
import '../../../domain/usecases/crear_orden_compra_usecase.dart';
import '../../../domain/usecases/actualizar_orden_compra_usecase.dart';
import 'orden_compra_form_state.dart';

@injectable
class OrdenCompraFormCubit extends Cubit<OrdenCompraFormState> {
  final CrearOrdenCompraUseCase _crearOrdenCompraUseCase;
  final ActualizarOrdenCompraUseCase _actualizarOrdenCompraUseCase;

  OrdenCompraFormCubit(
    this._crearOrdenCompraUseCase,
    this._actualizarOrdenCompraUseCase,
  ) : super(const OrdenCompraFormInitial());

  Future<void> crearOrdenCompra({
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    emit(const OrdenCompraFormLoading());

    final result = await _crearOrdenCompraUseCase(
      empresaId: empresaId,
      data: data,
    );

    if (isClosed) return;

    if (result is Success<OrdenCompra>) {
      emit(OrdenCompraFormSuccess(result.data, isUpdate: false));
    } else if (result is Error<OrdenCompra>) {
      emit(OrdenCompraFormError(result.message));
    }
  }

  Future<void> actualizarOrdenCompra({
    required String empresaId,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    emit(const OrdenCompraFormLoading());

    final result = await _actualizarOrdenCompraUseCase(
      empresaId: empresaId,
      id: id,
      data: data,
    );

    if (isClosed) return;

    if (result is Success<OrdenCompra>) {
      emit(OrdenCompraFormSuccess(result.data, isUpdate: true));
    } else if (result is Error<OrdenCompra>) {
      emit(OrdenCompraFormError(result.message));
    }
  }

  void reset() {
    emit(const OrdenCompraFormInitial());
  }
}
