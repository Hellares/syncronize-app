import 'package:flutter/material.dart';
import '../../domain/entities/mode_option.dart';

/// Bottom Sheet para selección de modo de login
/// Muestra opciones de Marketplace o Management
class ModeSelectionBottomSheet extends StatelessWidget {
  final List<ModeOption> modeOptions;
  final Function(String modeType, String? subdominioEmpresa) onModeSelected;
  final bool isLoading;

  const ModeSelectionBottomSheet({
    super.key,
    required this.modeOptions,
    required this.onModeSelected,
    this.isLoading = false,
  });

  /// Método estático para mostrar el Bottom Sheet
  static Future<void> show({
    required BuildContext context,
    required List<ModeOption> modeOptions,
    required Function(String modeType, String? subdominioEmpresa) onModeSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => ModeSelectionBottomSheet(
        modeOptions: modeOptions,
        onModeSelected: onModeSelected,
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
                  Icons.apps_rounded,
                  size: 48,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                Text(
                  '¿Qué deseas hacer?',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Selecciona cómo quieres continuar',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Lista de opciones de modo
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: modeOptions.length,
              itemBuilder: (context, index) {
                final option = modeOptions[index];
                return _ModeOptionTile(
                  option: option,
                  isLoading: isLoading,
                  onModeSelected: onModeSelected,
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

/// Widget para mostrar cada opción de modo
class _ModeOptionTile extends StatelessWidget {
  final ModeOption option;
  final bool isLoading;
  final Function(String modeType, String? subdominioEmpresa) onModeSelected;

  const _ModeOptionTile({
    required this.option,
    required this.isLoading,
    required this.onModeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasCompanies = option.availableCompanies != null &&
                              option.availableCompanies!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: InkWell(
        onTap: isLoading ? null : () => _handleModeSelection(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _getModeColor(option.type).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getModeColor(option.type).withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icono
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _getModeColor(option.type).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getModeIcon(option.type),
                      size: 28,
                      color: _getModeColor(option.type),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Título y descripción
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.label,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _getModeColor(option.type),
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          option.description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey.shade700,
                              ),
                        ),
                      ],
                    ),
                  ),

                  // Icono de flecha
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 20,
                    color: _getModeColor(option.type),
                  ),
                ],
              ),

              // Mostrar empresas disponibles si es modo management
              if (hasCompanies) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Empresas disponibles: ${option.availableCompanies!.length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: option.availableCompanies!.take(3).map((company) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.business,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            company.nombre,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                if (option.availableCompanies!.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '+ ${option.availableCompanies!.length - 3} más',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleModeSelection(BuildContext context) {
    // Si es modo marketplace, enviar directamente
    if (option.isMarketplace) {
      onModeSelected(option.type, null);
      return;
    }

    // Si es modo management y tiene empresas, mostrar selector
    if (option.isManagement && option.availableCompanies != null) {
      if (option.availableCompanies!.length == 1) {
        // Si solo tiene una empresa, seleccionarla automáticamente
        onModeSelected(option.type, option.availableCompanies!.first.subdominio);
      } else {
        // Mostrar selector de empresas
        _showCompanySelector(context);
      }
    } else {
      // Si no hay empresas disponibles, enviar sin subdominio
      onModeSelected(option.type, null);
    }
  }

  void _showCompanySelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                ],
              ),
            ),

            const Divider(height: 1),

            // Lista de empresas
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: option.availableCompanies!.length,
                itemBuilder: (context, index) {
                  final company = option.availableCompanies![index];
                  return ListTile(
                    leading: const Icon(Icons.business),
                    title: Text(company.nombre),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pop(context);
                      onModeSelected(option.type, company.subdominio);
                    },
                  );
                },
              ),
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Color _getModeColor(String type) {
    switch (type) {
      case 'marketplace':
        return Colors.blue;
      case 'management':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getModeIcon(String type) {
    switch (type) {
      case 'marketplace':
        return Icons.storefront_rounded;
      case 'management':
        return Icons.business_center_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}
