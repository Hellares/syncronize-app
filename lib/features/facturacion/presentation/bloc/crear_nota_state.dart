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
    this.resultado,
    this.errorMessage,
  });

  bool get formValido =>
      motivoSeleccionado != null &&
      motivo.trim().length >= 3 &&
      (!itemsParciales || itemsIncluidos.any((v) => v));

  CrearNotaState copyWith({
    CrearNotaStatus? status,
    List<MotivoNota>? motivos,
    int? motivoSeleccionado,
    String? motivo,
    bool? itemsParciales,
    List<CrearNotaItem>? itemsOrigen,
    List<bool>? itemsIncluidos,
    Map<int, double>? cantidadesEditadas,
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
        resultado,
        errorMessage,
      ];
}
