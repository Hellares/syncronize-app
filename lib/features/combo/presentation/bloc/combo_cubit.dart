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
import '../../domain/usecases/eliminar_componentes_batch_usecase.dart';
import '../../domain/usecases/get_combo_completo_usecase.dart';
import '../../domain/usecases/get_combos_usecase.dart';
import '../../domain/usecases/get_componentes_usecase.dart';
import '../../domain/usecases/get_reservacion_usecase.dart';
import '../../domain/usecases/reservar_stock_usecase.dart';
import '../../domain/usecases/liberar_reserva_usecase.dart';
import '../../domain/usecases/actualizar_precio_combo_usecase.dart';
import '../../domain/usecases/actualizar_oferta_combo_usecase.dart';
import '../../domain/usecases/desactivar_oferta_combo_usecase.dart';
import '../../domain/usecases/get_historial_precios_combo_usecase.dart';
import '../../data/models/update_combo_pricing_dto.dart';
import '../../data/models/update_combo_oferta_dto.dart';
import '../../domain/entities/combo_config_historial.dart';
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
  final EliminarComponentesBatchUseCase eliminarComponentesBatch;
  final GetReservacionUseCase getReservacionUseCase;
  final ReservarStockUseCase reservarStockUseCase;
  final LiberarReservaUseCase liberarReservaUseCase;
  final ActualizarPrecioComboUseCase actualizarPrecioComboUseCase;
  final ActualizarOfertaComboUseCase actualizarOfertaComboUseCase;
  final DesactivarOfertaComboUseCase desactivarOfertaComboUseCase;
  final GetHistorialPreciosComboUseCase getHistorialPreciosComboUseCase;

  ComboCubit({
    required this.createComboUseCase,
    required this.getCombos,
    required this.getComboCompleto,
    required this.agregarComponente,
    required this.agregarComponentesBatch,
    required this.getComponentes,
    required this.eliminarComponente,
    required this.eliminarComponentesBatch,
    required this.getReservacionUseCase,
    required this.reservarStockUseCase,
    required this.liberarReservaUseCase,
    required this.actualizarPrecioComboUseCase,
    required this.actualizarOfertaComboUseCase,
    required this.desactivarOfertaComboUseCase,
    required this.getHistorialPreciosComboUseCase,
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

  /// Elimina múltiples componentes del combo en batch
  Future<void> deleteComponentesBatch({
    required List<String> componenteIds,
    required String empresaId,
  }) async {
    emit(ComboLoading());

    final result = await eliminarComponentesBatch(
      componenteIds: componenteIds,
      empresaId: empresaId,
    );

    if (result is Success) {
      emit(ComponentesBatchDeleted(
        componenteIds.length,
        '${componenteIds.length} componentes eliminados exitosamente',
      ));
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

  /// Actualiza la configuración de precios del combo
  Future<void> actualizarPrecio({
    required String comboId,
    required String sedeId,
    required UpdateComboPricingDto dto,
  }) async {
    emit(ComboLoading());

    final result = await actualizarPrecioComboUseCase(
      comboId: comboId,
      sedeId: sedeId,
      dto: dto,
    );

    if (result is Success<Combo>) {
      emit(ComboPricingUpdated(result.data, 'Precio actualizado exitosamente'));
    } else if (result is Error) {
      final error = result as Error;
      emit(ComboError(error.message, errorCode: error.errorCode));
    }
  }

  /// Actualiza la oferta del combo
  Future<void> actualizarOferta({
    required String comboId,
    required String sedeId,
    required UpdateComboOfertaDto dto,
  }) async {
    emit(ComboLoading());

    final result = await actualizarOfertaComboUseCase(
      comboId: comboId,
      sedeId: sedeId,
      dto: dto,
    );

    if (result is Success<Combo>) {
      emit(ComboOfertaUpdated(result.data, 'Oferta actualizada exitosamente'));
    } else if (result is Error) {
      final error = result as Error;
      emit(ComboError(error.message, errorCode: error.errorCode));
    }
  }

  /// Desactiva la oferta del combo
  Future<void> desactivarOferta({
    required String comboId,
    required String sedeId,
  }) async {
    emit(ComboLoading());

    final result = await desactivarOfertaComboUseCase(
      comboId: comboId,
      sedeId: sedeId,
    );

    if (result is Success<Combo>) {
      emit(ComboOfertaUpdated(result.data, 'Oferta desactivada exitosamente'));
    } else if (result is Error) {
      final error = result as Error;
      emit(ComboError(error.message, errorCode: error.errorCode));
    }
  }

  /// Carga el historial de cambios de precios del combo
  Future<void> loadHistorialPrecios({
    required String comboId,
  }) async {
    emit(ComboLoading());

    final result = await getHistorialPreciosComboUseCase(
      comboId: comboId,
    );

    if (result is Success<List<ComboConfigHistorialEntry>>) {
      emit(ComboHistorialLoaded(result.data));
    } else if (result is Error) {
      final error = result as Error;
      emit(ComboError(error.message, errorCode: error.errorCode));
    }
  }

  /// Resetea el estado a inicial
  void reset() {
    emit(ComboInitial());
  }
}
