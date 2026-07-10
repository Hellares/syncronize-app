import '../../../sorteo/domain/entities/sorteo.dart';

/// Premio ganado — vista del CLIENTE ("Mis Premios"): incluye de qué
/// empresa/sorteo viene, el estado del envío, la foto del ticket de
/// agencia y (si es retiro) los datos de la tienda.
class PremioCliente {
  final String id;
  final String descripcion;
  final int cantidad;
  final ModalidadEntregaPremio modalidad;
  final String? agenciaNombre;
  final String? destinoDepartamento;
  final String? destinoProvincia;
  final String? agenciaDireccion;

  /// Datos del despacho — la CLAVE es la que pide la agencia al entregar.
  final String? envioNumeroOrden;
  final String? envioCodigo;
  final String? envioClave;
  final EstadoPremioSorteo estado;
  final DateTime? enviadoEn;
  final DateTime? entregadoEn;
  final DateTime creadoEn;
  final List<TicketEnvio> tickets;

  /// Fotos del premio ganado (la empresa las sube — imagen destacada).
  final List<TicketEnvio> fotos;

  // Del sorteo/empresa
  final String sorteoTitulo;
  final DateTime? fechaSorteo;
  final String empresaNombre;
  final String? empresaLogo;
  final String? empresaTelefono;

  // Sede de retiro (solo RETIRO_TIENDA)
  final String? sedeRetiroNombre;
  final String? sedeRetiroDireccion;
  final String? sedeRetiroTelefono;

  const PremioCliente({
    required this.id,
    required this.descripcion,
    this.cantidad = 1,
    required this.modalidad,
    this.agenciaNombre,
    this.destinoDepartamento,
    this.destinoProvincia,
    this.agenciaDireccion,
    this.envioNumeroOrden,
    this.envioCodigo,
    this.envioClave,
    required this.estado,
    this.enviadoEn,
    this.entregadoEn,
    required this.creadoEn,
    this.tickets = const [],
    this.fotos = const [],
    required this.sorteoTitulo,
    this.fechaSorteo,
    required this.empresaNombre,
    this.empresaLogo,
    this.empresaTelefono,
    this.sedeRetiroNombre,
    this.sedeRetiroDireccion,
    this.sedeRetiroTelefono,
  });

  /// "Tarapoto, San Martín" (destino del envío por agencia).
  String? get destinoTexto {
    final partes = [destinoProvincia, destinoDepartamento]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList();
    return partes.isEmpty ? null : partes.join(', ');
  }
}
