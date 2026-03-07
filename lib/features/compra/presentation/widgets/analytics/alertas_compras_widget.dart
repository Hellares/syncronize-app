import 'package:flutter/material.dart';
import '../../../domain/entities/compra_analytics.dart';

class AlertasComprasWidget extends StatelessWidget {
  final List<AlertaCompra> alertas;

  const AlertasComprasWidget({super.key, required this.alertas});

  @override
  Widget build(BuildContext context) {
    if (alertas.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 20),
            SizedBox(width: 8),
            Text('Sin alertas pendientes', style: TextStyle(fontSize: 12, color: Colors.green)),
          ],
        ),
      );
    }

    return Column(
      children: alertas.take(10).map((alerta) {
        final config = _getAlertConfig(alerta.tipo);
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: config.bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: config.borderColor, width: 0.5),
          ),
          child: Row(
            children: [
              Icon(config.icon, color: config.iconColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alerta.mensaje,
                  style: const TextStyle(fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  _AlertConfig _getAlertConfig(String tipo) {
    switch (tipo) {
      case 'oc_pendiente':
        return _AlertConfig(
          icon: Icons.pending_actions,
          iconColor: Colors.orange.shade700,
          bgColor: Colors.orange.shade50,
          borderColor: Colors.orange.shade200,
        );
      case 'entrega_vencida':
        return _AlertConfig(
          icon: Icons.warning_amber,
          iconColor: Colors.red.shade700,
          bgColor: Colors.red.shade50,
          borderColor: Colors.red.shade200,
        );
      case 'lote_por_vencer':
        return _AlertConfig(
          icon: Icons.timer,
          iconColor: Colors.amber.shade700,
          bgColor: Colors.amber.shade50,
          borderColor: Colors.amber.shade200,
        );
      case 'sin_compras_recientes':
        return _AlertConfig(
          icon: Icons.info_outline,
          iconColor: Colors.blue.shade700,
          bgColor: Colors.blue.shade50,
          borderColor: Colors.blue.shade200,
        );
      default:
        return _AlertConfig(
          icon: Icons.notifications,
          iconColor: Colors.grey.shade700,
          bgColor: Colors.grey.shade50,
          borderColor: Colors.grey.shade200,
        );
    }
  }
}

class _AlertConfig {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color borderColor;

  const _AlertConfig({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.borderColor,
  });
}
