/// Orden de servicio cobrable desde Venta Rápida.
///
/// Payload liviano de `GET /ordenes-servicio/cobrables`: órdenes en
/// REPARADO/LISTO_ENTREGA con saldo pendiente > 0 y sin venta vinculada.
/// Al agregarla al carrito entra como línea con `ordenServicioId`,
/// cantidad fija 1 y precio = [saldoPendiente].
class OrdenCobrable {
  final String id;
  final String codigo;
  final String estado; // REPARADO | LISTO_ENTREGA
  final String tipoServicio;
  final String? servicioNombre;
  final String? tipoEquipo;
  final String? marcaEquipo;
  final String? numeroSerie;
  final double costoTotal;
  final double adelanto;
  final double descuento;
  final double saldoPendiente;
  final OrdenCobrableCliente? cliente;
  final OrdenCobrableClienteEmpresa? clienteEmpresa;

  const OrdenCobrable({
    required this.id,
    required this.codigo,
    required this.estado,
    required this.tipoServicio,
    this.servicioNombre,
    this.tipoEquipo,
    this.marcaEquipo,
    this.numeroSerie,
    required this.costoTotal,
    required this.adelanto,
    required this.descuento,
    required this.saldoPendiente,
    this.cliente,
    this.clienteEmpresa,
  });

  /// Nombre para mostrar: razón social (B2B) o nombre de la persona.
  String get clienteNombre =>
      clienteEmpresa?.razonSocial ?? cliente?.nombre ?? 'Sin cliente';

  /// Descripción del equipo para la línea del carrito (ej. "LAPTOP DELL").
  String get equipoDescripcion =>
      [tipoEquipo, marcaEquipo].whereType<String>().join(' ').trim();

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  factory OrdenCobrable.fromJson(Map<String, dynamic> json) {
    return OrdenCobrable(
      id: json['id'] as String,
      codigo: json['codigo'] as String? ?? '',
      estado: json['estado'] as String? ?? '',
      tipoServicio: json['tipoServicio'] as String? ?? '',
      servicioNombre: json['servicioNombre'] as String?,
      tipoEquipo: json['tipoEquipo'] as String?,
      marcaEquipo: json['marcaEquipo'] as String?,
      numeroSerie: json['numeroSerie'] as String?,
      costoTotal: _toDouble(json['costoTotal']),
      adelanto: _toDouble(json['adelanto']),
      descuento: _toDouble(json['descuento']),
      saldoPendiente: _toDouble(json['saldoPendiente']),
      cliente: json['cliente'] is Map
          ? OrdenCobrableCliente.fromJson(
              Map<String, dynamic>.from(json['cliente'] as Map))
          : null,
      clienteEmpresa: json['clienteEmpresa'] is Map
          ? OrdenCobrableClienteEmpresa.fromJson(
              Map<String, dynamic>.from(json['clienteEmpresa'] as Map))
          : null,
    );
  }
}

/// Cliente persona (EmpresaPersona) de la orden — para pre-cargar la venta.
class OrdenCobrableCliente {
  final String clienteId;
  final String nombre;
  final String? numeroDocumento;
  final String? telefono;
  final String? email;

  const OrdenCobrableCliente({
    required this.clienteId,
    required this.nombre,
    this.numeroDocumento,
    this.telefono,
    this.email,
  });

  factory OrdenCobrableCliente.fromJson(Map<String, dynamic> json) {
    return OrdenCobrableCliente(
      clienteId: json['clienteId'] as String,
      nombre: json['nombre'] as String? ?? '',
      numeroDocumento: json['numeroDocumento'] as String?,
      telefono: json['telefono'] as String?,
      email: json['email'] as String?,
    );
  }
}

/// Cliente B2B (ClienteEmpresa) de la orden — para pre-cargar la venta.
class OrdenCobrableClienteEmpresa {
  final String clienteEmpresaId;
  final String razonSocial;
  final String? ruc;
  final String? email;
  final String? direccion;

  const OrdenCobrableClienteEmpresa({
    required this.clienteEmpresaId,
    required this.razonSocial,
    this.ruc,
    this.email,
    this.direccion,
  });

  factory OrdenCobrableClienteEmpresa.fromJson(Map<String, dynamic> json) {
    return OrdenCobrableClienteEmpresa(
      clienteEmpresaId: json['clienteEmpresaId'] as String,
      razonSocial: json['razonSocial'] as String? ?? '',
      ruc: json['ruc'] as String?,
      email: json['email'] as String?,
      direccion: json['direccion'] as String?,
    );
  }
}
