import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/cuenta_por_cobrar.dart';
import '../../domain/usecases/get_cuentas_cobrar_usecase.dart';
import '../../domain/usecases/get_resumen_cuentas_cobrar_usecase.dart';
import 'cuentas_cobrar_state.dart';

@injectable
class CuentasCobrarCubit extends Cubit<CuentasCobrarState> {
  final GetCuentasCobrarUseCase _getCuentasCobrarUseCase;
  final GetResumenCuentasCobrarUseCase _getResumenUseCase;

  CuentasCobrarCubit(this._getCuentasCobrarUseCase, this._getResumenUseCase)
      : super(const CuentasCobrarInitial());

  Future<void> loadCuentas({String? estado}) async {
    emit(const CuentasCobrarLoading());

    final results = await Future.wait([
      _getCuentasCobrarUseCase(estado: estado),
      _getResumenUseCase(),
    ]);
    if (isClosed) return;

    final cuentasResult = results[0] as Resource<List<CuentaPorCobrar>>;
    final resumenResult = results[1] as Resource<ResumenCuentasCobrar>;

    if (cuentasResult is Success<List<CuentaPorCobrar>>) {
      ResumenCuentasCobrar? resumen;
      if (resumenResult is Success<ResumenCuentasCobrar>) {
        resumen = resumenResult.data;
      }
      emit(CuentasCobrarLoaded(cuentas: cuentasResult.data, resumen: resumen));
    } else if (cuentasResult is Error<List<CuentaPorCobrar>>) {
      emit(CuentasCobrarError(cuentasResult.message));
    }
  }
}
