import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Tipo de movimiento de stock - 28 tipos que mapean al backend
enum TipoMovimientoStock {
  // Compras
  entradaCompra,
  salidaDevolucionProveedor,
  ajusteEntradaCompra,
  // Ventas
  salidaVenta,
  entradaDevolucionCliente,
  ajusteSalidaVenta,
  reservaVenta,
  liberarReservaVenta,
  reservaCombo,
  liberarReservaCombo,
  // Transferencias
  entradaTransferencia,
  salidaTransferencia,
  // Ajustes inventario
  ajusteEntrada,
  ajusteSalida,
  ajusteMerma,
  ajusteReparacion,
  ajustePerdida,
  ajusteEncontrado,
  salidaBaja,
  // Garantia
  entradaGarantia,
  salidaGarantia,
  retornoGarantia,
  // Legacy (mantener para compatibilidad)
  entradaAjuste,
  salidaAjuste,
  entradaDevolucion,
  salidaMerma,
  salidaRobo,
  salidaDonacion;

  /// Nombre legible en espanol
  String get label {
    switch (this) {
      case entradaCompra:
        return 'Entrada por compra';
      case salidaDevolucionProveedor:
        return 'Devolucion a proveedor';
      case ajusteEntradaCompra:
        return 'Ajuste entrada compra';
      case salidaVenta:
        return 'Salida por venta';
      case entradaDevolucionCliente:
        return 'Devolucion de cliente';
      case ajusteSalidaVenta:
        return 'Ajuste salida venta';
      case reservaVenta:
        return 'Reserva para venta';
      case liberarReservaVenta:
        return 'Liberar reserva venta';
      case reservaCombo:
        return 'Reserva para combo';
      case liberarReservaCombo:
        return 'Liberar reserva combo';
      case entradaTransferencia:
        return 'Entrada por transferencia';
      case salidaTransferencia:
        return 'Salida por transferencia';
      case ajusteEntrada:
        return 'Ajuste de entrada';
      case ajusteSalida:
        return 'Ajuste de salida';
      case ajusteMerma:
        return 'Merma / Danado';
      case ajusteReparacion:
        return 'Reparacion';
      case ajustePerdida:
        return 'Perdida';
      case ajusteEncontrado:
        return 'Encontrado';
      case salidaBaja:
        return 'Baja definitiva';
      case entradaGarantia:
        return 'Entrada en garantia';
      case salidaGarantia:
        return 'Salida a garantia';
      case retornoGarantia:
        return 'Retorno de garantia';
      case entradaAjuste:
        return 'Entrada ajuste';
      case salidaAjuste:
        return 'Salida ajuste';
      case entradaDevolucion:
        return 'Entrada devolucion';
      case salidaMerma:
        return 'Salida merma';
      case salidaRobo:
        return 'Salida robo';
      case salidaDonacion:
        return 'Donacion';
    }
  }

  /// Valor que se envia/recibe del backend
  String get apiValue {
    switch (this) {
      case entradaCompra:
        return 'ENTRADA_COMPRA';
      case salidaDevolucionProveedor:
        return 'SALIDA_DEVOLUCION_PROVEEDOR';
      case ajusteEntradaCompra:
        return 'AJUSTE_ENTRADA_COMPRA';
      case salidaVenta:
        return 'SALIDA_VENTA';
      case entradaDevolucionCliente:
        return 'ENTRADA_DEVOLUCION_CLIENTE';
      case ajusteSalidaVenta:
        return 'AJUSTE_SALIDA_VENTA';
      case reservaVenta:
        return 'RESERVA_VENTA';
      case liberarReservaVenta:
        return 'LIBERAR_RESERVA_VENTA';
      case reservaCombo:
        return 'RESERVA_COMBO';
      case liberarReservaCombo:
        return 'LIBERAR_RESERVA_COMBO';
      case entradaTransferencia:
        return 'ENTRADA_TRANSFERENCIA';
      case salidaTransferencia:
        return 'SALIDA_TRANSFERENCIA';
      case ajusteEntrada:
        return 'AJUSTE_ENTRADA';
      case ajusteSalida:
        return 'AJUSTE_SALIDA';
      case ajusteMerma:
        return 'AJUSTE_MERMA';
      case ajusteReparacion:
        return 'AJUSTE_REPARACION';
      case ajustePerdida:
        return 'AJUSTE_PERDIDA';
      case ajusteEncontrado:
        return 'AJUSTE_ENCONTRADO';
      case salidaBaja:
        return 'SALIDA_BAJA';
      case entradaGarantia:
        return 'ENTRADA_GARANTIA';
      case salidaGarantia:
        return 'SALIDA_GARANTIA';
      case retornoGarantia:
        return 'RETORNO_GARANTIA';
      case entradaAjuste:
        return 'ENTRADA_AJUSTE';
      case salidaAjuste:
        return 'SALIDA_AJUSTE';
      case entradaDevolucion:
        return 'ENTRADA_DEVOLUCION';
      case salidaMerma:
        return 'SALIDA_MERMA';
      case salidaRobo:
        return 'SALIDA_ROBO';
      case salidaDonacion:
        return 'SALIDA_DONACION';
    }
  }

