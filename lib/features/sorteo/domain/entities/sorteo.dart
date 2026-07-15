// Sorteos por redes sociales (lado empresa): registro de ganadores con
// premio (vínculo a inventario opcional) y envío trackeable.

enum EstadoSorteo {
  abierto('ABIERTO', 'Abierto'),
  cerrado('CERRADO', 'Cerrado'),
  finalizado('FINALIZADO', 'Finalizado');

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

/// Última entrega POR AGENCIA registrada para un DNI — para prellenar
/// el registro cuando el mismo participante gana otra vez (sus datos
/// de agencia/destino casi nunca cambian entre sorteos).
class EntregaPreviaGanador {
  final String? agenciaNombre;
  final String? destinoDepartamento;
  final String? destinoProvincia;
  final String? agenciaDireccion;

  const EntregaPreviaGanador({
    this.agenciaNombre,
    this.destinoDepartamento,
    this.destinoProvincia,
    this.agenciaDireccion,
  });
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

/// Ganador de una unidad del catálogo (con el ticket que salió).
class GanadorCatalogo {
  final String nombre;
  final int? numeroTicket;

  const GanadorCatalogo({required this.nombre, this.numeroTicket});
}

/// Item del catálogo de premios de la RIFA con ánfora: se registra
/// antes de jugar ("3× S/ 500 EN EFECTIVO") y cada unidad se adjudica
/// al salir un ticket ganador.
class SorteoPremioCatalogo {
  final String id;
  final String descripcion;
  final int cantidad;

  /// Premio en EFECTIVO 💸: se yapea al ganador (el bot le confirma su
  /// número de abono en vez de pedirle dirección de agencia).
  final bool esEfectivo;
  final int sorteados;
  final List<GanadorCatalogo> ganadores;
  final String? imagenUrl;
  final String? imagenThumbnail;

  const SorteoPremioCatalogo({
    required this.id,
    required this.descripcion,
    this.cantidad = 1,
    this.esEfectivo = false,
    this.sorteados = 0,
    this.ganadores = const [],
    this.imagenUrl,
    this.imagenThumbnail,
  });

  bool get agotado => sorteados >= cantidad;
}

/// SORTEO clásico (se sortea entre participantes) o DINÁMICA (el
/// participante paga, juega — canasta, etc. — y lo que saca YA lo ganó:
/// cada jugador termina registrado como ganador con su premio).
enum TipoSorteo {
  sorteo('SORTEO', 'Sorteo'),
  dinamica('DINAMICA', 'Dinámica'),
  bingo('BINGO', 'Bingo');

  final String apiValue;
  final String label;
  const TipoSorteo(this.apiValue, this.label);

  static TipoSorteo fromApi(String? v) => TipoSorteo.values.firstWhere(
        (e) => e.apiValue == v,
        orElse: () => TipoSorteo.sorteo,
      );
}

class Sorteo {
  final String id;
  final String? sedeId;
  final String titulo;
  final String? descripcion;
  final CanalSorteo canal;
  final TipoSorteo tipo;
  final DateTime fechaSorteo;

  /// Ventana de VENTA de tickets (informativa; el cierre es manual).
  final DateTime? ventaDesde;
  final DateTime? ventaHasta;
  final EstadoSorteo estado;

  /// Se reabrió tras cerrarse (solo para regularizar): el bot de
  /// WhatsApp lo ignora por completo.
  final bool reabierto;

  /// Precio default de la participación ("jugada") en S/.
  final double? precioParticipacion;
  final int cantidadPremios;
  final List<SorteoPremio> premios;

  /// Imágenes promocionales (la más reciente primero).
  final List<TicketEnvio> imagenes;
  final ResumenSorteo? resumen;

  /// Participantes captados por el BOT de WhatsApp (Fase A).
  final List<SorteoParticipante> participantes;

  /// Catálogo de premios de la rifa (tipo SORTEO).
  final List<SorteoPremioCatalogo> premiosCatalogo;

  /// BINGO: bolillas cantadas en orden.
  final List<int> bolillas;

  const Sorteo({
    required this.id,
    this.sedeId,
    required this.titulo,
    this.descripcion,
    required this.canal,
    this.tipo = TipoSorteo.sorteo,
    required this.fechaSorteo,
    this.ventaDesde,
    this.ventaHasta,
    required this.estado,
    this.reabierto = false,
    this.precioParticipacion,
    this.cantidadPremios = 0,
    this.premios = const [],
    this.imagenes = const [],
    this.resumen,
    this.participantes = const [],
    this.premiosCatalogo = const [],
    this.bolillas = const [],
  });

  /// Etiqueta visual del estado: la rifa/bingo CERRADO aún está en
  /// juego ("JUGANDO") hasta que se marque FINALIZADO.
  String get estadoTexto {
    if (estado == EstadoSorteo.cerrado && tipo != TipoSorteo.dinamica) {
      return tipo == TipoSorteo.bingo ? 'Jugando 🎱' : 'Jugando 🎲';
    }
    return estado.label;
  }
}

enum EstadoParticipanteSorteo {
  pendientePago('PENDIENTE_PAGO', 'Pago pendiente'),
  activo('ACTIVO', 'Activo'),
  rechazado('RECHAZADO', 'Rechazado');

