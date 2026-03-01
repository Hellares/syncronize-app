import 'package:equatable/equatable.dart';

class ConsultaRuc extends Equatable {
  final String ruc;
  final String razonSocial;
  final String tipoContribuyente;
  final String estado;
  final String condicion;
  final String departamento;
  final String provincia;
  final String distrito;
  final String direccion;
  final String direccionCompleta;
  final String ubigeo;

  const ConsultaRuc({
    required this.ruc,
    required this.razonSocial,
    required this.tipoContribuyente,
    required this.estado,
    required this.condicion,
    required this.departamento,
    required this.provincia,
    required this.distrito,
    required this.direccion,
    required this.direccionCompleta,
    required this.ubigeo,
  });

  bool get esHabido => condicion.toUpperCase() == 'HABIDO';
  bool get esActivo => estado.toUpperCase() == 'ACTIVO';

  @override
  List<Object?> get props => [
        ruc,
        razonSocial,
        tipoContribuyente,
        estado,
        condicion,
        departamento,
        provincia,
        distrito,
        direccion,
        direccionCompleta,
        ubigeo,
      ];
}
