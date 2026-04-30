import 'package:equatable/equatable.dart';
import '../../domain/entities/crear_nota_item.dart';
import '../../domain/entities/motivo_nota.dart';
import '../../domain/entities/nota_emitida.dart';
import '../../domain/entities/tipo_nota.dart';

enum CrearNotaStatus {
  initial,
  loadingMotivos,
  formReady,
  submitting,
  success,
  error,
}

/// Motivos ND (cat. SUNAT 10) que obligatoriamente deben llevar al menos
/// 1 ítem adicional con el monto del cargo. Los motivos 10/11 (ajustes)
/// quedan opcionales.
const Set<int> _motivosNDRequierenItems = {1, 2, 3};

class CrearNotaState extends Equatable {
  final CrearNotaStatus status;
  final TipoNota tipoNota;
  final List<MotivoNota> motivos;
  final int? motivoSeleccionado;
  final String motivo;

  /// Si false, copia completa del comprobante origen.
  /// Si true, usa [items] enviado por el usuario.
  final bool itemsParciales;

  /// Items origen del comprobante (display y base para parciales).
  final List<CrearNotaItem> itemsOrigen;

  /// Items efectivos a enviar (cuando itemsParciales = true).
  /// Cada flag indica si el item de [itemsOrigen] en esa posición está incluido.
  final List<bool> itemsIncluidos;

  /// Cantidades editadas por item (índice → cantidad). Solo aplica con itemsParciales.
  final Map<int, double> cantidadesEditadas;

  /// Items adicionales para ND (cargo adicional, intereses, ajustes de valor).
  /// Solo se envían cuando tipoNota = NotaDebito.
  /// Si está vacío, el backend copia los items del comprobante origen (caso ajustes IGV puro).
  final List<CrearNotaItem> itemsAdicionales;

  final NotaEmitida? resultado;
  final String? errorMessage;

  const CrearNotaState({
    this.status = CrearNotaStatus.initial,
    required this.tipoNota,
    this.motivos = const [],
    this.motivoSeleccionado,
    this.motivo = '',
    this.itemsParciales = false,
    this.itemsOrigen = const [],
    this.itemsIncluidos = const [],
    this.cantidadesEditadas = const {},
    this.itemsAdicionales = const [],
    this.resultado,
    this.errorMessage,
  });

  bool get esNotaDebito => tipoNota == TipoNota.notaDebito;

  /// True si el motivo ND seleccionado obliga a indicar items adicionales
  /// (intereses 01, aumento 02, penalidades 03). Para 10/11 es opcional.
  bool get motivoNDRequiereItems =>
      esNotaDebito &&
      motivoSeleccionado != null &&
      _motivosNDRequierenItems.contains(motivoSeleccionado);

  /// Validación de items adicionales (ND): cada uno debe tener descripción
  /// y montos numéricos > 0.
  bool get _itemsAdicionalesValidos {
    if (itemsAdicionales.isEmpty) return true;
    for (final it in itemsAdicionales) {
      if (it.descripcion.trim().isEmpty) return false;
      if (it.cantidad <= 0) return false;
      if (it.valorUnitario < 0) return false;
    }
    return true;
  }

  bool get formValido {
    if (motivoSeleccionado == null) return false;
    if (motivo.trim().length < 3) return false;
    if (esNotaDebito) {
      // Motivos 01/02/03 obligan al menos 1 item con monto.
      if (motivoNDRequiereItems && itemsAdicionales.isEmpty) return false;
      return _itemsAdicionalesValidos;
    }
    // NC: si parciales, al menos un item incluido
    return !itemsParciales || itemsIncluidos.any((v) => v);
  }

  CrearNotaState copyWith({
    CrearNotaStatus? status,
    List<MotivoNota>? motivos,
    int? motivoSeleccionado,
    String? motivo,
    bool? itemsParciales,
    List<CrearNotaItem>? itemsOrigen,
    List<bool>? itemsIncluidos,
    Map<int, double>? cantidadesEditadas,
    List<CrearNotaItem>? itemsAdicionales,
    NotaEmitida? resultado,
    String? errorMessage,
    bool clearError = false,
    bool clearResultado = false,
  }) {
    return CrearNotaState(
      status: status ?? this.status,
      tipoNota: tipoNota,
      motivos: motivos ?? this.motivos,
      motivoSeleccionado: motivoSeleccionado ?? this.motivoSeleccionado,
      motivo: motivo ?? this.motivo,
      itemsParciales: itemsParciales ?? this.itemsParciales,
      itemsOrigen: itemsOrigen ?? this.itemsOrigen,
      itemsIncluidos: itemsIncluidos ?? this.itemsIncluidos,
      cantidadesEditadas: cantidadesEditadas ?? this.cantidadesEditadas,
      itemsAdicionales: itemsAdicionales ?? this.itemsAdicionales,
      resultado: clearResultado ? null : (resultado ?? this.resultado),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        tipoNota,
        motivos,
        motivoSeleccionado,
        motivo,
        itemsParciales,
        itemsOrigen,
        itemsIncluidos,
        cantidadesEditadas,
        itemsAdicionales,
        resultado,
        errorMessage,
      ];
}
