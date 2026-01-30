import 'package:flutter/material.dart';
import '../../domain/entities/categoria_maestra.dart';

/// Card para mostrar una categoría maestra disponible
class CategoriaMaestraCard extends StatelessWidget {
  final CategoriaMaestra maestra;
  final VoidCallback onActivar;
  final bool isActivada;

  const CategoriaMaestraCard({
    super.key,
    required this.maestra,
    required this.onActivar,
    this.isActivada = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isActivada ? 0 : 2,
      color: isActivada ? Colors.grey.shade100 : null,
      child: ListTile(
        enabled: !isActivada,
        leading: _buildIcon(),
        title: Row(
          children: [
            Expanded(
              child: Text(
                maestra.nombre,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isActivada ? Colors.grey : null,
                ),
              ),
            ),
            if (isActivada)
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (maestra.descripcion != null)
              Text(
                maestra.descripcion!,
                style: TextStyle(
                  color: isActivada ? Colors.grey : null,
                ),
              ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (maestra.esPopular)
                  _buildChip('Popular', Colors.amber),
                if (maestra.nivel > 0)
                  _buildChip('Nivel ${maestra.nivel}', Colors.blue),
              ],
            ),
          ],
        ),
        trailing: isActivada
            ? const Icon(Icons.check, color: Colors.green)
            : ElevatedButton.icon(
                onPressed: onActivar,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Activar'),
                style: ElevatedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
        isThreeLine: maestra.descripcion != null,
      ),
    );
  }

  Widget _buildIcon() {
    final iconData = maestra.icono != null
        ? _getIconData(maestra.icono!)
        : Icons.category_outlined;

    final color = isActivada ? Colors.grey : Colors.blue;

    return Icon(iconData, color: color, size: 32);
  }

  Widget _buildChip(String label, Color color) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 11),
      ),
      backgroundColor: color.withValues(alpha:0.2),
      labelStyle: TextStyle(color: color),
      visualDensity: VisualDensity.compact,
    );
  }

  IconData _getIconData(String iconName) {
    final iconMap = <String, IconData>{
      'devices': Icons.devices,
      'phone_android': Icons.phone_android,
      'computer': Icons.computer,
      'tv': Icons.tv,
      'camera': Icons.camera,
      'headphones': Icons.headphones,
      'watch': Icons.watch,
      'print': Icons.print,
      'router': Icons.router,
      'keyboard': Icons.keyboard,
      'restaurant': Icons.restaurant,
      'local_cafe': Icons.local_cafe,
      'store': Icons.store,
      'shopping_cart': Icons.shopping_cart,
      'category': Icons.category_outlined,
    };

    return iconMap[iconName] ?? Icons.category_outlined;
  }
}
