import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/cotizacion_pos.dart';
import '../../../domain/repositories/pos_repository.dart';
import 'cola_pos_state.dart';

@injectable
class ColaPosCubit extends Cubit<ColaPosState> {
  final PosRepository _repository;

  ColaPosCubit(this._repository) : super(const ColaPosInitial());

  String? _sedeId;

  Future<void> loadCola({String? sedeId}) async {
    _sedeId = sedeId;
    emit(const ColaPosLoading());

    final result = await _repository.getColaPOS(sedeId: sedeId);
    if (isClosed) return;

    if (result is Success<List<CotizacionPOS>>) {
      emit(ColaPosLoaded(cotizaciones: result.data));
    } else if (result is Error<List<CotizacionPOS>>) {
      emit(ColaPosError(result.message));
    }
  }

  Future<void> refresh() async {
    await loadCola(sedeId: _sedeId);
  }
}
