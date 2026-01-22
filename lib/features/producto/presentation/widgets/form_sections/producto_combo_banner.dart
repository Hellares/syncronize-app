import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import '../../../../../core/theme/gradient_container.dart';

/// Banner informativo para productos combo
/// Muestra información sobre gestión de componentes del combo
class ProductoComboBanner extends StatelessWidget {
  final bool isEditing;
  final String? tipoPrecioCombo;

  const ProductoComboBanner({
    super.key,
    required this.isEditing,
    this.tipoPrecioCombo,
  });

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      shadowStyle: ShadowStyle.colorful,
      borderColor: Colors.blue,
      gradient: LinearGradient(colors: [Colors.blue.shade50, Colors.blue.shade50]),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          _buildInfoCard(),
          if (isEditing) ...[
            const SizedBox(height: 16),
            _buildManageButton(context),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.category, color: Colors.blue.shade700, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Producto Combo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isEditing
                    ? 'El precio y stock se calculan automáticamente según los productos componentes del combo.'
                    : 'Una vez creado el combo, podrás agregar los productos que lo componen. El precio y stock se calcularán automáticamente.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
              const SizedBox(width: 8),
              Text(
                'Tipo de precio: ${tipoPrecioCombo ?? "No definido"}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getPrecioDescription(),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '• El stock disponible depende del stock de cada componente',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  String _getPrecioDescription() {
    switch (tipoPrecioCombo) {
      case 'FIJO':
        return '• El precio es fijo y definido manualmente';
      case 'CALCULADO':
        return '• El precio es la suma de todos los productos componentes';
      case 'CALCULADO_CON_DESCUENTO':
        return '• El precio es la suma de componentes con descuento aplicado';
      default:
        return '• Selecciona un tipo de precio arriba';
    }
  }

  Widget _buildManageButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          // TODO: Navegar a página de gestión de componentes del combo
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Función de gestión de combos próximamente'),
              backgroundColor: Colors.blue,
            ),
          );
        },
        icon: const Icon(Icons.category, size: 20),
        label: const Text('Gestionar Componentes del Combo'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
