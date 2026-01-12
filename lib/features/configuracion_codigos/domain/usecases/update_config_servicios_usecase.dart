import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/configuracion_codigos.dart';
import '../repositories/configuracion_codigos_repository.dart';

/// UseCase para actualizar la configuración de servicios
@injectable
class UpdateConfigServiciosUseCase {
  final ConfiguracionCodigosRepository _repository;

  UpdateConfigServiciosUseCase(this._repository);

  Future<Resource<ConfiguracionCodigos>> call({
    required String empresaId,
    String? servicioCodigo,
    String? servicioSeparador,
    int? servicioLongitud,
    bool? servicioIncluirSede,
  }) {
    return _repository.updateConfigServicios(
      empresaId: empresaId,
      servicioCodigo: servicioCodigo,
      servicioSeparador: servicioSeparador,
      servicioLongitud: servicioLongitud,
      servicioIncluirSede: servicioIncluirSede,
    );
  }
}
