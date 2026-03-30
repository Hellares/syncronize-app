import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/pago_suscripcion.dart';
import '../repositories/pago_suscripcion_repository.dart';

@injectable
class GetMisPagosUseCase {
  final PagoSuscripcionRepository _repository;

  GetMisPagosUseCase(this._repository);

  Future<Resource<List<PagoSuscripcion>>> call({
    int page = 1,
    int pageSize = 20,
  }) {
    return _repository.getMisPagos(page: page, pageSize: pageSize);
  }
}
