import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/caja_chica.dart';
import '../../domain/entities/gasto_caja_chica.dart';
import '../../domain/usecases/get_caja_chica_usecase.dart';
import '../../domain/usecases/listar_gastos_usecase.dart';
import 'caja_chica_detail_state.dart';

@injectable
class CajaChicaDetailCubit extends Cubit<CajaChicaDetailState> {
  final GetCajaChicaUseCase _getCajaChicaUseCase;
  final ListarGastosUseCase _listarGastosUseCase;

  String? _currentCajaChicaId;

  CajaChicaDetailCubit(
    this._getCajaChicaUseCase,
    this._listarGastosUseCase,
  ) : super(const CajaChicaDetailInitial());

  Future<void> loadDetail(String cajaChicaId) async {
    _currentCajaChicaId = cajaChicaId;
    emit(const CajaChicaDetailLoading());

    final results = await Future.wait([
      _getCajaChicaUseCase(id: cajaChicaId),
      _listarGastosUseCase(cajaChicaId: cajaChicaId, pendientes: true),
    ]);
    if (isClosed) return;

    final cajaResult = results[0] as Resource<CajaChica>;
    final gastosResult = results[1] as Resource<List<GastoCajaChica>>;

    if (cajaResult is Success<CajaChica>) {
      List<GastoCajaChica> gastosPendientes = [];
      if (gastosResult is Success<List<GastoCajaChica>>) {
        gastosPendientes = gastosResult.data;
      }
      emit(CajaChicaDetailLoaded(
        cajaChica: cajaResult.data,
        gastosPendientes: gastosPendientes,
      ));
    } else if (cajaResult is Error<CajaChica>) {
      emit(CajaChicaDetailError(cajaResult.message));
    }
  }

  Future<void> reload() async {
    if (_currentCajaChicaId != null) {
      await loadDetail(_currentCajaChicaId!);
    }
  }
}
