import '../../../../core/utils/resource.dart';
import '../entities/categoria_maestra.dart';
import '../entities/marca_maestra.dart';
import '../entities/empresa_categoria.dart';
import '../entities/empresa_marca.dart';

/// Repository interface para operaciones relacionadas con catálogos (categorías y marcas)
abstract class CatalogoRepository {
  // ============================================
  // CATEGORÍAS MAESTRAS
  // ============================================

  /// Obtiene el catálogo global de categorías maestras
  Future<Resource<List<CategoriaMaestra>>> getCategoriasMaestras({
    bool incluirHijos = false,
    bool soloPopulares = false,
  });

  // ============================================
  // MARCAS MAESTRAS
  // ============================================

  /// Obtiene el catálogo global de marcas maestras
  Future<Resource<List<MarcaMaestra>>> getMarcasMaestras({
    bool soloPopulares = false,
  });

  // ============================================
  // CATEGORÍAS POR EMPRESA
  // ============================================

  /// Obtiene las categorías activas de una empresa
  Future<Resource<List<EmpresaCategoria>>> getCategoriasEmpresa(
    String empresaId,
  );

  /// Activa una categoría maestra para una empresa
  Future<Resource<EmpresaCategoria>> activarCategoria({
    required String empresaId,
    String? categoriaMaestraId,
    String? nombrePersonalizado,
    String? descripcionPersonalizada,
    String? nombreLocal,
    int? orden,
  });

  /// Desactiva una categoría de una empresa
  Future<Resource<void>> desactivarCategoria({
    required String empresaId,
    required String empresaCategoriaId,
  });

  /// Activa automáticamente las categorías populares para una empresa
  Future<Resource<List<EmpresaCategoria>>> activarCategoriasPopulares(
    String empresaId,
  );

  // ============================================
  // MARCAS POR EMPRESA
  // ============================================

  /// Obtiene las marcas activas de una empresa
  Future<Resource<List<EmpresaMarca>>> getMarcasEmpresa(
    String empresaId,
  );

  /// Activa una marca maestra para una empresa
  Future<Resource<EmpresaMarca>> activarMarca({
    required String empresaId,
    String? marcaMaestraId,
    String? nombrePersonalizado,
    String? descripcionPersonalizada,
    String? nombreLocal,
    int? orden,
  });

  /// Desactiva una marca de una empresa
  Future<Resource<void>> desactivarMarca({
    required String empresaId,
    required String empresaMarcaId,
  });

  /// Activa automáticamente las marcas populares para una empresa
  Future<Resource<List<EmpresaMarca>>> activarMarcasPopulares(
    String empresaId,
  );
}
