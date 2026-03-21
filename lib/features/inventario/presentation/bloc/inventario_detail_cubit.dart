import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/inventario.dart';
import '../../domain/usecases/get_detalle_inventario_usecase.dart';
import '../../domain/usecases/iniciar_inventario_usecase.dart';
import '../../domain/usecases/registrar_conteo_usecase.dart';
import '../../domain/usecases/finalizar_conteo_usecase.dart';
import '../../domain/usecases/aprobar_inventario_usecase.dart';
import '../../domain/usecases/aplicar_ajustes_usecase.dart';
import '../../domain/usecases/cancelar_inventario_usecase.dart';
import 'inventario_detail_state.dart';

@injectable
class InventarioDetailCubit extends Cubit<InventarioDetailState> {
  final GetDetalleInventarioUseCase _getDetalleUseCase;
  final IniciarInventarioUseCase _iniciarUseCase;
  final RegistrarConteoUseCase _registrarConteoUseCase;
  final FinalizarConteoUseCase _finalizarConteoUseCase;
  final AprobarInventarioUseCase _aprobarUseCase;
  final AplicarAjustesUseCase _aplicarAjustesUseCase;
  final CancelarInventarioUseCase _cancelarUseCase;

  InventarioDetailCubit(
    this._getDetalleUseCase,
    this._iniciarUseCase,
    this._registrarConteoUseCase,
    this._finalizarConteoUseCase,
    this._aprobarUseCase,
    this._aplicarAjustesUseCase,
    this._cancelarUseCase,
  ) : super(const InventarioDetailInitial());

  Inventario? get _currentInventario {
    final s = state;
    if (s is InventarioDetailLoaded) return s.inventario;
    if (s is InventarioDetailActionLoading) return s.inventario;
    if (s is InventarioDetailActionSuccess) return s.inventario;
    if (s is InventarioDetailActionError) return s.inventario;
    return null;
  }

  Future<void> loadDetalle(String id) async {
    emit(const InventarioDetailLoading());

    final result = await _getDetalleUseCase(id: id);
    if (isClosed) return;

    if (result is Success<Inventario>) {
      emit(InventarioDetailLoaded(result.data));
    } else if (result is Error<Inventario>) {
      emit(InventarioDetailError(result.message));
    }
  }

  Future<void> iniciar(String id) async {
    final inv = _currentInventario;
    if (inv == null) return;

    emit(InventarioDetailActionLoading(inv, 'Iniciando conteo...'));

    final result = await _iniciarUseCase(id: id);
    if (isClosed) return;

    if (result is Success) {
      emit(InventarioDetailActionSuccess(inv, 'Conteo iniciado exitosamente'));
      await loadDetalle(id);
    } else if (result is Error) {
      emit(InventarioDetailActionError(inv, (result as Error).message));
    }
  }

  Future<void> registrarConteo({
    required String inventarioId,
    required String itemId,
    required Map<String, dynamic> data,
  }) async {
    final inv = _currentInventario;
    if (inv == null) return;

    emit(InventarioDetailActionLoading(inv, 'Registrando conteo...'));

    final result = await _registrarConteoUseCase(
      id: inventarioId,
      itemId: itemId,
      data: data,
    );
    if (isClosed) return;

    if (result is Success) {
      emit(InventarioDetailActionSuccess(inv, 'Conteo registrado exitosamente'));
      await loadDetalle(inventarioId);
    } else if (result is Error) {
      emit(InventarioDetailActionError(inv, (result as Error).message));
    }
  }

  Future<void> finalizarConteo(String id) async {
    final inv = _currentInventario;
    if (inv == null) return;

    emit(InventarioDetailActionLoading(inv, 'Finalizando conteo...'));

    final result = await _finalizarConteoUseCase(id: id);
    if (isClosed) return;

    if (result is Success) {
      emit(InventarioDetailActionSuccess(inv, 'Conteo finalizado exitosamente'));
      await loadDetalle(id);
    } else if (result is Error) {
      emit(InventarioDetailActionError(inv, (result as Error).message));
    }
  }

  Future<void> aprobar(String id) async {
    final inv = _currentInventario;
    if (inv == null) return;

    emit(InventarioDetailActionLoading(inv, 'Aprobando inventario...'));

    final result = await _aprobarUseCase(id: id);
    if (isClosed) return;

    if (result is Success) {
      emit(InventarioDetailActionSuccess(inv, 'Inventario aprobado exitosamente'));
      await loadDetalle(id);
    } else if (result is Error) {
      emit(InventarioDetailActionError(inv, (result as Error).message));
    }
  }

  Future<void> aplicarAjustes(String id) async {
    final inv = _currentInventario;
    if (inv == null) return;

    emit(InventarioDetailActionLoading(inv, 'Aplicando ajustes de stock...'));

    final result = await _aplicarAjustesUseCase(id: id);
    if (isClosed) return;

    if (result is Success) {
      emit(InventarioDetailActionSuccess(inv, 'Ajustes aplicados exitosamente'));
      await loadDetalle(id);
    } else if (result is Error) {
      emit(InventarioDetailActionError(inv, (result as Error).message));
    }
  }

  Future<void> cancelar(String id) async {
    final inv = _currentInventario;
    if (inv == null) return;

    emit(InventarioDetailActionLoading(inv, 'Cancelando inventario...'));

    final result = await _cancelarUseCase(id: id);
    if (isClosed) return;

    if (result is Success) {
      emit(InventarioDetailActionSuccess(inv, 'Inventario cancelado'));
      await loadDetalle(id);
    } else if (result is Error) {
      emit(InventarioDetailActionError(inv, (result as Error).message));
    }
  }
}
