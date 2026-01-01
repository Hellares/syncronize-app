import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import '../../domain/entities/empresa_context.dart';

class RolesPermisosSection extends StatelessWidget {
  final EmpresaContext empresaContext;

  const RolesPermisosSection({
    super.key,
    required this.empresaContext,
  });

  @override
  Widget build(BuildContext context) {
    final roles = empresaContext.userRoles;
    final permissions = empresaContext.permissions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // const Text(
        //   'Tus Roles y Permisos',
        //   style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        // ),
        AppSubtitle('Tus Roles y Permisos', fontSize: 14),
        const SizedBox(height: 3),
        GradientContainer(
          borderColor: AppColors.blueborder,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Roles
                const Text(
                  'Roles asignados:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: roles.map((role) {
                    return Chip(
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(color: AppColors.white),
                      avatar: const Icon(Icons.badge, size: 16),
                      label: Text(_formatRole(role.rol), style: const TextStyle(fontSize: 10)),
                      backgroundColor: role.isActive
                          ? Colors.blue.shade100
                          : Colors.grey.shade200,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 5),
                const Divider(),
                const SizedBox(height: 12),
                // Permisos
                const Text(
                  'Permisos activos:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (permissions.canManageUsers)
                      _buildPermissionChip('Gestionar Usuarios', Icons.people),
                    if (permissions.canManageProducts)
                      _buildPermissionChip('Gestionar Productos', Icons.inventory),
                    if (permissions.canManageServices)
                      _buildPermissionChip('Gestionar Servicios', Icons.room_service),
                    if (permissions.canManageSedes)
                      _buildPermissionChip('Gestionar Sedes', Icons.store),
                    if (permissions.canManageOrders)
                      _buildPermissionChip('Gestionar Órdenes', Icons.assignment),
                    if (permissions.canManageInvoices)
                      _buildPermissionChip('Gestionar Comprobantes', Icons.receipt),
                    if (permissions.canViewReports)
                      _buildPermissionChip('Ver Reportes', Icons.analytics),
                    if (permissions.canViewStatistics)
                      _buildPermissionChip('Ver Estadísticas', Icons.bar_chart),
                    if (permissions.canManageSettings)
                      _buildPermissionChip('Configuración', Icons.settings),
                    if (permissions.canManagePaymentMethods)
                      _buildPermissionChip('Métodos de Pago', Icons.payment),
                    if (permissions.canChangePlan)
                      _buildPermissionChip('Cambiar Plan', Icons.upgrade),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionChip(String label, IconData icon) {
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(icon, size: 16, color: Colors.green.shade700),
      label: Text(label, style: const TextStyle(fontSize: 10)),
      backgroundColor: Colors.green.shade50,
      side: BorderSide(color: Colors.green.shade200),
    );
  }

  String _formatRole(String role) {
    final roleMap = {
      'SUPER_ADMIN': 'Super Admin',
      'EMPRESA_ADMIN': 'Administrador',
      'SEDE_ADMIN': 'Admin de Sede',
      'CAJERO': 'Cajero',
      'VENDEDOR': 'Vendedor',
      'TECNICO': 'Técnico',
      'CONTADOR': 'Contador',
      'LECTURA': 'Solo Lectura',
    };
    return roleMap[role] ?? role;
  }
}
