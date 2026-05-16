import 'package:injectable/injectable.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/error_handler_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/dashboard_gastos.dart';
import '../../domain/entities/gasto_recurrente.dart';
import '../../domain/entities/pago_gasto_recurrente.dart';
import '../../domain/entities/reporte_gastos.dart';
import '../../domain/repositories/gastos_recurrentes_repository.dart';
import '../datasources/gastos_recurrentes_remote_datasource.dart';

@LazySingleton(as: GastosRecurrentesRepository)
class GastosRecurrentesRepositoryImpl implements GastosRecurrentesRepository {
  final GastosRecurrentesRemoteDataSource _ds;
  final NetworkInfo _networkInfo;
  final ErrorHandlerService _errorHandler;

  GastosRecurrentesRepositoryImpl(
    this._ds,
    this._networkInfo,
    this._errorHandler,
  );

  static const _ctx = 'GastosRecurrentes';

  Future<Resource<T>> _guard<T>(Future<T> Function() op) async {
    if (!await _networkInfo.isConnected) {
      return Error('No hay conexion a internet', errorCode: 'NETWORK_ERROR');
    }
    try {
      return Success(await op());
    } catch (e) {
      return _errorHandler.handleException(e, context: _ctx);
    }
  }

  @override
  Future<Resource<List<GastoRecurrente>>> listar({
    String? sedeId,
    String? categoriaGastoId,
    String? proveedorId,
    FrecuenciaGasto? frecuencia,
    bool? activo,
  }) =>
      _guard(() async {
        final items = await _ds.listar(
          sedeId: sedeId,
          categoriaGastoId: categoriaGastoId,
          proveedorId: proveedorId,
          frecuencia: frecuencia,
          activo: activo,
        );
        return items.map((m) => m.toEntity()).toList();
      });

  @override
  Future<Resource<GastoRecurrente>> obtener(String id) =>
      _guard(() async => (await _ds.obtener(id)).toEntity());

  @override
  Future<Resource<GastoRecurrente>> crear({
    required String nombre,
    required String categoriaGastoId,
    String? sedeId,
    String? proveedorId,
    required double montoEstimado,
    required FrecuenciaGasto frecuencia,
    required int diaVencimiento,
    String? notas,
  }) =>
      _guard(() async => (await _ds.crear(
            nombre: nombre,
            categoriaGastoId: categoriaGastoId,
            sedeId: sedeId,
            proveedorId: proveedorId,
            montoEstimado: montoEstimado,
            frecuencia: frecuencia,
            diaVencimiento: diaVencimiento,
            notas: notas,
          ))
              .toEntity());

  @override
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
  }) =>
      _guard(() async => (await _ds.actualizar(
            id: id,
            nombre: nombre,
            categoriaGastoId: categoriaGastoId,
            sedeId: sedeId,
            proveedorId: proveedorId,
            montoEstimado: montoEstimado,
            frecuencia: frecuencia,
            diaVencimiento: diaVencimiento,
            activo: activo,
            notas: notas,
          ))
              .toEntity());

  @override
  Future<Resource<GastoRecurrente>> toggleActivo(String id) =>
      _guard(() async => (await _ds.toggleActivo(id)).toEntity());

  @override
  Future<Resource<void>> eliminar(String id) =>
      _guard(() => _ds.eliminar(id));

  @override
  Future<Resource<DashboardGastos>> dashboard({String? periodo, String? sedeId}) =>
      _guard(() => _ds.dashboard(periodo: periodo, sedeId: sedeId));

  @override
  Future<Resource<ReporteGastos>> reportes({int meses = 12}) =>
      _guard(() => _ds.reportes(meses: meses));

  @override
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
  }) =>
      _guard(() async => (await _ds.pagar(
            gastoId: gastoId,
            periodo: periodo,
            montoReal: montoReal,
            fuente: fuente,
            metodoPago: metodoPago,
            cajaId: cajaId,
            bancoId: bancoId,
            comprobanteUrl: comprobanteUrl,
            notas: notas,
          ))
              .toEntity());

  @override
  Future<Resource<List<PagoGastoRecurrente>>> listarPagos(
    String gastoId, {
    int? take,
    int? skip,
  }) =>
      _guard(() async {
        final items = await _ds.listarPagos(gastoId, take: take, skip: skip);
        return items.map((m) => m.toEntity()).toList();
      });

  @override
  Future<Resource<ComprobanteUploadResult>> uploadComprobante({
    required String filePath,
  }) =>
      _guard(() => _ds.uploadComprobante(filePath));
}
