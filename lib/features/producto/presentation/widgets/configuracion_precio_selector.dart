import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/widgets/custom_dropdown.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../domain/entities/configuracion_precio.dart';

/// Selector de configuración de precios para el formulario de producto
class ConfiguracionPrecioSelector extends StatelessWidget {
  final List<ConfiguracionPrecio> configuraciones;
  final String? configuracionSeleccionadaId;
  final Function(String?) onChanged;
  final VoidCallback? onManageConfigurations;

  const ConfiguracionPrecioSelector({
    super.key,
    required this.configuraciones,
    required this.configuracionSeleccionadaId,
    required this.onChanged,
    this.onManageConfigurations,
  });

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      shadowStyle: ShadowStyle.neumorphic,
      borderColor: AppColors.blueborder,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Row(
              children: [
                const Icon(Icons.auto_graph, size: 16, color: AppColors.blue1),
                const SizedBox(width: 8),
                const Expanded(
                  child: AppSubtitle(
                    'Configuración de Precios por Volumen',
                    fontSize: 11
                  ),
                ),
                if (onManageConfigurations != null)
                  TextButton.icon(
                    onPressed: onManageConfigurations,
                    icon: const Icon(Icons.settings, size: 16),
                    label: AppSubtitle(
                      'Gestionar',
                      fontSize: 10,
                      color: AppColors.blue1,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            AppSubtitle(
              'Selecciona una configuración predefinida de precios escalonados',
              fontSize: 10,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),

            if (configuraciones.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'No hay configuraciones disponibles',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Crea configuraciones de precios reutilizables en la sección de gestión',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              CustomDropdown<String>(
                value: configuracionSeleccionadaId,
                label: 'Configuración de precios',
                hintText: 'Selecciona una configuración (opcional)',
                borderColor: AppColors.blue1,
                items: [
                  const DropdownItem(
                    value: '',
                    label: 'Sin configuración',
                  ),
                  ...configuraciones.map((config) {
                    return DropdownItem(
                      value: config.id,
                      label: config.nombre,
                    );
                  }),
                ],
                onChanged: (value) => onChanged(value?.isEmpty ?? true ? null : value),
              ),

            if (configuracionSeleccionadaId != null)
              ..._buildConfigurationPreview(context),
        ],
      ),
    );
  }

  List<Widget> _buildConfigurationPreview(BuildContext context) {
    // Buscar la configuración seleccionada
    ConfiguracionPrecio? config;
    try {
      config = configuraciones.firstWhere(
        (c) => c.id == configuracionSeleccionadaId,
      );
    } catch (e) {
      // Si no se encuentra, usar la primera
      config = configuraciones.isNotEmpty ? configuraciones.first : null;
    }

    // Si no hay configuración, no mostrar preview
    if (config == null) return [];

    return [
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.visibility_outlined, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                AppSubtitle(
                  'Vista previa: ${config.nombre}',
                  fontSize: 11,
                  color: Colors.blue,
                ),
              ],
            ),
            if (config.descripcion != null) ...[
              const SizedBox(height: 6),
              Text(
                config.descripcion!,
                style: TextStyle(fontSize: 10, color: Colors.grey[700]),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            ...config.niveles.map((nivel) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            '${nivel.orden + 1}',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppSubtitle(
                          '${nivel.nombre} • ${nivel.rangoString} unid. • ${nivel.getDescripcionPrecio(null)}',
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    ];
  }
}
