import '../../../../core/utils/resource.dart';
import '../entities/inventario.dart';

/// Repository interface para operaciones de inventario fisico
abstract class InventarioRepository {
  Future<Resource<List<Inventario>>> listar({
    String? sedeId,
    String? estado,
  });

  Future<Resource<Inventario>> getDetalle({
    required String id,
  });

  Future<Resource<Inventario>> crear({
    required Map<String, dynamic> data,
  });

  Future<Resource<void>> iniciar({
    required String id,
  });

  Future<Resource<void>> registrarConteo({
    required String id,
    required String itemId,
    required Map<String, dynamic> data,
  });

  Future<Resource<void>> finalizarConteo({
    required String id,
  });

  Future<Resource<void>> aprobar({
    required String id,
  });

  Future<Resource<void>> aplicarAjustes({
    required String id,
  });

  Future<Resource<void>> cancelar({
    required String id,
  });
}
