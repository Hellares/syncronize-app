import 'granular_permissions_catalog.dart';
import '../../features/empresa/presentation/widgets/accesos_rapidos_section.dart'
    show AccesosRapidosCatalogo;

/// Configuración estándar (preset) de un rol cuando se crea un usuario
/// nuevo. El admin elige el rol, opcionalmente toca "Aplicar configuración
/// estándar" y se rellenan los campos. Después puede ajustar puntualmente.
///
/// Estos defaults reflejan operativa típica:
///  - VENDEDOR: vende, sin caja, no ve costos.
///  - CAJERO: vende y maneja caja, no ve costos.
///  - TECNICO: trabaja órdenes de servicio.
///  - CONTADOR: visualiza todo lo financiero, sin operar caja.
///
/// Si el cliente final tiene una operativa distinta, el admin igual
/// puede ajustar manualmente — el preset es solo punto de partida.
class RolPreset {
  final bool puedeAbrirCaja;
  final bool puedeCerrarCaja;
  /// Accesos rápidos del dashboard que NO debe ver por default.
  final List<String> accesosRapidosOcultos;
  /// Permisos granulares activados por default.
  final List<String> permisosEspeciales;

  const RolPreset({
    this.puedeAbrirCaja = false,
    this.puedeCerrarCaja = false,
    this.accesosRapidosOcultos = const [],
    this.permisosEspeciales = const [],
  });
}

/// Map rol → preset. Las claves coinciden con `RolUsuario.value`.
const Map<String, RolPreset> kRolPresets = {
  'VENDEDOR': RolPreset(
    // No abre caja por default (admin tilda manualmente si quiere).
    puedeAbrirCaja: false,
    puedeCerrarCaja: false,
    // Oculta items que solo sirven al admin/contador.
    accesosRapidosOcultos: [
      AccesosRapidosCatalogo.facturacion,
      AccesosRapidosCatalogo.monitorProductos,
      AccesosRapidosCatalogo.flujoDocs,
      AccesosRapidosCatalogo.config,
      AccesosRapidosCatalogo.cajaChica,
    ],
    permisosEspeciales: [],
  ),

  'CAJERO': RolPreset(
    // Por nombre del rol asume que opera caja.
    puedeAbrirCaja: true,
    puedeCerrarCaja: true,
    accesosRapidosOcultos: [
      AccesosRapidosCatalogo.config,
      AccesosRapidosCatalogo.monitorProductos,
    ],
    permisosEspeciales: [
      // Cajero típicamente puede anular movimientos suyos.
      GranularPermissionId.cajaMovimientoAnular,
    ],
  ),

  'TECNICO': RolPreset(
    accesosRapidosOcultos: [
      AccesosRapidosCatalogo.facturacion,
      AccesosRapidosCatalogo.finanzas,
      AccesosRapidosCatalogo.config,
      AccesosRapidosCatalogo.cajaChica,
      AccesosRapidosCatalogo.cuentasPorCobrar,
    ],
  ),

  'CONTADOR': RolPreset(
    // Contador NO opera caja, solo lee.
    accesosRapidosOcultos: [
      AccesosRapidosCatalogo.ventaRapida,
      AccesosRapidosCatalogo.ventaAvanzada,
      AccesosRapidosCatalogo.colaPos,
    ],
    permisosEspeciales: [
      GranularPermissionId.productoVerCosto,
      GranularPermissionId.clienteVerCredito,
    ],
  ),

  'OPERADOR': RolPreset(
    accesosRapidosOcultos: [
      AccesosRapidosCatalogo.ventaRapida,
      AccesosRapidosCatalogo.ventaAvanzada,
      AccesosRapidosCatalogo.facturacion,
      AccesosRapidosCatalogo.config,
    ],
  ),

  'LECTURA': RolPreset(
    accesosRapidosOcultos: [
      AccesosRapidosCatalogo.ventaRapida,
      AccesosRapidosCatalogo.ventaAvanzada,
      AccesosRapidosCatalogo.colaPos,
      AccesosRapidosCatalogo.config,
    ],
  ),

  'REPARTIDOR': RolPreset(
    // Solo entrega pedidos: sin caja y sin accesos de venta/finanzas.
    accesosRapidosOcultos: [
      AccesosRapidosCatalogo.ventaRapida,
      AccesosRapidosCatalogo.ventaAvanzada,
      AccesosRapidosCatalogo.colaPos,
      AccesosRapidosCatalogo.facturacion,
      AccesosRapidosCatalogo.config,
      AccesosRapidosCatalogo.cajaChica,
    ],
  ),
};

/// Devuelve el preset de un rol o un preset vacío si no está mapeado.
RolPreset presetParaRol(String rolValue) {
  return kRolPresets[rolValue] ?? const RolPreset();
}