  /// true si el movimiento suma stock
  bool get esEntrada {
    switch (this) {
      case entradaCompra:
      case ajusteEntradaCompra:
      case entradaDevolucionCliente:
      case liberarReservaVenta:
      case liberarReservaCombo:
      case entradaTransferencia:
      case ajusteEntrada:
      case ajusteReparacion:
      case ajusteEncontrado:
      case entradaGarantia:
      case retornoGarantia:
      case entradaAjuste:
      case entradaDevolucion:
        return true;
      default:
        return false;
    }
  }

  /// true si el movimiento resta stock
  bool get esSalida => !esEntrada;

  /// Icono representativo del tipo de movimiento
  IconData get icon {
    switch (this) {
      // Entradas
      case entradaCompra:
      case ajusteEntradaCompra:
      case entradaDevolucionCliente:
      case liberarReservaVenta:
      case liberarReservaCombo:
      case ajusteEntrada:
      case ajusteReparacion:
      case ajusteEncontrado:
      case entradaGarantia:
      case retornoGarantia:
      case entradaAjuste:
      case entradaDevolucion:
        return Icons.arrow_downward;
      // Salidas
      case salidaVenta:
      case salidaDevolucionProveedor:
      case ajusteSalidaVenta:
      case reservaVenta:
      case reservaCombo:
      case ajusteSalida:
      case ajusteMerma:
      case ajustePerdida:
      case salidaBaja:
      case salidaGarantia:
      case salidaAjuste:
      case salidaMerma:
      case salidaRobo:
      case salidaDonacion:
        return Icons.arrow_upward;
      // Transferencias
      case entradaTransferencia:
      case salidaTransferencia:
        return Icons.swap_horiz;
    }
  }

  /// Color representativo del tipo de movimiento
  Color get color {
    switch (this) {
      // Entradas - verde
      case entradaCompra:
      case ajusteEntradaCompra:
      case entradaDevolucionCliente:
      case liberarReservaVenta:
      case liberarReservaCombo:
      case ajusteEntrada:
      case ajusteEncontrado:
      case entradaAjuste:
      case entradaDevolucion:
        return Colors.green;
      // Salidas - rojo
      case salidaVenta:
      case salidaDevolucionProveedor:
      case reservaVenta:
      case reservaCombo:
      case salidaBaja:
      case salidaAjuste:
      case salidaRobo:
      case salidaDonacion:
        return Colors.red;
      // Ajustes - naranja
      case ajusteSalidaVenta:
      case ajusteSalida:
      case ajusteMerma:
      case ajusteReparacion:
      case ajustePerdida:
      case salidaMerma:
        return Colors.orange;
      // Transferencias - azul
      case entradaTransferencia:
      case salidaTransferencia:
        return Colors.blue;
      // Garantia - morado
      case entradaGarantia:
      case salidaGarantia:
      case retornoGarantia:
        return Colors.purple;
    }
  }

