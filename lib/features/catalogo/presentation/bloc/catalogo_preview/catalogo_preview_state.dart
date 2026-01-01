part of 'catalogo_preview_cubit.dart';

/// Estados del CatalogoPreviewCubit
abstract class CatalogoPreviewState extends Equatable {
  const CatalogoPreviewState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class CatalogoPreviewInitial extends CatalogoPreviewState {}

/// Estado de carga
class CatalogoPreviewLoading extends CatalogoPreviewState {}

/// Estado con datos cargados
class CatalogoPreviewLoaded extends CatalogoPreviewState {
  final CatalogoPreview preview;

  const CatalogoPreviewLoaded({required this.preview});

  @override
  List<Object?> get props => [preview];
}

/// Estado de error
class CatalogoPreviewError extends CatalogoPreviewState {
  final String message;

  const CatalogoPreviewError({required this.message});

  @override
  List<Object?> get props => [message];
}
