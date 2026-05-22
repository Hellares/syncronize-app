import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/resource.dart';
import '../../domain/entities/caja.dart';
import '../../domain/usecases/cerrar_caja_usecase.dart';
import 'cerrar_caja_state.dart';

/// Cubit dedicado al cierre de caja — sin acoplamiento con la noción
/// "mi caja activa". Permite que un admin cierre la caja de otro cajero
/// desde el monitor sin que su propio CajaActivaCubit emita estados
/// raros. El refresh del CajaActivaCubit (caso caja propia) lo hace la
/// page disparadora al volver, no este cubit.
@injectable
class CerrarCajaCubit extends Cubit<CerrarCajaState> {
  final CerrarCajaUseCase _cerrarCajaUseCase;

  CerrarCajaCubit(this._cerrarCajaUseCase) : super(const CerrarCajaInitial());

  Future<void> cerrarCaja({
    required String cajaId,
    required List<Map<String, dynamic>> conteos,
    String? observaciones,
  }) async {
    emit(const CerrarCajaSubmitting());

    final result = await _cerrarCajaUseCase(
      cajaId: cajaId,
      conteos: conteos,
      observaciones: observaciones,
    );
    if (isClosed) return;

    if (result is Success<Caja>) {
      emit(CerrarCajaSuccess(result.data));
    } else if (result is Error<Caja>) {
      emit(CerrarCajaError(result.message));
    }
  }

  void reset() {
    emit(const CerrarCajaInitial());
  }
}
