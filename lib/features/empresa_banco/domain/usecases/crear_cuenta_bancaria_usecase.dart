import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../entities/empresa_banco.dart';
import '../repositories/empresa_banco_repository.dart';

@injectable
class CrearCuentaBancariaUseCase {
  final EmpresaBancoRepository _repository;

  CrearCuentaBancariaUseCase(this._repository);

  Future<Resource<EmpresaBanco>> call({
    required String nombreBanco,
    required String tipoCuenta,
    required String numeroCuenta,
    String? cci,
    String? moneda,
    String? titular,
    bool? esPrincipal,
    double? saldoActual,
  }) {
    return _repository.crear(
      nombreBanco: nombreBanco,
      tipoCuenta: tipoCuenta,
      numeroCuenta: numeroCuenta,
      cci: cci,
      moneda: moneda,
      titular: titular,
      esPrincipal: esPrincipal,
      saldoActual: saldoActual,
    );
  }
}
