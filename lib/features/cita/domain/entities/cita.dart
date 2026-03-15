import 'package:equatable/equatable.dart';

/// Resúmenes de relaciones embebidas en la cita
class CitaServicioResumen extends Equatable {
  final String id;
  final String nombre;
  final int? duracionMinutos;
  final double? precio;

  const CitaServicioResumen({
    required this.id,
    required this.nombre,
    this.duracionMinutos,
    this.precio,
  });

  @override
  List<Object?> get props => [id, nombre, duracionMinutos, precio];
}

class CitaTecnicoResumen extends Equatable {
  final String id;
  final String nombres;
  final String apellidos;

  const CitaTecnicoResumen({
    required this.id,
    required this.nombres,
    required this.apellidos,
  });

  String get nombreCompleto => '$nombres $apellidos';

  @override
  List<Object?> get props => [id, nombres, apellidos];
}

class CitaClienteResumen extends Equatable {
  final String id;
  final String nombres;
  final String apellidos;
  final String? telefono;
  final String? email;

  const CitaClienteResumen({
    required this.id,
    required this.nombres,
    required this.apellidos,
    this.telefono,
    this.email,
  });

  String get nombreCompleto => '$nombres $apellidos';

  @override
  List<Object?> get props => [id, nombres, apellidos, telefono, email];
}

class CitaClienteEmpresaResumen extends Equatable {
  final String id;
  final String razonSocial;
  final String? nombreComercial;
  final String? telefono;

  const CitaClienteEmpresaResumen({
    required this.id,
    required this.razonSocial,
    this.nombreComercial,
    this.telefono,
  });

  @override
  List<Object?> get props => [id, razonSocial, nombreComercial, telefono];
}

class CitaSedeResumen extends Equatable {
  final String id;
  final String nombre;
  final String codigo;

  const CitaSedeResumen({
    required this.id,
    required this.nombre,
    required this.codigo,
  });

  @override
  List<Object?> get props => [id, nombre, codigo];
}

class CitaOrdenResumen extends Equatable {
  final String id;
  final String codigo;
  final String estado;

  const CitaOrdenResumen({
    required this.id,
    required this.codigo,
    required this.estado,
  });

  @override
  List<Object?> get props => [id, codigo, estado];
}

class CitaVinculoResumen extends Equatable {
  final String id;
  final String codigo;
  final DateTime fecha;
  final String horaInicio;
  final String estado;

  const CitaVinculoResumen({
    required this.id,
    required this.codigo,
    required this.fecha,
    required this.horaInicio,
    required this.estado,
  });

  @override
  List<Object?> get props => [id, codigo, fecha, horaInicio, estado];
}

/// Entidad principal de Cita
class Cita extends Equatable {
  final String id;
  final String empresaId;
  final String sedeId;
  final String servicioId;
  final String tecnicoId;
  final String? clienteId;
  final String? clienteEmpresaId;
  final String codigo;
  final DateTime fecha;
  final String horaInicio;
  final String horaFin;
  final String estado;
  final double? costoServicio;
  final double? costoProductos;
  final double? descuento;
  final double? adelanto;
  final double? costoTotal;
  final String? metodoPagoAdelanto;
  final Map<String, dynamic>? datosPersonalizados;
  final String? notas;
  final String? ordenServicioId;
  final String? siguienteCitaId;
  final String? creadoPor;
  final String? canceladoPor;
  final String? motivoCancelacion;
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  // Relaciones embebidas
  final CitaServicioResumen? servicio;
  final CitaTecnicoResumen? tecnico;
  final CitaClienteResumen? cliente;
  final CitaClienteEmpresaResumen? clienteEmpresa;
  final CitaSedeResumen? sede;
  final CitaOrdenResumen? ordenServicio;
  final CitaVinculoResumen? siguienteCita;
  final CitaVinculoResumen? citaAnterior;

  const Cita({
    required this.id,
    required this.empresaId,
    required this.sedeId,
    required this.servicioId,
    required this.tecnicoId,
    this.clienteId,
    this.clienteEmpresaId,
    required this.codigo,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.estado,
    this.costoServicio,
    this.costoProductos,
    this.descuento,
    this.adelanto,
    this.costoTotal,
    this.metodoPagoAdelanto,
    this.datosPersonalizados,
    this.notas,
    this.ordenServicioId,
    this.siguienteCitaId,
    this.creadoPor,
    this.canceladoPor,
    this.motivoCancelacion,
    required this.creadoEn,
    required this.actualizadoEn,
    this.servicio,
    this.tecnico,
    this.cliente,
    this.clienteEmpresa,
    this.sede,
    this.ordenServicio,
    this.siguienteCita,
    this.citaAnterior,
  });

  String get clienteNombre {
    if (cliente != null) return cliente!.nombreCompleto;
    if (clienteEmpresa != null) {
      return clienteEmpresa!.nombreComercial ?? clienteEmpresa!.razonSocial;
    }
    return 'Sin cliente';
  }

  bool get esEditable => estado == 'PENDIENTE' || estado == 'CONFIRMADA';
  bool get esTerminal => estado == 'COMPLETADA' || estado == 'CANCELADA' || estado == 'NO_ASISTIO';
  double get saldo => (costoTotal ?? 0) - (adelanto ?? 0);

  @override
  List<Object?> get props => [
        id,
        estado,
        costoServicio,
        costoProductos,
        descuento,
        adelanto,
        costoTotal,
        notas,
        ordenServicioId,
        siguienteCitaId,
        motivoCancelacion,
        actualizadoEn,
      ];
}

/// Item/producto agregado a una cita
class CitaItem extends Equatable {
  final String id;
  final String citaId;
  final String? productoId;
  final String nombre;
  final String? descripcion;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;
  final CitaItemProducto? producto;

  const CitaItem({
    required this.id,
    required this.citaId,
    this.productoId,
    required this.nombre,
    this.descripcion,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    this.producto,
  });

  @override
  List<Object?> get props => [id, cantidad, precioUnitario, subtotal];
}

class CitaItemProducto extends Equatable {
  final String id;
  final String nombre;
  final String codigoEmpresa;

  const CitaItemProducto({
    required this.id,
    required this.nombre,
    required this.codigoEmpresa,
  });

  @override
  List<Object?> get props => [id, nombre, codigoEmpresa];
}

/// Respuesta paginada de citas
class CitasPaginadas extends Equatable {
  final List<Cita> data;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const CitasPaginadas({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  @override
  List<Object?> get props => [data, total, page, totalPages];
}
