import '../../../../core/utils/resource.dart';
import '../entities/categoria_gasto.dart';

abstract class CategoriaGastoRepository {
  Future<Resource<List<CategoriaGasto>>> listar({String? tipo});

  Future<Resource<CategoriaGasto>> crear({
    required String nombre,
    required String tipo,
    String? color,
    String? icono,
  });

  Future<Resource<CategoriaGasto>> actualizar({
    required String id,
    String? nombre,
    String? color,
    String? icono,
  });

  Future<Resource<void>> eliminar({required String id});
}
