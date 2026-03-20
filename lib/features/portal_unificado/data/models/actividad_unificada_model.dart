import '../../domain/entities/actividad_unificada.dart';

class ActividadUnificadaModel {
  final List<EmpresaActividadModel> empresas;

  const ActividadUnificadaModel({required this.empresas});

  factory ActividadUnificadaModel.fromJson(Map<String, dynamic> json) {
    return ActividadUnificadaModel(
      empresas: (json['empresas'] as List<dynamic>? ?? [])
          .map((e) => EmpresaActividadModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  ActividadUnificada toEntity() => ActividadUnificada(
        empresas: empresas.map((e) => e.toEntity()).toList(),
      );
}

class EmpresaActividadModel {
  final EmpresaInfoModel empresa;
  final List<ActividadItemModel> cotizaciones;
  final List<ActividadItemModel> ventas;
  final List<ActividadItemModel> citas;
  final List<ActividadItemModel> ordenesServicio;

  const EmpresaActividadModel({
    required this.empresa,
    required this.cotizaciones,
    required this.ventas,
    required this.citas,
    required this.ordenesServicio,
  });

  factory EmpresaActividadModel.fromJson(Map<String, dynamic> json) {
    return EmpresaActividadModel(
      empresa: EmpresaInfoModel.fromJson(json['empresa'] as Map<String, dynamic>),
      cotizaciones: _parseItems(json['cotizaciones']),
      ventas: _parseItems(json['ventas']),
      citas: _parseItems(json['citas']),
      ordenesServicio: _parseItems(json['ordenesServicio']),
    );
  }

  EmpresaActividad toEntity() => EmpresaActividad(
        empresa: empresa.toEntity(),
        cotizaciones: cotizaciones.map((i) => i.toEntity()).toList(),
        ventas: ventas.map((i) => i.toEntity()).toList(),
        citas: citas.map((i) => i.toEntity()).toList(),
        ordenesServicio: ordenesServicio.map((i) => i.toEntity()).toList(),
      );

  static List<ActividadItemModel> _parseItems(dynamic list) {
    if (list == null) return [];
    return (list as List<dynamic>)
        .map((e) => ActividadItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class EmpresaInfoModel {
  final String id;
  final String nombre;
  final String? logo;
  final String? subdominio;

  const EmpresaInfoModel({
    required this.id,
    required this.nombre,
    this.logo,
    this.subdominio,
  });

  factory EmpresaInfoModel.fromJson(Map<String, dynamic> json) {
    return EmpresaInfoModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      logo: json['logo'] as String?,
      subdominio: json['subdominio'] as String?,
    );
  }

  EmpresaInfo toEntity() => EmpresaInfo(
        id: id,
        nombre: nombre,
        logo: logo,
        subdominio: subdominio,
      );
}

class ActividadItemModel {
  final String id;
  final String codigo;
  final String estado;
  final double? total;
  final String? moneda;
  final DateTime? fecha;
  final String? descripcion;

  const ActividadItemModel({
    required this.id,
    required this.codigo,
    required this.estado,
    this.total,
    this.moneda,
    this.fecha,
    this.descripcion,
  });

  factory ActividadItemModel.fromJson(Map<String, dynamic> json) {
    return ActividadItemModel(
      id: json['id'] as String,
      codigo: json['codigo'] as String? ?? '',
      estado: json['estado'] as String? ?? '',
      total: (json['total'] as num?)?.toDouble(),
      moneda: json['moneda'] as String?,
      fecha: json['fecha'] != null ? DateTime.tryParse(json['fecha'].toString()) : null,
      descripcion: json['descripcion'] as String?,
    );
  }

  ActividadItem toEntity() => ActividadItem(
        id: id,
        codigo: codigo,
        estado: estado,
        total: total,
        moneda: moneda,
        fecha: fecha,
        descripcion: descripcion,
      );
}
