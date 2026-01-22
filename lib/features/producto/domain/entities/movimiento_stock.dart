import 'package:equatable/equatable.dart';

/// Tipo de movimiento de stock
enum TipoMovimientoStock {
  entradaCompra('ENTRADA_COMPRA', 'Entrada por compra'),
  entradaTransferencia('ENTRADA_TRANSFERENCIA', 'Entrada por transferencia'),
  entradaAjuste('ENTRADA_AJUSTE', 'Ajuste de inventario (entrada)'),
  entradaDevolucion('ENTRADA_DEVOLUCION', 'Devolución de cliente'),
  salidaVenta('SALIDA_VENTA', 'Salida por venta'),
  salidaTransferencia('SALIDA_TRANSFERENCIA', 'Salida por transferencia'),
  salidaAjuste('SALIDA_AJUSTE', 'Ajuste de inventario (salida)'),
  salidaMerma('SALIDA_MERMA', 'Merma o pérdida'),
  salidaRobo('SALIDA_ROBO', 'Robo'),
  salidaDonacion('SALIDA_DONACION', 'Donación');

  final String value;
  final String descripcion;

  const TipoMovimientoStock(this.value, this.descripcion);

  bool get esEntrada => value.startsWith('ENTRADA');
  bool get esSalida => value.startsWith('SALIDA');
}

extension TipoMovimientoStockExtension on TipoMovimientoStock {
  static TipoMovimientoStock fromString(String value) {
    return TipoMovimientoStock.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TipoMovimientoStock.entradaAjuste,
    );
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
      ];

  /// Verifica si es un movimiento de entrada
  bool get esEntrada => tipo.esEntrada;

  /// Verifica si es un movimiento de salida
  bool get esSalida => tipo.esSalida;

  /// Retorna la cantidad absoluta del movimiento
  int get cantidadAbsoluta => cantidad.abs();
}
