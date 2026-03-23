import '../../domain/entities/boleta_pago.dart';

class DetalleBoletaPagoModel extends DetalleBoletaPago {
  const DetalleBoletaPagoModel({
    required super.id,
    required super.boletaId,
    required super.tipo,
    required super.concepto,
    super.descripcion,
    required super.monto,
    super.porcentaje,
  });

  factory DetalleBoletaPagoModel.fromJson(Map<String, dynamic> json) {
    return DetalleBoletaPagoModel(
      id: json['id'] as String,
      boletaId: json['boletaId'] as String? ?? '',
      tipo: TipoDetalleBoleta.fromString(json['tipo'] as String? ?? 'INGRESO'),
      concepto: json['concepto'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
      monto: _toDouble(json['monto']),
      porcentaje: _toDoubleNullable(json['porcentaje']),
    );
  }

  DetalleBoletaPago toEntity() => this;

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static double? _toDoubleNullable(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class BoletaPagoModel extends BoletaPago {
  const BoletaPagoModel({
    required super.id,
    required super.periodoId,
    required super.empleadoId,
    required super.empresaId,
    required super.diasTrabajados,
    super.diasFalta,
    super.diasTardanza,
    super.horasExtra,
    required super.salarioBase,
    required super.totalIngresos,
    required super.totalDescuentos,
    required super.totalAportaciones,
    required super.totalNeto,
    super.estado,
    super.fechaPago,
    super.metodoPago,
    super.observaciones,
    super.empleadoNombre,
    super.empleadoCodigo,
    super.empleadoCargo,
    super.empleadoDni,
    super.empleadoDepartamento,
    super.periodoPeriodo,
    super.periodoEstado,
    super.detalles,
  });

  factory BoletaPagoModel.fromJson(Map<String, dynamic> json) {
    final empleado = json['empleado'] as Map<String, dynamic>?;
    final usuario = empleado?['usuario'] as Map<String, dynamic>?;
    final persona = usuario?['persona'] as Map<String, dynamic>?;
    final periodo = json['periodo'] as Map<String, dynamic>?;

    String? empleadoNombre;
    if (persona != null) {
      final nombres = persona['nombres'] as String? ?? '';
      final apellidos = persona['apellidos'] as String? ?? '';
      empleadoNombre = '$nombres $apellidos'.trim();
    }

    // Detalles
    final detallesList = json['detalles'] as List?;
    List<DetalleBoletaPago>? detalles;
    if (detallesList != null) {
      detalles = detallesList
          .map((e) =>
              DetalleBoletaPagoModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return BoletaPagoModel(
      id: json['id'] as String,
      periodoId: json['periodoId'] as String? ?? '',
      empleadoId: json['empleadoId'] as String? ?? '',
      empresaId: json['empresaId'] as String? ?? '',
      diasTrabajados: json['diasTrabajados'] as int? ?? 0,
      diasFalta: json['diasFalta'] as int? ?? 0,
      diasTardanza: json['diasTardanza'] as int? ?? 0,
      horasExtra: _toDouble(json['horasExtra']),
      salarioBase: _toDouble(json['salarioBase']),
      totalIngresos: _toDouble(json['totalIngresos']),
      totalDescuentos: _toDouble(json['totalDescuentos']),
      totalAportaciones: _toDouble(json['totalAportaciones']),
      totalNeto: _toDouble(json['totalNeto']),
      estado: EstadoBoletaPago.fromString(
          json['estado'] as String? ?? 'PENDIENTE_BOLETA'),
      fechaPago: json['fechaPago'] != null
          ? DateTime.parse(json['fechaPago'] as String)
          : null,
      metodoPago: json['metodoPago'] as String?,
      observaciones: json['observaciones'] as String?,
      empleadoNombre: empleadoNombre,
      empleadoCodigo: empleado?['codigo'] as String?,
      empleadoCargo: empleado?['cargo'] as String?,
      empleadoDni: persona?['dni'] as String?,
      empleadoDepartamento: empleado?['departamento'] as String?,
      periodoPeriodo: periodo?['periodo'] as String?,
      periodoEstado: periodo?['estado'] as String?,
      detalles: detalles,
    );
  }

  BoletaPago toEntity() => this;

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
