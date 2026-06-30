import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/cuenta_por_cobrar.dart';
import '../../domain/usecases/get_cuentas_cobrar_usecase.dart';
import '../../domain/usecases/get_resumen_cuentas_cobrar_usecase.dart';
import '../../domain/usecases/registrar_abono_cuenta_cobrar_usecase.dart';
import 'cuentas_cobrar_state.dart';

@injectable
class CuentasCobrarCubit extends Cubit<CuentasCobrarState> {
  final GetCuentasCobrarUseCase _getCuentasCobrarUseCase;
  final GetResumenCuentasCobrarUseCase _getResumenUseCase;
  final RegistrarAbonoCuentaCobrarUseCase _registrarAbonoUseCase;

  String? _filtroEstado;
  String? _filtroSedeId;

  CuentasCobrarCubit(
    this._getCuentasCobrarUseCase,
    this._getResumenUseCase,
    this._registrarAbonoUseCase,
  ) : super(const CuentasCobrarInitial());

  Future<void> loadCuentas({String? estado, String? sedeId}) async {
    _filtroEstado = estado;
    _filtroSedeId = sedeId;
    emit(const CuentasCobrarLoading());

    final results = await Future.wait([
      _getCuentasCobrarUseCase(estado: estado, sedeId: sedeId),
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

  /// Registra un abono del cliente y recarga (manteniendo el filtro).
  /// Devuelve null si OK, o el mensaje de error.
  Future<String?> registrarAbono(
    String ventaId, {
    required String metodoPago,
    required double monto,
    String? referencia,
    String? fuente,
    String? bancoId,
    String? banco,
  }) async {
    final res = await _registrarAbonoUseCase(
      ventaId,
      metodoPago: metodoPago,
      monto: monto,
      referencia: referencia,
      fuente: fuente,
      bancoId: bancoId,
      banco: banco,
    );
    if (res is Error<void>) return res.message;
    await loadCuentas(estado: _filtroEstado, sedeId: _filtroSedeId);
    return null;
  }
}
