import '../../domain/entities/directorio_empresa.dart';

class DirectorioEmpresaModel extends DirectorioEmpresa {
  DirectorioEmpresaModel({
    required super.id,
    required super.nombre,
    super.logo,
    super.rubro,
    super.telefono,
    super.email,
    super.descripcion,
    super.descripcionTercerizacion,
    super.tiposServicioTercerizacion,
    super.departamento,
    super.provincia,
    super.distrito,
    super.direccionFiscal,
    super.sedePrincipal,
    super.servicios,
  });

  factory DirectorioEmpresaModel.fromJson(Map<String, dynamic> json) {
    final tiposRaw = json['tiposServicioTercerizacion'];
    final tipos = tiposRaw is List
        ? tiposRaw.map((e) => e.toString()).toList()
        : <String>[];

    final serviciosRaw = json['servicios'];
    final servicios = serviciosRaw is List
        ? serviciosRaw
            .map((e) =>
                ServicioResumenModel.fromJson(e as Map<String, dynamic>))
            .toList()
        : <ServicioResumen>[];

    return DirectorioEmpresaModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String? ?? '',
      logo: json['logo'] as String?,
      rubro: json['rubro'] as String?,
      telefono: json['telefono'] as String?,
      email: json['email'] as String?,
      descripcion: json['descripcion'] as String?,
      descripcionTercerizacion: json['descripcionTercerizacion'] as String?,
      tiposServicioTercerizacion: tipos,
      departamento: json['departamento'] as String?,
      provincia: json['provincia'] as String?,
      distrito: json['distrito'] as String?,
      direccionFiscal: json['direccionFiscal'] as String?,
      sedePrincipal: json['sedePrincipal'] != null
          ? SedePrincipalModel.fromJson(
              json['sedePrincipal'] as Map<String, dynamic>)
          : null,
      servicios: servicios,
    );
  }
}

class SedePrincipalModel extends SedePrincipal {
  SedePrincipalModel({
    required super.id,
    required super.nombre,
    super.direccion,
    super.distrito,
    super.provincia,
    super.departamento,
    super.coordenadas,
    super.telefono,
    super.horarioAtencion,
  });

  factory SedePrincipalModel.fromJson(Map<String, dynamic> json) {
    return SedePrincipalModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String? ?? '',
      direccion: json['direccion'] as String?,
      distrito: json['distrito'] as String?,
      provincia: json['provincia'] as String?,
      departamento: json['departamento'] as String?,
      coordenadas: json['coordenadas'] as Map<String, dynamic>?,
      telefono: json['telefono'] as String?,
      horarioAtencion: json['horarioAtencion'],
    );
  }
}

class ServicioResumenModel extends ServicioResumen {
  ServicioResumenModel({
    required super.id,
    required super.nombre,
    super.precio,
  });

  factory ServicioResumenModel.fromJson(Map<String, dynamic> json) {
    return ServicioResumenModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String? ?? '',
      precio: json['precio'] != null
          ? double.tryParse(json['precio'].toString())
          : null,
    );
  }
}
