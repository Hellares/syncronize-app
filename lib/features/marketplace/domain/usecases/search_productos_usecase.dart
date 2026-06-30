import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/productos_paginados.dart';
import '../repositories/marketplace_repository.dart';

@injectable
class SearchProductosUseCase {
  final MarketplaceRepository _repository;

  SearchProductosUseCase(this._repository);

  Future<Resource<ProductosPaginados>> call({
    String? search,
    String? categoriaId,
    String? marcaId,
    double? precioMin,
    double? precioMax,
    String? departamento,
    String? orden,
    double? lat,
    double? lng,
    int page = 1,
    int limit = 20,
  }) {
    return _repository.searchProductos(
      search: search,
      categoriaId: categoriaId,
      marcaId: marcaId,
      precioMin: precioMin,
      precioMax: precioMax,
      departamento: departamento,
      orden: orden,
      lat: lat,
      lng: lng,
      page: page,
      limit: limit,
    );
  }
}
