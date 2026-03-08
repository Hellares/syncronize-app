import 'package:equatable/equatable.dart';

class DirectorioEmpresa extends Equatable {
  final String id;
  final String nombre;
  final String? logo;
  final String? rubro;
  final String? telefono;
  final String? email;
  final String? descripcion;
  final String? descripcionTercerizacion;
  final List<String> tiposServicioTercerizacion;
  final String? departamento;
  final String? provincia;
  final String? distrito;
  final String? direccionFiscal;
  final SedePrincipal? sedePrincipal;
  final List<ServicioResumen> servicios;

  const DirectorioEmpresa({
    required this.id,
    required this.nombre,
    this.logo,
    this.rubro,
    this.telefono,
    this.email,
    this.descripcion,
    this.descripcionTercerizacion,
    this.tiposServicioTercerizacion = const [],
    this.departamento,
    this.provincia,
    this.distrito,
    this.direccionFiscal,
    this.sedePrincipal,
    this.servicios = const [],
  });

  String get ubicacion {
    final parts = [distrito, provincia, departamento]
        .where((p) => p != null && p.isNotEmpty)
        .toList();
    return parts.isNotEmpty ? parts.join(', ') : 'Sin ubicación';
  }

  @override
  List<Object?> get props => [id];
}

class SedePrincipal extends Equatable {
  final String id;
  final String nombre;
  final String? direccion;
  final String? distrito;
  final String? provincia;
  final String? departamento;
  final Map<String, dynamic>? coordenadas;
  final String? telefono;
  final dynamic horarioAtencion;

  const SedePrincipal({
    required this.id,
    required this.nombre,
    this.direccion,
    this.distrito,
    this.provincia,
    this.departamento,
    this.coordenadas,
    this.telefono,
    this.horarioAtencion,
  });

  String get ubicacionCompleta {
    final parts = [direccion, distrito, provincia, departamento]
        .where((p) => p != null && p.isNotEmpty)
        .toList();
    return parts.isNotEmpty ? parts.join(', ') : 'Sin dirección';
  }

  @override
  List<Object?> get props => [id];
}

class ServicioResumen extends Equatable {
  final String id;
  final String nombre;
  final double? precio;

  const ServicioResumen({
    required this.id,
    required this.nombre,
    this.precio,
  });

  @override
  List<Object?> get props => [id];
}

class DirectorioPaginado {
  final List<DirectorioEmpresa> data;
  final int total;
  final int page;
  final int totalPages;

  const DirectorioPaginado({
    required this.data,
    required this.total,
    required this.page,
    required this.totalPages,
  });
}
