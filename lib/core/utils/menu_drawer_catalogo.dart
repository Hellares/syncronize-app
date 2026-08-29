import '../../features/empresa/presentation/widgets/accesos_rapidos_section.dart'
    show AccesosRapidosCatalogo;

/// Ítems del drawer que un administrador puede ocultarle a un usuario.
///
/// Comparten lista con los accesos rápidos: todo va a
/// `UsuarioSedeRol.accesosRapidosOcultos`. Es a propósito — así un id que
/// existe en los dos lados (por ejemplo `cotizaciones`) se oculta de una sola
/// vez en el dashboard y en el menú, que es la paridad que se buscaba.
///
/// 🔴 Los ids de acá van con prefijo `menu.` para que NUNCA puedan chocar con
/// los 21 del dashboard. Un choque accidental haría que ocultar un botón
/// escondiera un ítem de menú que no tiene nada que ver.
///
/// 🔴 Igual que los del dashboard: **estos ids son para siempre**. Si se
/// renombra uno, a todos los usuarios que lo tenían oculto les reaparece sin
/// que nadie haya tocado su configuración.
///
/// ⚠️ Esto OCULTA, no prohíbe: la ruta se sigue pudiendo alcanzar. Lo que
/// impide de verdad son los permisos del rol.
///
/// **Alcance**: solo las secciones donde la operación varía de verdad entre
/// negocios. Administración y Catálogos quedaron afuera a propósito: ya están
/// bien cerradas por permisos y agregarlas solo sumaba ruido a la ficha.
class MenuDrawerCatalogo {
  // ── Ventas ──
  static const ventasDevoluciones = 'menu.ventas.devoluciones';
  static const ventasReportes = 'menu.ventas.reportes';
  static const ventasPoliticasDescuento = 'menu.ventas.politicas-descuento';
  static const ventasTipoCambio = 'menu.ventas.tipo-cambio';

  // ── Servicios ──
  static const serviciosCitas = 'menu.servicios.citas';
  static const serviciosHistorialCliente = 'menu.servicios.historial-cliente';
  static const serviciosPlantillas = 'menu.servicios.plantillas';
  static const serviciosTercerizacion = 'menu.servicios.tercerizacion';
  static const serviciosVinculaciones = 'menu.servicios.vinculaciones';

  // ── Tesorería ──
  static const tesoreriaConsolidado = 'menu.tesoreria.consolidado';
  static const tesoreriaGastosRecurrentes = 'menu.tesoreria.gastos-recurrentes';
  static const tesoreriaCuentasBancarias = 'menu.tesoreria.cuentas-bancarias';
  static const tesoreriaCuentasRecaudacion =
      'menu.tesoreria.cuentas-recaudacion';
  static const tesoreriaAgentesBancarios = 'menu.tesoreria.agentes-bancarios';

  // ── Facturación SUNAT ──
  static const facturacionCatalogosGre = 'menu.facturacion.catalogos-gre';
  static const facturacionAnulaciones = 'menu.facturacion.anulaciones';
  static const facturacionCorrelativos = 'menu.facturacion.correlativos';

  // ── Inventario ──
  static const invStockSede = 'menu.inventario.stock-sede';
  static const invAlertasStock = 'menu.inventario.alertas-stock';
  static const invTransferencias = 'menu.inventario.transferencias';
  static const invIncidenciasTransferencia =
      'menu.inventario.incidencias-transferencia';
  static const invReportesIncidencia = 'menu.inventario.reportes-incidencia';
  static const invKardex = 'menu.inventario.kardex';
  static const invProduccion = 'menu.inventario.produccion';
  static const invAbrirBultos = 'menu.inventario.abrir-bultos';
  static const invTrazabilidad = 'menu.inventario.trazabilidad';
  static const invInventarioFisico = 'menu.inventario.inventario-fisico';
  static const invStockUbicacion = 'menu.inventario.stock-ubicacion';
  static const invGestionUbicaciones = 'menu.inventario.gestion-ubicaciones';
  static const invStockMinMax = 'menu.inventario.stock-min-max';
  static const invMerma = 'menu.inventario.merma';
  static const invValorizacion = 'menu.inventario.valorizacion';
  static const invReorden = 'menu.inventario.reorden';
  static const invRotacion = 'menu.inventario.rotacion';
  static const invHistorialPrecios = 'menu.inventario.historial-precios';
  static const invCodigosBarras = 'menu.inventario.codigos-barras';

