import 'package:equatable/equatable.dart';
import 'componente.dart';

class OrdenServicio extends Equatable {
  final String id;
  final String empresaId;
  final String clienteId;
  final String? tecnicoId;
  final String? sedeId;
  final String codigo;
  final String tipoServicio;
  final String prioridad;
  final String? tipoEquipo;
  final String? marcaEquipo;
  final String? numeroSerie;
  final String? modeloEquipoId;
  final dynamic diagnostico;
  final String? descripcionProblema;
  final dynamic sintomas;
  final double? costoTotal;
  final double? adelanto;
  final double? descuento;
  final String? metodoPagoAdelanto;
  final int? tiempoEstimado;
  final DateTime? fechaEntrega;
  final String estado;
  final String estadoDiagnostico;
  final String? notas;
  final dynamic accesorios;
  final String? condicionEquipo;
  final Map<String, dynamic>? datosPersonalizados;
  final String? servicioId;
  final bool incluirAvisoMantenimiento;
  final DateTime? fechaAvisoPersonalizado;
  final String origenOrden;
  final int cantidadReingresos;
  final String? motivoReingreso;
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  // Related
  final OrdenCliente? cliente;
  final OrdenTecnico? tecnico;
  final List<OrdenComponente>? componentes;

  // Tercerización vinculada
  final TercerizacionResumen? tercerizacionOrigen;
  final TercerizacionResumen? tercerizacionDestino;

  const OrdenServicio({
    required this.id,
    required this.empresaId,
    required this.clienteId,
    this.tecnicoId,
    this.sedeId,
    required this.codigo,
    required this.tipoServicio,
    this.prioridad = 'NORMAL',
    this.tipoEquipo,
    this.marcaEquipo,
    this.numeroSerie,
    this.modeloEquipoId,
    this.diagnostico,
    this.descripcionProblema,
    this.sintomas,
    this.costoTotal,
    this.adelanto,
    this.descuento,
    this.metodoPagoAdelanto,
    this.tiempoEstimado,
    this.fechaEntrega,
    required this.estado,
    this.estadoDiagnostico = 'PENDIENTE',
    this.notas,
    this.accesorios,
    this.condicionEquipo,
    this.datosPersonalizados,
    this.servicioId,
    this.incluirAvisoMantenimiento = true,
    this.fechaAvisoPersonalizado,
    this.origenOrden = 'CLIENTE_FINAL',
    this.cantidadReingresos = 0,
    this.motivoReingreso,
    required this.creadoEn,
    required this.actualizadoEn,
    this.cliente,
    this.tecnico,
    this.componentes,
    this.tercerizacionOrigen,
    this.tercerizacionDestino,
  });

  /// Subtotal de componentes (mano de obra + repuestos)
  double get subtotalComponentes {
    if (componentes == null || componentes!.isEmpty) return 0;
    double total = 0;
    for (final comp in componentes!) {
      total += comp.costoAccion ?? 0;
      total += comp.costoRepuestos ?? 0;
    }
    return total;
  }

  /// Subtotal = costoTotal (servicio) + componentes
  double? get subtotal {
    final compCost = subtotalComponentes;
    if (costoTotal == null && compCost == 0) return null;
    return (costoTotal ?? 0) + compCost;
  }

  /// Costo final = subtotal - descuento
  double? get costoFinal {
    final sub = subtotal;
    if (sub == null) return null;
    return sub - (descuento ?? 0);
  }

  /// Saldo pendiente = costoFinal - adelanto
  double? get saldoPendiente {
    final final_ = costoFinal;
    if (final_ == null) return null;
    return final_ - (adelanto ?? 0);
  }

  bool get isTercerizado => estado == 'TERCERIZADO';
  bool get isB2BRecibido => origenOrden == 'B2B_RECIBIDO';
  bool get isB2BEnviado => origenOrden == 'B2B_ENVIADO';
  bool get isClienteFinal => origenOrden == 'CLIENTE_FINAL';

