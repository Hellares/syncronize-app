import '../../domain/entities/proveedor.dart';
import 'proveedor_contacto_model.dart';
import 'proveedor_banco_model.dart';
import 'proveedor_evaluacion_model.dart';

/// Model que representa un proveedor (extends Entity)
class ProveedorModel extends Proveedor {
  const ProveedorModel({
    required super.id,
    required super.empresaId,
    required super.codigo,
    required super.nombre,
    super.nombreComercial,
    required super.tipoDocumento,
    required super.numeroDocumento,
    super.email,
    super.telefono,
    super.telefonoAlternativo,
    super.sitioWeb,
    super.direccion,
    super.ciudad,
    super.provincia,
    super.pais,
    super.codigoPostal,
    super.terminosPago,
    super.diasCredito,
    super.limiteCredito,
    super.descuentoPreferencial,
    super.contactoPrincipal,
    super.cargoContacto,
    super.notas,
    super.calificacion,
    super.evaluaciones,
    required super.isActive,
    super.motivoInactivo,
    super.contactos,
    super.bancos,
    super.totalProductosPreferenciales,
    required super.creadoPor,
    super.actualizadoPor,
    required super.creadoEn,
    required super.actualizadoEn,
  });

  /// Crea una instancia desde JSON
  factory ProveedorModel.fromJson(Map<String, dynamic> json) {
    return ProveedorModel(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String,
      codigo: json['codigo'] as String,
      nombre: json['nombre'] as String,
      nombreComercial: json['nombreComercial'] as String?,
      tipoDocumento: _tipoDocumentoFromString(json['tipoDocumento'] as String),
      numeroDocumento: json['numeroDocumento'] as String,
      email: json['email'] as String?,
      telefono: json['telefono'] as String?,
      telefonoAlternativo: json['telefonoAlternativo'] as String?,
      sitioWeb: json['sitioWeb'] as String?,
      direccion: json['direccion'] as String?,
      ciudad: json['ciudad'] as String?,
      provincia: json['provincia'] as String?,
      pais: json['pais'] as String? ?? 'PE',
      codigoPostal: json['codigoPostal'] as String?,
      terminosPago: json['terminosPago'] != null
          ? _terminosPagoFromString(json['terminosPago'] as String)
          : null,
      diasCredito: json['diasCredito'] as int?,
      limiteCredito: json['limiteCredito'] != null
          ? double.parse(json['limiteCredito'].toString())
          : null,
      descuentoPreferencial: json['descuentoPreferencial'] != null
          ? double.parse(json['descuentoPreferencial'].toString())
          : null,
      contactoPrincipal: json['contactoPrincipal'] as String?,
      cargoContacto: json['cargoContacto'] as String?,
      notas: json['notas'] as String?,
      calificacion: json['calificacion'] as int?,
      evaluaciones: json['evaluaciones'] != null
          ? (json['evaluaciones'] as List)
              .map((e) => ProveedorEvaluacionModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      isActive: json['isActive'] as bool? ?? true,
      motivoInactivo: json['motivoInactivo'] as String?,
      contactos: json['contactos'] != null
          ? (json['contactos'] as List)
              .map((e) => ProveedorContactoModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      bancos: json['bancos'] != null
          ? (json['bancos'] as List)
              .map((e) => ProveedorBancoModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      totalProductosPreferenciales: json['_count'] != null
          ? (json['_count'] as Map<String, dynamic>)['productosPreferenciales'] as int?
          : null,
      creadoPor: json['creadoPor'] as String,
      actualizadoPor: json['actualizadoPor'] as String?,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      actualizadoEn: DateTime.parse(json['actualizadoEn'] as String),
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'empresaId': empresaId,
      'codigo': codigo,
      'nombre': nombre,
      'nombreComercial': nombreComercial,
      'tipoDocumento': _tipoDocumentoToString(tipoDocumento),
      'numeroDocumento': numeroDocumento,
      'email': email,
      'telefono': telefono,
      'telefonoAlternativo': telefonoAlternativo,
      'sitioWeb': sitioWeb,
      'direccion': direccion,
      'ciudad': ciudad,
      'provincia': provincia,
      'pais': pais,
      'codigoPostal': codigoPostal,
      'terminosPago': terminosPago != null ? _terminosPagoToString(terminosPago!) : null,
      'diasCredito': diasCredito,
      'limiteCredito': limiteCredito,
      'descuentoPreferencial': descuentoPreferencial,
      'contactoPrincipal': contactoPrincipal,
      'cargoContacto': cargoContacto,
      'notas': notas,
      'calificacion': calificacion,
      'isActive': isActive,
      'motivoInactivo': motivoInactivo,
      'creadoPor': creadoPor,
      'actualizadoPor': actualizadoPor,
    };
  }

  // Helper methods para conversión de enums
  static TipoDocumentoIdentidad _tipoDocumentoFromString(String tipo) {
    return TipoDocumentoIdentidad.values.firstWhere(
      (e) => e.toString().split('.').last == tipo,
      orElse: () => TipoDocumentoIdentidad.OTROS,
    );
  }

  static String _tipoDocumentoToString(TipoDocumentoIdentidad tipo) {
    return tipo.toString().split('.').last;
  }

  static TerminosPago _terminosPagoFromString(String terminos) {
    return TerminosPago.values.firstWhere(
      (e) => e.toString().split('.').last == terminos,
      orElse: () => TerminosPago.PERSONALIZADO,
    );
  }

  static String _terminosPagoToString(TerminosPago terminos) {
    return terminos.toString().split('.').last;
  }
}
