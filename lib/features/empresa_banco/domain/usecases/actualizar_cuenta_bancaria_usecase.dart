import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/empresa_banco.dart';
import '../repositories/empresa_banco_repository.dart';

@injectable
class ActualizarCuentaBancariaUseCase {
  final EmpresaBancoRepository _repository;

  ActualizarCuentaBancariaUseCase(this._repository);

  Future<Resource<EmpresaBanco>> call({
    required String id,
    String? nombreBanco,
    String? tipoCuenta,
    String? numeroCuenta,
    String? cci,
    String? moneda,
    String? titular,
    bool? esPrincipal,
  }) {
    return _repository.actualizar(
      id: id,
      nombreBanco: nombreBanco,
      tipoCuenta: tipoCuenta,
      numeroCuenta: numeroCuenta,
      cci: cci,
      moneda: moneda,
      titular: titular,
      esPrincipal: esPrincipal,
    );
  }
}
