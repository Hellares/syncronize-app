import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/caja_auditoria.dart';
import '../repositories/caja_repository.dart';

@injectable
class GetAuditoriaUseCase {
  final CajaRepository _repository;

  GetAuditoriaUseCase(this._repository);

  Future<Resource<CajaAuditoria>> call({required String cajaId}) {
    return _repository.getAuditoria(cajaId: cajaId);
  }
}