  /// El árbol que dibuja la ficha de usuario: sección → ítems (id, label).
  ///
  /// Incluye también los ids del dashboard que aparecen en el menú, para que
  /// el admin vea la sección COMPLETA y no una lista con huecos. Al tildar uno
  /// de esos, se oculta en los dos lados a la vez.
  static const secciones = <(String, List<(String, String)>)>[
    (
      'Ventas',
      [
        (AccesosRapidosCatalogo.ventaRapida, 'Venta Rápida'),
        (AccesosRapidosCatalogo.ventaAvanzada, 'Venta Avanzada'),
        (AccesosRapidosCatalogo.cotizaciones, 'Cotizaciones'),
        (AccesosRapidosCatalogo.ventas, 'Ventas'),
        (AccesosRapidosCatalogo.colaPos, 'Cola POS'),
        (ventasDevoluciones, 'Devoluciones'),
        (ventasReportes, 'Reportes Ventas'),
        (ventasPoliticasDescuento, 'Políticas de Descuento'),
        (ventasTipoCambio, 'Tipo de Cambio'),
      ]
    ),
    (
      'Servicios',
      [
        (AccesosRapidosCatalogo.servicios, 'Servicios'),
        (AccesosRapidosCatalogo.ordenesServicio, 'Órdenes de Servicio'),
        (serviciosCitas, 'Citas'),
        (serviciosHistorialCliente, 'Historial por Cliente'),
        (serviciosPlantillas, 'Plantillas de Servicio'),
        (serviciosTercerizacion, 'Tercerización B2B'),
        (serviciosVinculaciones, 'Vinculaciones B2B'),
      ]
    ),
    (
      'Tesorería',
      [
        (AccesosRapidosCatalogo.caja, 'Caja'),
        (AccesosRapidosCatalogo.monitorCajas, 'Monitor Cajas'),
        (AccesosRapidosCatalogo.historialCajas, 'Historial de Cajas'),
        (AccesosRapidosCatalogo.tesoreria, 'Tesorería'),
        (tesoreriaConsolidado, 'Tesorería Consolidado'),
        (AccesosRapidosCatalogo.cajaChica, 'Caja Chica'),
        (tesoreriaGastosRecurrentes, 'Gastos Recurrentes'),
        (tesoreriaCuentasBancarias, 'Cuentas Bancarias'),
        (tesoreriaCuentasRecaudacion, 'Cuentas de Recaudación'),
        (tesoreriaAgentesBancarios, 'Agentes Bancarios'),
        (AccesosRapidosCatalogo.cuentasPorCobrar, 'Cuentas por Cobrar'),
      ]
    ),
    (
      'Facturación SUNAT',
      [
        (AccesosRapidosCatalogo.facturacion, 'Monitor Facturación'),
        (AccesosRapidosCatalogo.guiasRemision, 'Guías de Remisión'),
        (facturacionCatalogosGre, 'Catálogos GRE'),
        (facturacionAnulaciones, 'Anulaciones SUNAT'),
        (AccesosRapidosCatalogo.flujoDocs, 'Flujo Documentos'),
        (facturacionCorrelativos, 'Reporte Correlativos'),
      ]
    ),
    (
      'Inventario',
      [
        (invStockSede, 'Stock por Sede'),
        (invAlertasStock, 'Alertas de Stock'),
        (invTransferencias, 'Transferencias'),
        (invIncidenciasTransferencia, 'Incidencias de Transferencia'),
        (invReportesIncidencia, 'Reportes de Incidencia'),
        (invKardex, 'Kardex'),
        (invProduccion, 'Producción (lotes fabricados)'),
        (invAbrirBultos, 'Abrir bultos'),
        (invTrazabilidad, 'Trazabilidad de producto'),
        (invInventarioFisico, 'Inventario Físico'),
        (invStockUbicacion, 'Stock por Ubicación'),
        (invGestionUbicaciones, 'Gestión Ubicaciones'),
        (invStockMinMax, 'Stock Min/Max'),
        (invMerma, 'Merma y Pérdida'),
        (invValorizacion, 'Valorización'),
        (invReorden, 'Reorden'),
        (invRotacion, 'Rotación'),
        (invHistorialPrecios, 'Historial de Precios'),
        (AccesosRapidosCatalogo.monitorProductos, 'Monitor Productos'),
        (invCodigosBarras, 'Códigos de Barras'),
      ]
    ),
  ];

  /// Todos los ids del árbol, para validar y para tests.
  static List<String> get todosLosIds =>
      [for (final (_, items) in secciones) ...items.map((i) => i.$1)];
}
