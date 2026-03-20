import 'package:equatable/equatable.dart';

class ActividadUnificada extends Equatable {
  final List<EmpresaActividad> empresas;

  const ActividadUnificada({required this.empresas});

  bool get isEmpty => empresas.isEmpty;

  @override
  List<Object?> get props => [empresas];
}

class EmpresaActividad extends Equatable {
  final EmpresaInfo empresa;
  final List<ActividadItem> cotizaciones;
  final List<ActividadItem> ventas;
  final List<ActividadItem> citas;
  final List<ActividadItem> ordenesServicio;

  const EmpresaActividad({
    required this.empresa,
    required this.cotizaciones,
    required this.ventas,
    required this.citas,
    required this.ordenesServicio,
  });

  int get totalItems =>
      cotizaciones.length + ventas.length + citas.length + ordenesServicio.length;

  @override
  List<Object?> get props => [empresa, cotizaciones, ventas, citas, ordenesServicio];
}

class EmpresaInfo extends Equatable {
  final String id;
  final String nombre;
  final String? logo;
  final String? subdominio;

  const EmpresaInfo({
    required this.id,
    required this.nombre,
    this.logo,
    this.subdominio,
  });

  @override
  List<Object?> get props => [id, nombre, logo, subdominio];
}

class ActividadItem extends Equatable {
  final String id;
  final String codigo;
  final String estado;
  final double? total;
  final String? moneda;
  final DateTime? fecha;
  final String? descripcion;

  const ActividadItem({
    required this.id,
    required this.codigo,
    required this.estado,
    this.total,
    this.moneda,
    this.fecha,
    this.descripcion,
  });

  @override
  List<Object?> get props => [id, codigo, estado, total, moneda, fecha, descripcion];
}
