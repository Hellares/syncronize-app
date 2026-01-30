import 'package:flutter/material.dart';
import '../../domain/entities/empresa_marca.dart';

/// Card para mostrar una marca activa de la empresa
class MarcaCard extends StatelessWidget {
  final EmpresaMarca marca;
  final VoidCallback onDesactivar;

  const MarcaCard({
    super.key,
    required this.marca,
    required this.onDesactivar,
  });

  @override
  Widget build(BuildContext context) {
    final isPersonalizada = marca.marcaMaestraId == null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: _buildIcon(),
        title: Text(
          marca.nombreDisplay,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (marca.descripcionDisplay != null)
              Text(marca.descripcionDisplay!),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (isPersonalizada)
                  _buildChip('Personalizada', Colors.purple),
                if (marca.orden != null)
                  _buildChip('Orden: ${marca.orden}', Colors.blue),
                if (marca.marcaMaestra?.esPopular ?? false)
                  _buildChip('Popular', Colors.amber),
                if (!marca.isVisible)
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
    final color = marca.marcaMaestraId == null
        ? Colors.purple // Personalizada
        : Colors.blue; // Maestra

    return Icon(Icons.label, color: color, size: 32);
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
}
