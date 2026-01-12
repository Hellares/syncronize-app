import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/configuracion_codigos.dart';
import '../repositories/configuracion_codigos_repository.dart';

/// UseCase para actualizar la configuración de variantes
@injectable
class UpdateConfigVariantesUseCase {
  final ConfiguracionCodigosRepository _repository;

  UpdateConfigVariantesUseCase(this._repository);

  Future<Resource<ConfiguracionCodigos>> call({
    required String empresaId,
    String? varianteCodigo,
    String? varianteSeparador,
    int? varianteLongitud,
  }) {
    return _repository.updateConfigVariantes(
      empresaId: empresaId,
      varianteCodigo: varianteCodigo,
      varianteSeparador: varianteSeparador,
      varianteLongitud: varianteLongitud,
    );
  }
}
