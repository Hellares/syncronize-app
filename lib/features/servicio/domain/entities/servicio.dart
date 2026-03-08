import 'package:equatable/equatable.dart';
import 'plantilla_servicio.dart';

class Servicio extends Equatable {
  final String id;
  final String empresaId;
  final String? sedeId;
  final String? empresaCategoriaId;
  final String? unidadMedidaId;
  final String? plantillaServicioId;
  final String codigoEmpresa;
  final String codigoSistema;
  final String nombre;
  final String? descripcion;
  final double? precio;
  final double? precioPorHora;
  final int? duracionMinutos;
  final double? duracionHoras;
  final bool requiereReserva;
  final bool requiereDeposito;
  final double? depositoPorcentaje;
  final String? videoUrl;
  final double? impuestoPorcentaje;
  final double? comisionTecnico;
  final bool visibleMarketplace;
  final bool destacado;
  final bool enOferta;
  final double? precioOferta;
  final DateTime? fechaInicioOferta;
  final DateTime? fechaFinOferta;
  final bool isActive;
  final DateTime? deletedAt;
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  // Related
  final ServicioCategoria? categoria;
  final ServicioSede? sede;
  final PlantillaServicio? plantillaServicio;

  const Servicio({
    required this.id,
    required this.empresaId,
    this.sedeId,
    this.empresaCategoriaId,
    this.unidadMedidaId,
    this.plantillaServicioId,
    required this.codigoEmpresa,
    required this.codigoSistema,
    required this.nombre,
    this.descripcion,
    this.precio,
    this.precioPorHora,
    this.duracionMinutos,
    this.duracionHoras,
    this.requiereReserva = false,
    this.requiereDeposito = false,
    this.depositoPorcentaje,
    this.videoUrl,
    this.impuestoPorcentaje,
    this.comisionTecnico,
    this.visibleMarketplace = true,
    this.destacado = false,
    this.enOferta = false,
    this.precioOferta,
    this.fechaInicioOferta,
    this.fechaFinOferta,
    this.isActive = true,
    this.deletedAt,
    required this.creadoEn,
    required this.actualizadoEn,
    this.categoria,
    this.sede,
    this.plantillaServicio,
  });

  @override
  List<Object?> get props => [id, nombre, codigoEmpresa, isActive];
}

class ServicioCategoria extends Equatable {
  final String id;
  final String nombre;

  const ServicioCategoria({required this.id, required this.nombre});

  @override
  List<Object?> get props => [id, nombre];
}

class ServicioSede extends Equatable {
  final String id;
  final String nombre;

  const ServicioSede({required this.id, required this.nombre});

  @override
  List<Object?> get props => [id, nombre];
}

class ServiciosPaginados {
  final List<Servicio> data;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;

  const ServiciosPaginados({
    required this.data,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
  });
}
