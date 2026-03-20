import 'package:equatable/equatable.dart';

class ConsultaDni extends Equatable {
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
  final bool? tieneUsuario;

  const ConsultaDni({
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
    this.tieneUsuario,
  });

  String get apellidos => '$apellidoPaterno $apellidoMaterno'.trim();

  @override
  List<Object?> get props => [
        dni,
        nombres,
        apellidoPaterno,
        apellidoMaterno,
        nombreCompleto,
        departamento,
        provincia,
        distrito,
        direccion,
        direccionCompleta,
        ubigeo,
        telefono,
        email,
        origen,
        existeEnSistema,
        personaId,
        tieneUsuario,
      ];
}
