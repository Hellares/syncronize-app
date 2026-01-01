import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/usecases/ajuste_masivo_precios_usecase.dart';
import 'ajuste_masivo_state.dart';

@injectable
class AjusteMasivoCubit extends Cubit<AjusteMasivoState> {
  final AjusteMasivoPreciosUseCase _ajusteMasivoPreciosUseCase;

  AjusteMasivoCubit(
    this._ajusteMasivoPreciosUseCase,
  ) : super(const AjusteMasivoInitial());

  /// Generar preview de cambios sin aplicar
  Future<void> generarPreview({
    required String empresaId,
    required Map<String, dynamic> dto,
  }) async {
    emit(const AjusteMasivoLoading());

    // Forzar preview = true
    final dtoConPreview = {
      ...dto,
      'preview': true,
    };

    final result = await _ajusteMasivoPreciosUseCase(
      empresaId: empresaId,
      dto: dtoConPreview,
    );

    if (result is Success<Map<String, dynamic>>) {
      emit(AjusteMasivoPreviewLoaded(result.data));
    } else if (result is Error<Map<String, dynamic>>) {
      emit(AjusteMasivoError(result.message, errorCode: result.errorCode));
    }
  }

  /// Aplicar cambios de forma definitiva
  Future<void> aplicarAjuste({
    required String empresaId,
    required Map<String, dynamic> dto,
  }) async {
    emit(const AjusteMasivoLoading());

    // Forzar preview = false
    final dtoSinPreview = {
      ...dto,
      'preview': false,
    };

    final result = await _ajusteMasivoPreciosUseCase(
      empresaId: empresaId,
      dto: dtoSinPreview,
    );

    if (result is Success<Map<String, dynamic>>) {
      emit(AjusteMasivoSuccess(result.data));
    } else if (result is Error<Map<String, dynamic>>) {
      emit(AjusteMasivoError(result.message, errorCode: result.errorCode));
    }
  }

  /// Resetear el estado
  void reset() {
    emit(const AjusteMasivoInitial());
  }
}
