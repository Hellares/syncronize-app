import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/resource.dart';
import '../entities/catalogo_preview.dart';
import '../repositories/catalogos_repository.dart';

/// Caso de uso para obtener el preview de catálogos según rubro
@injectable
class GetCatalogoPreviewUseCase
    implements UseCase<CatalogoPreview, GetCatalogoPreviewParams> {
  final CatalogosRepository repository;

  GetCatalogoPreviewUseCase(this.repository);

  @override
  Future<Resource<CatalogoPreview>> call(
      GetCatalogoPreviewParams params) async {
    return await repository.getCatalogoPreview(params.rubro);
  }
}

/// Parámetros para obtener preview de catálogos
class GetCatalogoPreviewParams extends Equatable {
  final String rubro;

  const GetCatalogoPreviewParams({required this.rubro});

  @override
  List<Object?> get props => [rubro];
}
