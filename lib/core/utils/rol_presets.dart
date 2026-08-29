import 'menu_drawer_catalogo.dart';
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

  /// Ítems del MENÚ LATERAL que no debe ver por default
  /// (catálogo `MenuDrawerCatalogo`). Vacío = ve todo lo que su rol permita.
  ///
  /// Va en una lista aparte de [accesosRapidosOcultos] aunque las dos terminen
  /// juntas en el backend: tenerlas separadas acá es lo que permite que
  /// "aplicar configuración estándar" reemplace TODO de forma coherente, en
  /// vez de borrar en silencio lo que el admin había configurado del menú.
  final List<String> menuOcultos;

  const RolPreset({
    this.puedeAbrirCaja = false,
    this.puedeCerrarCaja = false,
    this.accesosRapidosOcultos = const [],
    this.permisosEspeciales = const [],
    this.menuOcultos = const [],
  });
}

/// Map rol → preset. Las claves coinciden con `RolUsuario.value`.
///
/// 🔴 **Solo se listan cosas que el rol REALMENTE VE.** Ocultar algo que su
/// permiso ya le niega no hace nada y ensucia: el preset anterior le escondía
/// al vendedor Facturación, Configuración y Caja Chica, tres pantallas a las
/// que su rol no llegaba de todos modos. Antes de agregar una línea acá,
/// verificar contra `PermissionsService.calculatePermissions`.
///
/// Y el límite de siempre: esto OCULTA, no prohíbe. Si un rol no debe poder
/// entrar aunque conozca la ruta, eso se cambia en los permisos.
const Map<String, RolPreset> kRolPresets = {
  // Vende y cotiza. Sin caja, sin inventario, sin facturación — todo eso ya se
  // lo niega el rol, así que acá solo se sacan las tres cosas que SÍ vería y
  // no hacen a su trabajo.
  'VENDEDOR': RolPreset(
    puedeAbrirCaja: false,
    puedeCerrarCaja: false,
    accesosRapidosOcultos: [
      AccesosRapidosCatalogo.monitorProductos,
      AccesosRapidosCatalogo.flujoDocs,
      AccesosRapidosCatalogo.cuentasPorCobrar,
    ],
    menuOcultos: [
      // Config de la empresa, no del vendedor.
      MenuDrawerCatalogo.ventasTipoCambio,
    ],
    permisosEspeciales: [],
  ),

  // Vende, cobra y maneja SU caja. Le queda el mostrador y poco más:
  // V. Rápida, V. Avanzada, Cola POS, sus ventas, cotizaciones, Caja,
  // Historial de Cajas, Facturación, Productos, Servicios y Por Cobrar.
  //
  // Los ids son compartidos con el menú, así que cada uno de estos también
  // saca el ítem correspondiente del drawer.
  'CAJERO': RolPreset(
    puedeAbrirCaja: true,
    puedeCerrarCaja: true,
    accesosRapidosOcultos: [
      AccesosRapidosCatalogo.monitorProductos,
      AccesosRapidosCatalogo.flujoDocs,
      // Mira el dinero de TODAS las sedes: es gestión, no mostrador.
      AccesosRapidosCatalogo.tesoreria,
      AccesosRapidosCatalogo.sorteos,
      // Sirve para supervisar las cajas de OTROS.
      AccesosRapidosCatalogo.monitorCajas,
      // Fondo fijo: lo maneja administración.
      AccesosRapidosCatalogo.cajaChica,
      // Despacho de mercadería, no cobro.
      AccesosRapidosCatalogo.guiasRemision,
    ],
    menuOcultos: [
      MenuDrawerCatalogo.tesoreriaConsolidado,
    ],
    // Sin permisos especiales: abrir y cerrar caja ya vienen con el rol
    // CAJERO, así que no hay nada que sumarle.
    permisosEspeciales: [],
  ),

  // Trabaja órdenes de servicio. Su rol ya le niega ventas y caja.
  'TECNICO': RolPreset(
    accesosRapidosOcultos: [
      AccesosRapidosCatalogo.monitorProductos,
    ],
    menuOcultos: [
      // Configuración del catálogo de servicios y acuerdos B2B: son de
      // administración, no del técnico que atiende la orden.
      MenuDrawerCatalogo.serviciosPlantillas,
      MenuDrawerCatalogo.serviciosTercerizacion,
    ],
    permisosEspeciales: [],
  ),

  // Mira todo lo financiero y la facturación, pero no opera: ni vende ni
  // cobra. Las pantallas de lectura (Monitor e Historial de Cajas) se quedan.
  'CONTADOR': RolPreset(
    puedeAbrirCaja: false,
    puedeCerrarCaja: false,
    accesosRapidosOcultos: [
      AccesosRapidosCatalogo.ventaRapida,
      AccesosRapidosCatalogo.ventaAvanzada,
      AccesosRapidosCatalogo.colaPos,
      // La pantalla de Caja es operativa (abrir turno, registrar movimientos).
      AccesosRapidosCatalogo.caja,
      AccesosRapidosCatalogo.sorteos,
    ],
    permisosEspeciales: [],
  ),

  // ⚠️ ALMACENERO: no hay preset porque no hay a qué aplicárselo. El rol de
  // empresa más cercano es OPERADOR, y la sección Inventario del drawer exige
  // `canManageProducts`, que hoy es SOLO-ADMIN. Un operador no ve Inventario
  // en absoluto, y eso no se arregla ocultando: hay que decidir si se le
  // concede el permiso o si la sección pasa a pedir `canViewProducts`.
  'OPERADOR': RolPreset(
    accesosRapidosOcultos: [
      AccesosRapidosCatalogo.monitorProductos,
    ],
    permisosEspeciales: [],
  ),

  'LECTURA': RolPreset(
    accesosRapidosOcultos: [
      AccesosRapidosCatalogo.ventaRapida,
      AccesosRapidosCatalogo.ventaAvanzada,
      AccesosRapidosCatalogo.colaPos,
    ],
  ),

  'REPARTIDOR': RolPreset(
    // Solo entrega pedidos: sin nada de venta ni finanzas.
    accesosRapidosOcultos: [
      AccesosRapidosCatalogo.ventaRapida,
      AccesosRapidosCatalogo.ventaAvanzada,
      AccesosRapidosCatalogo.colaPos,
      AccesosRapidosCatalogo.monitorProductos,
    ],
  ),
};

/// Devuelve el preset de un rol o un preset vacío si no está mapeado.
RolPreset presetParaRol(String rolValue) {
  return kRolPresets[rolValue] ?? const RolPreset();
}
