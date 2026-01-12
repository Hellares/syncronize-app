import 'package:equatable/equatable.dart';

/// Tipos de sede según su función operativa
enum TipoSede {
  operativaCompleta('OPERATIVA_COMPLETA', 'Operativa Completa'),
  soloAlmacen('SOLO_ALMACEN', 'Solo Almacén'),
  puntoVenta('PUNTO_VENTA', 'Punto de Venta'),
  oficinaAdministrativa('OFICINA_ADMINISTRATIVA', 'Oficina Administrativa'),
  tallerLaboratorio('TALLER_LABORATORIO', 'Taller/Laboratorio');

  final String value;
  final String displayName;

  const TipoSede(this.value, this.displayName);

  static TipoSede fromString(String value) {
    return TipoSede.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TipoSede.operativaCompleta,
    );
  }
}

/// Entidad que representa una sede de la empresa
class Sede extends Equatable {
  final String id;
  final String empresaId;
  final String codigo;
  final String nombre;
  final String? telefono;
  final String? email;
  final TipoSede tipoSede;

  // Ubicación completa
  final String? direccion;
  final String? referencia;
  final String? distrito;
  final String? provincia;
  final String? departamento;
  final String? pais;
  final Map<String, dynamic>? coordenadas;

  // Configuración operativa
  final Map<String, dynamic>? horarioAtencion;
  final Map<String, dynamic>? configuracion;

  // Series de comprobantes por sede
  final String serieFactura;
  final String serieBoleta;
  final String serieNotaCredito;
  final String serieNotaDebito;
  final String? serieGuiaRemision;

  // Contadores de documentos por sede
  final int ultimoNumeroFactura;
  final int ultimoNumeroBoleta;
  final int ultimoNumeroNotaCredito;
  final int ultimoNumeroNotaDebito;
  final int ultimoNumeroGuiaRemision;

  // Estado
  final bool isActive;
  final DateTime? deletedAt;
  final bool esPrincipal;

  // Auditoría
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  // Información adicional
  final String? userRole;
  final int? totalUsuarios;
  final int? totalProductos;
  final int? totalServicios;

  const Sede({
    required this.id,
    required this.empresaId,
    required this.codigo,
    required this.nombre,
    this.telefono,
    this.email,
    required this.tipoSede,
    this.direccion,
    this.referencia,
    this.distrito,
    this.provincia,
    this.departamento,
    this.pais,
    this.coordenadas,
    this.horarioAtencion,
    this.configuracion,
    required this.serieFactura,
    required this.serieBoleta,
    required this.serieNotaCredito,
    required this.serieNotaDebito,
    this.serieGuiaRemision,
    required this.ultimoNumeroFactura,
    required this.ultimoNumeroBoleta,
    required this.ultimoNumeroNotaCredito,
    required this.ultimoNumeroNotaDebito,
    required this.ultimoNumeroGuiaRemision,
    required this.isActive,
    this.deletedAt,
    required this.esPrincipal,
    required this.creadoEn,
    required this.actualizadoEn,
    this.userRole,
    this.totalUsuarios,
    this.totalProductos,
    this.totalServicios,
  });

  /// Indica si el usuario tiene un rol específico en esta sede
  bool get hasUserRole => userRole != null && userRole!.isNotEmpty;

  /// Obtiene la dirección completa formateada
  String get direccionCompleta {
    final partes = <String>[];
    if (direccion != null && direccion!.isNotEmpty) partes.add(direccion!);
    if (distrito != null && distrito!.isNotEmpty) partes.add(distrito!);
    if (provincia != null && provincia!.isNotEmpty) partes.add(provincia!);
    if (departamento != null && departamento!.isNotEmpty) partes.add(departamento!);
    return partes.isNotEmpty ? partes.join(', ') : 'Sin dirección';
  }

  /// Obtiene el color para el tipo de sede
  int get tipoSedeColor {
    switch (tipoSede) {
      case TipoSede.operativaCompleta:
        return 0xFF4CAF50; // Verde
      case TipoSede.soloAlmacen:
        return 0xFF2196F3; // Azul
      case TipoSede.puntoVenta:
        return 0xFFFF9800; // Naranja
      case TipoSede.oficinaAdministrativa:
        return 0xFF9C27B0; // Púrpura
      case TipoSede.tallerLaboratorio:
        return 0xFF00BCD4; // Cian
    }
  }

  /// Obtiene el icono para el tipo de sede
  int get tipoSedeIconCode {
    switch (tipoSede) {
      case TipoSede.operativaCompleta:
        return 0xe559; // Icons.business
      case TipoSede.soloAlmacen:
        return 0xe1b1; // Icons.warehouse
      case TipoSede.puntoVenta:
        return 0xe59c; // Icons.shopping_cart
      case TipoSede.oficinaAdministrativa:
        return 0xe3f7; // Icons.corporate_fare
      case TipoSede.tallerLaboratorio:
        return 0xe869; // Icons.handyman
    }
  }

  @override
  List<Object?> get props => [
        id,
        empresaId,
        codigo,
        nombre,
        telefono,
        email,
        tipoSede,
        direccion,
        referencia,
        distrito,
        provincia,
        departamento,
        pais,
        coordenadas,
        horarioAtencion,
        configuracion,
        serieFactura,
        serieBoleta,
        serieNotaCredito,
        serieNotaDebito,
        serieGuiaRemision,
        ultimoNumeroFactura,
        ultimoNumeroBoleta,
        ultimoNumeroNotaCredito,
        ultimoNumeroNotaDebito,
        ultimoNumeroGuiaRemision,
        isActive,
        deletedAt,
        esPrincipal,
        creadoEn,
        actualizadoEn,
        userRole,
        totalUsuarios,
        totalProductos,
        totalServicios,
      ];
}
