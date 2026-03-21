import '../../domain/entities/gasto_caja_chica.dart';

class GastoCajaChicaModel extends GastoCajaChica {
  const GastoCajaChicaModel({
    required super.id,
    required super.cajaChicaId,
    required super.monto,
    required super.descripcion,
    required super.categoriaGastoId,
    required super.categoriaGastoNombre,
    super.categoriaGastoIcono,
    super.categoriaGastoColor,
    super.comprobanteUrl,
    super.rendicionId,
    required super.registradoPorNombre,
    required super.fechaGasto,
  });

  factory GastoCajaChicaModel.fromJson(Map<String, dynamic> json) {
    final categoriaGasto = json['categoriaGasto'] as Map<String, dynamic>?;
    final registradoPor = json['registradoPor'] as Map<String, dynamic>?;

    String registradoPorNombre = '';
    if (registradoPor != null) {
      final persona = registradoPor['persona'] as Map<String, dynamic>?;
      if (persona != null) {
        registradoPorNombre =
            '${persona['nombres'] ?? ''} ${persona['apellidos'] ?? ''}'.trim();
      }
      if (registradoPorNombre.isEmpty) {
        registradoPorNombre = registradoPor['email'] as String? ?? '';
      }
    }
    if (registradoPorNombre.isEmpty) {
      registradoPorNombre = json['registradoPorNombre'] as String? ?? '';
    }

    return GastoCajaChicaModel(
      id: json['id'] as String,
      cajaChicaId: json['cajaChicaId'] as String? ?? '',
      monto: _toDouble(json['monto']),
      descripcion: json['descripcion'] as String? ?? '',
      categoriaGastoId: categoriaGasto?['id'] as String? ??
          json['categoriaGastoId'] as String? ??
          '',
      categoriaGastoNombre: categoriaGasto?['nombre'] as String? ??
          json['categoriaGastoNombre'] as String? ??
          '',
      categoriaGastoIcono: categoriaGasto?['icono'] as String? ??
          json['categoriaGastoIcono'] as String?,
      categoriaGastoColor: categoriaGasto?['color'] as String? ??
          json['categoriaGastoColor'] as String?,
      comprobanteUrl: json['comprobanteUrl'] as String?,
      rendicionId: json['rendicionId'] as String?,
      registradoPorNombre: registradoPorNombre,
      fechaGasto: DateTime.parse(
          json['fechaGasto'] as String? ?? json['createdAt'] as String),
    );
  }

  GastoCajaChica toEntity() => this;

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
