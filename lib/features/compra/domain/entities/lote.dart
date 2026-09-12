// Los valores del enum mapean directamente a los strings del backend
// (`'ACTIVO'`, `'AGOTADO'`, `'VENCIDO'`, `'BLOQUEADO'`). Renombrarlos a
// lowerCamelCase rompería `byName(...)` y comparaciones con strings.
// ignore_for_file: constant_identifier_names

import 'package:equatable/equatable.dart';

import '../../../../core/utils/fecha_calendario.dart' as fc;

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

  /// Días que faltan para el vencimiento, por DÍA de calendario (negativo =
  /// ya pasó, null = no vence). Ver `core/utils/fecha_calendario.dart`: el
  /// envase vale el día entero; compararlo como instante lo daba por vencido
  /// desde la tarde anterior.
  int? get diasParaVencer => fc.diasParaVencer(fechaVencimiento);

  /// Ya pasó el día del envase.
  bool get estaVencido => fc.estaVencido(fechaVencimiento);

  /// Vence dentro de 30 días — o ya venció. Es el filtro de "hay que hacer
  /// algo con este lote".
  bool get proximoAVencer {
    final d = diasParaVencer;
    return d != null && d <= 30;
  }

  @override
  List<Object?> get props => [id, estado, cantidadActual];
}
