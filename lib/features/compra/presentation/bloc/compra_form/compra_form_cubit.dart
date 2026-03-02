import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/compra.dart';
import '../../../domain/usecases/crear_compra_usecase.dart';
import '../../../domain/usecases/crear_compra_desde_oc_usecase.dart';
import 'compra_form_state.dart';

@injectable
class CompraFormCubit extends Cubit<CompraFormState> {
  final CrearCompraUseCase _crearCompraUseCase;
  final CrearCompraDesdeOcUseCase _crearCompraDesdeOcUseCase;

  CompraFormCubit(
    this._crearCompraUseCase,
    this._crearCompraDesdeOcUseCase,
  ) : super(const CompraFormInitial());

  Future<void> crearCompra({
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    emit(const CompraFormLoading());

    final result = await _crearCompraUseCase(
      empresaId: empresaId,
      data: data,
    );

    if (isClosed) return;

    if (result is Success<Compra>) {
      emit(CompraFormSuccess(result.data));
    } else if (result is Error<Compra>) {
      emit(CompraFormError(result.message));
    }
  }

  Future<void> crearCompraDesdeOc({
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    emit(const CompraFormLoading());

    final result = await _crearCompraDesdeOcUseCase(
      empresaId: empresaId,
      data: data,
    );

    if (isClosed) return;

    if (result is Success<Compra>) {
      emit(CompraFormSuccess(result.data, isFromOc: true));
    } else if (result is Error<Compra>) {
      emit(CompraFormError(result.message));
    }
  }

  void reset() {
    emit(const CompraFormInitial());
  }
}
