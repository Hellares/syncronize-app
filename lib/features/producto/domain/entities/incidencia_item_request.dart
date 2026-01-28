import 'package:equatable/equatable.dart';
import 'transferencia_incidencia.dart';

/// DTO para reportar una incidencia individual en un item
class IncidenciaItemRequest extends Equatable {
  final TipoIncidenciaTransferencia tipo;
  final int cantidadAfectada;
  final String? descripcion;
  final List<String> evidenciasUrls;

  const IncidenciaItemRequest({
    required this.tipo,
    required this.cantidadAfectada,
    this.descripcion,
    this.evidenciasUrls = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'tipo': tipo.value,
      'cantidadAfectada': cantidadAfectada,
      if (descripcion != null) 'descripcion': descripcion,
      if (evidenciasUrls.isNotEmpty) 'evidenciasUrls': evidenciasUrls,
    };
  }

  @override
  List<Object?> get props => [tipo, cantidadAfectada, descripcion, evidenciasUrls];
}

/// DTO para recibir un item individual con sus incidencias
class RecibirItemRequest extends Equatable {
  final String itemId;
  final int cantidadRecibidaBuenEstado;
  final List<IncidenciaItemRequest> incidencias;
  final String? ubicacion;
  final String? observaciones;

  const RecibirItemRequest({
    required this.itemId,
    required this.cantidadRecibidaBuenEstado,
    this.incidencias = const [],
    this.ubicacion,
    this.observaciones,
  });

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'cantidadRecibidaBuenEstado': cantidadRecibidaBuenEstado,
      if (incidencias.isNotEmpty)
        'incidencias': incidencias.map((i) => i.toJson()).toList(),
      if (ubicacion != null) 'ubicacion': ubicacion,
      if (observaciones != null) 'observaciones': observaciones,
    };
  }

  /// Total de productos afectados por incidencias
  int get totalAfectado =>
      incidencias.fold(0, (sum, inc) => sum + inc.cantidadAfectada);

  /// Total que llegó físicamente (buenos + dañados)
  int get totalRecibidoFisicamente => cantidadRecibidaBuenEstado + totalAfectado;

  /// Indica si tiene incidencias reportadas
  bool get tieneIncidencias => incidencias.isNotEmpty;

  /// Cantidad de incidencias reportadas
  int get cantidadIncidencias => incidencias.length;

  @override
  List<Object?> get props => [
        itemId,
        cantidadRecibidaBuenEstado,
        incidencias,
        ubicacion,
        observaciones,
      ];
}

/// Request principal para recibir transferencia con incidencias
class RecibirTransferenciaConIncidenciasRequest extends Equatable {
  final List<RecibirItemRequest> items;
  final String? observacionesGenerales;
  final bool marcarComoCompletada;

  const RecibirTransferenciaConIncidenciasRequest({
    required this.items,
    this.observacionesGenerales,
    this.marcarComoCompletada = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((i) => i.toJson()).toList(),
      if (observacionesGenerales != null)
        'observacionesGenerales': observacionesGenerales,
      'marcarComoCompletada': marcarComoCompletada,
    };
  }

  /// Total de incidencias reportadas en toda la transferencia
  int get totalIncidencias =>
      items.fold(0, (sum, item) => sum + item.cantidadIncidencias);

  /// Total de items a recibir
  int get totalItems => items.length;

  /// Items con incidencias
  List<RecibirItemRequest> get itemsConIncidencias =>
      items.where((item) => item.tieneIncidencias).toList();

  /// Items sin incidencias (recepción normal)
  List<RecibirItemRequest> get itemsSinIncidencias =>
      items.where((item) => !item.tieneIncidencias).toList();

  @override
  List<Object?> get props => [items, observacionesGenerales, marcarComoCompletada];
}

/// Request para resolver una incidencia
class ResolverIncidenciaRequest extends Equatable {
  final AccionResolucionIncidencia accion;
  final String? observaciones;

  const ResolverIncidenciaRequest({
    required this.accion,
    this.observaciones,
  });

  Map<String, dynamic> toJson() {
    return {
      'accion': accion.value,
      if (observaciones != null) 'observaciones': observaciones,
    };
  }

  @override
  List<Object?> get props => [accion, observaciones];
}
