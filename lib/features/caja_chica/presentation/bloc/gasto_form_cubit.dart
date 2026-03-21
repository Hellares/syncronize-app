import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/gasto_caja_chica.dart';
import '../../domain/usecases/registrar_gasto_usecase.dart';
import 'gasto_form_state.dart';

@injectable
class GastoFormCubit extends Cubit<GastoFormState> {
  final RegistrarGastoUseCase _registrarGastoUseCase;

  GastoFormCubit(this._registrarGastoUseCase)
      : super(const GastoFormInitial());

  Future<void> registrarGasto({
    required String cajaChicaId,
    required double monto,
    required String descripcion,
    required String categoriaGastoId,
    String? comprobanteUrl,
  }) async {
    emit(const GastoFormSubmitting());

    final result = await _registrarGastoUseCase(
      cajaChicaId: cajaChicaId,
      monto: monto,
      descripcion: descripcion,
      categoriaGastoId: categoriaGastoId,
      comprobanteUrl: comprobanteUrl,
    );
    if (isClosed) return;

    if (result is Success<GastoCajaChica>) {
      emit(GastoFormSuccess(result.data));
    } else if (result is Error<GastoCajaChica>) {
      emit(GastoFormError(result.message));
    }
  }
}
