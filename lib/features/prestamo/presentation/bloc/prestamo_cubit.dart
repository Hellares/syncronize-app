import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/prestamo.dart';
import '../../domain/usecases/get_prestamos_usecase.dart';
import '../../domain/usecases/get_resumen_prestamos_usecase.dart';
import '../../domain/usecases/crear_prestamo_usecase.dart';
import '../../domain/usecases/registrar_pago_prestamo_usecase.dart';
import 'prestamo_state.dart';

@injectable
class PrestamoCubit extends Cubit<PrestamoState> {
  final GetPrestamosUseCase _getPrestamosUseCase;
  final GetResumenPrestamosUseCase _getResumenPrestamosUseCase;
  final CrearPrestamoUseCase _crearPrestamoUseCase;
  final RegistrarPagoPrestamoUseCase _registrarPagoPrestamoUseCase;

  PrestamoCubit(
    this._getPrestamosUseCase,
    this._getResumenPrestamosUseCase,
    this._crearPrestamoUseCase,
    this._registrarPagoPrestamoUseCase,
  ) : super(const PrestamoInitial());

  Future<void> loadData({String? estado}) async {
    emit(const PrestamoLoading());

    final results = await Future.wait([
      _getResumenPrestamosUseCase(),
      _getPrestamosUseCase(estado: estado),
    ]);
    if (isClosed) return;

    final resumenResult = results[0];
    final prestamosResult = results[1];

    ResumenPrestamos? resumen;
    if (resumenResult is Success<ResumenPrestamos>) {
      resumen = resumenResult.data;
    }

    if (prestamosResult is Success<List<Prestamo>>) {
      emit(PrestamoLoaded(prestamos: prestamosResult.data, resumen: resumen));
    } else if (prestamosResult is Error<List<Prestamo>>) {
      emit(PrestamoError(prestamosResult.message));
    }
  }

  Future<void> loadPrestamos({String? estado}) async {
    final currentState = state;
    ResumenPrestamos? currentResumen;
    if (currentState is PrestamoLoaded) {
      currentResumen = currentState.resumen;
    }

    final result = await _getPrestamosUseCase(estado: estado);
    if (isClosed) return;

    if (result is Success<List<Prestamo>>) {
      emit(PrestamoLoaded(prestamos: result.data, resumen: currentResumen));
    } else if (result is Error<List<Prestamo>>) {
      emit(PrestamoError(result.message));
    }
  }

  Future<bool> crear({
    required String tipo,
    required String entidadPrestamo,
    String? descripcion,
    required double montoOriginal,
    double? tasaInteres,
    String? moneda,
    int? cantidadCuotas,
    double? montoCuota,
    required String fechaDesembolso,
    String? fechaVencimiento,
    String? observaciones,
  }) async {
    final result = await _crearPrestamoUseCase(
      tipo: tipo,
      entidadPrestamo: entidadPrestamo,
      descripcion: descripcion,
      montoOriginal: montoOriginal,
      tasaInteres: tasaInteres,
      moneda: moneda,
      cantidadCuotas: cantidadCuotas,
      montoCuota: montoCuota,
      fechaDesembolso: fechaDesembolso,
      fechaVencimiento: fechaVencimiento,
      observaciones: observaciones,
    );

    if (result is Success<Prestamo>) {
      loadData();
      return true;
    }
    return false;
  }

  Future<bool> registrarPago({
    required String prestamoId,
    required String metodoPago,
    required double monto,
    String? referencia,
  }) async {
    final result = await _registrarPagoPrestamoUseCase(
      prestamoId: prestamoId,
      metodoPago: metodoPago,
      monto: monto,
      referencia: referencia,
    );

    if (result is Success<Prestamo>) {
      loadData();
      return true;
    }
    return false;
  }
}
