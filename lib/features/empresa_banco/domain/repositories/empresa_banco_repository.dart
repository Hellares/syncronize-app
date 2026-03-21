import '../../../../core/utils/resource.dart';
import '../entities/empresa_banco.dart';

/// Repository interface para operaciones de cuentas bancarias
abstract class EmpresaBancoRepository {
  Future<Resource<List<EmpresaBanco>>> listar();

  Future<Resource<EmpresaBanco>> crear({
    required String nombreBanco,
    required String tipoCuenta,
    required String numeroCuenta,
    String? cci,
    String? moneda,
    String? titular,
    bool? esPrincipal,
    double? saldoActual,
  });

  Future<Resource<EmpresaBanco>> actualizar({
    required String id,
    String? nombreBanco,
    String? tipoCuenta,
    String? numeroCuenta,
    String? cci,
    String? moneda,
    String? titular,
    bool? esPrincipal,
  });

  Future<Resource<void>> eliminar({required String id});

  Future<Resource<EmpresaBanco>> marcarPrincipal({required String id});

  Future<Resource<EmpresaBanco>> actualizarSaldo({
    required String id,
    required double saldo,
  });

  Future<Resource<ConciliacionBancaria>> getConciliacion({
    required String cuentaId,
    String? fechaDesde,
    String? fechaHasta,
  });
}
