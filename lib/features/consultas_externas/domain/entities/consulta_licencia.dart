import 'package:equatable/equatable.dart';

class ConsultaLicencia extends Equatable {
  final String numeroDocumento;
  final String nombreCompleto;
  final String licenciaNumero;
  final String licenciaCategoria;
  final String licenciaFechaVencimiento;
  final String licenciaEstado;
  final String licenciaRestricciones;

  const ConsultaLicencia({
    required this.numeroDocumento,
    required this.nombreCompleto,
    required this.licenciaNumero,
    required this.licenciaCategoria,
    required this.licenciaFechaVencimiento,
    required this.licenciaEstado,
    this.licenciaRestricciones = '',
  });

  bool get esVigente => licenciaEstado.toUpperCase() == 'VIGENTE';

  // Split nombre into nombre + apellidos for GRE form
  String get nombres {
    final parts = nombreCompleto.split(' ');
    return parts.length > 2 ? parts.sublist(0, parts.length - 2).join(' ') : parts.first;
  }

  String get apellidos {
    final parts = nombreCompleto.split(' ');
    return parts.length > 2 ? parts.sublist(parts.length - 2).join(' ') : parts.last;
  }

  @override
  List<Object?> get props => [numeroDocumento, licenciaNumero];
}
