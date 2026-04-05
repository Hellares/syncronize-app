import 'package:flutter/material.dart';
import '../../domain/entities/resultado_compatibilidad.dart';

/// Widget indicador de compatibilidad entre productos
/// Muestra un chip verde "Compatible" o rojo "X conflictos" con detalle expandible
class CompatibilidadIndicator extends StatelessWidget {
  final ResultadoCompatibilidad resultado;

  const CompatibilidadIndicator({
    super.key,
    required this.resultado,
  });

  @override
  Widget build(BuildContext context) {
    if (resultado.compatible) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 16, color: Colors.green),
            SizedBox(width: 6),
            Text(
              'Compatible',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error, size: 16, color: Colors.red),
              const SizedBox(width: 6),
              Text(
                '${resultado.conflictos.length} conflicto${resultado.conflictos.length > 1 ? 's' : ''}',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...resultado.conflictos.map((conflicto) => _buildConflictoTile(conflicto)),
      ],
    );
  }

  Widget _buildConflictoTile(ConflictoCompatibilidad conflicto) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber, size: 14, color: Colors.red),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  conflicto.reglaNombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            conflicto.mensaje,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _buildValueChip(conflicto.productoOrigenNombre,
                  conflicto.valorOrigen, Colors.orange),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.close, size: 12, color: Colors.red),
              ),
              _buildValueChip(conflicto.productoDestinoNombre,
                  conflicto.valorDestino, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValueChip(String nombre, String valor, Color color) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '$nombre: $valor',
          style: TextStyle(fontSize: 11, color: color),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
