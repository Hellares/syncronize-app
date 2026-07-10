// Sorteos por redes sociales (lado empresa): registro de ganadores con
// premio (vínculo a inventario opcional) y envío trackeable.

enum EstadoSorteo {
  abierto('ABIERTO', 'Abierto'),
  cerrado('CERRADO', 'Cerrado');

  final String apiValue;
  final String label;
  const EstadoSorteo(this.apiValue, this.label);

  static EstadoSorteo fromApi(String? v) => EstadoSorteo.values.firstWhere(
        (e) => e.apiValue == v,
        orElse: () => EstadoSorteo.abierto,
      );
}

enum CanalSorteo {
  facebook('FACEBOOK', 'Facebook'),
  instagram('INSTAGRAM', 'Instagram'),
  tiktok('TIKTOK', 'TikTok'),
  whatsapp('WHATSAPP', 'WhatsApp'),
  otro('OTRO', 'Otro');

  final String apiValue;
  final String label;
  const CanalSorteo(this.apiValue, this.label);

  static CanalSorteo fromApi(String? v) => CanalSorteo.values.firstWhere(
        (e) => e.apiValue == v,
        orElse: () => CanalSorteo.otro,
      );
}

enum EstadoPremioSorteo {
  registrado('REGISTRADO', 'Registrado'),
  preparando('PREPARANDO', 'Preparando'),
  enviado('ENVIADO', 'Enviado'),
  entregado('ENTREGADO', 'Entregado'),
  anulado('ANULADO', 'Anulado');

  final String apiValue;
  final String label;
  const EstadoPremioSorteo(this.apiValue, this.label);

  static EstadoPremioSorteo fromApi(String? v) =>
      EstadoPremioSorteo.values.firstWhere(
        (e) => e.apiValue == v,
        orElse: () => EstadoPremioSorteo.registrado,
      );
}

enum ModalidadEntregaPremio {
  envioAgencia('ENVIO_AGENCIA', 'Envío por agencia'),
  retiroTienda('RETIRO_TIENDA', 'Retiro en tienda');

  final String apiValue;
  final String label;
  const ModalidadEntregaPremio(this.apiValue, this.label);

  static ModalidadEntregaPremio fromApi(String? v) =>
      ModalidadEntregaPremio.values.firstWhere(
        (e) => e.apiValue == v,
        orElse: () => ModalidadEntregaPremio.retiroTienda,
      );
}

/// Economía del sorteo (solo en el detalle): recaudado por
/// participaciones, costo real de los premios (kardex) y ganancia.
class ResumenSorteo {
  final double totalRecaudado;
  final double costoPremios;
  final double ganancia;

  const ResumenSorteo({
    this.totalRecaudado = 0,
    this.costoPremios = 0,
    this.ganancia = 0,
  });
}

class Sorteo {
  final String id;
  final String? sedeId;
  final String titulo;
  final String? descripcion;
  final CanalSorteo canal;
  final DateTime fechaSorteo;
  final EstadoSorteo estado;

  /// Precio default de la participación ("jugada") en S/.
  final double? precioParticipacion;
  final int cantidadPremios;
  final List<SorteoPremio> premios;

  /// Imágenes promocionales (la más reciente primero).
  final List<TicketEnvio> imagenes;
  final ResumenSorteo? resumen;

  const Sorteo({
    required this.id,
    this.sedeId,
    required this.titulo,
    this.descripcion,
    required this.canal,
    required this.fechaSorteo,
    required this.estado,
    this.precioParticipacion,
    this.cantidadPremios = 0,
    this.premios = const [],
    this.imagenes = const [],
    this.resumen,
  });
}

class TicketEnvio {
  final String id;
  final String url;
  final String? urlThumbnail;

  const TicketEnvio({required this.id, required this.url, this.urlThumbnail});
}

class SorteoPremio {
  final String id;
  final String sorteoId;
  final String ganadorId;
  final String? ganadorDni;
  final String ganadorNombre;
  final String? ganadorCelular;
  final String descripcion;
  final String? productoId;
  final String? varianteId;
  final int cantidad;
  final bool descuentaStock;

  /// Lo que ESTE ganador pagó por participar (S/).
  final double? montoParticipacion;
  final ModalidadEntregaPremio modalidad;
  final String? agenciaNombre;

  /// Destino desglosado: "envío a San Martín, Tarapoto".
  final String? destinoDepartamento;
  final String? destinoProvincia;

  /// Dirección de la oficina de la agencia destino.
  final String? agenciaDireccion;

  /// Datos del despacho de agencia (el ganador los ve en Mis Premios;
  /// la CLAVE es la que pide la agencia para entregar).
  final String? envioNumeroOrden;
  final String? envioCodigo;
  final String? envioClave;
  final EstadoPremioSorteo estado;
  final DateTime? enviadoEn;
  final DateTime? entregadoEn;
  final String? observaciones;
  final DateTime creadoEn;
  final List<TicketEnvio> tickets;

  /// Fotos del premio ganado (categoría PRINCIPAL).
  final List<TicketEnvio> fotos;

  const SorteoPremio({
    required this.id,
    required this.sorteoId,
    required this.ganadorId,
    this.ganadorDni,
    required this.ganadorNombre,
    this.ganadorCelular,
    required this.descripcion,
    this.productoId,
    this.varianteId,
    this.cantidad = 1,
    this.descuentaStock = false,
    this.montoParticipacion,
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
    this.observaciones,
    required this.creadoEn,
    this.tickets = const [],
    this.fotos = const [],
  });

  /// "Tarapoto, San Martín" (o lo que haya).
  String? get destinoTexto {
    final partes = [destinoProvincia, destinoDepartamento]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList();
    return partes.isEmpty ? null : partes.join(', ');
  }
}
