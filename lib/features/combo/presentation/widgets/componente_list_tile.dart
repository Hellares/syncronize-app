import 'package:flutter/material.dart';
import '../../domain/entities/componente_combo.dart';

class ComponenteListTile extends StatelessWidget {
  final ComponenteCombo componente;
  final VoidCallback onDelete;

  const ComponenteListTile({
    super.key,
    required this.componente,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          child: Icon(
            Icons.inventory_2,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          _getNombreComponente(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Cantidad: ${componente.cantidad}'),
            if (componente.esPersonalizable)
              Chip(
                label: const Text(
                  'Personalizable',
                  style: TextStyle(fontSize: 11),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            if (componente.categoriaComponente != null)
              Text(
                'Categoría: ${componente.categoriaComponente}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: onDelete,
        ),
      ),
    );
  }

  String _getNombreComponente() {
    if (componente.componenteInfo != null) {
      final info = componente.componenteInfo!;

      // Si es una variante, mostrar: "Producto - Variante"
      if (info.esVariante && info.varianteNombre != null && info.productoNombre != null) {
        return '${info.productoNombre} - ${info.varianteNombre}';
      }

      // Si no es variante o no tiene los nombres específicos, usar el nombre general
      return info.nombre;
    }
    return 'Componente';
  }
}
