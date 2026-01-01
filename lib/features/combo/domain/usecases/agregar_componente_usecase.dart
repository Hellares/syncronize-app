import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/componente_combo.dart';
import '../repositories/combo_repository.dart';

@injectable
class AgregarComponenteUseCase {
  final ComboRepository repository;

  AgregarComponenteUseCase(this.repository);

  Future<Resource<ComponenteCombo>> call({
    required String comboId,
    required String empresaId,
    String? componenteProductoId,
    String? componenteVarianteId,
    required int cantidad,
    bool? esPersonalizable,
    String? categoriaComponente,
    int? orden,
  }) {
    return repository.agregarComponente(
      comboId: comboId,
      empresaId: empresaId,
      componenteProductoId: componenteProductoId,
      componenteVarianteId: componenteVarianteId,
      cantidad: cantidad,
      esPersonalizable: esPersonalizable,
      categoriaComponente: categoriaComponente,
      orden: orden,
    );
  }
}
