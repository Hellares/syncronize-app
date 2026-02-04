import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../data/models/create_combo_dto.dart';
import '../../domain/entities/combo.dart';
import '../../domain/entities/componente_combo.dart';
import '../../domain/usecases/agregar_componente_usecase.dart';
import '../../domain/usecases/agregar_componentes_batch_usecase.dart';
import '../../domain/usecases/create_combo_usecase.dart';
import '../../domain/usecases/eliminar_componente_usecase.dart';
import '../../domain/usecases/get_combo_completo_usecase.dart';
import '../../domain/usecases/get_combos_usecase.dart';
import '../../domain/usecases/get_componentes_usecase.dart';
import '../../domain/usecases/get_reservacion_usecase.dart';
import '../../domain/usecases/reservar_stock_usecase.dart';
import '../../domain/usecases/liberar_reserva_usecase.dart';
import 'combo_state.dart';

@injectable
class ComboCubit extends Cubit<ComboState> {
  final CreateComboUseCase createComboUseCase;
  final GetCombosUseCase getCombos;
  final GetComboCompletoUseCase getComboCompleto;
  final AgregarComponenteUseCase agregarComponente;
  final AgregarComponentesBatchUseCase agregarComponentesBatch;
  final GetComponentesUseCase getComponentes;
  final EliminarComponenteUseCase eliminarComponente;
  final GetReservacionUseCase getReservacionUseCase;
  final ReservarStockUseCase reservarStockUseCase;
  final LiberarReservaUseCase liberarReservaUseCase;

  ComboCubit({
    required this.createComboUseCase,
    required this.getCombos,
    required this.getComboCompleto,
    required this.agregarComponente,
    required this.agregarComponentesBatch,
    required this.getComponentes,
    required this.eliminarComponente,
    required this.getReservacionUseCase,
    required this.reservarStockUseCase,
    required this.liberarReservaUseCase,
  }) : super(ComboInitial());

  /// Crea un nuevo combo directamente
  Future<void> createCombo({
    required CreateComboDto dto,
  }) async {
    emit(ComboLoading());

    final result = await createComboUseCase(dto: dto);

    if (result is Success<Combo>) {
      emit(ComboOperationSuccess(
        'Combo creado exitosamente',
        combo: result.data,
      ));
    } else if (result is Error) {
      final error = result as Error;
      emit(ComboError(
        error.message,
        errorCode: error.errorCode,
      ));
    }
  }

  /// Obtiene todos los combos de una empresa
  Future<void> loadCombos({
    required String empresaId,
    required String sedeId,
  }) async {
    emit(ComboLoading());

    final result = await getCombos(
      empresaId: empresaId,
      sedeId: sedeId,
    );

    if (result is Success<List<Combo>>) {
      emit(CombosLoaded(result.data));
    } else if (result is Error) {
      final error = result as Error;
      emit(ComboError(
        error.message,
        errorCode: error.errorCode,
      ));
    }
  }

  /// Obtiene información completa de un combo
  Future<void> loadCombo({
    required String comboId,
    required String empresaId,
    required String sedeId,
  }) async {
    emit(ComboLoading());

    final result = await getComboCompleto(
      comboId: comboId,
      empresaId: empresaId,
      sedeId: sedeId,
    );

    if (result is Success<Combo>) {
      final resResult = await getReservacionUseCase(
        comboId: comboId,
        sedeId: sedeId,
      );
      final reservacionCantidad = resResult is Success<int> ? resResult.data : 0;
      emit(ComboLoaded(result.data, reservacionCantidad: reservacionCantidad));
    } else if (result is Error) {
      final error = result as Error;
      emit(ComboError(
        error.message,
        errorCode: error.errorCode,
      ));
    }
  }

