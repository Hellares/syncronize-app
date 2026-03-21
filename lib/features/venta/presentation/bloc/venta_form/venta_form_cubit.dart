import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/venta.dart';
import '../../../domain/usecases/crear_venta_usecase.dart';
import '../../../domain/usecases/crear_venta_desde_cotizacion_usecase.dart';
import '../../../domain/usecases/crear_y_cobrar_venta_usecase.dart';
import '../../../domain/usecases/actualizar_venta_usecase.dart';
import '../../../domain/usecases/confirmar_venta_usecase.dart';
import '../../../domain/usecases/procesar_pago_usecase.dart';
import '../../../domain/usecases/anular_venta_usecase.dart';
import 'venta_form_state.dart';

@injectable
class VentaFormCubit extends Cubit<VentaFormState> {
  final CrearVentaUseCase _crearVentaUseCase;
  final CrearVentaDesdeCotizacionUseCase _crearDesdeCotizacionUseCase;
  final CrearYCobrarVentaUseCase _crearYCobrarVentaUseCase;
  final ActualizarVentaUseCase _actualizarVentaUseCase;
  final ConfirmarVentaUseCase _confirmarVentaUseCase;
  final ProcesarPagoUseCase _procesarPagoUseCase;
  final AnularVentaUseCase _anularVentaUseCase;

  VentaFormCubit({
    required CrearVentaUseCase crearVentaUseCase,
    required CrearVentaDesdeCotizacionUseCase crearDesdeCotizacionUseCase,
    required CrearYCobrarVentaUseCase crearYCobrarVentaUseCase,
    required ActualizarVentaUseCase actualizarVentaUseCase,
    required ConfirmarVentaUseCase confirmarVentaUseCase,
    required ProcesarPagoUseCase procesarPagoUseCase,
    required AnularVentaUseCase anularVentaUseCase,
  })  : _crearVentaUseCase = crearVentaUseCase,
        _crearDesdeCotizacionUseCase = crearDesdeCotizacionUseCase,
        _crearYCobrarVentaUseCase = crearYCobrarVentaUseCase,
        _actualizarVentaUseCase = actualizarVentaUseCase,
        _confirmarVentaUseCase = confirmarVentaUseCase,
        _procesarPagoUseCase = procesarPagoUseCase,
        _anularVentaUseCase = anularVentaUseCase,
        super(const VentaFormInitial());

  Future<void> crearVenta(Map<String, dynamic> data) async {
    emit(const VentaFormLoading());
    final result = await _crearVentaUseCase(data: data);
    if (isClosed) return;

    if (result is Success<Venta>) {
      emit(VentaFormSuccess(
        venta: result.data,
        message: 'Venta creada exitosamente',
      ));
    } else if (result is Error<Venta>) {
      emit(VentaFormError(result.message));
    }
  }

  Future<void> crearDesdeCotizacion(
    String cotizacionId,
    Map<String, dynamic> data,
  ) async {
    emit(const VentaFormLoading());
    final result = await _crearDesdeCotizacionUseCase(
      cotizacionId: cotizacionId,
      data: data,
    );
    if (isClosed) return;

    if (result is Success<Venta>) {
      emit(VentaFormSuccess(
        venta: result.data,
        message: 'Venta creada desde cotizacion exitosamente',
      ));
    } else if (result is Error<Venta>) {
      emit(VentaFormError(result.message));
    }
  }

  Future<void> crearYCobrar(Map<String, dynamic> data) async {
    emit(const VentaFormLoading());
    final result = await _crearYCobrarVentaUseCase(data: data);
    if (isClosed) return;

    if (result is Success<Venta>) {
      emit(VentaFormSuccess(
        venta: result.data,
        message: 'Venta cobrada exitosamente',
      ));
    } else if (result is Error<Venta>) {
      emit(VentaFormError(result.message));
    }
  }

  Future<void> actualizarVenta(String id, Map<String, dynamic> data) async {
    emit(const VentaFormLoading());
    final result = await _actualizarVentaUseCase(ventaId: id, data: data);
    if (isClosed) return;

    if (result is Success<Venta>) {
      emit(VentaFormSuccess(
        venta: result.data,
        message: 'Venta actualizada exitosamente',
      ));
    } else if (result is Error<Venta>) {
      emit(VentaFormError(result.message));
    }
  }

  Future<void> confirmarVenta(String id) async {
    emit(const VentaFormLoading());
    final result = await _confirmarVentaUseCase(ventaId: id);
    if (isClosed) return;

    if (result is Success<Venta>) {
      emit(VentaConfirmada(result.data));
    } else if (result is Error<Venta>) {
      emit(VentaFormError(result.message));
    }
  }

  Future<void> procesarPago(String id, Map<String, dynamic> data) async {
    emit(const VentaFormLoading());
    final result = await _procesarPagoUseCase(ventaId: id, data: data);
    if (isClosed) return;

    if (result is Success<Venta>) {
      emit(VentaPagoRegistrado(result.data));
    } else if (result is Error<Venta>) {
      emit(VentaFormError(result.message));
    }
  }

  Future<void> anularVenta(
    String id, {
    required String autorizadoPorId,
    required String motivo,
  }) async {
    emit(const VentaFormLoading());
    final result = await _anularVentaUseCase(
      ventaId: id,
      autorizadoPorId: autorizadoPorId,
      motivo: motivo,
    );
    if (isClosed) return;

    if (result is Success<Venta>) {
      emit(VentaAnulada(result.data));
    } else if (result is Error<Venta>) {
      emit(VentaFormError(result.message));
    }
  }

  void reset() {
    emit(const VentaFormInitial());
  }
}
