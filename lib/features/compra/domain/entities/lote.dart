import 'package:equatable/equatable.dart';

enum EstadoLote {
  ACTIVO,
  AGOTADO,
  VENCIDO,
  BLOQUEADO,
}

class Lote extends Equatable {
  final String id;
  final String empresaId;
  final String sedeId;
  final String productoStockId;
  final String? productoId;
  final String? varianteId;
  final String? compraId;
  final String codigo;
  final String? numeroLote;
  final double precioCosto;
  final String moneda;
  final int cantidadInicial;
  final int cantidadActual;
  final int cantidadReservada;
  final DateTime fechaIngreso;
  final DateTime? fechaProduccion;
  final DateTime? fechaVencimiento;
  final EstadoLote estado;
  final String? proveedorId;
  final String? nombreProveedor;
  final String? observaciones;
  final String creadoPor;
  final DateTime creadoEn;
  final DateTime actualizadoEn;
  final Map<String, dynamic>? productoStock;
  final Map<String, dynamic>? sede;
  final Map<String, dynamic>? proveedor;
  final Map<String, dynamic>? compra;

  const Lote({
    required this.id,
    required this.empresaId,
    required this.sedeId,
    required this.productoStockId,
    this.productoId,
    this.varianteId,
    this.compraId,
    required this.codigo,
    this.numeroLote,
    required this.precioCosto,
    this.moneda = 'PEN',
    required this.cantidadInicial,
    required this.cantidadActual,
    this.cantidadReservada = 0,
    required this.fechaIngreso,
    this.fechaProduccion,
    this.fechaVencimiento,
    this.estado = EstadoLote.ACTIVO,
    this.proveedorId,
    this.nombreProveedor,
    this.observaciones,
    required this.creadoPor,
    required this.creadoEn,
    required this.actualizadoEn,
    this.productoStock,
    this.sede,
    this.proveedor,
    this.compra,
  });

  String get estadoTexto {
    switch (estado) {
      case EstadoLote.ACTIVO:
        return 'Activo';
      case EstadoLote.AGOTADO:
        return 'Agotado';
      case EstadoLote.VENCIDO:
        return 'Vencido';
      case EstadoLote.BLOQUEADO:
        return 'Bloqueado';
    }
  }

  bool get esActivo => estado == EstadoLote.ACTIVO;
  int get cantidadDisponible => cantidadActual - cantidadReservada;
  double get porcentajeConsumido =>
      cantidadInicial > 0 ? ((cantidadInicial - cantidadActual) / cantidadInicial) * 100 : 0;

  String get nombreProducto {
    if (productoStock != null) {
      final variante = productoStock!['variante'];
      final producto = productoStock!['producto'];
      if (variante != null) return variante['nombre'] ?? '';
      if (producto != null) return producto['nombre'] ?? '';
    }
    return '';
  }

  String get codigoProducto {
    if (productoStock != null) {
      final variante = productoStock!['variante'];
      final producto = productoStock!['producto'];
      if (variante != null) return variante['sku'] ?? '';
      if (producto != null) return producto['codigoEmpresa'] ?? '';
    }
    return '';
  }

  bool get proximoAVencer {
    if (fechaVencimiento == null) return false;
    return fechaVencimiento!.difference(DateTime.now()).inDays <= 30;
  }

  @override
  List<Object?> get props => [id, estado, cantidadActual];
}