  final String apiValue;
  final String label;
  const EstadoParticipanteSorteo(this.apiValue, this.label);

  static EstadoParticipanteSorteo fromApi(String? v) =>
      EstadoParticipanteSorteo.values.firstWhere(
        (e) => e.apiValue == v,
        orElse: () => EstadoParticipanteSorteo.pendientePago,
      );
}

/// Participante registrado por el bot de WhatsApp: la empresa valida el
/// pago por fuera y lo ACTIVA (se le asigna numeroTicket y el bot le
/// confirma por WhatsApp).
class SorteoParticipante {
  final String id;
  final String celular;
  final String nombre;
  final String dni;
  final EstadoParticipanteSorteo estado;
  final int? numeroTicket;

  /// COMPRA de tickets (tipo SORTEO): "quiero 20" = 20 filas con el
  /// mismo compraId — un pago, una validación, tickets consecutivos.
  final String? compraId;

  /// REGALO: quien recibe el premio si NO es el propio jugador.
  final String? recibeNombre;
  final String? recibeDni;

  /// Quién hará el YAPE si NO es el propio jugador (null = él mismo) —
  /// clave para cuadrar la notificación de Yape al validar.
  final String? pagadorNombre;
  final String? pagadorCelular;

  /// Datos de envío que dejó en el bot al registrarse (opcionales) —
  /// si gana, la entrega ya está lista.
  final String? agenciaNombre;
  final String? destinoDepartamento;
  final String? destinoProvincia;
  final String? agenciaDireccion;
  final DateTime creadoEn;

  const SorteoParticipante({
    required this.id,
    required this.celular,
    required this.nombre,
    required this.dni,
    required this.estado,
    this.numeroTicket,
    this.compraId,
    this.recibeNombre,
    this.recibeDni,
    this.pagadorNombre,
    this.pagadorCelular,
    this.agenciaNombre,
    this.destinoDepartamento,
    this.destinoProvincia,
    this.agenciaDireccion,
    required this.creadoEn,
  });

  /// "MARÍA LÓPEZ · 987654321" — quien yapea si no es el jugador (o null).
  String? get pagadorTexto {
    if (pagadorNombre == null || pagadorNombre!.isEmpty) return null;
    return [
      pagadorNombre,
      if (pagadorCelular != null && pagadorCelular!.isNotEmpty)
        '· $pagadorCelular',
    ].join(' ');
  }

  /// "SHALOM → TARAPOTO, SAN MARTÍN · JR. LOS PINOS 123" (o null).
  String? get envioTexto {
    if (agenciaNombre == null || agenciaNombre!.isEmpty) return null;
    final destino = [destinoProvincia, destinoDepartamento]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(', ');
    return [
      agenciaNombre,
      if (destino.isNotEmpty) '→ $destino',
      if (agenciaDireccion != null && agenciaDireccion!.isNotEmpty)
        '· $agenciaDireccion',
    ].join(' ');
  }
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

  /// Participación (SorteoParticipante) que originó este premio — un
  /// DNI puede jugar varias veces y cada jugada tiene su premio.
  final String? participanteId;

  /// REGALO: quien recibe (null = el propio ganador). El rotulo usa
  /// estos datos como destinatario.
  final String? recibeNombre;
  final String? recibeDni;
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

  /// Premio en EFECTIVO 💸: se yapea al ganador (sin envío por agencia).
  /// [abonoNumero] = número confirmado por el ganador con el bot
  /// (null = aún no confirma; fallback su celular).
  final bool esEfectivo;
  final String? abonoNumero;

  /// Rótulo de envío ya impreso (chip IMPRESO en la card).
  final DateTime? rotuloImpresoEn;

  /// Ticket enviado por WhatsApp automático al ganador (chip en la card).
  final DateTime? whatsappEnviadoEn;
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
    this.participanteId,
    this.recibeNombre,
    this.recibeDni,
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
    this.esEfectivo = false,
    this.abonoNumero,
    this.rotuloImpresoEn,
    this.whatsappEnviadoEn,
    required this.estado,
    this.enviadoEn,
    this.entregadoEn,
    this.observaciones,
    required this.creadoEn,
    this.tickets = const [],
    this.fotos = const [],
  });

  bool get rotuloImpreso => rotuloImpresoEn != null;

  /// El premio lo recibe OTRA persona (regalo del jugador).
  bool get esRegalo => recibeNombre != null && recibeNombre!.isNotEmpty;

  /// El ticket ya le llegó al ganador por WhatsApp automático.
  bool get whatsappEnviado => whatsappEnviadoEn != null;

  /// "Tarapoto, San Martín" (o lo que haya).
  String? get destinoTexto {
    final partes = [destinoProvincia, destinoDepartamento]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList();
    return partes.isEmpty ? null : partes.join(', ');
  }
}
