import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/proveedor.dart';
import '../../../domain/usecases/crear_proveedor_usecase.dart';
import '../../../domain/usecases/actualizar_proveedor_usecase.dart';
import 'proveedor_form_state.dart';

@injectable
class ProveedorFormCubit extends Cubit<ProveedorFormState> {
  final CrearProveedorUseCase _crearProveedorUseCase;
  final ActualizarProveedorUseCase _actualizarProveedorUseCase;

  ProveedorFormCubit(
    this._crearProveedorUseCase,
    this._actualizarProveedorUseCase,
  ) : super(const ProveedorFormInitial());

  /// Crea un nuevo proveedor
  Future<void> crearProveedor({
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    emit(const ProveedorFormLoading());

    final result = await _crearProveedorUseCase(
      empresaId: empresaId,
      data: data,
    );

    if (isClosed) return;

    if (result is Success<Proveedor>) {
      emit(ProveedorFormSuccess(result.data, isUpdate: false));
    } else if (result is Error<Proveedor>) {
      emit(ProveedorFormError(result.message));
    }
  }

  /// Actualiza un proveedor existente
  Future<void> actualizarProveedor({
    required String empresaId,
    required String proveedorId,
    required Map<String, dynamic> data,
  }) async {
    emit(const ProveedorFormLoading());

    final result = await _actualizarProveedorUseCase(
      empresaId: empresaId,
      proveedorId: proveedorId,
      data: data,
    );

    if (isClosed) return;

    if (result is Success<Proveedor>) {
      emit(ProveedorFormSuccess(result.data, isUpdate: true));
    } else if (result is Error<Proveedor>) {
      emit(ProveedorFormError(result.message));
    }
  }

  /// Resetea el formulario al estado inicial
  void reset() {
    emit(const ProveedorFormInitial());
  }
}
