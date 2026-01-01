import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../data/models/create_combo_dto.dart';
import '../entities/combo.dart';
import '../repositories/combo_repository.dart';

/// Use case para crear un nuevo combo directamente
@lazySingleton
class CreateComboUseCase {
  final ComboRepository _repository;

  CreateComboUseCase(this._repository);

  /// Ejecuta el use case para crear un combo
  ///
  /// Parámetros:
  /// - [dto]: Datos del combo a crear
  ///
  /// Retorna un [Resource] con el combo creado o un error
  Future<Resource<Combo>> call({
    required CreateComboDto dto,
  }) async {
    return await _repository.createCombo(dto: dto);
  }
}
