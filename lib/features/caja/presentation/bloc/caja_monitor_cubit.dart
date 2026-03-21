import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/caja_monitor.dart';
import '../../domain/usecases/get_monitor_usecase.dart';
import 'caja_monitor_state.dart';

@injectable
class CajaMonitorCubit extends Cubit<CajaMonitorState> {
  final GetMonitorUseCase _getMonitorUseCase;

  CajaMonitorCubit(this._getMonitorUseCase) : super(const CajaMonitorInitial());

  Future<void> loadMonitor({String? sedeId}) async {
    emit(const CajaMonitorLoading());
    final result = await _getMonitorUseCase(sedeId: sedeId);
    if (isClosed) return;

    if (result is Success<CajaMonitorData>) {
      emit(CajaMonitorLoaded(result.data));
    } else if (result is Error<CajaMonitorData>) {
      emit(CajaMonitorError(result.message));
    }
  }
}
