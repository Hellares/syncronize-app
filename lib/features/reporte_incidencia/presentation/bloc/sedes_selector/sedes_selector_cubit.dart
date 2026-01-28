import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../../sede/domain/usecases/get_sedes_usecase.dart';
import '../../../../empresa/domain/entities/sede.dart';

part 'sedes_selector_state.dart';

// Modelo temporal para sede (simplificado)
class SedeSimple {
  final String id;
  final String nombre;
  final String? codigo;

  const SedeSimple({
    required this.id,
    required this.nombre,
    this.codigo,
  });

  factory SedeSimple.fromSede(Sede sede) {
    return SedeSimple(
      id: sede.id,
      nombre: sede.nombre,
      codigo: sede.codigo,
    );
  }
}

@injectable
class SedesSelectorCubit extends Cubit<SedesSelectorState> {
  final GetSedesUseCase _getSedesUseCase;

  SedesSelectorCubit(this._getSedesUseCase)
      : super(const SedesSelectorInitial());

  Future<void> cargarSedes({String? empresaId}) async {
    if (empresaId == null) {
      emit(const SedesSelectorError('empresaId is required'));
      return;
    }

    emit(const SedesSelectorLoading());

    try {
      final result = await _getSedesUseCase.call(empresaId);

      switch (result) {
        case Success<List<Sede>>():
          final sedesSimples = result.data
              .where((sede) => sede.isActive && sede.deletedAt == null)
              .map((sede) => SedeSimple.fromSede(sede))
              .toList();
          emit(SedesSelectorLoaded(sedesSimples));
        case Error<List<Sede>>():
          emit(SedesSelectorError(result.message));
      }
    } catch (e) {
      emit(SedesSelectorError(e.toString()));
    }
  }
}
