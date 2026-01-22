import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import '../../../../../core/theme/gradient_container.dart';

/// Banner informativo para productos con variantes
/// Muestra información sobre gestión de variantes
class ProductoVariantesBanner extends StatelessWidget {
  final bool isEditing;
  final String? productoId;
  final String nombreProducto;
  final String? categoriaId;
  final bool productoIsActive;

  const ProductoVariantesBanner({
    super.key,
    required this.isEditing,
    this.productoId,
    required this.nombreProducto,
    this.categoriaId,
    required this.productoIsActive,
  });

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      shadowStyle: ShadowStyle.colorful,
      borderColor: Colors.amber,
      gradient: LinearGradient(colors: [Colors.amber.shade50, Colors.amber.shade50]),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.amber.shade700, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Producto con Variantes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEditing
                          ? 'Los precios y stock se gestionan en cada variante individual.'
                          : 'Una vez creado el producto, podrás agregar variantes con sus precios y stock individuales.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isEditing && productoId != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final nombre = nombreProducto.isNotEmpty ? nombreProducto : 'Producto';
                  final categoriaIdParam = categoriaId != null
                      ? '&categoriaId=${Uri.encodeComponent(categoriaId!)}'
                      : '';
                  context.push(
                    '/empresa/productos/$productoId/variantes?nombre=${Uri.encodeComponent(nombre)}&isActive=$productoIsActive$categoriaIdParam',
                  );
                },
                icon: const Icon(Icons.settings, size: 20),
                label: const Text('Gestionar Variantes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
