import 'package:equatable/equatable.dart';

class PedidoMarketplaceEmpresa extends Equatable {
  final String id;
  final String codigo;
  final String estado;
  final String nombreComprador;
  final String? emailComprador;
  final String? telefonoComprador;
  final double total;
  final String? direccionEnvio;
  final String? referenciaEnvio;
  final String? distritoEnvio;
  final String? provinciaEnvio;
  final String? departamentoEnvio;
  final Map<String, dynamic>? coordenadasEnvio;
  final String? metodoPago;
  final String? comprobantePagoUrl;
  final String? motivoRechazo;
  final String? codigoSeguimiento;
  final List<PedidoItem> detalles;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  const PedidoMarketplaceEmpresa({
    required this.id,
    required this.codigo,
    required this.estado,
    required this.nombreComprador,
    this.emailComprador,
    this.telefonoComprador,
    required this.total,
    this.direccionEnvio,
    this.referenciaEnvio,
    this.distritoEnvio,
    this.provinciaEnvio,
    this.departamentoEnvio,
    this.coordenadasEnvio,
    this.metodoPago,
    this.comprobantePagoUrl,
    this.motivoRechazo,
    this.codigoSeguimiento,
    required this.detalles,
    this.creadoEn,
    this.actualizadoEn,
  });

  bool get requiereAccion => estado == 'PAGO_ENVIADO';

  @override
  List<Object?> get props => [
        id,
        codigo,
        estado,
        nombreComprador,
        emailComprador,
        telefonoComprador,
        total,
        direccionEnvio,
        referenciaEnvio,
        distritoEnvio,
        provinciaEnvio,
        departamentoEnvio,
        coordenadasEnvio,
        metodoPago,
        comprobantePagoUrl,
        motivoRechazo,
        codigoSeguimiento,
        detalles,
        creadoEn,
        actualizadoEn,
      ];
}

class PedidoItem extends Equatable {
  final String productoNombre;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;
  final String? imagenUrl;

  const PedidoItem({
    required this.productoNombre,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    this.imagenUrl,
  });

  @override
  List<Object?> get props => [productoNombre, cantidad, precioUnitario, subtotal, imagenUrl];
}

class ResumenPedidos extends Equatable {
  final int total;
  final int pendientePago;
  final int pagoEnviado;
  final int pagoValidado;
  final int enPreparacion;
  final int enviados;
  final int entregados;
  final int cancelados;
  final int pagoRechazado;

  const ResumenPedidos({
    required this.total,
    required this.pendientePago,
    required this.pagoEnviado,
    required this.pagoValidado,
    required this.enPreparacion,
    required this.enviados,
    required this.entregados,
    required this.cancelados,
    required this.pagoRechazado,
  });

  @override
  List<Object?> get props => [
        total,
        pendientePago,
        pagoEnviado,
        pagoValidado,
        enPreparacion,
        enviados,
        entregados,
        cancelados,
        pagoRechazado,
      ];
}
