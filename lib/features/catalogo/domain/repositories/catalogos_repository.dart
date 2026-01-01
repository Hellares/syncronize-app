import '../../../../core/utils/resource.dart';
import '../entities/catalogo_preview.dart';

/// Contrato del repositorio de catálogos
abstract class CatalogosRepository {
  /// Obtener preview de catálogos que se activarán para un rubro
  Future<Resource<CatalogoPreview>> getCatalogoPreview(String rubro);
}
