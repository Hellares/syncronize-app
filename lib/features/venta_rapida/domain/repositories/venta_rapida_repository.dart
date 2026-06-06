import '../../../../core/utils/resource.dart';
import '../../../venta/domain/entities/venta.dart';
import '../entities/orden_cobrable.dart';

/// Repository interface para el flujo de Venta Rápida (POS simplificado).
///
/// Reusa la entidad `Venta` del módulo venta porque el resultado del cobro
/// es exactamente el mismo. Solo se separa el repositorio para permitir
/// mocks/tests aislados de este flujo.
abstract class VentaRapidaRepository {
  /// Crea + cobra una venta en una sola operación.
  /// Mismo endpoint que el POS avanzado pero el payload viene
  /// estructurado por el cubit del módulo Venta Rápida.
  Future<Resource<Venta>> cobrar({required Map<String, dynamic> data});

  /// Obtiene (o crea on-the-fly) el id del EmpresaPersona "CLIENTES VARIOS"
  /// para la empresa actual. Usado cuando el cajero elige "Genérico" en el
  /// flujo de cobro.
  Future<Resource<String>> obtenerClienteGenericoId();

  /// Busca (o crea) un cliente por DNI vía RENIEC. Backend hace upsert
  /// idempotente: si la persona ya está en el sistema la reusa, si no la
  /// crea con los datos de RENIEC. Devuelve los datos listos para vincular
  /// como `clienteId` en la venta.
  Future<Resource<ClienteResueltoDni>> buscarClientePorDni(String dni);

  /// Busca (o crea) un cliente empresa por RUC vía SUNAT. Idempotente.
  /// Devuelve datos listos para vincular como `clienteEmpresaId` en la venta.
  Future<Resource<ClienteResueltoRuc>> buscarClientePorRuc(String ruc);

  /// Órdenes de servicio cobrables (REPARADO/LISTO_ENTREGA con saldo > 0 y
  /// sin venta vinculada) para el selector "Cobrar servicio" de VR.
  Future<Resource<List<OrdenCobrable>>> getOrdenesCobrables({String? search});
}

/// Resultado de resolver un cliente por DNI.
class ClienteResueltoDni {
  final String clienteEmpresaId;
  final String personaId;
  final String dni;
  final String nombres;
  final String apellidos;
  final String nombreCompleto;
  final String? direccion;
  final String origen; // 'INTERNO' | 'RENIEC'

  const ClienteResueltoDni({
    required this.clienteEmpresaId,
    required this.personaId,
    required this.dni,
    required this.nombres,
    required this.apellidos,
    required this.nombreCompleto,
    this.direccion,
    required this.origen,
  });
}

/// Resultado de resolver un cliente empresa (B2B) por RUC.
class ClienteResueltoRuc {
  /// Id del registro `ClienteEmpresa` listo para vincular como `clienteEmpresaId`.
  final String clienteEmpresaId;
  final String ruc;
  final String razonSocial;
  final String? nombreComercial;
  final String? direccion;
  final String? estadoContribuyente;
  final String? condicionContribuyente;

  const ClienteResueltoRuc({
    required this.clienteEmpresaId,
    required this.ruc,
    required this.razonSocial,
    this.nombreComercial,
    this.direccion,
    this.estadoContribuyente,
    this.condicionContribuyente,
  });
}
