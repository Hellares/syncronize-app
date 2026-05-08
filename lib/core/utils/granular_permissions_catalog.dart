/// Catálogo de permisos granulares — espejo del backend.
/// Backend: `backend/src/auth/services/granular-permissions.catalog.ts`.
///
/// Estos permisos viven en `UsuarioSedeRol.permisos: String[]` y se
/// asignan por usuario individual (no por rol). El admin los marca/desmarca
/// en el form de usuario y `usuario_form_page` / `asignar_rol_dialog`.
///
/// **MANTENER SINCRONIZADO** con la lista del backend. Si agregás un
/// permiso allá, agregalo aquí también con el mismo `id` (string exacto).
class GranularPermission {
  final String id;
  final String label;
  final String description;
  final String category;

  const GranularPermission({
    required this.id,
    required this.label,
    required this.description,
    required this.category,
  });
}

/// IDs constantes para uso desde código (autocompletado + refactor seguro).
class GranularPermissionId {
  static const cajaAbrir = 'caja.abrir';
  static const cajaCerrar = 'caja.cerrar';
  static const cajaMovimientoAnular = 'caja.movimiento-anular';

  static const ventaDescuentoLibre = 'venta.descuento-libre';
  static const ventaAnular = 'venta.anular';
  static const ventaEditarPrecio = 'venta.editar-precio';

  static const cotizacionAprobarGrande = 'cotizacion.aprobar-grande';

  static const productoVerCosto = 'producto.ver-costo';
  static const productoEditarCosto = 'producto.editar-costo';

  static const devolucionCrear = 'devolucion.crear';

  static const clienteVerCredito = 'cliente.ver-credito';
}

/// Catálogo completo. Orden importa para la UI (agrupar por category).
const List<GranularPermission> kGranularPermissionsCatalog = [
  // Caja
  GranularPermission(
    id: GranularPermissionId.cajaAbrir,
    label: 'Abrir caja',
    description: 'Permite abrir la caja del turno aunque no sea CAJERO/ADMIN.',
    category: 'Caja',
  ),
  GranularPermission(
    id: GranularPermissionId.cajaCerrar,
    label: 'Cerrar caja',
    description: 'Permite cerrar caja con conteo físico.',
    category: 'Caja',
  ),
  GranularPermission(
    id: GranularPermissionId.cajaMovimientoAnular,
    label: 'Anular movimiento de caja',
    description: 'Anular un ingreso/egreso registrado en caja.',
    category: 'Caja',
  ),

  // Venta
  GranularPermission(
    id: GranularPermissionId.ventaDescuentoLibre,
    label: 'Aplicar descuento libre',
    description: 'Descuentos sin solicitar autorización superior.',
    category: 'Venta',
  ),
  GranularPermission(
    id: GranularPermissionId.ventaAnular,
    label: 'Anular venta',
    description: 'Anular ventas ya registradas.',
    category: 'Venta',
  ),
  GranularPermission(
    id: GranularPermissionId.ventaEditarPrecio,
    label: 'Editar precio en venta',
    description: 'Modificar el precio del producto al cobrar.',
    category: 'Venta',
  ),

  // Cotización
  GranularPermission(
    id: GranularPermissionId.cotizacionAprobarGrande,
    label: 'Aprobar cotización grande',
    description: 'Aprobar cotizaciones que excedan el límite estándar.',
    category: 'Cotización',
  ),

  // Producto
  GranularPermission(
    id: GranularPermissionId.productoVerCosto,
    label: 'Ver costo de productos',
    description: 'Ver el campo costo en producto y reportes.',
    category: 'Producto',
  ),
  GranularPermission(
    id: GranularPermissionId.productoEditarCosto,
    label: 'Editar costo de productos',
    description: 'Modificar el costo registrado del producto.',
    category: 'Producto',
  ),

  // Devolución
  GranularPermission(
    id: GranularPermissionId.devolucionCrear,
    label: 'Crear devolución',
    description: 'Registrar devolución de venta.',
    category: 'Devolución',
  ),

  // Cliente
  GranularPermission(
    id: GranularPermissionId.clienteVerCredito,
    label: 'Ver crédito de clientes',
    description: 'Ver línea de crédito y deuda actual.',
    category: 'Cliente',
  ),
];

/// Agrupa el catálogo por categoría preservando orden de declaración.
Map<String, List<GranularPermission>> groupedGranularPermissions() {
  final map = <String, List<GranularPermission>>{};
  for (final p in kGranularPermissionsCatalog) {
    map.putIfAbsent(p.category, () => []).add(p);
  }
  return map;
}
