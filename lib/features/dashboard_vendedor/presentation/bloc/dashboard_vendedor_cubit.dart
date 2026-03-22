import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/dashboard_vendedor.dart';
import '../../domain/usecases/get_dashboard_vendedor_usecase.dart';
import 'dashboard_vendedor_state.dart';

@injectable
class DashboardVendedorCubit extends Cubit<DashboardVendedorState> {
  final GetDashboardVendedorUseCase _getDashboardUseCase;

  String? _lastVendedorId;
  String? _lastSedeId;

  DashboardVendedorCubit(this._getDashboardUseCase)
      : super(const DashboardVendedorInitial());

  Future<void> loadDashboard({String? vendedorId, String? sedeId}) async {
    _lastVendedorId = vendedorId;
    _lastSedeId = sedeId;
    emit(const DashboardVendedorLoading());

    final result = await _getDashboardUseCase(
      vendedorId: vendedorId,
      sedeId: sedeId,
    );
    if (isClosed) return;

    if (result is Success<DashboardVendedor>) {
      emit(DashboardVendedorLoaded(result.data));
    } else if (result is Error<DashboardVendedor>) {
      emit(DashboardVendedorError(result.message));
    }
  }

  Future<void> refresh() async {
    await loadDashboard(vendedorId: _lastVendedorId, sedeId: _lastSedeId);
  }
}
