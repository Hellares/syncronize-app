import '../../domain/entities/consulta_dni.dart';

class ConsultaDniModel {
  final String dni;
  final String nombres;
  final String apellidoPaterno;
  final String apellidoMaterno;
  final String nombreCompleto;
  final String departamento;
  final String provincia;
  final String distrito;
  final String direccion;
  final String direccionCompleta;
  final String ubigeo;
  final String? telefono;
  final String? email;
  final String? origen;
  final bool? existeEnSistema;
  final String? personaId;

  ConsultaDniModel({
    required this.dni,
    required this.nombres,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    required this.nombreCompleto,
    required this.departamento,
    required this.provincia,
    required this.distrito,
    required this.direccion,
    required this.direccionCompleta,
    required this.ubigeo,
    this.telefono,
    this.email,
    this.origen,
    this.existeEnSistema,
    this.personaId,
  });

  factory ConsultaDniModel.fromJson(Map<String, dynamic> json) {
    return ConsultaDniModel(
      dni: json['dni'] ?? '',
      nombres: json['nombres'] ?? '',
      apellidoPaterno: json['apellidoPaterno'] ?? '',
      apellidoMaterno: json['apellidoMaterno'] ?? '',
      nombreCompleto: json['nombreCompleto'] ?? '',
      departamento: json['departamento'] ?? '',
      provincia: json['provincia'] ?? '',
      distrito: json['distrito'] ?? '',
      direccion: json['direccion'] ?? '',
      direccionCompleta: json['direccionCompleta'] ?? '',
      ubigeo: json['ubigeo'] ?? '',
      telefono: json['telefono'] as String?,
      email: json['email'] as String?,
      origen: json['origen'] as String?,
      existeEnSistema: json['existeEnSistema'] as bool?,
      personaId: json['personaId'] as String?,
    );
  }

  ConsultaDni toEntity() {
    return ConsultaDni(
      dni: dni,
      nombres: nombres,
      apellidoPaterno: apellidoPaterno,
      apellidoMaterno: apellidoMaterno,
      nombreCompleto: nombreCompleto,
      departamento: departamento,
      provincia: provincia,
      distrito: distrito,
      direccion: direccion,
      direccionCompleta: direccionCompleta,
      ubigeo: ubigeo,
      telefono: telefono,
      email: email,
      origen: origen,
      existeEnSistema: existeEnSistema,
      personaId: personaId,
    );
  }
}
