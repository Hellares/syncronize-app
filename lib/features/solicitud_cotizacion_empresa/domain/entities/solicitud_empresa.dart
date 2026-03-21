import 'package:equatable/equatable.dart';

/// Entidad que representa un item dentro de una solicitud de cotizacion
class SolicitudItem extends Equatable {
  final String? id;
  final String descripcion;
  final int cantidad;
  final double? precioReferencia;
  final String? notasItem;
  final bool esManual;
  final String? imagenUrl;

  const SolicitudItem({
    this.id,
    required this.descripcion,
    required this.cantidad,
    this.precioReferencia,
    this.notasItem,
    this.esManual = false,
    this.imagenUrl,
  });

  @override
  List<Object?> get props => [
        id,
        descripcion,
        cantidad,
        precioReferencia,
        notasItem,
        esManual,
        imagenUrl,
      ];
}

/// Informacion basica del solicitante
class Solicitante extends Equatable {
  final String? id;
  final String? nombre;
  final String? email;
  final String? telefono;
  final String? dni;

  const Solicitante({
    this.id,
    this.nombre,
    this.email,
    this.telefono,
    this.dni,
  });

  @override
  List<Object?> get props => [id, nombre, email, telefono, dni];
}

/// Entidad principal que representa una solicitud de cotizacion recibida por la empresa
class SolicitudRecibida extends Equatable {
  final String id;
  final String? codigo;
  final String estado;
  final String? nombreSolicitante;
  final String? emailSolicitante;
  final String? telefonoSolicitante;
  final Solicitante? solicitante;
  final List<SolicitudItem> items;
  final String? observaciones;
  final String? respuestaVendedor;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  const SolicitudRecibida({
    required this.id,
    this.codigo,
    required this.estado,
    this.nombreSolicitante,
    this.emailSolicitante,
    this.telefonoSolicitante,
    this.solicitante,
    this.items = const [],
    this.observaciones,
    this.respuestaVendedor,
    this.creadoEn,
    this.actualizadoEn,
  });

  /// Verifica si la solicitud permite acciones (rechazar / cotizar)
  bool get permiteAcciones =>
      estado == 'PENDIENTE' || estado == 'EN_REVISION';

  /// Cantidad de items manuales
  int get itemsManuales =>
      items.where((i) => i.esManual).length;

  @override
  List<Object?> get props => [
        id,
        codigo,
        estado,
        nombreSolicitante,
        emailSolicitante,
        telefonoSolicitante,
        solicitante,
        items,
        observaciones,
        respuestaVendedor,
        creadoEn,
        actualizadoEn,
      ];
}
