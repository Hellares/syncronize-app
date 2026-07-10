import '../../../sorteo/domain/entities/sorteo.dart';
import '../../domain/entities/premio_cliente.dart';

DateTime? _fecha(dynamic v) => v is String ? DateTime.tryParse(v) : null;

class PremioClienteModel {
  final Map<String, dynamic> json;
  PremioClienteModel(this.json);

  factory PremioClienteModel.fromJson(Map<String, dynamic> json) =>
      PremioClienteModel(json);

  PremioCliente toEntity() {
    final sorteo = (json['sorteo'] as Map?)?.cast<String, dynamic>();
    final empresa = (sorteo?['empresa'] as Map?)?.cast<String, dynamic>();
    final sede = (json['sedeRetiro'] as Map?)?.cast<String, dynamic>();
    final ticketsJson = (json['tickets'] as List?) ?? const [];
    final fotosJson = (json['fotos'] as List?) ?? const [];

    final direccionPartes = [
      sede?['direccion'],
      sede?['distrito'],
      sede?['provincia'],
    ].whereType<String>().where((s) => s.isNotEmpty).toList();

    return PremioCliente(
      id: json['id'] as String,
      descripcion: json['descripcion'] as String? ?? '',
      cantidad: (json['cantidad'] as num?)?.toInt() ?? 1,
      modalidad: ModalidadEntregaPremio.fromApi(json['modalidad'] as String?),
      agenciaNombre: json['agenciaNombre'] as String?,
      destinoDepartamento: json['destinoDepartamento'] as String?,
      destinoProvincia: json['destinoProvincia'] as String?,
      agenciaDireccion: json['agenciaDireccion'] as String?,
      envioNumeroOrden: json['envioNumeroOrden'] as String?,
      envioCodigo: json['envioCodigo'] as String?,
      envioClave: json['envioClave'] as String?,
      estado: EstadoPremioSorteo.fromApi(json['estado'] as String?),
      enviadoEn: _fecha(json['enviadoEn']),
      entregadoEn: _fecha(json['entregadoEn']),
      creadoEn: _fecha(json['creadoEn']) ?? DateTime.now(),
      tickets: ticketsJson
          .map((e) => TicketEnvio(
                id: (e as Map)['id'] as String? ?? '',
                url: e['url'] as String? ?? '',
                urlThumbnail: e['urlThumbnail'] as String?,
              ))
          .toList(),
      fotos: fotosJson
          .map((e) => TicketEnvio(
                id: (e as Map)['id'] as String? ?? '',
                url: e['url'] as String? ?? '',
                urlThumbnail: e['urlThumbnail'] as String?,
              ))
          .toList(),
      sorteoTitulo: sorteo?['titulo'] as String? ?? 'Sorteo',
      fechaSorteo: _fecha(sorteo?['fechaSorteo']),
      empresaNombre: empresa?['nombre'] as String? ?? '',
      empresaLogo: empresa?['logo'] as String?,
      empresaTelefono: empresa?['telefono'] as String?,
      sedeRetiroNombre: sede?['nombre'] as String?,
      sedeRetiroDireccion:
          direccionPartes.isEmpty ? null : direccionPartes.join(', '),
      sedeRetiroTelefono: sede?['telefono'] as String?,
    );
  }
}
