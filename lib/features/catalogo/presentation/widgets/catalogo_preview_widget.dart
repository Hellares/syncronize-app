import 'package:flutter/material.dart';
import '../../domain/entities/catalogo_preview.dart';

/// Widget para mostrar el preview de catálogos que se activarán
class CatalogoPreviewWidget extends StatelessWidget {
  final CatalogoPreview preview;

  const CatalogoPreviewWidget({
    super.key,
    required this.preview,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.preview,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Catálogos que se activarán',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Se activarán automáticamente ${preview.total} catálogos para tu empresa',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),

            // Categorías
            if (preview.categorias.isNotEmpty) ...[
              _SectionHeader(
                icon: Icons.category,
                title: 'Categorías (${preview.categorias.length})',
                color: Colors.blue,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: preview.categorias.map((categoria) {
                  return Chip(
                    avatar: categoria.icono != null
                        ? Text(
                            categoria.icono!,
                            style: const TextStyle(fontSize: 16),
                          )
                        : const Icon(Icons.category, size: 16),
                    label: Text(categoria.nombre),
                    backgroundColor: Colors.blue.shade50,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Marcas
            if (preview.marcas.isNotEmpty) ...[
              _SectionHeader(
                icon: Icons.business,
                title: 'Marcas (${preview.marcas.length})',
                color: Colors.green,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: preview.marcas.map((marca) {
                  return Chip(
                    avatar: const Icon(Icons.business, size: 16),
                    label: Text(marca.nombre),
                    backgroundColor: Colors.green.shade50,
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.amber.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.amber[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Podrás agregar o quitar catálogos más tarde desde la configuración',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
        ),
      ],
    );
  }
}
