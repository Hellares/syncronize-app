import '../../domain/entities/barcode_item.dart';

class BarcodeItemModel {
  final String id;
  final String productoId;
  final String nombre;
  final String? codigoBarras;
  final String? codigoEmpresa;
  final String? sku;
  final double? precio;
  final String? sedeNombre;
  final int stockActual;

  const BarcodeItemModel({
    required this.id,
    required this.productoId,
    required this.nombre,
    this.codigoBarras,
    this.codigoEmpresa,
    this.sku,
    this.precio,
    this.sedeNombre,
    this.stockActual = 0,
  });

  factory BarcodeItemModel.fromJson(Map<String, dynamic> json) {
    return BarcodeItemModel(
      id: json['id'] as String? ?? '',
      productoId: json['productoId'] as String? ?? json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      codigoBarras: json['codigoBarras'] as String?,
      codigoEmpresa: json['codigoEmpresa'] as String?,
      sku: json['sku'] as String?,
      precio: (json['precio'] as num?)?.toDouble(),
      sedeNombre: json['sedeNombre'] as String?,
      stockActual: json['stockActual'] as int? ?? 0,
    );
  }

  BarcodeItem toEntity() {
    return BarcodeItem(
      id: id,
      productoId: productoId,
      nombre: nombre,
      codigoBarras: codigoBarras,
      codigoEmpresa: codigoEmpresa,
      sku: sku,
      precio: precio,
      sedeNombre: sedeNombre,
      stockActual: stockActual,
    );
  }
}

class GenerarCodigosResultModel {
  final int generados;
  final List<CodigoGeneradoModel> resultados;

  const GenerarCodigosResultModel({
    required this.generados,
    required this.resultados,
  });

  factory GenerarCodigosResultModel.fromJson(Map<String, dynamic> json) {
    final resultadosList = json['resultados'] as List<dynamic>? ?? [];
    return GenerarCodigosResultModel(
      generados: json['generados'] as int? ?? 0,
      resultados: resultadosList
          .map((e) => CodigoGeneradoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  GenerarCodigosResult toEntity() {
    return GenerarCodigosResult(
      generados: generados,
      resultados: resultados.map((e) => e.toEntity()).toList(),
    );
  }
}

class CodigoGeneradoModel {
  final String productoId;
  final String? varianteId;
  final String tipo;
  final String codigo;
  final String nombre;

  const CodigoGeneradoModel({
    required this.productoId,
    this.varianteId,
    required this.tipo,
    required this.codigo,
    required this.nombre,
  });

  factory CodigoGeneradoModel.fromJson(Map<String, dynamic> json) {
    return CodigoGeneradoModel(
      productoId: json['productoId'] as String? ?? '',
      varianteId: json['varianteId'] as String?,
      tipo: json['tipo'] as String? ?? '',
      codigo: json['codigo'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
    );
  }

  CodigoGenerado toEntity() {
    return CodigoGenerado(
      productoId: productoId,
      varianteId: varianteId,
      tipo: tipo,
      codigo: codigo,
      nombre: nombre,
    );
  }
}
