import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/catalogo_preview.dart';
import '../../../domain/usecases/get_catalogo_preview_usecase.dart';

part 'catalogo_preview_state.dart';

/// Cubit para manejar el preview de catálogos según rubro
@injectable
class CatalogoPreviewCubit extends Cubit<CatalogoPreviewState> {
  final GetCatalogoPreviewUseCase getCatalogoPreviewUseCase;

  CatalogoPreviewCubit({required this.getCatalogoPreviewUseCase})
      : super(CatalogoPreviewInitial());

  /// Cargar preview de catálogos para un rubro específico
  Future<void> loadPreview(String rubro) async {
    if (rubro.isEmpty) {
      emit(CatalogoPreviewInitial());
      return;
    }

    emit(CatalogoPreviewLoading());

    final params = GetCatalogoPreviewParams(rubro: rubro);
    final result = await getCatalogoPreviewUseCase(params);

    if (result is Success<CatalogoPreview>) {
      emit(CatalogoPreviewLoaded(preview: result.data));
    } else if (result is Error<CatalogoPreview>) {
      emit(CatalogoPreviewError(message: result.message));
    }
  }

  /// Resetear estado
  void reset() {
    emit(CatalogoPreviewInitial());
  }
}
