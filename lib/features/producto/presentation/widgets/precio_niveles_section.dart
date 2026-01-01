import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import '../../domain/entities/precio_nivel.dart';
import '../../data/models/precio_nivel_model.dart';
import 'precio_nivel_form_dialog.dart';

/// Widget que muestra y gestiona los niveles de precio por volumen
class PrecioNivelesSection extends StatefulWidget {
  final List<PrecioNivel> niveles;
  final double? precioBase;
  final Function(PrecioNivelDto) onNivelCreated;
  final Function(String nivelId, PrecioNivelDto) onNivelUpdated;
  final Function(String nivelId) onNivelDeleted;

  const PrecioNivelesSection({
    super.key,
    required this.niveles,
    this.precioBase,
    required this.onNivelCreated,
    required this.onNivelUpdated,
    required this.onNivelDeleted,
  });

  @override
  State<PrecioNivelesSection> createState() => _PrecioNivelesSectionState();
}

class _PrecioNivelesSectionState extends State<PrecioNivelesSection> {
  void _showNivelDialog({PrecioNivel? nivelToEdit}) {
    showDialog(
      context: context,
      builder: (context) => PrecioNivelFormDialog(
        precioBase: widget.precioBase,
        nivelToEdit: nivelToEdit,
        nivelesExistentes: widget.niveles,
        onSave: (dto) {
          if (nivelToEdit != null) {
            widget.onNivelUpdated(nivelToEdit.id, dto);
          } else {
            widget.onNivelCreated(dto);
          }
        },
      ),
    );
  }

  void _confirmDelete(PrecioNivel nivel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar nivel de precio'),
        content: Text(
          '¿Estás seguro de eliminar el nivel "${nivel.nombre}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              widget.onNivelDeleted(nivel.id);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nivelesOrdenados = [...widget.niveles]
      ..sort((a, b) => a.cantidadMinima.compareTo(b.cantidadMinima));

    return GradientContainer(
      shadowStyle: ShadowStyle.neumorphic,
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_graph, size: 16, color: AppColors.blue1),
                const SizedBox(width: 8),
                AppSubtitle('Precios por Volumen', fontSize: 12),
                const Spacer(),
                if (widget.niveles.isNotEmpty)
                  // Text(
                  //   '${widget.niveles.length} niveles',
                  //   style: TextStyle(
                  //     fontSize: 10,
                  //     color: Colors.grey[600],
                  //   ),
                  // ),
                  Text(
                    '${widget.niveles.length} nivel${widget.niveles.length > 1 ? 'es' : ''}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            AppSubtitle(
              'Configura precios diferentes según la cantidad comprada',
              // fontSize: 10,
              color: Colors.grey[600],
            ),

            // Lista de niveles
            if (nivelesOrdenados.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Column(
                    children: [
                      Icon(
                        Icons.discount_outlined,
                        size: 35,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No hay niveles de precio configurados',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Agrega niveles para ofrecer descuentos por volumen',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: nivelesOrdenados.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final nivel = nivelesOrdenados[index];
                  return _buildNivelTile(nivel);
                },
              ),

            const SizedBox(height: 5),

            // Botón agregar
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showNivelDialog,
                icon: const Icon(Icons.add, size: 16),
                label: AppSubtitle('Agregar Nivel', fontSize: 10),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 32),
                  maximumSize: const Size(double.infinity, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNivelTile(PrecioNivel nivel) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: AppSubtitle(
            '${nivel.orden + 1}',
            fontSize: 12,
            color: theme.primaryColor,
          ),
        ),
      ),
      title: Row(
        children: [
          Text(
            nivel.nombre,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              nivel.rangoString,
              style: const TextStyle(
                fontSize: 9,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                nivel.tipoPrecio == TipoPrecioNivel.precioFijo
                    ? Icons.attach_money
                    : Icons.percent,
                size: 14,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                nivel.getDescripcionPrecio(widget.precioBase),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (nivel.descripcion != null) ...[
            const SizedBox(height: 2),
            Text(
              nivel.descripcion!,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 16),
            onPressed: () => _showNivelDialog(nivelToEdit: nivel),
            tooltip: 'Editar',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 16),
            onPressed: () => _confirmDelete(nivel),
            tooltip: 'Eliminar',
            color: Colors.red,
          ),
        ],
      ),
    );
  }
}
