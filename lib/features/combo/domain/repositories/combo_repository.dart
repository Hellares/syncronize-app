import '../../../../core/utils/resource.dart';
import '../../data/models/create_combo_dto.dart';
import '../entities/combo.dart';
import '../entities/componente_combo.dart';

/// Repository interface para operaciones relacionadas con combos
abstract class ComboRepository {
  /// Crea un nuevo combo directamente
  Future<Resource<Combo>> createCombo({
    required CreateComboDto dto,
  });

  /// Obtiene todos los combos de una empresa
  Future<Resource<List<Combo>>> getCombos({
    required String empresaId,
    required String sedeId,
  });

  /// Obtiene la información completa de un combo
  Future<Resource<Combo>> getComboCompleto({
    required String comboId,
    required String empresaId,
    required String sedeId,
  });

  /// Agrega un componente a un combo
  Future<Resource<ComponenteCombo>> agregarComponente({
    required String comboId,
    required String empresaId,
    required String sedeId,
    String? componenteProductoId,
    String? componenteVarianteId,
    required int cantidad,
    bool? esPersonalizable,
    String? categoriaComponente,
    int? orden,
  });

  /// Agrega múltiples componentes a un combo en batch
  Future<Resource<List<ComponenteCombo>>> agregarComponentesBatch({
    required String comboId,
    required String empresaId,
    required String sedeId,
    required List<Map<String, dynamic>> componentes,
  });

  /// Obtiene todos los componentes de un combo
  Future<Resource<List<ComponenteCombo>>> getComponentes({
    required String comboId,
    required String empresaId,
    required String sedeId,
  });

  /// Actualiza un componente del combo
  Future<Resource<ComponenteCombo>> actualizarComponente({
    required String componenteId,
    required String empresaId,
    required String sedeId,
    int? cantidad,
    bool? esPersonalizable,
    String? categoriaComponente,
    int? orden,
  });

  /// Elimina un componente del combo
  Future<Resource<void>> eliminarComponente({
    required String componenteId,
    required String empresaId,
  });

  /// Obtiene el stock disponible de un combo
  Future<Resource<int>> getStockDisponible({
    required String comboId,
    required String sedeId,
  });

  /// Calcula el precio del combo
  Future<Resource<double>> getPrecioCalculado({
    required String comboId,
    required String sedeId,
  });

  /// Valida si el combo tiene stock suficiente
  Future<Resource<bool>> validarStock({
    required String comboId,
    required int cantidad,
    required String sedeId,
  });

  /// Obtiene la reservación actual de un combo en una sede
  Future<Resource<int>> getReservacion({
    required String comboId,
    required String sedeId,
  });

  /// Reserva stock para un combo (cantidad total, no delta)
  Future<Resource<int>> reservarStock({
    required String comboId,
    required String sedeId,
    required int cantidad,
  });

  /// Libera toda la reservación de un combo en una sede
  Future<Resource<void>> liberarReserva({
    required String comboId,
    required String sedeId,
  });
}
