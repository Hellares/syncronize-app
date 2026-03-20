import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Estados posibles de un pedido en el marketplace
enum EstadoPedidoMarketplace {
  pendientePago,
  pagoEnviado,
  pagoValidado,
  enPreparacion,
  enviado,
  entregado,
  cancelado,
  pagoRechazado;

  String get label {
    switch (this) {
      case EstadoPedidoMarketplace.pendientePago:
        return 'Pendiente de Pago';
      case EstadoPedidoMarketplace.pagoEnviado:
        return 'Pago Enviado';
      case EstadoPedidoMarketplace.pagoValidado:
        return 'Pago Validado';
      case EstadoPedidoMarketplace.enPreparacion:
        return 'En Preparacion';
      case EstadoPedidoMarketplace.enviado:
        return 'Enviado';
      case EstadoPedidoMarketplace.entregado:
        return 'Entregado';
      case EstadoPedidoMarketplace.cancelado:
        return 'Cancelado';
      case EstadoPedidoMarketplace.pagoRechazado:
        return 'Pago Rechazado';
    }
  }

  Color get color {
    switch (this) {
      case EstadoPedidoMarketplace.pendientePago:
        return AppColors.orange;
      case EstadoPedidoMarketplace.pagoEnviado:
        return AppColors.blue;
      case EstadoPedidoMarketplace.pagoValidado:
        return AppColors.green;
      case EstadoPedidoMarketplace.enPreparacion:
        return AppColors.blue2;
      case EstadoPedidoMarketplace.enviado:
        return AppColors.blue1;
      case EstadoPedidoMarketplace.entregado:
        return AppColors.greendark;
      case EstadoPedidoMarketplace.cancelado:
        return AppColors.red;
      case EstadoPedidoMarketplace.pagoRechazado:
        return AppColors.red;
    }
  }

  String get apiValue {
    switch (this) {
      case EstadoPedidoMarketplace.pendientePago:
        return 'PENDIENTE_PAGO';
      case EstadoPedidoMarketplace.pagoEnviado:
        return 'PAGO_ENVIADO';
      case EstadoPedidoMarketplace.pagoValidado:
        return 'PAGO_VALIDADO';
      case EstadoPedidoMarketplace.enPreparacion:
        return 'EN_PREPARACION';
      case EstadoPedidoMarketplace.enviado:
        return 'ENVIADO';
      case EstadoPedidoMarketplace.entregado:
        return 'ENTREGADO';
      case EstadoPedidoMarketplace.cancelado:
        return 'CANCELADO';
      case EstadoPedidoMarketplace.pagoRechazado:
        return 'PAGO_RECHAZADO';
    }
  }

  static EstadoPedidoMarketplace fromString(String value) {
    switch (value.toUpperCase()) {
      case 'PENDIENTE_PAGO':
        return EstadoPedidoMarketplace.pendientePago;
      case 'PAGO_ENVIADO':
        return EstadoPedidoMarketplace.pagoEnviado;
      case 'PAGO_VALIDADO':
        return EstadoPedidoMarketplace.pagoValidado;
      case 'EN_PREPARACION':
        return EstadoPedidoMarketplace.enPreparacion;
      case 'ENVIADO':
        return EstadoPedidoMarketplace.enviado;
      case 'ENTREGADO':
        return EstadoPedidoMarketplace.entregado;
      case 'CANCELADO':
        return EstadoPedidoMarketplace.cancelado;
      case 'PAGO_RECHAZADO':
        return EstadoPedidoMarketplace.pagoRechazado;
      default:
        return EstadoPedidoMarketplace.pendientePago;
    }
  }
}

/// Informacion de la empresa asociada al pedido
class EmpresaInfo extends Equatable {
  final String id;
  final String nombre;
  final String? logo;
  final String subdominio;

  const EmpresaInfo({
    required this.id,
    required this.nombre,
    this.logo,
    required this.subdominio,
  });

  @override
  List<Object?> get props => [id, nombre, logo, subdominio];
}

/// Detalle de un item dentro del pedido
class PedidoDetalle extends Equatable {
  final String id;
  final String descripcion;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;
  final String? imagenUrl;

  const PedidoDetalle({
    required this.id,
    required this.descripcion,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    this.imagenUrl,
  });

  @override
  List<Object?> get props => [id, descripcion, cantidad, precioUnitario, subtotal, imagenUrl];
}

/// Entidad principal de un pedido de marketplace
class PedidoMarketplace extends Equatable {
  final String id;
  final String codigo;
  final String compradorId;
  final String empresaId;
  final String nombreComprador;
  final String emailComprador;
  final String? telefonoComprador;
  final String direccionEnvio;
  final double subtotal;
  final double total;
  final String moneda;
  final EstadoPedidoMarketplace estado;
  final String metodoPago;
  final String? comprobantePagoUrl;
  final String? motivoRechazo;
  final DateTime creadoEn;
  final EmpresaInfo empresa;
  final List<PedidoDetalle> detalles;

  const PedidoMarketplace({
    required this.id,
    required this.codigo,
    required this.compradorId,
    required this.empresaId,
    required this.nombreComprador,
    required this.emailComprador,
    this.telefonoComprador,
    required this.direccionEnvio,
    required this.subtotal,
    required this.total,
    required this.moneda,
    required this.estado,
    required this.metodoPago,
    this.comprobantePagoUrl,
    this.motivoRechazo,
    required this.creadoEn,
    required this.empresa,
    required this.detalles,
  });

  /// Etiqueta legible del estado
  String get estadoLabel => estado.label;

  /// Color asociado al estado
  Color get estadoColor => estado.color;

  /// Si puede subir comprobante de pago
  bool get puedeSubirComprobante =>
      estado == EstadoPedidoMarketplace.pendientePago ||
      estado == EstadoPedidoMarketplace.pagoRechazado;

  /// Si puede cancelar el pedido
  bool get puedeCancelar => estado == EstadoPedidoMarketplace.pendientePago;

  /// Si puede confirmar recepcion del pedido
  bool get puedeConfirmarRecepcion => estado == EstadoPedidoMarketplace.enviado;

  @override
  List<Object?> get props => [
        id,
        codigo,
        compradorId,
        empresaId,
        nombreComprador,
        emailComprador,
        telefonoComprador,
        direccionEnvio,
        subtotal,
        total,
        moneda,
        estado,
        metodoPago,
        comprobantePagoUrl,
        motivoRechazo,
        creadoEn,
        empresa,
        detalles,
      ];
}
