import '../../domain/entities/gasto_recurrente.dart';

class GastoRecurrenteModel extends GastoRecurrente {
  const GastoRecurrenteModel({
    required super.id,
    required super.empresaId,
    super.sedeId,
    super.sedeNombre,
    required super.nombre,
    required super.categoriaGastoId,
    required super.categoriaGastoNombre,
    super.categoriaGastoIcono,
    super.categoriaGastoColor,
    super.proveedorId,
    super.proveedorNombre,
    super.proveedorDocumento,
    required super.montoEstimado,
    required super.frecuencia,
    required super.diaVencimiento,
    required super.activo,
    super.ultimoPagoEn,
    super.notas,
  });

  factory GastoRecurrenteModel.fromJson(Map<String, dynamic> json) {
    final cat = json['categoriaGasto'] as Map<String, dynamic>?;
    final sede = json['sede'] as Map<String, dynamic>?;
    final prov = json['proveedor'] as Map<String, dynamic>?;

    return GastoRecurrenteModel(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String? ?? '',
      sedeId: json['sedeId'] as String?,
      sedeNombre: sede?['nombre'] as String?,
      nombre: json['nombre'] as String? ?? '',
      categoriaGastoId: json['categoriaGastoId'] as String? ?? '',
      categoriaGastoNombre: cat?['nombre'] as String? ?? '',
      categoriaGastoIcono: cat?['icono'] as String?,
      categoriaGastoColor: cat?['color'] as String?,
      proveedorId: json['proveedorId'] as String?,
      proveedorNombre: prov?['nombre'] as String?,
      proveedorDocumento: prov?['numeroDocumento'] as String?,
      montoEstimado: _toDouble(json['montoEstimado']),
      frecuencia: FrecuenciaGasto.fromString(json['frecuencia'] as String? ?? ''),
      diaVencimiento: _toInt(json['diaVencimiento']),
      activo: json['activo'] as bool? ?? true,
      ultimoPagoEn: _toDateTime(json['ultimoPagoEn']),
      notas: json['notas'] as String?,
    );
  }

  GastoRecurrente toEntity() => this;

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static DateTime? _toDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }
}
