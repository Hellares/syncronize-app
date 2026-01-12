import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/configuracion_codigos.dart';
import '../repositories/configuracion_codigos_repository.dart';

/// UseCase para actualizar la configuración de ventas (Notas de Venta)
@injectable
class UpdateConfigVentasUseCase {
  final ConfiguracionCodigosRepository _repository;

  UpdateConfigVentasUseCase(this._repository);

  Future<Resource<ConfiguracionCodigos>> call({
    required String empresaId,
    String? ventaCodigo,
    String? ventaSeparador,
    int? ventaLongitud,
    bool? ventaIncluirSede,
  }) {
    return _repository.updateConfigVentas(
      empresaId: empresaId,
      ventaCodigo: ventaCodigo,
      ventaSeparador: ventaSeparador,
      ventaLongitud: ventaLongitud,
      ventaIncluirSede: ventaIncluirSede,
    );
  }
}
