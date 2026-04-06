import '../../domain/entities/consulta_licencia.dart';

class ConsultaLicenciaModel {
  final String numeroDocumento;
  final String nombreCompleto;
  final String licenciaNumero;
  final String licenciaCategoria;
  final String licenciaFechaVencimiento;
  final String licenciaEstado;
  final String licenciaRestricciones;

  ConsultaLicenciaModel({
    required this.numeroDocumento,
    required this.nombreCompleto,
    required this.licenciaNumero,
    required this.licenciaCategoria,
    required this.licenciaFechaVencimiento,
    required this.licenciaEstado,
    this.licenciaRestricciones = '',
  });

  factory ConsultaLicenciaModel.fromJson(Map<String, dynamic> json) {
    return ConsultaLicenciaModel(
      numeroDocumento: json['numeroDocumento'] ?? '',
      nombreCompleto: json['nombreCompleto'] ?? '',
      licenciaNumero: json['licenciaNumero'] ?? '',
      licenciaCategoria: json['licenciaCategoria'] ?? '',
      licenciaFechaVencimiento: json['licenciaFechaVencimiento'] ?? '',
      licenciaEstado: json['licenciaEstado'] ?? '',
      licenciaRestricciones: json['licenciaRestricciones'] ?? '',
    );
  }

  ConsultaLicencia toEntity() {
    return ConsultaLicencia(
      numeroDocumento: numeroDocumento,
      nombreCompleto: nombreCompleto,
      licenciaNumero: licenciaNumero,
      licenciaCategoria: licenciaCategoria,
      licenciaFechaVencimiento: licenciaFechaVencimiento,
      licenciaEstado: licenciaEstado,
      licenciaRestricciones: licenciaRestricciones,
    );
  }
}
