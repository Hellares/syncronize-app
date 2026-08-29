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

  static const ventaDescuentoLibre = 'venta.descuento-libre';
  static const ventaEditarPrecio = 'venta.editar-precio';

  static const productoEditarCosto = 'producto.editar-costo';

  static const devolucionCrear = 'devolucion.crear';
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

  // Venta
  GranularPermission(
    id: GranularPermissionId.ventaDescuentoLibre,
    label: 'Aplicar descuento libre',
    description: 'Descuentos sin solicitar autorización superior.',
    category: 'Venta',
  ),
  GranularPermission(
    id: GranularPermissionId.ventaEditarPrecio,
    label: 'Editar precio en venta',
    description: 'Modificar el precio del producto al cobrar.',
    category: 'Venta',
  ),

  // Producto
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
    description:
        'Registrar devoluciones sin ser administrador (por defecto solo '
        'los admin pueden).',
    category: 'Devolución',
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
