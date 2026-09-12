import 'package:flutter/material.dart';
import '../../../../core/utils/fecha_calendario.dart';
import '../../domain/entities/lote.dart';

class LoteListTile extends StatelessWidget {
  final Lote lote;
  final VoidCallback? onTap;

  const LoteListTile({
    super.key,
    required this.lote,
    this.onTap,
  });

  Color _estadoColor() {
    switch (lote.estado) {
      case EstadoLote.ACTIVO:
        return Colors.green;
      case EstadoLote.AGOTADO:
        return Colors.grey;
      case EstadoLote.VENCIDO:
        return Colors.red;
      case EstadoLote.BLOQUEADO:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _estadoColor().withValues(alpha: 0.15),
          child: Icon(
            Icons.inventory_2_outlined,
            color: _estadoColor(),
            size: 20,
          ),
        ),
        title: Text(
          lote.nombreProducto.isNotEmpty ? lote.nombreProducto : lote.codigo,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${lote.codigo}${lote.numeroLote != null ? ' · Lote: ${lote.numeroLote}' : ''}',
              style: const TextStyle(fontSize: 12),
            ),
            Row(
              children: [
                Text(
                  'Stock: ${lote.cantidadActual}/${lote.cantidadInicial}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 8),
                Text(
                  '${lote.moneda} ${lote.precioCosto.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            // El día del envase por sus campos UTC (nunca a hora local: en
            // Lima daría el día anterior), y el estado por DÍA de calendario.
            if (lote.fechaVencimiento != null)
              Text(
                lote.estaVencido
                    ? 'VENCIDO el ${formatearDiaEnvase(lote.fechaVencimiento, anioCompleto: true)}'
                    : lote.diasParaVencer == 0
                        ? 'Vence HOY'
                        : 'Vence: ${formatearDiaEnvase(lote.fechaVencimiento, anioCompleto: true)}'
                            '${lote.proximoAVencer ? ' · ${lote.diasParaVencer} días' : ''}',
                style: TextStyle(
                  fontSize: 11,
                  color: lote.estaVencido
                      ? Colors.red
                      : lote.proximoAVencer
                          ? Colors.orange.shade800
                          : Colors.grey,
                  fontWeight: lote.proximoAVencer ? FontWeight.bold : FontWeight.normal,
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _estadoColor().withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                lote.estadoTexto,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _estadoColor(),
                ),
              ),
            ),
            if (lote.proximoAVencer && lote.esActivo) ...[
              const SizedBox(height: 4),
              const Icon(Icons.warning_amber, size: 16, color: Colors.orange),
            ],
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
