import '../../domain/entities/cliente_empresa.dart';

class ClienteEmpresaModel extends ClienteEmpresa {
  const ClienteEmpresaModel({
    required super.id,
    required super.empresaId,
    required super.codigo,
    required super.razonSocial,
    super.nombreComercial,
    super.tipoDocumento,
    required super.numeroDocumento,
    super.email,
    super.telefono,
    super.direccion,
    super.isActive,
    super.contactos,
  });

  factory ClienteEmpresaModel.fromJson(Map<String, dynamic> json) {
    return ClienteEmpresaModel(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String,
      codigo: json['codigo'] as String? ?? '',
      razonSocial: json['razonSocial'] as String? ?? '',
      nombreComercial: json['nombreComercial'] as String?,
      tipoDocumento: json['tipoDocumento'] as String? ?? 'RUC',
      numeroDocumento: json['numeroDocumento'] as String? ?? '',
      email: json['email'] as String?,
      telefono: json['telefono'] as String?,
      direccion: json['direccion'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      contactos: json['contactos'] != null
          ? (json['contactos'] as List)
              .map((e) => ClienteEmpresaContactoModel.fromJson(
                  e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  /// Para persistir el catálogo local (delta-sync).
  Map<String, dynamic> toJson() => {
        'id': id,
        'empresaId': empresaId,
        'codigo': codigo,
        'razonSocial': razonSocial,
        'nombreComercial': nombreComercial,
        'tipoDocumento': tipoDocumento,
        'numeroDocumento': numeroDocumento,
        'email': email,
        'telefono': telefono,
        'direccion': direccion,
        'isActive': isActive,
        'contactos': contactos
            ?.map((c) => ClienteEmpresaContactoModel.fromEntity(c).toJson())
            .toList(),
      };

  factory ClienteEmpresaModel.fromEntity(ClienteEmpresa e) {
    if (e is ClienteEmpresaModel) return e;
    return ClienteEmpresaModel(
      id: e.id,
      empresaId: e.empresaId,
      codigo: e.codigo,
      razonSocial: e.razonSocial,
      nombreComercial: e.nombreComercial,
      tipoDocumento: e.tipoDocumento,
      numeroDocumento: e.numeroDocumento,
      email: e.email,
      telefono: e.telefono,
      direccion: e.direccion,
      isActive: e.isActive,
      contactos: e.contactos,
    );
  }
}

class ClienteEmpresaContactoModel extends ClienteEmpresaContacto {
  const ClienteEmpresaContactoModel({
    required super.id,
    required super.nombre,
    super.cargo,
    super.dni,
    super.email,
    super.telefono,
    super.telefonoMovil,
    super.esPrincipal,
  });

  factory ClienteEmpresaContactoModel.fromJson(Map<String, dynamic> json) {
    return ClienteEmpresaContactoModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String? ?? '',
      cargo: json['cargo'] as String?,
      dni: json['dni'] as String?,
      email: json['email'] as String?,
      telefono: json['telefono'] as String?,
      telefonoMovil: json['telefonoMovil'] as String?,
      esPrincipal: json['esPrincipal'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'cargo': cargo,
        'dni': dni,
        'email': email,
        'telefono': telefono,
        'telefonoMovil': telefonoMovil,
        'esPrincipal': esPrincipal,
      };

  factory ClienteEmpresaContactoModel.fromEntity(ClienteEmpresaContacto e) {
    if (e is ClienteEmpresaContactoModel) return e;
    return ClienteEmpresaContactoModel(
      id: e.id,
      nombre: e.nombre,
      cargo: e.cargo,
      dni: e.dni,
      email: e.email,
      telefono: e.telefono,
      telefonoMovil: e.telefonoMovil,
      esPrincipal: e.esPrincipal,
    );
  }
}
