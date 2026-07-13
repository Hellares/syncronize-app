import '../../domain/entities/sorteo.dart';

/// Parser tolerante de fechas ISO (null-safe).
DateTime? _fecha(dynamic v) => v is String ? DateTime.tryParse(v) : null;

/// Prisma serializa Decimal como String en JSON — parser tolerante
/// (gotcha conocido: `as num?` revienta).
double? _numero(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

List<TicketEnvio> _archivos(dynamic lista) => ((lista as List?) ?? const [])
    .map((e) => TicketEnvio(
          id: (e as Map)['id'] as String? ?? '',
          url: e['url'] as String? ?? '',
          urlThumbnail: e['urlThumbnail'] as String?,
        ))
    .toList();

class SorteoModel {
  final Map<String, dynamic> json;
  SorteoModel(this.json);

  factory SorteoModel.fromJson(Map<String, dynamic> json) =>
      SorteoModel(json);

  Sorteo toEntity() {
    final premiosJson = (json['premios'] as List?) ?? const [];
    final count = json['_count'] is Map
        ? ((json['_count'] as Map)['premios'] as num?)?.toInt()
        : null;
    final resumenJson = (json['resumen'] as Map?)?.cast<String, dynamic>();
    return Sorteo(
      id: json['id'] as String,
      sedeId: json['sedeId'] as String?,
      titulo: json['titulo'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
      canal: CanalSorteo.fromApi(json['canal'] as String?),
      fechaSorteo: _fecha(json['fechaSorteo']) ?? DateTime.now(),
      estado: EstadoSorteo.fromApi(json['estado'] as String?),
      precioParticipacion: _numero(json['precioParticipacion']),
      cantidadPremios: count ?? premiosJson.length,
      premios: premiosJson
          .map((e) =>
              SorteoPremioModel.fromJson(e as Map<String, dynamic>).toEntity())
          .toList(),
      imagenes: _archivos(json['imagenes']),
      participantes: ((json['participantes'] as List?) ?? const [])
          .map((e) => SorteoParticipante(
                id: (e as Map)['id'] as String? ?? '',
                celular: e['celular'] as String? ?? '',
                nombre: e['nombre'] as String? ?? '',
                dni: e['dni'] as String? ?? '',
                estado:
                    EstadoParticipanteSorteo.fromApi(e['estado'] as String?),
                numeroTicket: (e['numeroTicket'] as num?)?.toInt(),
                agenciaNombre: e['agenciaNombre'] as String?,
                destinoDepartamento: e['destinoDepartamento'] as String?,
                destinoProvincia: e['destinoProvincia'] as String?,
                agenciaDireccion: e['agenciaDireccion'] as String?,
                creadoEn: _fecha(e['creadoEn']) ?? DateTime.now(),
              ))
          .toList(),
      resumen: resumenJson == null
          ? null
          : ResumenSorteo(
              totalRecaudado: _numero(resumenJson['totalRecaudado']) ?? 0,
              costoPremios: _numero(resumenJson['costoPremios']) ?? 0,
              ganancia: _numero(resumenJson['ganancia']) ?? 0,
            ),
    );
  }
}

class SorteoPremioModel {
  final Map<String, dynamic> json;
  SorteoPremioModel(this.json);

  factory SorteoPremioModel.fromJson(Map<String, dynamic> json) =>
      SorteoPremioModel(json);

  SorteoPremio toEntity() {
    return SorteoPremio(
      id: json['id'] as String,
      sorteoId: json['sorteoId'] as String? ?? '',
      ganadorId: json['ganadorId'] as String? ?? '',
      ganadorDni: json['ganadorDni'] as String?,
      ganadorNombre: json['ganadorNombre'] as String? ?? '',
      ganadorCelular: json['ganadorCelular'] as String?,
      descripcion: json['descripcion'] as String? ?? '',
      productoId: json['productoId'] as String?,
      varianteId: json['varianteId'] as String?,
      cantidad: (json['cantidad'] as num?)?.toInt() ?? 1,
      descuentaStock: json['movimientoStockId'] != null,
      montoParticipacion: _numero(json['montoParticipacion']),
      modalidad: ModalidadEntregaPremio.fromApi(json['modalidad'] as String?),
      agenciaNombre: json['agenciaNombre'] as String?,
      destinoDepartamento: json['destinoDepartamento'] as String?,
      destinoProvincia: json['destinoProvincia'] as String?,
      agenciaDireccion: json['agenciaDireccion'] as String?,
      envioNumeroOrden: json['envioNumeroOrden'] as String?,
      envioCodigo: json['envioCodigo'] as String?,
      envioClave: json['envioClave'] as String?,
      rotuloImpresoEn: _fecha(json['rotuloImpresoEn']),
      whatsappEnviadoEn: _fecha(json['whatsappEnviadoEn']),
      estado: EstadoPremioSorteo.fromApi(json['estado'] as String?),
      enviadoEn: _fecha(json['enviadoEn']),
      entregadoEn: _fecha(json['entregadoEn']),
      observaciones: json['observaciones'] as String?,
      creadoEn: _fecha(json['creadoEn']) ?? DateTime.now(),
      tickets: _archivos(json['tickets']),
      fotos: _archivos(json['fotos']),
    );
  }
}
