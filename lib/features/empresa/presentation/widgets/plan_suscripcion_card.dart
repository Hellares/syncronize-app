import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/widgets/info_chip.dart';
import 'package:syncronize/features/auth/presentation/widgets/widgets.dart';
import '../../../../core/widgets/animated_container.dart';
import '../../domain/entities/empresa_context.dart';

class PlanSuscripcionCard extends StatelessWidget {
  final EmpresaContext empresaContext;

  const PlanSuscripcionCard({
    super.key,
    required this.empresaContext,
  });

  @override
  Widget build(BuildContext context) {
    final empresa = empresaContext.empresa;
    final plan = empresa.planSuscripcion;

    return AnimatedNeonBorder(
      enableGlow: true,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium, color: AppColors.blue1, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan != null ? 'Plan ${plan.nombre}' : 'Sin Plan',
                      style: const TextStyle(
                        color: AppColors.blue1,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (plan != null)
                      Text(
                        '\$${plan.precio.toStringAsFixed(2)} / ${plan.periodo}',
                        style: const TextStyle(
                          color: AppColors.blue1,
                          fontSize: 9,
                        ),
                      ),
                  ],
                ),
              ),
              InfoChip(
                icon: Icons.check_circle_outline_rounded, 
                text: _formatEstadoSuscripcion(empresa.estadoSuscripcion,),
                backgroundColor: _getEstadoColor(empresa.estadoSuscripcion),
                textColor: AppColors.blue2,
              )
            ],
          ),
          const SizedBox(height: 5),
          const Divider(color: AppColors.greyLight),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPlanInfoItem(
                Icons.people,
                'Usuarios',
                '${empresa.usuariosActuales}',
              ),
              if (empresa.fechaVencimiento != null)
                _buildPlanInfoItem(
                  Icons.calendar_today,
                  'Vence',
                  _formatFechaVencimiento(empresa.fechaVencimiento!),
                ),
            ],
          ),
          if (empresaContext.permissions.canChangePlan) ...[
            const SizedBox(height: 16),
            CustomButton(
              // borderColor: AppColors.white,
              backgroundColor: AppColors.blue1,
              borderWidth: 1,
              height: 31,
              text:  'Cambiar Plan', 
              textColor: AppColors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cambio de plan - Por implementar'),
                  ),
                );
              }, 
              icon: Icon(Icons.upgrade, color: AppColors.white),
              // backgroundColor: AppColors.blue,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.blue1, size: 18),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.blue1,
                fontSize: 10,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.blue1,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatEstadoSuscripcion(String estado) {
    final estadoMap = {
      'ACTIVA': 'Activa',
      'SUSPENDIDA': 'Suspendida',
      'CANCELADA': 'Cancelada',
      'VENCIDA': 'Vencida',
    };
    return estadoMap[estado] ?? estado;
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'ACTIVA':
        return Colors.blue.withValues(alpha: 0.2);
      case 'SUSPENDIDA':
        return Colors.orange;
      case 'CANCELADA':
      case 'VENCIDA':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatFechaVencimiento(DateTime fecha) {
    final now = DateTime.now();
    final difference = fecha.difference(now).inDays;

    if (difference < 0) {
      return 'Vencida';
    } else if (difference == 0) {
      return 'Hoy';
    } else if (difference == 1) {
      return 'Mañana';
    } else if (difference <= 7) {
      return '$difference días';
    } else {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    }
  }
}


