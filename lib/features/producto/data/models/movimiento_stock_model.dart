import 'package:syncronize/core/utils/type_converters.dart';
import '../../domain/entities/movimiento_stock.dart';

class MovimientoStockModel extends MovimientoStock {
  const MovimientoStockModel({
    required super.id,
    required super.sedeId,
    required super.productoStockId,
    required super.empresaId,
    required super.tipo,
    super.tipoDocumento,
    super.numeroDocumento,
    required super.cantidadAnterior,
    required super.cantidad,
    required super.cantidadNueva,
    super.motivo,
    super.observaciones,
    super.transferenciaId,
    required super.usuarioId,
    required super.creadoEn,
    super.usuarioNombre,
    super.ventaCodigo,
    super.compraCodigo,
    super.transferenciaCodigo,
    super.devolucionCodigo,
  });

  factory MovimientoStockModel.fromJson(Map<String, dynamic> json) {
    // Parsear nombre del usuario desde la relacion anidada
    String? usuarioNombre;
    final usuario = json['usuario'] as Map<String, dynamic>?;
    if (usuario != null) {
      final persona = usuario['persona'] as Map<String, dynamic>?;
      if (persona != null) {
        final nombres = persona['nombres'] as String? ?? '';
        final apellidos = persona['apellidos'] as String? ?? '';
        usuarioNombre = '$nombres $apellidos'.trim();
        if (usuarioNombre.isEmpty) usuarioNombre = null;
      }
    }

    // Parsear codigos de documentos relacionados
    final venta = json['venta'] as Map<String, dynamic>?;
    final compra = json['compra'] as Map<String, dynamic>?;
    final transferencia = json['transferencia'] as Map<String, dynamic>?;
    final devolucion = json['devolucion'] as Map<String, dynamic>?;

    return MovimientoStockModel(
      id: json['id'] as String,
      sedeId: json['sedeId'] as String,
      productoStockId: json['productoStockId'] as String,
      empresaId: json['empresaId'] as String,
      tipo: TipoMovimientoStock.fromString(json['tipo'] as String),
      tipoDocumento: json['tipoDocumento'] as String?,
      numeroDocumento: json['numeroDocumento'] as String?,
      cantidadAnterior: toSafeInt(json['cantidadAnterior']),
      cantidad: toSafeInt(json['cantidad']),
      cantidadNueva: toSafeInt(json['cantidadNueva']),
      motivo: json['motivo'] as String?,
      observaciones: json['observaciones'] as String?,
      transferenciaId: json['transferenciaId'] as String?,
      usuarioId: json['usuarioId'] as String,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      usuarioNombre: usuarioNombre,
      ventaCodigo: venta?['codigo'] as String?,
      compraCodigo: compra?['codigo'] as String?,
      transferenciaCodigo: transferencia?['codigo'] as String?,
      devolucionCodigo: devolucion?['codigo'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sedeId': sedeId,
      'productoStockId': productoStockId,
      'empresaId': empresaId,
      'tipo': tipo.apiValue,
      if (tipoDocumento != null) 'tipoDocumento': tipoDocumento,
      if (numeroDocumento != null) 'numeroDocumento': numeroDocumento,
      'cantidadAnterior': cantidadAnterior,
      'cantidad': cantidad,
      'cantidadNueva': cantidadNueva,
      if (motivo != null) 'motivo': motivo,
      if (observaciones != null) 'observaciones': observaciones,
      if (transferenciaId != null) 'transferenciaId': transferenciaId,
      'usuarioId': usuarioId,
      'creadoEn': creadoEn.toIso8601String(),
    };
  }
}

class KardexResumenItemModel extends KardexResumenItem {
  const KardexResumenItemModel({
    required super.tipo,
    required super.totalCantidad,
    required super.totalMovimientos,
  });

  factory KardexResumenItemModel.fromJson(Map<String, dynamic> json) {
    return KardexResumenItemModel(
      tipo: json['tipo'] as String? ?? '',
      totalCantidad: toSafeInt(json['totalCantidad']),
      totalMovimientos: toSafeInt(json['totalMovimientos']),
    );
  }
}
