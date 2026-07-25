import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/network/dio_client.dart';
import 'venta_analytics_state.dart';

@injectable
class VentaAnalyticsCubit extends Cubit<VentaAnalyticsState> {
  final DioClient _dioClient;

  VentaAnalyticsCubit(this._dioClient) : super(const VentaAnalyticsInitial());

  Future<void> load({
    String? sedeId,
    String? periodo,
    String? fechaInicio,
    String? fechaFin,
    String? compAInicio,
    String? compAFin,
    String? compBInicio,
    String? compBFin,
    String? categoriaId,
    String? canalVenta,
    String? conEnvio,
    String? ordenarPor,
  }) async {
    // Con datos ya cargados solo se marca refreshing: la página los mantiene
    // visibles y los reemplaza al llegar los nuevos (sin flash de spinner).
    final current = state;
    if (current is VentaAnalyticsLoaded) {
      emit(current.copyWith(refreshing: true));
    } else {
      emit(const VentaAnalyticsLoading());
    }

    try {
      // UN solo request: el backend consolida las 15 secciones server-side
      // (antes eran 15 requests paralelos — 15 round-trips móviles).
      final params = <String, dynamic>{
        if (sedeId != null) 'sedeId': sedeId,
        if (periodo != null) 'periodo': periodo,
        if (fechaInicio != null) 'fechaInicio': fechaInicio,
        if (fechaFin != null) 'fechaFin': fechaFin,
        if (canalVenta != null) 'canalVenta': canalVenta,
        if (conEnvio != null) 'conEnvio': conEnvio,
        // Rankings de productos
        'limit': '10',
        if (categoriaId != null) 'categoriaId': categoriaId,
        if (ordenarPor != null) 'ordenarPor': ordenarPor,
        // Comparativo: ambos periodos explícitos
        if (compAInicio != null) 'fechaInicioA': compAInicio,
        if (compAFin != null) 'fechaFinA': compAFin,
        if (compBInicio != null) 'fechaInicioB': compBInicio,
        if (compBFin != null) 'fechaFinB': compBFin,
      };

      final response = await _dioClient.get(
        '/ventas/analytics/dashboard',
        queryParameters: params,
      );

      if (isClosed) return;

      final data = response.data as Map<String, dynamic>;
      emit(VentaAnalyticsLoaded(
        resumen: data['resumen'] as Map<String, dynamic>,
        ventasPeriodo: data['ventasPeriodo'] as List<dynamic>,
        topProductos: data['topProductos'] as List<dynamic>,
        topClientes: data['topClientes'] as List<dynamic>,
        comparativo: data['comparativo'] as Map<String, dynamic>,
        alertas: data['alertas'] as List<dynamic>,
        menosVendidos: data['menosVendidos'] as List<dynamic>,
        porCanal: data['porCanal'] as Map<String, dynamic>,
        porCategoria: data['porCategoria'] as List<dynamic>,
        porMarca: data['porMarca'] as List<dynamic>,
        porProveedor: data['porProveedor'] as List<dynamic>,
        entregas: data['entregas'] as Map<String, dynamic>,
        metodosPago: data['metodosPago'] as List<dynamic>,
        horasPico: data['horasPico'] as Map<String, dynamic>,
        reposicion: data['reposicion'] as List<dynamic>,
        proyeccion: data['proyeccion'] as Map<String, dynamic>,
        // Tolerante a backend viejo (APK nueva + beta sin deploy): {} = oculta.
        porEmisor: (data['porEmisor'] as Map<String, dynamic>?) ?? const {},
      ));
    } catch (e) {
      if (isClosed) return;
      emit(VentaAnalyticsError(e.toString()));
    }
  }
}
