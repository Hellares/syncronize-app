import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/gasto_recurrente.dart';
import '../../domain/repositories/gastos_recurrentes_repository.dart';
import 'gasto_form_state.dart';

@injectable
class GastoFormCubit extends Cubit<GastoFormState> {
  final GastosRecurrentesRepository _repo;
  GastoFormCubit(this._repo) : super(const GastoFormInitial());

  Future<void> cargarParaEditar(String id) async {
    emit(const GastoFormLoading());
    final r = await _repo.obtener(id);
    if (isClosed) return;
    if (r is Success<GastoRecurrente>) {
      emit(GastoFormEditing(r.data));
    } else if (r is Error<GastoRecurrente>) {
      emit(GastoFormError(r.message));
    }
  }

  Future<void> crear({
    required String nombre,
    required String categoriaGastoId,
    String? sedeId,
    String? proveedorId,
    required double montoEstimado,
    required FrecuenciaGasto frecuencia,
    required int diaVencimiento,
    String? notas,
  }) async {
    emit(const GastoFormSaving());
    final r = await _repo.crear(
      nombre: nombre,
      categoriaGastoId: categoriaGastoId,
      sedeId: sedeId,
      proveedorId: proveedorId,
      montoEstimado: montoEstimado,
      frecuencia: frecuencia,
      diaVencimiento: diaVencimiento,
      notas: notas,
    );
    if (isClosed) return;
    if (r is Success<GastoRecurrente>) {
      emit(GastoFormSaved(r.data));
    } else if (r is Error<GastoRecurrente>) {
      emit(GastoFormError(r.message));
    }
  }

  Future<void> actualizar({
    required String id,
    String? nombre,
    String? categoriaGastoId,
    String? sedeId,
    String? proveedorId,
    double? montoEstimado,
    FrecuenciaGasto? frecuencia,
    int? diaVencimiento,
    bool? activo,
    String? notas,
  }) async {
    emit(const GastoFormSaving());
    final r = await _repo.actualizar(
      id: id,
      nombre: nombre,
      categoriaGastoId: categoriaGastoId,
      sedeId: sedeId,
      proveedorId: proveedorId,
      montoEstimado: montoEstimado,
      frecuencia: frecuencia,
      diaVencimiento: diaVencimiento,
      activo: activo,
      notas: notas,
    );
    if (isClosed) return;
    if (r is Success<GastoRecurrente>) {
      emit(GastoFormSaved(r.data));
    } else if (r is Error<GastoRecurrente>) {
      emit(GastoFormError(r.message));
    }
  }
}
