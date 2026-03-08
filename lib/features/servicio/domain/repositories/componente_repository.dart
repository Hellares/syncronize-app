import '../../../../core/utils/resource.dart';
import '../entities/componente.dart';

abstract class ComponenteRepository {
  Future<Resource<List<TipoComponente>>> getTipos();

  Future<Resource<TipoComponente>> crearTipo({
    required String nombre,
    required String categoria,
    String? descripcion,
  });

  Future<Resource<List<Componente>>> getComponentes({
    String? tipoComponenteId,
    String? search,
  });

  Future<Resource<Componente>> crearComponente({
    required String tipoComponenteId,
    String? marca,
    String? modelo,
    String? numeroSerie,
  });

  Future<Resource<Componente>> findOrCreateComponente({
    required String tipoComponenteId,
    String? marca,
    String? modelo,
    String? numeroSerie,
  });

  Future<Resource<List<String>>> getMarcas({
    required String tipoComponenteId,
  });

  Future<Resource<List<String>>> getModelos({
    required String tipoComponenteId,
    required String marca,
  });
}