  @override
  List<Object?> get props => [id, codigo, estado, tipoServicio];
}

class OrdenCliente extends Equatable {
  final String id;
  final String? nombre;
  final String? apellido;
  final String? email;
  final String? telefono;
  final String? documentoNumero;

  const OrdenCliente({
    required this.id,
    this.nombre,
    this.apellido,
    this.email,
    this.telefono,
    this.documentoNumero,
  });

  String get nombreCompleto => [nombre, apellido].where((e) => e != null && e.isNotEmpty).join(' ');

  @override
  List<Object?> get props => [id, nombre, apellido];
}

class OrdenTecnico extends Equatable {
  final String id;
  final String? nombre;
  final String? apellido;
  final String? email;

  const OrdenTecnico({
    required this.id,
    this.nombre,
    this.apellido,
    this.email,
  });

  String get nombreCompleto => [nombre, apellido].where((e) => e != null && e.isNotEmpty).join(' ');

  @override
  List<Object?> get props => [id, nombre];
}

class OrdenComponente extends Equatable {
  final String id;
  final String ordenServicioId;
  final String componenteId;
  final String tipoAccion;
  final String estadoComponente;
  final String? descripcionAccion;
  final double? costoAccion;
  final int? tiempoAccion;
  final double? costoRepuestos;
  final String? resultadoAccion;
  final bool pruebaRealizada;
  final String? observaciones;
  final int? garantiaMeses;
  final Componente? componente;

  const OrdenComponente({
    required this.id,
    required this.ordenServicioId,
    required this.componenteId,
    required this.tipoAccion,
    this.estadoComponente = 'INGRESADO',
    this.descripcionAccion,
    this.costoAccion,
    this.tiempoAccion,
    this.costoRepuestos,
    this.resultadoAccion,
    this.pruebaRealizada = false,
    this.observaciones,
    this.garantiaMeses,
    this.componente,
  });

  @override
  List<Object?> get props => [id, tipoAccion, componenteId];
}

class HistorialOrdenServicio extends Equatable {
  final String id;
  final String ordenServicioId;
  final String estadoAnterior;
  final String estadoNuevo;
  final String? notas;
  final dynamic diagnostico;
  final bool comunicarCliente;
  final String? creadoPor;
  final DateTime creadoEn;

  const HistorialOrdenServicio({
    required this.id,
    required this.ordenServicioId,
    required this.estadoAnterior,
    required this.estadoNuevo,
    this.notas,
    this.diagnostico,
    this.comunicarCliente = false,
    this.creadoPor,
    required this.creadoEn,
  });

  @override
  List<Object?> get props => [id, estadoAnterior, estadoNuevo, creadoEn];
}

class TercerizacionResumen extends Equatable {
  final String id;
  final String estado;
  final double? precioB2B;
  final String? empresaOrigenId;
  final String? empresaDestinoId;
  final EmpresaB2BResumen? empresaOrigen;
  final EmpresaB2BResumen? empresaDestino;

  const TercerizacionResumen({
    required this.id,
    required this.estado,
    this.precioB2B,
    this.empresaOrigenId,
    this.empresaDestinoId,
    this.empresaOrigen,
    this.empresaDestino,
  });

  @override
  List<Object?> get props => [id, estado];
}

class EmpresaB2BResumen extends Equatable {
  final String id;
  final String nombre;
  final String? logo;
  final String? telefono;

  const EmpresaB2BResumen({
    required this.id,
    required this.nombre,
    this.logo,
    this.telefono,
  });

  @override
  List<Object?> get props => [id];
}

class OrdenesServicioPaginadas {
  final List<OrdenServicio> data;
  final int total;
  final bool hasNext;
  final String? nextCursor;

  const OrdenesServicioPaginadas({
    required this.data,
    required this.total,
    required this.hasNext,
    this.nextCursor,
  });
}
