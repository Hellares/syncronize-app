import 'package:equatable/equatable.dart';
import 'proveedor_contacto.dart';
import 'proveedor_banco.dart';
import 'proveedor_evaluacion.dart';

/// Enums
// ignore_for_file: constant_identifier_names
enum TipoDocumentoIdentidad {
  RUC,
  DNI,
  PASAPORTE,
  CARNET_EXTRANJERIA,
  OTROS,
}

enum TerminosPago {
  CONTADO,
  CREDITO_7,
  CREDITO_15,
  CREDITO_30,
  CREDITO_45,
  CREDITO_60,
  CREDITO_90,
  PERSONALIZADO,
}

/// Entity que representa un proveedor
class Proveedor extends Equatable {
  final String id;
  final String empresaId;

  // Identificación
  final String codigo;
  final String nombre;
  final String? nombreComercial;
  final TipoDocumentoIdentidad tipoDocumento;
  final String numeroDocumento;

  // Información de Contacto
  final String? email;
  final String? telefono;
  final String? telefonoAlternativo;
  final String? sitioWeb;

  // Dirección
  final String? direccion;
  final String? ciudad;
  final String? provincia;
  final String pais;
  final String? codigoPostal;

  // Términos Comerciales
  final TerminosPago? terminosPago;
  final int? diasCredito;
  final double? limiteCredito;
  final double? descuentoPreferencial;

  // Datos Adicionales
  final String? contactoPrincipal;
  final String? cargoContacto;
  final String? notas;

  // Evaluación
  final int? calificacion;
  final List<ProveedorEvaluacion>? evaluaciones;

  // Control
  final bool isActive;
  final String? motivoInactivo;

  // Relaciones
  final List<ProveedorContacto>? contactos;
  final List<ProveedorBanco>? bancos;
  final int? totalProductosPreferenciales;

  // Auditoría
  final String creadoPor;
  final String? actualizadoPor;
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  const Proveedor({
    required this.id,
    required this.empresaId,
    required this.codigo,
    required this.nombre,
    this.nombreComercial,
    required this.tipoDocumento,
    required this.numeroDocumento,
    this.email,
    this.telefono,
    this.telefonoAlternativo,
    this.sitioWeb,
    this.direccion,
    this.ciudad,
    this.provincia,
    this.pais = 'PE',
    this.codigoPostal,
    this.terminosPago,
    this.diasCredito,
    this.limiteCredito,
    this.descuentoPreferencial,
    this.contactoPrincipal,
    this.cargoContacto,
    this.notas,
    this.calificacion,
    this.evaluaciones,
    required this.isActive,
    this.motivoInactivo,
    this.contactos,
    this.bancos,
    this.totalProductosPreferenciales,
    required this.creadoPor,
    this.actualizadoPor,
    required this.creadoEn,
    required this.actualizadoEn,
  });

  /// Obtiene las iniciales del proveedor
  String get iniciales {
    final palabras = nombre.split(' ');
    if (palabras.isEmpty) return '';
    if (palabras.length == 1) return palabras[0].substring(0, 1).toUpperCase();
    return '${palabras[0].substring(0, 1)}${palabras[1].substring(0, 1)}'.toUpperCase();
  }

  /// Verifica si el proveedor tiene datos de contacto completos
  bool get datosContactoCompletos {
    return email != null &&
           telefono != null &&
           direccion != null &&
           ciudad != null &&
           provincia != null;
  }

  /// Obtiene el texto descriptivo de los términos de pago
  String get terminosPagoTexto {
    if (terminosPago == null) return 'No especificado';

    switch (terminosPago!) {
      case TerminosPago.CONTADO:
        return 'Contado';
      case TerminosPago.CREDITO_7:
        return 'Crédito 7 días';
      case TerminosPago.CREDITO_15:
        return 'Crédito 15 días';
      case TerminosPago.CREDITO_30:
        return 'Crédito 30 días';
      case TerminosPago.CREDITO_45:
        return 'Crédito 45 días';
      case TerminosPago.CREDITO_60:
        return 'Crédito 60 días';
      case TerminosPago.CREDITO_90:
        return 'Crédito 90 días';
      case TerminosPago.PERSONALIZADO:
        return diasCredito != null ? 'Crédito $diasCredito días' : 'Personalizado';
    }
  }

  /// Obtiene la calificación con estrellas
  String get calificacionEstrellas {
    if (calificacion == null) return 'Sin calificar';
    return '⭐' * calificacion!;
  }

  /// Verifica si tiene una buena calificación (4 o 5 estrellas)
  bool get buenaCalificacion {
    return calificacion != null && calificacion! >= 4;
  }

  @override
  List<Object?> get props => [
        id,
        empresaId,
        codigo,
        nombre,
        nombreComercial,
        tipoDocumento,
        numeroDocumento,
        email,
        telefono,
        telefonoAlternativo,
        sitioWeb,
        direccion,
        ciudad,
        provincia,
        pais,
        codigoPostal,
        terminosPago,
        diasCredito,
        limiteCredito,
        descuentoPreferencial,
        contactoPrincipal,
        cargoContacto,
        notas,
        calificacion,
        evaluaciones,
        isActive,
        motivoInactivo,
        contactos,
        bancos,
        totalProductosPreferenciales,
        creadoPor,
        actualizadoPor,
        creadoEn,
        actualizadoEn,
      ];
}
