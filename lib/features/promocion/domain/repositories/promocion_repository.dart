import '../../../../core/utils/resource.dart';
import '../entities/campana.dart';

abstract class PromocionRepository {
  Future<Resource<CampanasPaginadas>> getCampanas({
    int page = 1,
    int limit = 20,
  });

  Future<Resource<Campana>> crearCampana({
    required String titulo,
    required String mensaje,
    List<String>? productosIds,
  });

  Future<Resource<List<ProductoEnOferta>>> getProductosEnOferta();
}
