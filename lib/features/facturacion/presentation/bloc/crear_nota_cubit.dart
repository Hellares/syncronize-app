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

  // ── Items adicionales (ND con cargo) ──

  void agregarItemAdicional() {
    final lista = List<CrearNotaItem>.from(state.itemsAdicionales);
    // Default: 1 unidad, 0 valor, IGV 18% (gravado)
    lista.add(const CrearNotaItem(
      descripcion: '',
      cantidad: 1,
      valorUnitario: 0,
      precioUnitario: 0,
      tipoAfectacion: '10',
      igv: 0,
      icbper: 0,
      subtotal: 0,
      total: 0,
    ));
    emit(state.copyWith(itemsAdicionales: lista, clearError: true));
  }

  void editarItemAdicional(int index, CrearNotaItem item) {
    if (index < 0 || index >= state.itemsAdicionales.length) return;
    final lista = List<CrearNotaItem>.from(state.itemsAdicionales);
    lista[index] = _recalcularItem(item);
    emit(state.copyWith(itemsAdicionales: lista, clearError: true));
  }

  void eliminarItemAdicional(int index) {
    if (index < 0 || index >= state.itemsAdicionales.length) return;
    final lista = List<CrearNotaItem>.from(state.itemsAdicionales);
    lista.removeAt(index);
    emit(state.copyWith(itemsAdicionales: lista, clearError: true));
  }

  /// Recalcula subtotal/igv/total/precioUnitario desde cantidad+valorUnitario+tipoAfectacion.
  /// Asume IGV 18% para tipoAfectacion='10' (gravado). Otros tipos no llevan IGV.
  CrearNotaItem _recalcularItem(CrearNotaItem item) {
    final cant = item.cantidad;
    final valorU = item.valorUnitario;
    final ta = item.tipoAfectacion ?? '10';
    final subtotal = (cant * valorU * 100).round() / 100;
    final igv = ta == '10' ? (subtotal * 0.18 * 100).round() / 100 : 0.0;
    final icbper = item.icbper ?? 0;
    final total = ((subtotal + igv + icbper) * 100).round() / 100;
    final precioU = cant > 0 ? (total / cant * 100).round() / 100 : 0.0;
    return item.copyWith(
      precioUnitario: precioU,
      subtotal: subtotal,
      igv: igv,
      total: total,
    );
  }

  Future<void> emitir({required String comprobanteOrigenId, required String sedeId}) async {
    if (!state.formValido) {
      emit(state.copyWith(
        status: CrearNotaStatus.error,
        errorMessage: 'Completa el formulario antes de emitir',
      ));
      return;
    }

    // Para ND con items adicionales → mandar esos.
    // Para NC con itemsParciales → mandar lista recortada.
    // Caso contrario → null (backend copia del origen).
    final items = state.esNotaDebito
        ? (state.itemsAdicionales.isNotEmpty ? state.itemsAdicionales : null)
        : (state.itemsParciales ? _construirItemsParciales() : null);
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
