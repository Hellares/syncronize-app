import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/aviso_mantenimiento.dart';

class AvisoCardWidget extends StatelessWidget {
  final AvisoMantenimiento aviso;
  final VoidCallback? onMarcarAtendido;
  final VoidCallback? onDescartar;
  final VoidCallback? onTap;

  const AvisoCardWidget({
    super.key,
    required this.aviso,
    this.onMarcarAtendido,
    this.onDescartar,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final diasRestantes = aviso.diasRestantes;
    final isVencido = diasRestantes < 0;
    final isProximo = diasRestantes >= 0 && diasRestantes <= 7;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: GradientContainer(
          borderColor: isVencido
              ? Colors.red.shade300
              : isProximo
                  ? Colors.orange.shade300
                  : AppColors.blueborder,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Cliente + Estado
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        aviso.cliente?.nombreCompleto ?? 'Cliente',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildEstadoBadge(),
                  ],
                ),
                const SizedBox(height: 8),

                // Equipo
                if (aviso.equipoDescripcion != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(Icons.devices_outlined,
                            size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            aviso.equipoDescripcion!,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Tipo de servicio + Orden
                Row(
                  children: [
                    Icon(Icons.build_outlined,
                        size: 13, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Text(
                      _tipoLabel(aviso.tipoServicio),
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600),
                    ),
                    if (aviso.ordenServicio != null) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.receipt_outlined,
                          size: 13, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        aviso.ordenServicio!.codigo,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),

                // Fechas
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isVencido
                        ? Colors.red.shade50
                        : isProximo
                            ? Colors.orange.shade50
                            : AppColors.bluechip,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: isVencido
                            ? Colors.red.shade700
                            : isProximo
                                ? Colors.orange.shade700
                                : AppColors.blue1,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Próximo mantenimiento: ${DateFormatter.formatDate(aviso.fechaRecomendada)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isVencido
                                    ? Colors.red.shade700
                                    : isProximo
                                        ? Colors.orange.shade700
                                        : AppColors.blue1,
                              ),
                            ),
                            Text(
                              isVencido
                                  ? 'Vencido hace ${-diasRestantes} día(s)'
                                  : diasRestantes == 0
                                      ? 'Hoy'
                                      : 'En $diasRestantes día(s)',
                              style: TextStyle(
                                fontSize: 10,
                                color: isVencido
                                    ? Colors.red.shade600
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Acciones rápidas
                if (aviso.esActivo) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (onDescartar != null)
                        _buildActionButton(
                          'Descartar',
                          Icons.close,
                          Colors.grey.shade500,
                          onDescartar!,
                        ),
                      const SizedBox(width: 8),
                      if (onMarcarAtendido != null)
                        _buildActionButton(
                          'Atendido',
                          Icons.check_circle_outline,
                          Colors.green.shade700,
                          onMarcarAtendido!,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoBadge() {
    Color color;
    String label;

    switch (aviso.estado) {
      case 'PENDIENTE':
        color = Colors.orange;
        label = 'Pendiente';
        break;
      case 'NOTIFICADO':
        color = AppColors.blue1;
        label = 'Notificado';
        break;
      case 'ATENDIDO':
        color = Colors.green;
        label = 'Atendido';
        break;
      case 'DESCARTADO':
        color = Colors.grey;
        label = 'Descartado';
        break;
      default:
        color = Colors.grey;
        label = aviso.estado;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  String _tipoLabel(String tipo) {
    const labels = {
      'REPARACION': 'Reparación',
      'MANTENIMIENTO': 'Mantenimiento',
      'INSTALACION': 'Instalación',
      'DIAGNOSTICO': 'Diagnóstico',
      'ACTUALIZACION': 'Actualización',
      'LIMPIEZA': 'Limpieza',
    };
    return labels[tipo] ?? tipo;
  }
}
