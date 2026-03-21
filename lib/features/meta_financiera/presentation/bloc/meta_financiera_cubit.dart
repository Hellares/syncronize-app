import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/meta_financiera.dart';
import '../../domain/usecases/get_metas_financieras_usecase.dart';
import '../../domain/usecases/crear_meta_financiera_usecase.dart';
import 'meta_financiera_state.dart';

@injectable
class MetaFinancieraCubit extends Cubit<MetaFinancieraState> {
  final GetMetasFinancierasUseCase _getMetasFinancierasUseCase;
  final CrearMetaFinancieraUseCase _crearMetaFinancieraUseCase;

  MetaFinancieraCubit(
    this._getMetasFinancierasUseCase,
    this._crearMetaFinancieraUseCase,
  ) : super(const MetaFinancieraInitial());

  Future<void> loadMetas() async {
    emit(const MetaFinancieraLoading());

    final result = await _getMetasFinancierasUseCase();
    if (isClosed) return;

    if (result is Success<List<MetaFinanciera>>) {
      emit(MetaFinancieraLoaded(metas: result.data));
    } else if (result is Error<List<MetaFinanciera>>) {
      emit(MetaFinancieraError(result.message));
    }
  }

  Future<void> crearMeta({
    required String tipo,
    required String nombre,
    required double montoMeta,
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    final result = await _crearMetaFinancieraUseCase(
      tipo: tipo,
      nombre: nombre,
      montoMeta: montoMeta,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
    );
    if (isClosed) return;

    if (result is Error<MetaFinanciera>) {
      emit(MetaFinancieraError(result.message));
      return;
    }

    await loadMetas();
  }
}
