import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../../empresa/domain/entities/sede.dart';
import '../../../domain/usecases/create_sede_usecase.dart';
import '../../../domain/usecases/get_sede_by_id_usecase.dart';
import '../../../domain/usecases/update_sede_usecase.dart';
import 'sede_form_state.dart';

@injectable
class SedeFormCubit extends Cubit<SedeFormState> {
  final GetSedeByIdUseCase _getSedeByIdUseCase;
  final CreateSedeUseCase _createSedeUseCase;
  final UpdateSedeUseCase _updateSedeUseCase;

  SedeFormCubit(
    this._getSedeByIdUseCase,
    this._createSedeUseCase,
    this._updateSedeUseCase,
  ) : super(const SedeFormInitial());

  /// Inicializa el formulario para crear una nueva sede
  void initForCreate() {
    emit(const SedeFormReady(sede: null));
  }

  /// Inicializa el formulario para editar una sede existente
  Future<void> initForEdit({
    required String empresaId,
    required String sedeId,
  }) async {
    emit(const SedeFormLoading());

    final result = await _getSedeByIdUseCase(
      empresaId: empresaId,
      sedeId: sedeId,
    );

    if (isClosed) return;

    if (result is Success<Sede>) {
      emit(SedeFormReady(sede: result.data));
    } else if (result is Error<Sede>) {
      emit(SedeFormError(result.message, errorCode: result.errorCode));
    }
  }

  /// Crea una nueva sede
  Future<void> createSede({
    required String empresaId,
    required Map<String, dynamic> data,
  }) async {
    emit(const SedeFormSubmitting());

    final result = await _createSedeUseCase(
      empresaId: empresaId,
      data: data,
    );

    if (isClosed) return;

    if (result is Success<Sede>) {
      emit(SedeFormSuccess(result.data, isEdit: false));
    } else if (result is Error<Sede>) {
      emit(SedeFormError(result.message, errorCode: result.errorCode));
    }
  }

  /// Actualiza una sede existente
  Future<void> updateSede({
    required String empresaId,
    required String sedeId,
    required Map<String, dynamic> data,
  }) async {
    emit(const SedeFormSubmitting());

    final result = await _updateSedeUseCase(
      empresaId: empresaId,
      sedeId: sedeId,
      data: data,
    );

    if (isClosed) return;

    if (result is Success<Sede>) {
      emit(SedeFormSuccess(result.data, isEdit: true));
    } else if (result is Error<Sede>) {
      emit(SedeFormError(result.message, errorCode: result.errorCode));
    }
  }

  /// Resetea el formulario
  void reset() {
    emit(const SedeFormInitial());
  }
}
