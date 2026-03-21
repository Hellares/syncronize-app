import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/empresa_banco.dart';
import '../../domain/usecases/get_cuentas_bancarias_usecase.dart';
import '../../domain/usecases/crear_cuenta_bancaria_usecase.dart';
import '../../domain/usecases/actualizar_cuenta_bancaria_usecase.dart';
import '../../domain/usecases/eliminar_cuenta_bancaria_usecase.dart';
import '../../domain/usecases/marcar_principal_usecase.dart';
import '../../domain/usecases/actualizar_saldo_usecase.dart';
import 'empresa_banco_state.dart';

@injectable
class EmpresaBancoCubit extends Cubit<EmpresaBancoState> {
  final GetCuentasBancariasUseCase _getCuentasBancariasUseCase;
  final CrearCuentaBancariaUseCase _crearCuentaBancariaUseCase;
  final ActualizarCuentaBancariaUseCase _actualizarCuentaBancariaUseCase;
  final EliminarCuentaBancariaUseCase _eliminarCuentaBancariaUseCase;
  final MarcarPrincipalUseCase _marcarPrincipalUseCase;
  final ActualizarSaldoUseCase _actualizarSaldoUseCase;

  EmpresaBancoCubit(
    this._getCuentasBancariasUseCase,
    this._crearCuentaBancariaUseCase,
    this._actualizarCuentaBancariaUseCase,
    this._eliminarCuentaBancariaUseCase,
    this._marcarPrincipalUseCase,
    this._actualizarSaldoUseCase,
  ) : super(const EmpresaBancoInitial());

  Future<void> loadCuentas() async {
    emit(const EmpresaBancoLoading());

    final result = await _getCuentasBancariasUseCase();
    if (isClosed) return;

    if (result is Success<List<EmpresaBanco>>) {
      emit(EmpresaBancoLoaded(result.data));
    } else if (result is Error<List<EmpresaBanco>>) {
      emit(EmpresaBancoError(result.message));
    }
  }

  Future<void> crear({
    required String nombreBanco,
    required String tipoCuenta,
    required String numeroCuenta,
    String? cci,
    String? moneda,
    String? titular,
    bool? esPrincipal,
    double? saldoActual,
  }) async {
    final result = await _crearCuentaBancariaUseCase(
      nombreBanco: nombreBanco,
      tipoCuenta: tipoCuenta,
      numeroCuenta: numeroCuenta,
      cci: cci,
      moneda: moneda,
      titular: titular,
      esPrincipal: esPrincipal,
      saldoActual: saldoActual,
    );
    if (isClosed) return;

    if (result is Success<EmpresaBanco>) {
      loadCuentas();
    } else if (result is Error<EmpresaBanco>) {
      emit(EmpresaBancoError(result.message));
    }
  }

  Future<void> actualizar({
    required String id,
    String? nombreBanco,
    String? tipoCuenta,
    String? numeroCuenta,
    String? cci,
    String? moneda,
    String? titular,
    bool? esPrincipal,
  }) async {
    final result = await _actualizarCuentaBancariaUseCase(
      id: id,
      nombreBanco: nombreBanco,
      tipoCuenta: tipoCuenta,
      numeroCuenta: numeroCuenta,
      cci: cci,
      moneda: moneda,
      titular: titular,
      esPrincipal: esPrincipal,
    );
    if (isClosed) return;

    if (result is Success<EmpresaBanco>) {
      loadCuentas();
    } else if (result is Error<EmpresaBanco>) {
      emit(EmpresaBancoError(result.message));
    }
  }

  Future<void> eliminar({required String id}) async {
    final result = await _eliminarCuentaBancariaUseCase(id: id);
    if (isClosed) return;

    if (result is Success<void>) {
      loadCuentas();
    } else if (result is Error<void>) {
      emit(EmpresaBancoError(result.message));
    }
  }

  Future<void> marcarPrincipal({required String id}) async {
    final result = await _marcarPrincipalUseCase(id: id);
    if (isClosed) return;

    if (result is Success<EmpresaBanco>) {
      loadCuentas();
    } else if (result is Error<EmpresaBanco>) {
      emit(EmpresaBancoError(result.message));
    }
  }

  Future<void> actualizarSaldo({
    required String id,
    required double saldo,
  }) async {
    final result = await _actualizarSaldoUseCase(id: id, saldo: saldo);
    if (isClosed) return;

    if (result is Success<EmpresaBanco>) {
      loadCuentas();
    } else if (result is Error<EmpresaBanco>) {
      emit(EmpresaBancoError(result.message));
    }
  }
}
