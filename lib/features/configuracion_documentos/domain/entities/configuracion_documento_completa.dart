import 'package:equatable/equatable.dart';
import 'configuracion_documentos.dart';
import 'plantilla_documento.dart';

/// Datos de sede relevantes para documentos PDF
class SedeDocumento extends Equatable {
  final String id;
  final String nombre;
  final String? direccion;
  final String? telefono;
  final String? email;
  final String? distrito;
  final String? provincia;
  final String? departamento;

  const SedeDocumento({
    required this.id,
    required this.nombre,
    this.direccion,
    this.telefono,
    this.email,
    this.distrito,
    this.provincia,
    this.departamento,
  });

  /// Dirección completa formateada
  String get direccionCompleta {
    final partes = <String>[];
    if (direccion != null && direccion!.isNotEmpty) partes.add(direccion!);
    if (distrito != null && distrito!.isNotEmpty) partes.add(distrito!);
    if (provincia != null && provincia!.isNotEmpty) partes.add(provincia!);
    if (departamento != null && departamento!.isNotEmpty) {
      partes.add(departamento!);
    }
    return partes.isNotEmpty ? partes.join(', ') : '';
  }

  @override
  List<Object?> get props => [
        id,
        nombre,
        direccion,
        telefono,
        email,
        distrito,
        provincia,
        departamento,
      ];
}

class ConfiguracionDocumentoCompleta extends Equatable {
  final ConfiguracionDocumentos configuracion;
  final PlantillaDocumento plantilla;
  final SedeDocumento? sede;

  const ConfiguracionDocumentoCompleta({
    required this.configuracion,
    required this.plantilla,
    this.sede,
  });

  /// Color primario efectivo: plantilla override o configuracion global
  String get colorPrimarioEfectivo =>
      plantilla.colorEncabezado ?? configuracion.colorPrimario;

  /// Color de cuerpo efectivo: plantilla override o configuracion global
  String get colorCuerpoEfectivo =>
      plantilla.colorCuerpo ?? configuracion.colorTexto;

  /// Dirección efectiva: sede > configuracion global
  String? get direccionEfectiva =>
      sede?.direccionCompleta.isNotEmpty == true
          ? sede!.direccionCompleta
          : configuracion.direccion;

  /// Teléfono efectivo: sede > configuracion global
  String? get telefonoEfectivo => sede?.telefono ?? configuracion.telefono;

  /// Email efectivo: sede > configuracion global
  String? get emailEfectivo => sede?.email ?? configuracion.email;

  @override
  List<Object?> get props => [configuracion, plantilla, sede];
}
