import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/empresa_banco.dart';
import '../repositories/empresa_banco_repository.dart';

@injectable
class GetConciliacionUseCase {
  final EmpresaBancoRepository _repository;

  GetConciliacionUseCase(this._repository);

  Future<Resource<ConciliacionBancaria>> call({
    required String cuentaId,
    String? fechaDesde,
    String? fechaHasta,
  }) {
    return _repository.getConciliacion(
      cuentaId: cuentaId,
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
    );
  }
}
