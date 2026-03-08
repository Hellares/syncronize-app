import 'package:equatable/equatable.dart';

class AvisoMantenimiento extends Equatable {
  final String id;
  final String empresaId;
  final String ordenServicioId;
  final String clienteId;
  final String tipoServicio;
  final String? equipoDescripcion;
  final DateTime fechaUltimoServicio;
  final DateTime fechaRecomendada;
  final String estado;
  final String? ordenGeneradaId;
  final DateTime? notificadoEn;
  final String? notas;
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  // Related
  final AvisoCliente? cliente;
  final AvisoOrdenResumen? ordenServicio;

  const AvisoMantenimiento({
    required this.id,
    required this.empresaId,
    required this.ordenServicioId,
    required this.clienteId,
    required this.tipoServicio,
    this.equipoDescripcion,
    required this.fechaUltimoServicio,
    required this.fechaRecomendada,
    required this.estado,
    this.ordenGeneradaId,
    this.notificadoEn,
    this.notas,
    required this.creadoEn,
    required this.actualizadoEn,
    this.cliente,
    this.ordenServicio,
  });

  /// Días restantes hasta la fecha recomendada (negativo = vencido)
  int get diasRestantes {
    return fechaRecomendada.difference(DateTime.now()).inDays;
  }

  bool get estaVencido => diasRestantes < 0;
  bool get estaProximo => diasRestantes >= 0 && diasRestantes <= 7;
  bool get esActivo => estado == 'PENDIENTE' || estado == 'NOTIFICADO';

  @override
  List<Object?> get props => [id, estado, fechaRecomendada];
}

class AvisoCliente extends Equatable {
  final String id;
  final String? nombre;
  final String? apellido;
  final String? email;
  final String? telefono;

  const AvisoCliente({
    required this.id,
    this.nombre,
    this.apellido,
    this.email,
    this.telefono,
  });

  String get nombreCompleto =>
      [nombre, apellido].where((e) => e != null && e.isNotEmpty).join(' ');

  @override
  List<Object?> get props => [id, nombre, apellido];
}

class AvisoOrdenResumen extends Equatable {
  final String id;
  final String codigo;
  final String tipoServicio;
  final String? tipoEquipo;
  final String? marcaEquipo;
  final String estado;

  const AvisoOrdenResumen({
    required this.id,
    required this.codigo,
    required this.tipoServicio,
    this.tipoEquipo,
    this.marcaEquipo,
    required this.estado,
  });

  @override
  List<Object?> get props => [id, codigo];
}

class ConfiguracionAvisoMantenimiento extends Equatable {
  final String? id;
  final String empresaId;
  final Map<String, int> intervalos;
  final int diasAnticipacion;
  final bool habilitado;

  const ConfiguracionAvisoMantenimiento({
    this.id,
    required this.empresaId,
    required this.intervalos,
    required this.diasAnticipacion,
    required this.habilitado,
  });

  @override
  List<Object?> get props => [id, empresaId, habilitado];
}

class AvisoResumen extends Equatable {
  final int pendientes;
  final int notificados;
  final int atendidos;
  final int proximosSemana;
  final int totalActivos;

  const AvisoResumen({
    required this.pendientes,
    required this.notificados,
    required this.atendidos,
    required this.proximosSemana,
    required this.totalActivos,
  });

  @override
  List<Object?> get props => [pendientes, notificados, totalActivos];
}
