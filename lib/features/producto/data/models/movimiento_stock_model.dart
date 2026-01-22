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
  });

  factory MovimientoStockModel.fromJson(Map<String, dynamic> json) {
    return MovimientoStockModel(
      id: json['id'] as String,
      sedeId: json['sedeId'] as String,
      productoStockId: json['productoStockId'] as String,
      empresaId: json['empresaId'] as String,
      tipo: TipoMovimientoStockExtension.fromString(json['tipo'] as String),
      tipoDocumento: json['tipoDocumento'] as String?,
      numeroDocumento: json['numeroDocumento'] as String?,
      cantidadAnterior: _toInt(json['cantidadAnterior']),
      cantidad: _toInt(json['cantidad']),
      cantidadNueva: _toInt(json['cantidadNueva']),
      motivo: json['motivo'] as String?,
      observaciones: json['observaciones'] as String?,
      transferenciaId: json['transferenciaId'] as String?,
      usuarioId: json['usuarioId'] as String,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.parse(value);
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sedeId': sedeId,
      'productoStockId': productoStockId,
      'empresaId': empresaId,
      'tipo': tipo.value,
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
