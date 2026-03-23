import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';


import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/dashboard_rrhh.dart';
import '../../../domain/repositories/dashboard_rrhh_repository.dart';
import 'dashboard_rrhh_state.dart';

@injectable
class DashboardRrhhCubit extends Cubit<DashboardRrhhState> {
  final DashboardRrhhRepository _repository;

  DashboardRrhhCubit(this._repository) : super(const DashboardRrhhInitial());

  Future<void> loadDashboard() async {
    emit(const DashboardRrhhLoading());

    final result = await _repository.getDashboard();
    if (isClosed) return;

    if (result is Success<DashboardRrhh>) {
      emit(DashboardRrhhLoaded(result.data));
    } else if (result is Error) {
      emit(DashboardRrhhError((result as Error).message));
    }
  }

  Future<void> refresh() async {
    await loadDashboard();
  }
}
