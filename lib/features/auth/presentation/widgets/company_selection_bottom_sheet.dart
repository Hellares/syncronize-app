import 'package:flutter/material.dart';
import '../../domain/entities/available_company.dart';

/// Bottom Sheet para selección de empresa
/// Muestra una lista de empresas disponibles y permite al usuario seleccionar una
class CompanySelectionBottomSheet extends StatelessWidget {
  final List<AvailableCompany> companies;
  final Function(String subdominio) onCompanySelected;
  final bool isLoading;

  const CompanySelectionBottomSheet({
    super.key,
    required this.companies,
    required this.onCompanySelected,
    this.isLoading = false,
  });

  /// Método estático para mostrar el Bottom Sheet
  static Future<void> show({
    required BuildContext context,
    required List<AvailableCompany> companies,
    required Function(String subdominio) onCompanySelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CompanySelectionBottomSheet(
        companies: companies,
        onCompanySelected: onCompanySelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicador de drag
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Icon(
                  Icons.business_center_rounded,
                  size: 48,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                Text(
                  'Selecciona tu Empresa',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tienes acceso a ${companies.length} empresa${companies.length > 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Lista de empresas
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: companies.length,
              itemBuilder: (context, index) {
                final company = companies[index];
                return _CompanyTile(
                  company: company,
                  onTap: isLoading
                      ? null
                      : () => onCompanySelected(company.subdominio),
                );
              },
            ),
          ),

          // Espacio inferior para safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

/// Widget para mostrar cada empresa en la lista
class _CompanyTile extends StatelessWidget {
  final AvailableCompany company;
  final VoidCallback? onTap;

  const _CompanyTile({
    required this.company,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            // Logo de la empresa
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.shade100,
                  width: 1,
                ),
              ),
              child: company.logo != null && company.logo!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        company.logo!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildDefaultLogo();
                        },
                      ),
                    )
                  : _buildDefaultLogo(),
            ),

            const SizedBox(width: 16),

            // Información de la empresa
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    company.nombre,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (company.roles.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: company.roles.map((rol) {
                        return _RolChip(rol: rol);
                      }).toList(),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Icono de flecha
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultLogo() {
    return Center(
      child: Icon(
        Icons.business,
        size: 28,
        color: Colors.blue.shade300,
      ),
    );
  }
}

/// Chip para mostrar los roles del usuario en la empresa
class _RolChip extends StatelessWidget {
  final String rol;

  const _RolChip({required this.rol});

  @override
  Widget build(BuildContext context) {
    Color chipColor = _getChipColor(rol);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: chipColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        rol,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: chipColor,
        ),
      ),
    );
  }

  Color _getChipColor(String rol) {
    switch (rol.toUpperCase()) {
      case 'ADMIN':
      case 'ADMINISTRADOR':
        return Colors.red;
      case 'GERENTE':
      case 'MANAGER':
        return Colors.orange;
      case 'EMPLEADO':
      case 'EMPLOYEE':
        return Colors.green;
      case 'CLIENTE':
      case 'CLIENT':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
