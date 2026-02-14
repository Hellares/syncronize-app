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
      cantidadAnterior: toSafeInt(json['cantidadAnterior']),
      cantidad: toSafeInt(json['cantidad']),
      cantidadNueva: toSafeInt(json['cantidadNueva']),
      motivo: json['motivo'] as String?,
      observaciones: json['observaciones'] as String?,
      transferenciaId: json['transferenciaId'] as String?,
      usuarioId: json['usuarioId'] as String,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
    );
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
