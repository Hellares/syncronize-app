import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/network/dio_client.dart';
import 'venta_analytics_state.dart';

@injectable
class VentaAnalyticsCubit extends Cubit<VentaAnalyticsState> {
  final DioClient _dioClient;

  VentaAnalyticsCubit(this._dioClient) : super(const VentaAnalyticsInitial());

  Future<void> load({String? sedeId, String? periodo, String? fechaInicio, String? fechaFin, String? compAInicio, String? compAFin, String? compBInicio, String? compBFin}) async {
    emit(const VentaAnalyticsLoading());

    try {
      final params = <String, dynamic>{};
      if (sedeId != null) params['sedeId'] = sedeId;
      if (periodo != null) params['periodo'] = periodo;
      if (fechaInicio != null) params['fechaInicio'] = fechaInicio;
      if (fechaFin != null) params['fechaFin'] = fechaFin;

      // Comparativo: enviar ambos periodos explícitamente
      final comparativoParams = <String, dynamic>{};
      if (sedeId != null) comparativoParams['sedeId'] = sedeId;
      if (compAInicio != null) comparativoParams['fechaInicioA'] = compAInicio;
      if (compAFin != null) comparativoParams['fechaFinA'] = compAFin;
      if (compBInicio != null) comparativoParams['fechaInicioB'] = compBInicio;
      if (compBFin != null) comparativoParams['fechaFinB'] = compBFin;

      final results = await Future.wait([
        _dioClient.get('/ventas/analytics/resumen', queryParameters: params),
        _dioClient.get('/ventas/analytics/ventas-periodo', queryParameters: params),
        _dioClient.get('/ventas/analytics/top-productos', queryParameters: params),
        _dioClient.get('/ventas/analytics/top-clientes', queryParameters: params),
        _dioClient.get('/ventas/analytics/comparativo', queryParameters: comparativoParams),
        _dioClient.get('/ventas/analytics/alertas', queryParameters: comparativoParams),
      ]);

      if (isClosed) return;

      emit(VentaAnalyticsLoaded(
        resumen: results[0].data as Map<String, dynamic>,
        ventasPeriodo: results[1].data as List<dynamic>,
        topProductos: results[2].data as List<dynamic>,
        topClientes: results[3].data as List<dynamic>,
        comparativo: results[4].data as Map<String, dynamic>,
        alertas: results[5].data as List<dynamic>,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(VentaAnalyticsError(e.toString()));
    }
  }
}
