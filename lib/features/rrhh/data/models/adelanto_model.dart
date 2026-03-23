import '../../domain/entities/adelanto.dart';

class AdelantoModel extends Adelanto {
  const AdelantoModel({
    required super.id,
    required super.empleadoId,
    required super.empresaId,
    required super.monto,
    super.motivo,
    required super.fechaSolicitud,
    super.estado,
    super.aprobadoPorId,
    super.fechaAprobacion,
    super.metodoPago,
    super.pagadoPorId,
    super.motivoRechazo,
    super.empleadoNombre,
    super.empleadoCodigo,
    super.empleadoCargo,
    super.empleadoDni,
    super.aprobadoPorNombre,
  });

  factory AdelantoModel.fromJson(Map<String, dynamic> json) {
    final empleado = json['empleado'] as Map<String, dynamic>?;
    final usuario = empleado?['usuario'] as Map<String, dynamic>?;
    final persona = usuario?['persona'] as Map<String, dynamic>?;

    String? empleadoNombre;
    if (persona != null) {
      final nombres = persona['nombres'] as String? ?? '';
      final apellidos = persona['apellidos'] as String? ?? '';
      empleadoNombre = '$nombres $apellidos'.trim();
    }

    // Aprobador
    final aprobadoPor = json['aprobadoPor'] as Map<String, dynamic>?;
    String? aprobadoPorNombre;
    if (aprobadoPor != null) {
      final apPersona = aprobadoPor['persona'] as Map<String, dynamic>?;
      if (apPersona != null) {
        final n = apPersona['nombres'] as String? ?? '';
        final a = apPersona['apellidos'] as String? ?? '';
        aprobadoPorNombre = '$n $a'.trim();
      }
    }

    return AdelantoModel(
      id: json['id'] as String,
      empleadoId: json['empleadoId'] as String? ?? '',
      empresaId: json['empresaId'] as String? ?? '',
      monto: _toDouble(json['monto']),
      motivo: json['motivo'] as String?,
      fechaSolicitud: json['fechaSolicitud'] != null
          ? DateTime.parse(json['fechaSolicitud'] as String)
          : (json['creadoEn'] != null
              ? DateTime.parse(json['creadoEn'] as String)
              : DateTime.now()),
      estado: EstadoAdelanto.fromString(
          json['estado'] as String? ?? 'PENDIENTE_ADELANTO'),
      aprobadoPorId: json['aprobadoPorId'] as String?,
      fechaAprobacion: json['fechaAprobacion'] != null
          ? DateTime.parse(json['fechaAprobacion'] as String)
          : null,
      metodoPago: json['metodoPago'] as String?,
      pagadoPorId: json['pagadoPorId'] as String?,
      motivoRechazo: json['motivoRechazo'] as String?,
      empleadoNombre: empleadoNombre,
      empleadoCodigo: empleado?['codigo'] as String?,
      empleadoCargo: empleado?['cargo'] as String?,
      empleadoDni: persona?['dni'] as String?,
      aprobadoPorNombre: aprobadoPorNombre,
    );
  }

  Adelanto toEntity() => this;

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
