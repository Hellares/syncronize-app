import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/reporte_gastos.dart';
import '../../domain/repositories/gastos_recurrentes_repository.dart';
import 'reportes_state.dart';

@injectable
class ReportesGastosCubit extends Cubit<ReportesGastosState> {
  final GastosRecurrentesRepository _repo;
  int _meses = 12;

  ReportesGastosCubit(this._repo) : super(const ReportesGastosInitial());

  Future<void> load({int? meses}) async {
    if (meses != null) _meses = meses;
    emit(const ReportesGastosLoading());
    final r = await _repo.reportes(meses: _meses);
    if (isClosed) return;
    if (r is Success<ReporteGastos>) {
      emit(ReportesGastosLoaded(r.data, _meses));
    } else if (r is Error<ReporteGastos>) {
      emit(ReportesGastosError(r.message));
    }
  }

  Future<void> reload() => load();
}
