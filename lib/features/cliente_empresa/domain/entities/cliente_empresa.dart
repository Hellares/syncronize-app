import 'package:equatable/equatable.dart';

class ClienteEmpresa extends Equatable {
  final String id;
  final String empresaId;
  final String codigo;
  final String razonSocial;
  final String? nombreComercial;
  final String tipoDocumento;
  final String numeroDocumento;
  final String? email;
  final String? telefono;
  final String? direccion;
  final bool isActive;
  final List<ClienteEmpresaContacto>? contactos;

  const ClienteEmpresa({
    required this.id,
    required this.empresaId,
    required this.codigo,
    required this.razonSocial,
    this.nombreComercial,
    this.tipoDocumento = 'RUC',
    required this.numeroDocumento,
    this.email,
    this.telefono,
    this.direccion,
    this.isActive = true,
    this.contactos,
  });

  String get nombreDisplay => nombreComercial ?? razonSocial;

  String get iniciales {
    final name = nombreDisplay;
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  ClienteEmpresaContacto? get contactoPrincipal {
    if (contactos == null || contactos!.isEmpty) return null;
    final principal = contactos!.where((c) => c.esPrincipal).firstOrNull;
    return principal ?? contactos!.first;
  }

  @override
  List<Object?> get props => [id, razonSocial, numeroDocumento];
}

class ClienteEmpresaContacto extends Equatable {
  final String id;
  final String nombre;
  final String? cargo;
  final String? dni;
  final String? email;
  final String? telefono;
  final String? telefonoMovil;
  final bool esPrincipal;

  const ClienteEmpresaContacto({
    required this.id,
    required this.nombre,
    this.cargo,
    this.dni,
    this.email,
    this.telefono,
    this.telefonoMovil,
    this.esPrincipal = false,
  });

  @override
  List<Object?> get props => [id, nombre];
}

class ClienteEmpresaCreado {
  final ClienteEmpresa clienteEmpresa;
  final EmpresaVinculableInfo? empresaVinculable;

  const ClienteEmpresaCreado({
    required this.clienteEmpresa,
    this.empresaVinculable,
  });
}

class EmpresaVinculableInfo {
  final String id;
  final String nombre;
  final String? logo;
  final String? rubro;

  const EmpresaVinculableInfo({
    required this.id,
    required this.nombre,
    this.logo,
    this.rubro,
  });
}

class ClientesEmpresaPaginados {
  final List<ClienteEmpresa> data;
  final int total;

  const ClientesEmpresaPaginados({
    required this.data,
    required this.total,
  });
}
