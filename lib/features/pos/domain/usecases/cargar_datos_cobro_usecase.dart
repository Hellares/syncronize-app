import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/cobrar_cotizacion_data.dart';
import '../repositories/pos_repository.dart';

@injectable
class CargarDatosCobroUseCase {
  final PosRepository _repository;

  CargarDatosCobroUseCase(this._repository);

  Future<Resource<CobrarCotizacionData>> call({required String cotizacionId}) {
    return _repository.cargarDatosCobro(cotizacionId: cotizacionId);
  }
}
