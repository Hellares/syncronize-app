import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/info_chip.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/transferencia_stock.dart';

class TransferenciaCard extends StatelessWidget {
  final TransferenciaStock transferencia;
  final VoidCallback? onTap;

  const TransferenciaCard({
    super.key,
    required this.transferencia,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      margin: const EdgeInsets.only(bottom: 12),
      gradient: AppGradients.blueWhiteBlue(),
      borderColor: AppColors.blueborder,
      shadowStyle: ShadowStyle.glow,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado con código y estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transferencia.codigo,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.blue1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          transferencia.nombresProductos,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildEstadoBadge(transferencia.estado),
                ],
              ),

              // const SizedBox(height: 2),
              const Divider(),
              // const SizedBox(height: 8),

              // Información de sedes
              Row(
                children: [
                  Expanded(
                    child: _buildSedeInfo(
                      Icons.upload,
                      'Origen',
                      transferencia.sedeOrigen?.nombre ?? 'Sede origen',
                      Colors.orange,
                    ),
                  ),
                  Icon(Icons.arrow_forward, color: Colors.grey[400], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSedeInfo(
                      Icons.download,
                      'Destino',
                      transferencia.sedeDestino?.nombre ?? 'Sede destino',
                      Colors.green,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Cantidad y fecha
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${transferencia.cantidadTotal} unidades',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy').format(transferencia.creadoEn),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              // Motivo si existe
              if (transferencia.motivo != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        transferencia.motivo!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSedeInfo(
    IconData icon,
    String label,
    String sede,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          sede,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildEstadoBadge(EstadoTransferencia estado) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (estado) {
      case EstadoTransferencia.pendiente:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        icon = Icons.schedule;
        break;
      case EstadoTransferencia.aprobada:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        icon = Icons.check_circle_outline;
        break;
      case EstadoTransferencia.enTransito:
        backgroundColor = Colors.purple.shade100;
        textColor = Colors.purple.shade800;
        icon = Icons.local_shipping;
        break;
      case EstadoTransferencia.recibida:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        icon = Icons.done_all;
        break;
      case EstadoTransferencia.rechazada:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        icon = Icons.cancel;
        break;
      case EstadoTransferencia.cancelada:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
        icon = Icons.block;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
        icon = Icons.help_outline;
    }
    return InfoChip(icon: icon, text: estado.descripcion, backgroundColor: backgroundColor, textColor: textColor, fontWeight: FontWeight.bold,);
  }
}
