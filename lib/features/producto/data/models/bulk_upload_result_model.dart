import '../../domain/entities/bulk_upload_result.dart';

class BulkUploadResultModel {
  final int totalFilas;
  final int creados;
  final int errores;
  final List<RowError> detalleErrores;
  final List<CreatedProductSummary> productosCreados;

  BulkUploadResultModel({
    required this.totalFilas,
    required this.creados,
    required this.errores,
    required this.detalleErrores,
    required this.productosCreados,
  });

  factory BulkUploadResultModel.fromJson(Map<String, dynamic> json) {
    return BulkUploadResultModel(
      totalFilas: json['totalFilas'] as int? ?? 0,
      creados: json['creados'] as int? ?? 0,
      errores: json['errores'] as int? ?? 0,
      detalleErrores: (json['detalleErrores'] as List<dynamic>?)
              ?.map((e) => RowError(
                    fila: e['fila'] as int? ?? 0,
                    columna: e['columna'] as String? ?? '',
                    valor: (e['valor'] ?? '').toString(),
                    mensaje: e['mensaje'] as String? ?? '',
                  ))
              .toList() ??
          [],
      productosCreados: (json['productosCreados'] as List<dynamic>?)
              ?.map((e) => CreatedProductSummary(
                    id: e['id'] as String? ?? '',
                    nombre: e['nombre'] as String? ?? '',
                    codigoEmpresa: e['codigoEmpresa'] as String? ?? '',
                  ))
              .toList() ??
          [],
    );
  }

  BulkUploadResult toEntity() {
    return BulkUploadResult(
      totalFilas: totalFilas,
      creados: creados,
      errores: errores,
      detalleErrores: detalleErrores,
      productosCreados: productosCreados,
    );
  }
}
