import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/tipo_cambio.dart';
import '../../domain/usecases/get_tipo_cambio_hoy_usecase.dart';
import '../../domain/usecases/get_historial_tipo_cambio_usecase.dart';
import '../../domain/usecases/registrar_tipo_cambio_manual_usecase.dart';
import '../../domain/usecases/get_configuracion_moneda_usecase.dart';
import 'tipo_cambio_state.dart';

@injectable
class TipoCambioCubit extends Cubit<TipoCambioState> {
  final GetTipoCambioHoyUseCase _getTipoCambioHoyUseCase;
  final GetHistorialTipoCambioUseCase _getHistorialUseCase;
  final RegistrarTipoCambioManualUseCase _registrarManualUseCase;
  final GetConfiguracionMonedaUseCase _getConfiguracionUseCase;

  TipoCambioCubit(
    this._getTipoCambioHoyUseCase,
    this._getHistorialUseCase,
    this._registrarManualUseCase,
    this._getConfiguracionUseCase,
  ) : super(const TipoCambioInitial());

  Future<void> loadAll() async {
    emit(const TipoCambioLoading());

    final results = await Future.wait([
      _getTipoCambioHoyUseCase(),
      _getHistorialUseCase(limit: 30),
      _getConfiguracionUseCase(),
    ]);
    if (isClosed) return;

    final hoyResult = results[0] as Resource<TipoCambio>;
    final historialResult = results[1] as Resource<List<TipoCambio>>;
    final configResult = results[2] as Resource<ConfiguracionMoneda>;

    TipoCambio? tipoCambioHoy;
    List<TipoCambio> historial = [];
    ConfiguracionMoneda? configuracion;

    if (hoyResult is Success<TipoCambio>) {
      tipoCambioHoy = hoyResult.data;
    }
    if (historialResult is Success<List<TipoCambio>>) {
      historial = historialResult.data;
    }
    if (configResult is Success<ConfiguracionMoneda>) {
      configuracion = configResult.data;
    }

    // Si al menos el tipo de cambio de hoy o el historial se cargaron, mostrar
    if (tipoCambioHoy != null || historial.isNotEmpty) {
      emit(TipoCambioLoaded(
        tipoCambioHoy: tipoCambioHoy,
        historial: historial,
        configuracion: configuracion,
      ));
    } else if (hoyResult is Error<TipoCambio>) {
      emit(TipoCambioError(hoyResult.message));
    } else {
      emit(const TipoCambioError('No se pudo cargar el tipo de cambio'));
    }
  }

  Future<bool> registrarManual({
    required double compra,
    required double venta,
    required String fecha,
  }) async {
    final result = await _registrarManualUseCase(
      compra: compra,
      venta: venta,
      fecha: fecha,
    );

    if (result is Success<TipoCambio>) {
      // Recargar todo para reflejar el cambio
      await loadAll();
      return true;
    }
    return false;
  }

  Future<void> reload() => loadAll();
}
