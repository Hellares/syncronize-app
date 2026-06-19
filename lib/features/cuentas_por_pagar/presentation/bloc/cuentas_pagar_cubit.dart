import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/cuenta_por_pagar.dart';
import '../../domain/usecases/get_cuentas_pagar_usecase.dart';
import '../../domain/usecases/get_resumen_cuentas_pagar_usecase.dart';
import '../../domain/usecases/registrar_pago_cuenta_pagar_usecase.dart';
import 'cuentas_pagar_state.dart';

@injectable
class CuentasPagarCubit extends Cubit<CuentasPagarState> {
  final GetCuentasPagarUseCase _getCuentasPagarUseCase;
  final GetResumenCuentasPagarUseCase _getResumenUseCase;
  final RegistrarPagoCuentaPagarUseCase _registrarPagoUseCase;

  String? _filtroEstado;

  CuentasPagarCubit(
    this._getCuentasPagarUseCase,
    this._getResumenUseCase,
    this._registrarPagoUseCase,
  ) : super(const CuentasPagarInitial());

  Future<void> loadCuentas({String? estado}) async {
    _filtroEstado = estado;
    emit(const CuentasPagarLoading());

    final results = await Future.wait([
      _getCuentasPagarUseCase(estado: estado),
      _getResumenUseCase(),
    ]);
    if (isClosed) return;

    final cuentasResult = results[0] as Resource<List<CuentaPorPagar>>;
    final resumenResult = results[1] as Resource<ResumenCuentasPagar>;

    if (cuentasResult is Success<List<CuentaPorPagar>>) {
      ResumenCuentasPagar? resumen;
      if (resumenResult is Success<ResumenCuentasPagar>) {
        resumen = resumenResult.data;
      }
      emit(CuentasPagarLoaded(cuentas: cuentasResult.data, resumen: resumen));
    } else if (cuentasResult is Error<List<CuentaPorPagar>>) {
      emit(CuentasPagarError(cuentasResult.message));
    }
  }

  /// Registra un pago a proveedor y recarga la lista (manteniendo el filtro).
  /// Devuelve null si OK, o el mensaje de error.
  Future<String?> registrarPago(
    String compraId, {
    required String metodoPago,
    required double monto,
    String? referencia,
    String? bancoDestino,
    String? cuentaDestino,
  }) async {
    final res = await _registrarPagoUseCase(
      compraId,
      metodoPago: metodoPago,
      monto: monto,
      referencia: referencia,
      bancoDestino: bancoDestino,
      cuentaDestino: cuentaDestino,
    );
    if (res is Error<void>) return res.message;
    await loadCuentas(estado: _filtroEstado);
    return null;
  }
}
