import '../../../../core/utils/resource.dart';
import '../entities/atributo_plantilla.dart';

/// Repository interface para operaciones relacionadas con plantillas de atributos
abstract class PlantillaRepository {
  /// Crea una nueva plantilla de atributos
  Future<Resource<AtributoPlantilla>> crearPlantilla({
    required String nombre,
    String? descripcion,
    String? icono,
    String? categoriaId,
    int? orden,
    required List<PlantillaAtributoCreate> atributos,
  });

  /// Obtiene todas las plantillas de atributos
  Future<Resource<List<AtributoPlantilla>>> getPlantillas({
    String? categoriaId,
  });

  /// Obtiene una plantilla por ID
  Future<Resource<AtributoPlantilla>> getPlantilla({
    required String plantillaId,
  });

  /// Actualiza una plantilla existente
  Future<Resource<AtributoPlantilla>> actualizarPlantilla({
    required String plantillaId,
    String? nombre,
    String? descripcion,
    String? icono,
    String? categoriaId,
    int? orden,
    List<PlantillaAtributoCreate>? atributos,
  });

  /// Elimina una plantilla (soft delete)
  Future<Resource<void>> eliminarPlantilla({
    required String plantillaId,
  });

  /// Aplica una plantilla a un producto o variante
  Future<Resource<AplicarPlantillaResult>> aplicarPlantilla({
    required String plantillaId,
    String? productoId,
    String? varianteId,
  });

  /// Obtiene información de límites del plan de suscripción
  Future<Resource<PlanLimitsInfo>> getLimitsInfo();
}

/// Clase para definir atributo al crear/actualizar plantilla
class PlantillaAtributoCreate {
  final String atributoId;
  final int? orden;
  final bool? requeridoOverride;
  final List<String>? valoresOverride;

  const PlantillaAtributoCreate({
    required this.atributoId,
    this.orden,
    this.requeridoOverride,
    this.valoresOverride,
  });
}

/// Resultado de aplicar una plantilla
class AplicarPlantillaResult {
  final int atributosCreados;

  const AplicarPlantillaResult({
    required this.atributosCreados,
  });
}

/// Información de límites del plan
class PlanLimitsInfo {
  final String plan;
  final PlanLimitDetail plantillasAtributos;

  const PlanLimitsInfo({
    required this.plan,
    required this.plantillasAtributos,
  });
}

/// Detalle de límite de un recurso
class PlanLimitDetail {
  final int? limite; // null = ilimitado
  final int actual;
  final int? disponible; // null = ilimitado

  const PlanLimitDetail({
    this.limite,
    required this.actual,
    this.disponible,
  });

  bool get esIlimitado => limite == null;
  bool get alcanzado => disponible != null && disponible! <= 0;
}
