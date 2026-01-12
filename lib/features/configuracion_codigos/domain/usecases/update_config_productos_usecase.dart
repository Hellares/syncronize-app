import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/configuracion_codigos.dart';
import '../repositories/configuracion_codigos_repository.dart';

/// UseCase para actualizar la configuración de productos
@injectable
class UpdateConfigProductosUseCase {
  final ConfiguracionCodigosRepository _repository;

  UpdateConfigProductosUseCase(this._repository);

  Future<Resource<ConfiguracionCodigos>> call({
    required String empresaId,
    String? productoCodigo,
    String? productoSeparador,
    int? productoLongitud,
    bool? productoIncluirSede,
  }) {
    return _repository.updateConfigProductos(
      empresaId: empresaId,
      productoCodigo: productoCodigo,
      productoSeparador: productoSeparador,
      productoLongitud: productoLongitud,
      productoIncluirSede: productoIncluirSede,
    );
  }
}
