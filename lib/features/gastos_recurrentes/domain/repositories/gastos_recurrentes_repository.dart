import '../../../../core/utils/resource.dart';
import '../entities/dashboard_gastos.dart';
import '../entities/gasto_recurrente.dart';
import '../entities/pago_gasto_recurrente.dart';
import '../entities/reporte_gastos.dart';

abstract class GastosRecurrentesRepository {
  Future<Resource<List<GastoRecurrente>>> listar({
    String? sedeId,
    String? categoriaGastoId,
    String? proveedorId,
    FrecuenciaGasto? frecuencia,
    bool? activo,
  });

  Future<Resource<GastoRecurrente>> obtener(String id);

  Future<Resource<GastoRecurrente>> crear({
    required String nombre,
    required String categoriaGastoId,
    String? sedeId,
    String? proveedorId,
    required double montoEstimado,
    required FrecuenciaGasto frecuencia,
    required int diaVencimiento,
    String? notas,
  });

  Future<Resource<GastoRecurrente>> actualizar({
    required String id,
    String? nombre,
    String? categoriaGastoId,
    String? sedeId,
    String? proveedorId,
    double? montoEstimado,
    FrecuenciaGasto? frecuencia,
    int? diaVencimiento,
    bool? activo,
    String? notas,
  });

  Future<Resource<GastoRecurrente>> toggleActivo(String id);

  Future<Resource<void>> eliminar(String id);

  Future<Resource<DashboardGastos>> dashboard({String? periodo, String? sedeId});

  Future<Resource<ReporteGastos>> reportes({int meses = 12});

  Future<Resource<PagoGastoRecurrente>> pagar({
    required String gastoId,
    required String periodo,
    required double montoReal,
    required FuentePagoGasto fuente,
    required MetodoPagoGasto metodoPago,
    String? cajaId,
    String? bancoId,
    String? comprobanteUrl,
    String? notas,
  });

  Future<Resource<List<PagoGastoRecurrente>>> listarPagos(
    String gastoId, {
    int? take,
    int? skip,
  });

  Future<Resource<ComprobanteUploadResult>> uploadComprobante({
    required String filePath,
  });
}
