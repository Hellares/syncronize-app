import '../../../../core/utils/resource.dart';
import '../entities/politica_descuento.dart';

/// Repository interface para operaciones relacionadas con políticas de descuento
abstract class DescuentoRepository {
  /// Obtener todas las políticas de descuento con filtros y paginación
  Future<Resource<Map<String, dynamic>>> getPoliticas({
    String? tipoDescuento,
    bool? isActive,
    int page = 1,
    int limit = 20,
  });

  /// Obtener una política por ID
  Future<Resource<PoliticaDescuento>> getPoliticaById(String id);

  /// Crear nueva política de descuento
  Future<Resource<PoliticaDescuento>> createPolitica({
    required String nombre,
    String? descripcion,
    required TipoDescuento tipoDescuento,
    required TipoCalculoDescuento tipoCalculo,
    required double valorDescuento,
    double? descuentoMaximo,
    double? montoMinCompra,
    int? cantidadMaxUsos,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    bool? aplicarATodos,
    int? prioridad,
    int? maxFamiliaresPorTrabajador,
  });

  /// Actualizar política de descuento
  Future<Resource<PoliticaDescuento>> updatePolitica({
    required String id,
    String? nombre,
    String? descripcion,
    TipoDescuento? tipoDescuento,
    TipoCalculoDescuento? tipoCalculo,
    double? valorDescuento,
    double? descuentoMaximo,
    double? montoMinCompra,
    int? cantidadMaxUsos,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    bool? aplicarATodos,
    int? prioridad,
    int? maxFamiliaresPorTrabajador,
    bool? isActive,
  });

  /// Eliminar política de descuento
  Future<Resource<void>> deletePolitica(String id);

  /// Asignar usuarios a una política
  Future<Resource<List<Map<String, dynamic>>>> asignarUsuarios({
    required String politicaId,
    required List<String> usuariosIds,
    int? limiteMensualUsos,
  });

  /// Obtener IDs de usuarios asignados a una política
  Future<Resource<List<String>>> obtenerUsuariosAsignados(String politicaId);

  /// Remover usuario de una política
  Future<Resource<void>> removerUsuario({
    required String politicaId,
    required String usuarioId,
  });

  /// Agregar familiar a un trabajador
  Future<Resource<Map<String, dynamic>>> agregarFamiliar({
    required String trabajadorId,
    required String familiarUsuarioId,
    required Parentesco parentesco,
    int? limiteMensualUsos,
    String? documentoVerificacion,
  });

  /// Obtener familiares de un trabajador
  Future<Resource<List<Map<String, dynamic>>>> obtenerFamiliares(String trabajadorId);

  /// Remover familiar
  Future<Resource<void>> removerFamiliar({
    required String trabajadorId,
    required String familiarId,
  });

  /// Asignar productos a una política
  Future<Resource<List<Map<String, dynamic>>>> asignarProductos({
    required String politicaId,
    required List<Map<String, dynamic>> productos,
  });

  /// Asignar categorías a una política
  Future<Resource<List<Map<String, dynamic>>>> asignarCategorias({
    required String politicaId,
    required List<Map<String, dynamic>> categorias,
  });

  /// Calcular descuento aplicable
  Future<Resource<Map<String, dynamic>>> calcularDescuento({
    required String usuarioId,
    required String productoId,
    String? varianteId,
    required int cantidad,
    required double precioBase,
  });

  /// Obtener historial de uso de una política
  Future<Resource<List<Map<String, dynamic>>>> obtenerHistorialUso(String politicaId);
}
