import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../../venta/domain/entities/venta.dart';
import '../../domain/entities/cobrar_cotizacion_data.dart';
import '../../domain/usecases/cargar_datos_cobro_usecase.dart';
import '../../domain/usecases/cobrar_cotizacion_usecase.dart';
import 'cobrar_pos_state.dart';

@injectable
class CobrarPosCubit extends Cubit<CobrarPosState> {
  final CargarDatosCobroUseCase _cargarDatosCobroUseCase;
  final CobrarCotizacionUseCase _cobrarCotizacionUseCase;

  CobrarPosCubit(this._cargarDatosCobroUseCase, this._cobrarCotizacionUseCase)
      : super(const CobrarPosInitial());

  Future<void> cargarDatos(String cotizacionId) async {
    emit(const CobrarPosLoading());
    final result = await _cargarDatosCobroUseCase(cotizacionId: cotizacionId);
    if (isClosed) return;

    if (result is Success<CobrarCotizacionData>) {
      emit(CobrarPosLoaded(result.data));
    } else if (result is Error<CobrarCotizacionData>) {
      emit(CobrarPosError(result.message));
    }
  }

  Future<void> cobrar(String cotizacionId, Map<String, dynamic> data) async {
    emit(const CobrarPosProcesando());
    final result = await _cobrarCotizacionUseCase(
      cotizacionId: cotizacionId,
      data: data,
    );
    if (isClosed) return;

    if (result is Success<Venta>) {
      emit(CobrarPosCobrado(result.data));
    } else if (result is Error<Venta>) {
      emit(CobrarPosError(result.message));
    }
  }
}
