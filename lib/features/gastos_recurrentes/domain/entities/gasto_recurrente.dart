import 'package:equatable/equatable.dart';

enum FrecuenciaGasto {
  mensual,
  bimestral,
  trimestral,
  anual;

  String get label {
    switch (this) {
      case FrecuenciaGasto.mensual:
        return 'Mensual';
      case FrecuenciaGasto.bimestral:
        return 'Bimestral';
      case FrecuenciaGasto.trimestral:
        return 'Trimestral';
      case FrecuenciaGasto.anual:
        return 'Anual';
    }
  }

  String get apiValue => name.toUpperCase();

  static FrecuenciaGasto fromString(String value) {
    switch (value.toUpperCase()) {
      case 'BIMESTRAL':
        return FrecuenciaGasto.bimestral;
      case 'TRIMESTRAL':
        return FrecuenciaGasto.trimestral;
      case 'ANUAL':
        return FrecuenciaGasto.anual;
      case 'MENSUAL':
      default:
        return FrecuenciaGasto.mensual;
    }
  }
}

class GastoRecurrente extends Equatable {
  final String id;
  final String empresaId;
  final String? sedeId;
  final String? sedeNombre;
  final String nombre;
  final String categoriaGastoId;
  final String categoriaGastoNombre;
  final String? categoriaGastoIcono;
  final String? categoriaGastoColor;
  final String? proveedorId;
  final String? proveedorNombre;
  final String? proveedorDocumento;
  final double montoEstimado;
  final FrecuenciaGasto frecuencia;
  final int diaVencimiento;
  final bool activo;
  final DateTime? ultimoPagoEn;
  final String? notas;

  const GastoRecurrente({
    required this.id,
    required this.empresaId,
    this.sedeId,
    this.sedeNombre,
    required this.nombre,
    required this.categoriaGastoId,
    required this.categoriaGastoNombre,
    this.categoriaGastoIcono,
    this.categoriaGastoColor,
    this.proveedorId,
    this.proveedorNombre,
    this.proveedorDocumento,
    required this.montoEstimado,
    required this.frecuencia,
    required this.diaVencimiento,
    required this.activo,
    this.ultimoPagoEn,
    this.notas,
  });

  @override
  List<Object?> get props => [
        id,
        empresaId,
        sedeId,
        nombre,
        categoriaGastoId,
        proveedorId,
        montoEstimado,
        frecuencia,
        diaVencimiento,
        activo,
        ultimoPagoEn,
      ];
}
