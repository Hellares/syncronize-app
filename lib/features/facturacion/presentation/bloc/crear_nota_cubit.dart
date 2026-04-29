import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/crear_nota_item.dart';
import '../../domain/entities/crear_nota_request.dart';
import '../../domain/entities/tipo_nota.dart';
import '../../domain/usecases/crear_nota_credito_usecase.dart';
import '../../domain/usecases/crear_nota_debito_usecase.dart';
import '../../domain/usecases/obtener_motivos_nota_usecase.dart';
import 'crear_nota_state.dart';

@injectable
class CrearNotaCubit extends Cubit<CrearNotaState> {
  final ObtenerMotivosNotaUseCase _obtenerMotivos;
  final CrearNotaCreditoUseCase _crearNotaCredito;
  final CrearNotaDebitoUseCase _crearNotaDebito;

  CrearNotaCubit(
    this._obtenerMotivos,
    this._crearNotaCredito,
    this._crearNotaDebito,
  ) : super(const CrearNotaState(tipoNota: TipoNota.notaCredito));

  Future<void> inicializar({
    required TipoNota tipoNota,
    required List<CrearNotaItem> itemsOrigen,
  }) async {
    emit(CrearNotaState(
      status: CrearNotaStatus.loadingMotivos,
      tipoNota: tipoNota,
      itemsOrigen: itemsOrigen,
      itemsIncluidos: List<bool>.filled(itemsOrigen.length, true),
    ));

    final result = await _obtenerMotivos(tipoNota);
    if (result is Success) {
      final motivos = (result as Success).data as List;
      emit(state.copyWith(
        status: CrearNotaStatus.formReady,
        motivos: motivos.cast(),
      ));
    } else if (result is Error) {
      emit(state.copyWith(
        status: CrearNotaStatus.error,
        errorMessage: (result as Error).message,
      ));
    }
  }

  void seleccionarMotivo(int codigo) {
    emit(state.copyWith(motivoSeleccionado: codigo, clearError: true));
  }

  void cambiarMotivoTexto(String motivo) {
    emit(state.copyWith(motivo: motivo, clearError: true));
  }

  void cambiarModoItems(bool parciales) {
    emit(state.copyWith(itemsParciales: parciales, clearError: true));
  }

  void toggleItem(int index, bool incluido) {
    final lista = List<bool>.from(state.itemsIncluidos);
    if (index < 0 || index >= lista.length) return;
    lista[index] = incluido;
    emit(state.copyWith(itemsIncluidos: lista, clearError: true));
  }

  void editarCantidad(int index, double cantidad) {
    if (index < 0 || index >= state.itemsOrigen.length) return;
    final mapa = Map<int, double>.from(state.cantidadesEditadas);
    mapa[index] = cantidad;
    emit(state.copyWith(cantidadesEditadas: mapa, clearError: true));
  }

  Future<void> emitir({required String comprobanteOrigenId, required String sedeId}) async {
    if (!state.formValido) {
      emit(state.copyWith(
        status: CrearNotaStatus.error,
        errorMessage: 'Completa el formulario antes de emitir',
      ));
      return;
    }

    final items = state.itemsParciales ? _construirItemsParciales() : null;
    final request = CrearNotaRequest(
      sedeId: sedeId,
      tipoNota: state.motivoSeleccionado!,
      motivo: state.motivo.trim(),
      items: items,
    );

    emit(state.copyWith(status: CrearNotaStatus.submitting, clearError: true));

    final result = state.tipoNota == TipoNota.notaCredito
        ? await _crearNotaCredito(comprobanteOrigenId: comprobanteOrigenId, request: request)
        : await _crearNotaDebito(comprobanteOrigenId: comprobanteOrigenId, request: request);

    if (result is Success) {
      emit(state.copyWith(
        status: CrearNotaStatus.success,
        resultado: (result as Success).data,
      ));
    } else if (result is Error) {
      emit(state.copyWith(
        status: CrearNotaStatus.error,
        errorMessage: (result as Error).message,
      ));
    }
  }

  List<CrearNotaItem> _construirItemsParciales() {
    final result = <CrearNotaItem>[];
    for (var i = 0; i < state.itemsOrigen.length; i++) {
      if (!state.itemsIncluidos[i]) continue;
      final original = state.itemsOrigen[i];
      final cantidadEditada = state.cantidadesEditadas[i];
      if (cantidadEditada != null && cantidadEditada > 0 && cantidadEditada != original.cantidad) {
        final factor = cantidadEditada / original.cantidad;
        result.add(original.copyWith(
          cantidad: cantidadEditada,
          subtotal: (original.subtotal ?? 0) * factor,
          total: (original.total ?? 0) * factor,
          igv: (original.igv ?? 0) * factor,
        ));
      } else {
        result.add(original);
      }
    }
    return result;
  }
}
