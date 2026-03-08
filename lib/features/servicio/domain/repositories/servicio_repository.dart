import '../../../../core/utils/resource.dart';
import '../entities/servicio.dart';
import '../entities/servicio_filtros.dart';

abstract class ServicioRepository {
  Future<Resource<Servicio>> crear({
    required String empresaId,
    required String nombre,
    String? descripcion,
    double? precio,
    double? precioPorHora,
    int? duracionMinutos,
    double? duracionHoras,
    String? tipoServicio,
    bool? requiereReserva,
    bool? requiereDeposito,
    double? depositoPorcentaje,
    bool? visibleMarketplace,
    bool? enOferta,
    double? precioOferta,
    String? sedeId,
    String? empresaCategoriaId,
    String? unidadMedidaId,
    String? videoUrl,
    double? impuestoPorcentaje,
    double? comisionTecnico,
    String? plantillaServicioId,
  });

  Future<Resource<ServiciosPaginados>> getServicios({
    required String empresaId,
    required ServicioFiltros filtros,
  });

  Future<Resource<Servicio>> getServicio({
    required String id,
    required String empresaId,
  });

  Future<Resource<Servicio>> actualizar({
    required String id,
    required String empresaId,
    String? nombre,
    String? descripcion,
    double? precio,
    double? precioPorHora,
    int? duracionMinutos,
    double? duracionHoras,
    String? tipoServicio,
    bool? requiereReserva,
    bool? requiereDeposito,
    double? depositoPorcentaje,
    bool? visibleMarketplace,
    bool? enOferta,
    double? precioOferta,
    String? sedeId,
    String? empresaCategoriaId,
    String? unidadMedidaId,
    String? videoUrl,
    double? impuestoPorcentaje,
    double? comisionTecnico,
    String? plantillaServicioId,
  });

  Future<Resource<void>> eliminar({
    required String id,
    required String empresaId,
  });
}
