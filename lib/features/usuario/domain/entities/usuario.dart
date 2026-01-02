import 'package:equatable/equatable.dart';

/// Entity que representa un usuario/empleado en el sistema
class Usuario extends Equatable {
  final String id;
  final String personaId;
  final String dni;
  final String nombres;
  final String apellidos;
  final String nombreCompleto;
  final String? email;
  final String? telefono;
  final String rolEnEmpresa;
  final String? rolGlobal;
  final bool isActive;
  final bool emailVerificado;
  final bool telefonoVerificado;
  final bool dniVerificado;
  final bool requiereCambioPassword;
  final DateTime? lastLoginAt;
  final String estado;
  final String? registradoPor;
  final String? registradoPorNombre;
  final DateTime creadoEn;
  final DateTime actualizadoEn;
  final List<UsuarioSede> sedes;

  const Usuario({
    required this.id,
    required this.personaId,
    required this.dni,
    required this.nombres,
    required this.apellidos,
    required this.nombreCompleto,
    this.email,
    this.telefono,
    required this.rolEnEmpresa,
    this.rolGlobal,
    required this.isActive,
    required this.emailVerificado,
    required this.telefonoVerificado,
    required this.dniVerificado,
    required this.requiereCambioPassword,
    this.lastLoginAt,
    required this.estado,
    this.registradoPor,
    this.registradoPorNombre,
    required this.creadoEn,
    required this.actualizadoEn,
    this.sedes = const [],
  });

  /// Obtiene las iniciales del usuario
  String get iniciales {
    final primeraLetraNombre = nombres.isNotEmpty ? nombres[0] : '';
    final primeraLetraApellido = apellidos.isNotEmpty ? apellidos[0] : '';
    return '$primeraLetraNombre$primeraLetraApellido'.toUpperCase();
  }

  /// Verifica si el usuario tiene datos de contacto completos
  bool get datosContactoCompletos => email != null && telefono != null;

  /// Verifica si el usuario está completamente verificado
  bool get totalmenteVerificado =>
      emailVerificado && telefonoVerificado && dniVerificado;

  /// Verifica si el usuario tiene sedes asignadas
  bool get tieneSedes => sedes.isNotEmpty;

  /// Obtiene el número de sedes activas asignadas
  int get sedesActivas => sedes.where((s) => s.isActive).length;

  /// Verifica si el usuario puede abrir caja en alguna sede
  bool get puedeAbrirCaja =>
      sedes.any((sede) => sede.isActive && sede.puedeAbrirCaja);

  /// Verifica si el usuario puede cerrar caja en alguna sede
  bool get puedeCerrarCaja =>
      sedes.any((sede) => sede.isActive && sede.puedeCerrarCaja);

  /// Obtiene el rol formateado para mostrar
  String get rolFormateado {
    switch (rolEnEmpresa) {
      case 'VENDEDOR':
        return 'Vendedor';
      case 'CAJERO':
        return 'Cajero';
      case 'TECNICO':
        return 'Técnico';
      case 'CONTADOR':
        return 'Contador';
      case 'EMPRESA_ADMIN':
        return 'Administrador de Empresa';
      case 'SEDE_ADMIN':
        return 'Administrador de Sede';
      case 'SUPER_ADMIN':
        return 'Super Administrador';
      case 'OPERADOR':
        return 'Operador';
      case 'LECTURA':
        return 'Solo Lectura';
      default:
        return rolEnEmpresa;
    }
  }

  /// Obtiene el estado formateado para mostrar
  String get estadoFormateado {
    switch (estado) {
      case 'ACTIVO':
        return 'Activo';
      case 'INACTIVO':
        return 'Inactivo';
      case 'BLOQUEADO':
        return 'Bloqueado';
      case 'SUSPENDIDO':
        return 'Suspendido';
      default:
        return estado;
    }
  }

  @override
  List<Object?> get props => [
        id,
        personaId,
        dni,
        nombres,
        apellidos,
        nombreCompleto,
        email,
        telefono,
        rolEnEmpresa,
        rolGlobal,
        isActive,
        emailVerificado,
        telefonoVerificado,
        dniVerificado,
        requiereCambioPassword,
        lastLoginAt,
        estado,
        registradoPor,
        registradoPorNombre,
        creadoEn,
        actualizadoEn,
        sedes,
      ];
}

/// Entity que representa una sede asignada a un usuario
class UsuarioSede extends Equatable {
  final String id;
  final String sedeId;
  final String sedeNombre;
  final String rol;
  final bool puedeAbrirCaja;
  final bool puedeCerrarCaja;
  final double? limiteCreditoVenta;
  final List<String> permisos;
  final bool isActive;

  const UsuarioSede({
    required this.id,
    required this.sedeId,
    required this.sedeNombre,
    required this.rol,
    required this.puedeAbrirCaja,
    required this.puedeCerrarCaja,
    this.limiteCreditoVenta,
    this.permisos = const [],
    required this.isActive,
  });

  /// Obtiene el rol de sede formateado para mostrar
  String get rolFormateado {
    switch (rol) {
      case 'GERENTE_SEDE':
        return 'Gerente de Sede';
      case 'ADMINISTRADOR':
        return 'Administrador';
      case 'SUPERVISOR':
        return 'Supervisor';
      case 'CAJERO':
        return 'Cajero';
      case 'VENDEDOR':
        return 'Vendedor';
      case 'ALMACENERO':
        return 'Almacenero';
      case 'TECNICO_SERVICIO':
        return 'Técnico de Servicio';
      case 'REPARTIDOR':
        return 'Repartidor';
      case 'CONTADOR_SEDE':
        return 'Contador';
      case 'ASISTENTE':
        return 'Asistente';
      case 'CONSULTOR':
        return 'Consultor';
      case 'PRACTICANTE':
        return 'Practicante';
      default:
        return rol;
    }
  }

  @override
  List<Object?> get props => [
        id,
        sedeId,
        sedeNombre,
        rol,
        puedeAbrirCaja,
        puedeCerrarCaja,
        limiteCreditoVenta,
        permisos,
        isActive,
      ];
}
