import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/dio_client.dart';
import 'sorteo_analytics_state.dart';

/// Dashboard de analytics de sorteos — UN request consolidado (mismo
/// patrón que el dashboard de ventas). Se instancia manual con
/// `locator<DioClient>()` en la ruta (sin codegen de injectable).
class SorteoAnalyticsCubit extends Cubit<SorteoAnalyticsState> {
  final DioClient _dioClient;

  SorteoAnalyticsCubit(this._dioClient) : super(const SorteoAnalyticsInitial());

  Future<void> load({
    String? fechaInicio,
    String? fechaFin,
    String? tipo,
  }) async {
    final current = state;
    if (current is SorteoAnalyticsLoaded) {
      emit(current.copyWith(refreshing: true));
    } else {
      emit(const SorteoAnalyticsLoading());
    }

    try {
      final response = await _dioClient.get(
        '/sorteos/analytics/dashboard',
        queryParameters: {
          if (fechaInicio != null) 'fechaInicio': fechaInicio,
          if (fechaFin != null) 'fechaFin': fechaFin,
          if (tipo != null) 'tipo': tipo,
        },
      );
      if (isClosed) return;
      emit(SorteoAnalyticsLoaded(
          data: response.data as Map<String, dynamic>));
    } catch (e) {
      if (isClosed) return;
      emit(SorteoAnalyticsError(e.toString()));
    }
  }
}
