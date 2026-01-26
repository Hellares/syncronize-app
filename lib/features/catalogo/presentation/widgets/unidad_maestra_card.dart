import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/chip_simple.dart';
import '../../domain/entities/unidad_medida.dart';

/// Card para mostrar una unidad de medida maestra disponible
class UnidadMaestraCard extends StatelessWidget {
  final UnidadMedidaMaestra maestra;
  final VoidCallback onActivar;
  final bool isActivada;

  const UnidadMaestraCard({
    super.key,
    required this.maestra,
    required this.onActivar,
    this.isActivada = false,
  });

  @override
Widget build(BuildContext context) {
  return GradientContainer(
    borderColor: AppColors.blueborder,
    margin: const EdgeInsets.only(bottom: 12),
    gradient: isActivada ? AppGradients.gray() : null,
    child: ListTile(
      enabled: !isActivada,
      visualDensity: VisualDensity.compact, // ← hace todo más apretado y moderno
      contentPadding: const EdgeInsets.symmetric(horizontal: 16,),
      leading: _buildIcon(),
      title: Text( // ← quitamos el Row y el icono check_circle
        maestra.displayConCodigo,
        style: TextStyle(
          fontSize: 12, // ← subí un poco el tamaño para mejor jerarquía
          fontWeight: FontWeight.bold,
          color: isActivada ? Colors.grey : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (maestra.descripcion != null)
            Text(
              maestra.descripcion!,
              style: TextStyle(
                color: isActivada ? Colors.grey : null,
                fontSize: 10,
              ),
            ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildChip(maestra.categoria.label, Colors.blue),
              if (maestra.esPopular) _buildChip('Popular', Colors.amber),
            ],
          ),
        ],
      ),
      trailing: SizedBox( // ← tamaño fijo = alineación perfecta siempre
        width: 56,
        height: 56,
        child: isActivada
            ? const Icon(
                Icons.check_circle_outlined,
                color: Colors.green,
                size: 20,
              )
            : IconButton(
                onPressed: onActivar,
                icon: const Icon(
                  Icons.add_circle_outline,
                  size: 20,
                ),
                color: AppColors.blue1,
                tooltip: 'Activar',
              ),
      ),
      isThreeLine: maestra.descripcion != null,
    ),
  );
}

  Widget _buildIcon() {
    final color = isActivada ? Colors.grey : Colors.blue;

    IconData icon = Icons.straighten;
    switch (maestra.categoria) {
      case CategoriaUnidad.cantidad:
        icon = Icons.tag;
        break;
      case CategoriaUnidad.masa:
        icon = Icons.scale;
        break;
      case CategoriaUnidad.longitud:
        icon = Icons.straighten;
        break;
      case CategoriaUnidad.area:
        icon = Icons.crop_square;
        break;
      case CategoriaUnidad.volumen:
        icon = Icons.water_drop;
        break;
      case CategoriaUnidad.tiempo:
        icon = Icons.schedule;
        break;
      case CategoriaUnidad.servicio:
        icon = Icons.room_service;
        break;
    }

    return Icon(icon, color: color, size: 20);
  }

  Widget _buildChip(String label, Color color) {
    return ChipSimple(label: label, color: color, fontSize: 10,borderRadius: 4,);
  }
}
