import '../../domain/entities/consulta_ruc.dart';

class ConsultaRucModel {
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

  ConsultaRucModel({
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

  factory ConsultaRucModel.fromJson(Map<String, dynamic> json) {
    return ConsultaRucModel(
      ruc: json['ruc'] ?? '',
      razonSocial: json['razonSocial'] ?? '',
      tipoContribuyente: json['tipoContribuyente'] ?? '',
      estado: json['estado'] ?? '',
      condicion: json['condicion'] ?? '',
      departamento: json['departamento'] ?? '',
      provincia: json['provincia'] ?? '',
      distrito: json['distrito'] ?? '',
      direccion: json['direccion'] ?? '',
      direccionCompleta: json['direccionCompleta'] ?? '',
      ubigeo: json['ubigeo'] ?? '',
    );
  }

  ConsultaRuc toEntity() {
    return ConsultaRuc(
      ruc: ruc,
      razonSocial: razonSocial,
      tipoContribuyente: tipoContribuyente,
      estado: estado,
      condicion: condicion,
      departamento: departamento,
      provincia: provincia,
      distrito: distrito,
      direccion: direccion,
      direccionCompleta: direccionCompleta,
      ubigeo: ubigeo,
    );
  }
}
