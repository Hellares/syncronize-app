import 'package:syncronize/core/utils/type_converters.dart';
import '../../domain/entities/servicio.dart';
import 'plantilla_servicio_model.dart';

class ServicioModel extends Servicio {
  ServicioModel({
    required super.id,
    required super.empresaId,
    super.sedeId,
    super.empresaCategoriaId,
    super.unidadMedidaId,
    required super.codigoEmpresa,
    required super.codigoSistema,
    required super.nombre,
    super.descripcion,
    super.precio,
    super.precioPorHora,
    super.duracionMinutos,
    super.duracionHoras,
    super.requiereReserva,
    super.requiereDeposito,
    super.depositoPorcentaje,
    super.videoUrl,
    super.impuestoPorcentaje,
    super.comisionTecnico,
    super.visibleMarketplace,
    super.destacado,
    super.enOferta,
    super.precioOferta,
    super.fechaInicioOferta,
    super.fechaFinOferta,
    super.isActive,
    super.deletedAt,
    required super.creadoEn,
    required super.actualizadoEn,
    super.plantillaServicioId,
    super.categoria,
    super.sede,
    super.plantillaServicio,
  });

  factory ServicioModel.fromJson(Map<String, dynamic> json) {
    return ServicioModel(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String,
      sedeId: json['sedeId'] as String?,
      empresaCategoriaId: json['empresaCategoriaId'] as String?,
      unidadMedidaId: json['unidadMedidaId'] as String?,
      plantillaServicioId: json['plantillaServicioId'] as String?,
      codigoEmpresa: json['codigoEmpresa'] as String,
      codigoSistema: json['codigoSistema'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      precio: json['precio'] != null ? toSafeDouble(json['precio']) : null,
      precioPorHora: json['precioPorHora'] != null ? toSafeDouble(json['precioPorHora']) : null,
      duracionMinutos: json['duracionMinutos'] as int?,
      duracionHoras: json['duracionHoras'] != null ? toSafeDouble(json['duracionHoras']) : null,
      requiereReserva: json['requiereReserva'] as bool? ?? false,
      requiereDeposito: json['requiereDeposito'] as bool? ?? false,
      depositoPorcentaje: json['depositoPorcentaje'] != null ? toSafeDouble(json['depositoPorcentaje']) : null,
      videoUrl: json['videoUrl'] as String?,
      impuestoPorcentaje: json['impuestoPorcentaje'] != null ? toSafeDouble(json['impuestoPorcentaje']) : null,
      comisionTecnico: json['comisionTecnico'] != null ? toSafeDouble(json['comisionTecnico']) : null,
      visibleMarketplace: json['visibleMarketplace'] as bool? ?? true,
      destacado: json['destacado'] as bool? ?? false,
      enOferta: json['enOferta'] as bool? ?? false,
      precioOferta: json['precioOferta'] != null ? toSafeDouble(json['precioOferta']) : null,
      fechaInicioOferta: json['fechaInicioOferta'] != null ? DateTime.parse(json['fechaInicioOferta'] as String) : null,
      fechaFinOferta: json['fechaFinOferta'] != null ? DateTime.parse(json['fechaFinOferta'] as String) : null,
      isActive: json['isActive'] as bool? ?? true,
      deletedAt: json['deletedAt'] != null ? DateTime.parse(json['deletedAt'] as String) : null,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      actualizadoEn: DateTime.parse(json['actualizadoEn'] as String),
      categoria: json['empresaCategoria'] != null
          ? ServicioCategoriaModel.fromJson(json['empresaCategoria'] as Map<String, dynamic>)
          : null,
      sede: json['sede'] != null
          ? ServicioSedeModel.fromJson(json['sede'] as Map<String, dynamic>)
          : null,
      plantillaServicio: json['plantillaServicio'] != null
          ? PlantillaServicioModel.fromJson(json['plantillaServicio'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ServicioCategoriaModel extends ServicioCategoria {
  const ServicioCategoriaModel({required super.id, required super.nombre});

  factory ServicioCategoriaModel.fromJson(Map<String, dynamic> json) {
    return ServicioCategoriaModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
    );
  }
}

class ServicioSedeModel extends ServicioSede {
  const ServicioSedeModel({required super.id, required super.nombre});

  factory ServicioSedeModel.fromJson(Map<String, dynamic> json) {
    return ServicioSedeModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
    );
  }
}
