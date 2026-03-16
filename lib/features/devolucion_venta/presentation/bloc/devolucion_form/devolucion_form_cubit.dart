import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/devolucion_venta.dart';
import '../../../domain/usecases/crear_devolucion_usecase.dart';
import '../../../domain/usecases/aprobar_devolucion_usecase.dart';
import '../../../domain/usecases/procesar_devolucion_usecase.dart';
import 'devolucion_form_state.dart';

@injectable
class DevolucionFormCubit extends Cubit<DevolucionFormState> {
  final CrearDevolucionUseCase _crearUseCase;
  final AprobarDevolucionUseCase _aprobarUseCase;
  final ProcesarDevolucionUseCase _procesarUseCase;

  DevolucionFormCubit({
    required CrearDevolucionUseCase crearUseCase,
    required AprobarDevolucionUseCase aprobarUseCase,
    required ProcesarDevolucionUseCase procesarUseCase,
  })  : _crearUseCase = crearUseCase,
        _aprobarUseCase = aprobarUseCase,
        _procesarUseCase = procesarUseCase,
        super(const DevolucionFormInitial());

  Future<void> crear(Map<String, dynamic> data) async {
    emit(const DevolucionFormLoading());
    final result = await _crearUseCase(data: data);
    if (isClosed) return;
    if (result is Success<DevolucionVenta>) {
      emit(DevolucionFormSuccess(devolucion: result.data, message: 'Devolucion creada'));
    } else if (result is Error<DevolucionVenta>) {
      emit(DevolucionFormError(result.message));
    }
  }

  Future<void> aprobar(String id) async {
    emit(const DevolucionFormLoading());
    final result = await _aprobarUseCase(id: id);
    if (isClosed) return;
    if (result is Success<DevolucionVenta>) {
      emit(DevolucionEstadoUpdated(devolucion: result.data, message: 'Devolucion aprobada'));
    } else if (result is Error<DevolucionVenta>) {
      emit(DevolucionFormError(result.message));
    }
  }

  Future<void> procesar(String id) async {
    emit(const DevolucionFormLoading());
    final result = await _procesarUseCase(id: id);
    if (isClosed) return;
    if (result is Success<DevolucionVenta>) {
      emit(DevolucionEstadoUpdated(devolucion: result.data, message: 'Devolucion procesada - Stock actualizado'));
    } else if (result is Error<DevolucionVenta>) {
      emit(DevolucionFormError(result.message));
    }
  }

  void reset() => emit(const DevolucionFormInitial());
}
