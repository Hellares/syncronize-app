import 'package:flutter/material.dart';
import '../../domain/entities/empresa_categoria.dart';

/// Card para mostrar una categoría activa de la empresa
class CategoriaCard extends StatelessWidget {
  final EmpresaCategoria categoria;
  final VoidCallback onDesactivar;

  const CategoriaCard({
    super.key,
    required this.categoria,
    required this.onDesactivar,
  });

  @override
  Widget build(BuildContext context) {
    final isPersonalizada = categoria.categoriaMaestraId == null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: _buildIcon(),
        title: Text(
          categoria.nombreDisplay,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (categoria.descripcionDisplay != null)
              Text(categoria.descripcionDisplay!),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (isPersonalizada)
                  _buildChip('Personalizada', Colors.purple),
                if (categoria.orden != null)
                  _buildChip('Orden: ${categoria.orden}', Colors.blue),
                if (categoria.categoriaMaestra?.esPopular ?? false)
                  _buildChip('Popular', Colors.amber),
                if (!categoria.isVisible)
                  _buildChip('Oculta', Colors.grey),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'desactivar') {
              onDesactivar();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'desactivar',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Desactivar'),
                ],
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildIcon() {
    final iconData = categoria.categoriaMaestra?.icono != null
        ? _getIconData(categoria.categoriaMaestra!.icono!)
        : Icons.category;

    final color = categoria.categoriaMaestraId == null
        ? Colors.purple // Personalizada
        : Colors.blue; // Maestra

    return Icon(iconData, color: color, size: 32);
  }

  Widget _buildChip(String label, Color color) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 11),
      ),
      backgroundColor: color.withOpacity(0.2),
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
      'category': Icons.category,
    };

    return iconMap[iconName] ?? Icons.category;
  }
}
