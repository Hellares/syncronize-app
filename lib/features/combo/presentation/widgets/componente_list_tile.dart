import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/info_chip.dart';
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
    return GradientContainer(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          child: Icon(
            Icons.inventory_2,
            color: AppColors.blue1,
            size: 20,
          ),
        ),
        title: AppSubtitle(_getNombreComponente()),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            AppSubtitle('Cantidad: ${componente.cantidad}'),
            if (componente.esPersonalizable)
              InfoChip(text: 'Personalizable'),
            if (componente.categoriaComponente != null)
              Text(
                'Categoría: ${componente.categoriaComponente}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18,),
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