  /// Factory para crear desde un string del backend
  static TipoMovimientoStock fromString(String value) {
    switch (value.toUpperCase()) {
      case 'ENTRADA_COMPRA':
        return entradaCompra;
      case 'SALIDA_DEVOLUCION_PROVEEDOR':
        return salidaDevolucionProveedor;
      case 'AJUSTE_ENTRADA_COMPRA':
        return ajusteEntradaCompra;
      case 'SALIDA_VENTA':
        return salidaVenta;
      case 'ENTRADA_DEVOLUCION_CLIENTE':
        return entradaDevolucionCliente;
      case 'AJUSTE_SALIDA_VENTA':
        return ajusteSalidaVenta;
      case 'RESERVA_VENTA':
        return reservaVenta;
      case 'LIBERAR_RESERVA_VENTA':
        return liberarReservaVenta;
      case 'RESERVA_COMBO':
        return reservaCombo;
      case 'LIBERAR_RESERVA_COMBO':
        return liberarReservaCombo;
      case 'ENTRADA_TRANSFERENCIA':
        return entradaTransferencia;
      case 'SALIDA_TRANSFERENCIA':
        return salidaTransferencia;
      case 'AJUSTE_ENTRADA':
        return ajusteEntrada;
      case 'AJUSTE_SALIDA':
        return ajusteSalida;
      case 'AJUSTE_MERMA':
        return ajusteMerma;
      case 'AJUSTE_REPARACION':
        return ajusteReparacion;
      case 'AJUSTE_PERDIDA':
        return ajustePerdida;
      case 'AJUSTE_ENCONTRADO':
        return ajusteEncontrado;
      case 'SALIDA_BAJA':
        return salidaBaja;
      case 'ENTRADA_GARANTIA':
        return entradaGarantia;
      case 'SALIDA_GARANTIA':
        return salidaGarantia;
      case 'RETORNO_GARANTIA':
        return retornoGarantia;
      case 'ENTRADA_AJUSTE':
        return entradaAjuste;
      case 'SALIDA_AJUSTE':
        return salidaAjuste;
      case 'ENTRADA_DEVOLUCION':
        return entradaDevolucion;
      case 'SALIDA_MERMA':
        return salidaMerma;
      case 'SALIDA_ROBO':
        return salidaRobo;
      case 'SALIDA_DONACION':
        return salidaDonacion;
      default:
        return ajusteEntrada; // fallback
    }
  }
}

/// Entity para MovimientoStock - Historial de movimientos de inventario
class MovimientoStock extends Equatable {
  final String id;
  final String sedeId;
  final String productoStockId;
  final String empresaId;
  final TipoMovimientoStock tipo;
  final String? tipoDocumento;
  final String? numeroDocumento;
  final int cantidadAnterior;
  final int cantidad; // Positivo = entrada, Negativo = salida
  final int cantidadNueva;
  final String? motivo;
  final String? observaciones;
  final String? transferenciaId;
  final String usuarioId;
  final DateTime creadoEn;
  // Campos enriquecidos del backend
  final String? usuarioNombre;
  final String? ventaCodigo;
  final String? compraCodigo;
  final String? transferenciaCodigo;
  final String? devolucionCodigo;

  const MovimientoStock({
    required this.id,
    required this.sedeId,
    required this.productoStockId,
    required this.empresaId,
    required this.tipo,
    this.tipoDocumento,
    this.numeroDocumento,
    required this.cantidadAnterior,
    required this.cantidad,
    required this.cantidadNueva,
    this.motivo,
    this.observaciones,
    this.transferenciaId,
    required this.usuarioId,
    required this.creadoEn,
    this.usuarioNombre,
    this.ventaCodigo,
    this.compraCodigo,
    this.transferenciaCodigo,
    this.devolucionCodigo,
  });

  @override
  List<Object?> get props => [
        id,
        sedeId,
        productoStockId,
        empresaId,
        tipo,
        tipoDocumento,
        numeroDocumento,
        cantidadAnterior,
        cantidad,
        cantidadNueva,
        motivo,
        observaciones,
        transferenciaId,
        usuarioId,
        creadoEn,
        usuarioNombre,
        ventaCodigo,
        compraCodigo,
        transferenciaCodigo,
        devolucionCodigo,
      ];

  /// Verifica si es un movimiento de entrada
  bool get esEntrada => tipo.esEntrada;

  /// Verifica si es un movimiento de salida
  bool get esSalida => tipo.esSalida;

  /// Retorna la cantidad absoluta del movimiento
  int get cantidadAbsoluta => cantidad.abs();

  /// Retorna el codigo de documento asociado (si hay alguno)
  String? get documentoReferencia =>
      ventaCodigo ?? compraCodigo ?? transferenciaCodigo ?? devolucionCodigo;
}

/// Datos completos del Kardex: movimientos + resumen
class KardexData {
  final List<MovimientoStock> movimientos;
  final List<KardexResumenItem> resumen;

  const KardexData({required this.movimientos, required this.resumen});
}

/// Item de resumen agrupado por tipo de movimiento
class KardexResumenItem {
  final String tipo;
  final int totalCantidad;
  final int totalMovimientos;

  const KardexResumenItem({
    required this.tipo,
    required this.totalCantidad,
    required this.totalMovimientos,
  });
}
