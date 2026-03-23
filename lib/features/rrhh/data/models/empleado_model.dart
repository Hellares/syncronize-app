import '../../domain/entities/empleado.dart';

class EmpleadoModel extends Empleado {
  const EmpleadoModel({
    required super.id,
    required super.empresaId,
    required super.sedeId,
    required super.usuarioId,
    required super.codigo,
    super.cargo,
    super.departamento,
    required super.fechaIngreso,
    super.fechaCese,
    required super.tipoContrato,
    required super.salarioBase,
    super.moneda,
    super.banco,
    super.numeroCuenta,
    super.cci,
    super.horarioPlantillaId,
    super.estado,
    super.isActive,
    super.nombres,
    super.apellidos,
    super.dni,
    super.email,
    super.telefono,
    super.sedeNombre,
  });

  factory EmpleadoModel.fromJson(Map<String, dynamic> json) {
    final usuario = json['usuario'] as Map<String, dynamic>?;
    final persona = usuario?['persona'] as Map<String, dynamic>?;
    final sede = json['sede'] as Map<String, dynamic>?;

    return EmpleadoModel(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String? ?? '',
      sedeId: json['sedeId'] as String? ?? '',
      usuarioId: json['usuarioId'] as String? ?? '',
      codigo: json['codigo'] as String? ?? '',
      cargo: json['cargo'] as String?,
      departamento: json['departamento'] as String?,
      fechaIngreso: DateTime.parse(json['fechaIngreso'] as String),
      fechaCese: json['fechaCese'] != null
          ? DateTime.parse(json['fechaCese'] as String)
          : null,
      tipoContrato: TipoContrato.fromString(
          json['tipoContrato'] as String? ?? 'PLANILLA'),
      salarioBase: _toDouble(json['salarioBase']),
      moneda: json['moneda'] as String? ?? 'PEN',
      banco: json['banco'] as String?,
      numeroCuenta: json['numeroCuenta'] as String?,
      cci: json['cci'] as String?,
      horarioPlantillaId: json['horarioPlantillaId'] as String?,
      estado: EstadoEmpleado.fromString(
          json['estado'] as String? ?? 'ACTIVO'),
      isActive: json['isActive'] as bool? ?? true,
      nombres: persona?['nombres'] as String?,
      apellidos: persona?['apellidos'] as String?,
      dni: persona?['dni'] as String?,
      email: usuario?['email'] as String?,
      telefono: persona?['telefono'] as String?,
      sedeNombre: sede?['nombre'] as String? ?? json['sedeNombre'] as String?,
    );
  }

  Empleado toEntity() => this;

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
