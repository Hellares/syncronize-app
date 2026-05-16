import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/dashboard_gastos.dart';
import '../../domain/repositories/gastos_recurrentes_repository.dart';
import 'dashboard_state.dart';

@injectable
class DashboardGastosCubit extends Cubit<DashboardGastosState> {
  final GastosRecurrentesRepository _repo;
  String? _periodoActual;
  String? _sedeId;

  DashboardGastosCubit(this._repo) : super(const DashboardGastosInitial());

  String _periodoVigente() {
    if (_periodoActual != null) return _periodoActual!;
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  Future<void> load({String? periodo, String? sedeId}) async {
    if (periodo != null) _periodoActual = periodo;
    if (sedeId != null) _sedeId = sedeId;

    emit(const DashboardGastosLoading());
    final result = await _repo.dashboard(
      periodo: _periodoVigente(),
      sedeId: _sedeId,
    );
    if (isClosed) return;

    if (result is Success<DashboardGastos>) {
      emit(DashboardGastosLoaded(result.data, _periodoVigente()));
    } else if (result is Error<DashboardGastos>) {
      emit(DashboardGastosError(result.message));
    }
  }

  Future<void> cambiarPeriodo(String periodo) async {
    _periodoActual = periodo;
    await load();
  }

  Future<void> reload() => load();
}
