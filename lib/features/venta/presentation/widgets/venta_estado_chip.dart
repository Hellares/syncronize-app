import 'package:flutter/material.dart';
import '../../domain/entities/venta.dart';

class VentaEstadoChip extends StatelessWidget {
  final EstadoVenta estado;

  /// Marca la venta como financiada dentro del mismo chip
  /// ("Confirmada · CRÉDITO"). En el listado el estado solo no alcanza: una
  /// CONFIRMADA al contado y una a crédito se ven igual. El detalle ya tiene
  /// su propia sección de cuotas, así que ahí no hace falta.
  final bool esCredito;

  const VentaEstadoChip({
    super.key,
    required this.estado,
    this.esCredito = false,
  });

  @override
  Widget build(BuildContext context) {
    final (color, bgColor) = _getColors();
    final base = TextStyle(
      color: color,
      fontSize: 10,
      fontWeight: FontWeight.w600,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: estado.label, style: base,),
            if (esCredito)
              // Más chico que el estado: informa sin robarle protagonismo
              // ni ensanchar de más la fila de la card.
              TextSpan(
                text: ' · CREDITO',
                style: base.copyWith(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
          ],
        ),
      ),
    );
  }

  (Color, Color) _getColors() {
    switch (estado) {
      case EstadoVenta.borrador:
        return (Colors.grey.shade700, Colors.grey.shade200);
      case EstadoVenta.confirmada:
        return (Colors.blue.shade700, Colors.blue.shade50);
      case EstadoVenta.pagadaParcial:
        return (Colors.orange.shade700, Colors.orange.shade50);
      case EstadoVenta.pagadaCompleta:
        return (Colors.green.shade700, Colors.green.shade50);
      case EstadoVenta.anulada:
        return (Colors.red.shade700, Colors.red.shade50);
    }
  }
}
