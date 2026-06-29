/// Estado de cuenta de un cliente: identidad + resumen + ventas a crédito +
/// timeline de abonos. Mapea la respuesta de
/// `GET /cuentas-por-cobrar/estado-cuenta-cliente`.
class EstadoCuentaCliente {
  final ClienteInfo cliente;
  final ResumenEstadoCuenta resumen;
  final List<VentaCreditoItem> ventas;
  final List<AbonoItem> abonos;

  const EstadoCuentaCliente({
    required this.cliente,
    required this.resumen,
    required this.ventas,
    required this.abonos,
  });

  factory EstadoCuentaCliente.fromJson(Map<String, dynamic> json) {
    return EstadoCuentaCliente(
      cliente: ClienteInfo.fromJson(json['cliente'] as Map<String, dynamic>? ?? {}),
      resumen: ResumenEstadoCuenta.fromJson(json['resumen'] as Map<String, dynamic>? ?? {}),
      ventas: (json['ventas'] as List<dynamic>? ?? [])
          .map((e) => VentaCreditoItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      abonos: (json['abonos'] as List<dynamic>? ?? [])
          .map((e) => AbonoItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

double _d(dynamic v) => v == null ? 0 : (v as num).toDouble();
int _i(dynamic v) => v == null ? 0 : (v as num).toInt();

class ClienteInfo {
  final String? id;
  final String tipo; // PERSONA | EMPRESA
  final String? nombre;
  final String? documento;

  const ClienteInfo({this.id, required this.tipo, this.nombre, this.documento});

  factory ClienteInfo.fromJson(Map<String, dynamic> j) => ClienteInfo(
        id: j['id'] as String?,
        tipo: (j['tipo'] as String?) ?? 'PERSONA',
        nombre: j['nombre'] as String?,
        documento: j['documento'] as String?,
      );
}

class ResumenEstadoCuenta {
  final double saldoPendiente;
  final double totalVendido;
  final double totalAbonado;
  final double totalMora;
  final int cantidadVentas;
  final int ventasConSaldo;

  const ResumenEstadoCuenta({
    required this.saldoPendiente,
    required this.totalVendido,
    required this.totalAbonado,
    required this.totalMora,
    required this.cantidadVentas,
    required this.ventasConSaldo,
  });

  factory ResumenEstadoCuenta.fromJson(Map<String, dynamic> j) => ResumenEstadoCuenta(
        saldoPendiente: _d(j['saldoPendiente']),
        totalVendido: _d(j['totalVendido']),
        totalAbonado: _d(j['totalAbonado']),
        totalMora: _d(j['totalMora']),
        cantidadVentas: _i(j['cantidadVentas']),
        ventasConSaldo: _i(j['ventasConSaldo']),
      );
}

class VentaCreditoItem {
  final String ventaId;
  final String codigo;
  final DateTime? fechaVenta;
  final double total;
  final double totalPagado;
  final double saldoPendiente;
  final String estado;
  final DateTime? fechaVencimiento;
  final int? numeroCuotas;
  final double totalMora;

  const VentaCreditoItem({
    required this.ventaId,
    required this.codigo,
    this.fechaVenta,
    required this.total,
    required this.totalPagado,
    required this.saldoPendiente,
    required this.estado,
    this.fechaVencimiento,
    this.numeroCuotas,
    required this.totalMora,
  });

  factory VentaCreditoItem.fromJson(Map<String, dynamic> j) => VentaCreditoItem(
        ventaId: j['ventaId'] as String? ?? '',
        codigo: j['codigo'] as String? ?? '',
        fechaVenta: j['fechaVenta'] != null ? DateTime.tryParse(j['fechaVenta'].toString()) : null,
        total: _d(j['total']),
        totalPagado: _d(j['totalPagado']),
        saldoPendiente: _d(j['saldoPendiente']),
        estado: j['estado'] as String? ?? '',
        fechaVencimiento: j['fechaVencimiento'] != null ? DateTime.tryParse(j['fechaVencimiento'].toString()) : null,
        numeroCuotas: j['numeroCuotas'] != null ? _i(j['numeroCuotas']) : null,
        totalMora: _d(j['totalMora']),
      );
}

class AbonoItem {
  final String id;
  final double monto;
  final String metodoPago;
  final String? fuente; // TESORERIA | CAJA | BANCO
  final DateTime? fechaPago;
  final String? ventaCodigo;

  const AbonoItem({
    required this.id,
    required this.monto,
    required this.metodoPago,
    this.fuente,
    this.fechaPago,
    this.ventaCodigo,
  });

  factory AbonoItem.fromJson(Map<String, dynamic> j) => AbonoItem(
        id: j['id'] as String? ?? '',
        monto: _d(j['monto']),
        metodoPago: j['metodoPago'] as String? ?? '',
        fuente: j['fuente'] as String?,
        fechaPago: j['fechaPago'] != null ? DateTime.tryParse(j['fechaPago'].toString()) : null,
        ventaCodigo: j['ventaCodigo'] as String?,
      );
}