  /// Agrega un componente al combo
  Future<void> addComponente({
    required String comboId,
    required String empresaId,
    required String sedeId,
    String? componenteProductoId,
    String? componenteVarianteId,
    required int cantidad,
    bool? esPersonalizable,
    String? categoriaComponente,
    int? orden,
  }) async {
    emit(ComboLoading());

    final result = await agregarComponente(
      comboId: comboId,
      empresaId: empresaId,
      sedeId: sedeId,
      componenteProductoId: componenteProductoId,
      componenteVarianteId: componenteVarianteId,
      cantidad: cantidad,
      esPersonalizable: esPersonalizable,
      categoriaComponente: categoriaComponente,
      orden: orden,
    );

    if (result is Success<ComponenteCombo>) {
      emit(ComponenteAdded(
        result.data,
        'Componente agregado exitosamente',
      ));
    } else if (result is Error) {
      final error = result as Error;
      emit(ComboError(
        error.message,
        errorCode: error.errorCode,
      ));
    }
  }

  /// Agrega múltiples componentes a un combo en batch
  Future<void> addComponentesBatch({
    required String comboId,
    required String empresaId,
    required String sedeId,
    required List<Map<String, dynamic>> componentes,
  }) async {
    emit(ComboLoading());

    final result = await agregarComponentesBatch(
      comboId: comboId,
      empresaId: empresaId,
      sedeId: sedeId,
      componentes: componentes,
    );

    if (result is Success<List<ComponenteCombo>>) {
      emit(ComponentesBatchAdded(
        result.data,
        '${result.data.length} componentes agregados exitosamente',
      ));
    } else if (result is Error) {
      final error = result as Error;
      emit(ComboError(
        error.message,
        errorCode: error.errorCode,
      ));
    }
  }

  /// Carga los componentes de un combo
  Future<void> loadComponentes({
    required String comboId,
    required String empresaId,
    required String sedeId,
  }) async {
    emit(ComboLoading());

    final result = await getComponentes(
      comboId: comboId,
      empresaId: empresaId,
      sedeId: sedeId,
    );

    if (result is Success<List<ComponenteCombo>>) {
      emit(ComponentesLoaded(result.data));
    } else if (result is Error) {
      final error = result as Error;
      emit(ComboError(
        error.message,
        errorCode: error.errorCode,
      ));
    }
  }

  /// Elimina un componente del combo
  Future<void> deleteComponente({
    required String componenteId,
    required String empresaId,
  }) async {
    emit(ComboLoading());

    final result = await eliminarComponente(
      componenteId: componenteId,
      empresaId: empresaId,
    );

    if (result is Success) {
      emit(ComponenteDeleted('Componente eliminado exitosamente'));
    } else if (result is Error) {
      emit(ComboError(
        result.message,
        errorCode: result.errorCode,
      ));
    }
  }

  /// Reserva stock para combos en una sede
  Future<void> reservarStock({
    required String comboId,
    required String sedeId,
    required int cantidad,
  }) async {
    emit(ComboLoading());

    final result = await reservarStockUseCase(
      comboId: comboId,
      sedeId: sedeId,
      cantidad: cantidad,
    );

    if (result is Success<int>) {
      emit(ReservacionUpdated(result.data, 'Reserva actualizada a ${result.data} combos'));
    } else if (result is Error) {
      final error = result as Error;
      emit(ComboError(
        error.message,
        errorCode: error.errorCode,
      ));
    }
  }

  /// Libera la reserva de stock de un combo en una sede
  Future<void> liberarReserva({
    required String comboId,
    required String sedeId,
  }) async {
    emit(ComboLoading());

    final result = await liberarReservaUseCase(
      comboId: comboId,
      sedeId: sedeId,
    );

    if (result is Success) {
      emit(ReservacionUpdated(0, 'Reserva liberada exitosamente'));
    } else if (result is Error) {
      final error = result;
      emit(ComboError(
        error.message,
        errorCode: error.errorCode,
      ));
    }
  }

  /// Resetea el estado a inicial
  void reset() {
    emit(ComboInitial());
  }
}
