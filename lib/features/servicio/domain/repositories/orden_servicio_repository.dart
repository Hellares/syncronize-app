import '../../../../core/utils/resource.dart';
import '../entities/orden_servicio.dart';
import '../entities/servicio_filtros.dart';

abstract class OrdenServicioRepository {
  Future<Resource<OrdenServicio>> crear({
    required String empresaId,
    String? clienteId,
    String? clienteEmpresaId,
    String? contactoClienteEmpresaId,
    required String tipoServicio,
    String? tecnicoId,
    String? sedeId,
    String? prioridad,
    String? descripcionProblema,
    dynamic sintomas,
    String? tipoEquipo,
    String? marcaEquipo,
    String? numeroSerie,
    String? modeloEquipoId,
    dynamic accesorios,
    String? condicionEquipo,
    String? notas,
    String? servicioId,
    Map<String, dynamic>? datosPersonalizados,
    bool? incluirAvisoMantenimiento,
    DateTime? fechaAvisoPersonalizado,
  });

  Future<Resource<OrdenesServicioPaginadas>> getOrdenes({
    required String empresaId,
    required OrdenServicioFiltros filtros,
  });

  Future<Resource<OrdenesServicioPaginadas>> getMisOrdenes({
    required OrdenServicioFiltros filtros,
  });

  Future<Resource<OrdenServicio>> getOrden({
    required String id,
    required String empresaId,
  });

  Future<Resource<OrdenServicio>> actualizar({
    required String id,
    required String empresaId,
    String? tipoServicio,
    String? prioridad,
    String? descripcionProblema,
    dynamic sintomas,
    String? tipoEquipo,
    String? marcaEquipo,
    String? numeroSerie,
    String? condicionEquipo,
    String? notas,
    double? costoTotal,
    double? adelanto,
    double? descuento,
    String? metodoPagoAdelanto,
  });

  Future<Resource<OrdenServicio>> transitionEstado({
    required String id,
    required String empresaId,
    required String nuevoEstado,
    String? notas,
    dynamic diagnostico,
    bool comunicarCliente = false,
    String? motivoReingreso,
    double? costoTotal,
    double? adelanto,
    double? descuento,
    String? metodoPagoAdelanto,
  });

  Future<Resource<OrdenServicio>> assignTecnico({
    required String id,
    required String empresaId,
    required String tecnicoId,
  });

  Future<Resource<OrdenComponente>> addComponente({
    required String ordenId,
    required Map<String, dynamic> data,
  });

  Future<Resource<List<OrdenComponente>>> getComponentes({
    required String ordenId,
  });

  Future<Resource<void>> removeComponente({
    required String ordenId,
    required String componenteId,
  });

  Future<Resource<List<HistorialOrdenServicio>>> getHistorial({
    required String ordenId,
    required String empresaId,
  });
}
