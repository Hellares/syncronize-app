import '../../domain/entities/rendicion_caja_chica.dart';
import '../../domain/entities/gasto_caja_chica.dart';
import 'gasto_caja_chica_model.dart';

class RendicionCajaChicaModel extends RendicionCajaChica {
  const RendicionCajaChicaModel({
    required super.id,
    required super.cajaChicaId,
    required super.cajaChicaNombre,
    required super.codigo,
    required super.totalGastado,
    required super.estado,
    super.observaciones,
    super.aprobadoPorNombre,
    required super.creadoEn,
    super.gastos,
  });

  factory RendicionCajaChicaModel.fromJson(Map<String, dynamic> json) {
    final cajaChica = json['cajaChica'] as Map<String, dynamic>?;
    final aprobadoPor = json['aprobadoPor'] as Map<String, dynamic>?;

    String? aprobadoPorNombre;
    if (aprobadoPor != null) {
      final persona = aprobadoPor['persona'] as Map<String, dynamic>?;
      if (persona != null) {
        aprobadoPorNombre =
            '${persona['nombres'] ?? ''} ${persona['apellidos'] ?? ''}'.trim();
      }
      if (aprobadoPorNombre == null || aprobadoPorNombre.isEmpty) {
        aprobadoPorNombre = aprobadoPor['email'] as String?;
      }
    }
    if (aprobadoPorNombre == null || aprobadoPorNombre.isEmpty) {
      aprobadoPorNombre = json['aprobadoPorNombre'] as String?;
    }

    final gastosJson = json['gastos'] as List<dynamic>?;
    final gastos = gastosJson
            ?.map((e) =>
                GastoCajaChicaModel.fromJson(e as Map<String, dynamic>)
                    .toEntity())
            .toList() ??
        <GastoCajaChica>[];

    return RendicionCajaChicaModel(
      id: json['id'] as String,
      cajaChicaId: json['cajaChicaId'] as String? ?? '',
      cajaChicaNombre: cajaChica?['nombre'] as String? ??
          json['cajaChicaNombre'] as String? ??
          '',
      codigo: json['codigo'] as String? ?? '',
      totalGastado: _toDouble(json['totalGastado']),
      estado:
          EstadoRendicion.fromString(json['estado'] as String? ?? ''),
      observaciones: json['observaciones'] as String?,
      aprobadoPorNombre: aprobadoPorNombre,
      creadoEn: DateTime.parse(
          json['creadoEn'] as String? ?? json['createdAt'] as String),
      gastos: gastos,
    );
  }

  RendicionCajaChica toEntity() => this;

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
