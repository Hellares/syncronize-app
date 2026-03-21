import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/utils/date_formatter.dart';
import 'package:syncronize/core/widgets/info_chip.dart';
import 'package:syncronize/features/auth/presentation/widgets/widgets.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/animated_container.dart';
import '../../domain/entities/empresa_context.dart';

class PlanSuscripcionCard extends StatefulWidget {
  final EmpresaContext empresaContext;

  const PlanSuscripcionCard({
    super.key,
    required this.empresaContext,
  });

  @override
  State<PlanSuscripcionCard> createState() => _PlanSuscripcionCardState();
}

class _PlanSuscripcionCardState extends State<PlanSuscripcionCard> {
  double? _tcCompra;
  double? _tcVenta;
  bool _expandido = false;

  @override
  void initState() {
    super.initState();
    _loadTipoCambio();
  }

  Future<void> _loadTipoCambio() async {
    try {
      final dio = locator<DioClient>();
      final response = await dio.get('/consultas/tipo-cambio');
      final data = response.data as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _tcCompra = _toDouble(data['compra']);
          _tcVenta = _toDouble(data['venta']);
        });
      }
    } catch (_) {}
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final empresa = widget.empresaContext.empresa;
    final plan = empresa.planSuscripcion;

    return AnimatedNeonBorder(
      borderRadius: 8,
      enableGlow: true,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (siempre visible, tap para expandir/colapsar)
          GestureDetector(
            onTap: () => setState(() => _expandido = !_expandido),
            behavior: HitTestBehavior.opaque,
            child: Row(
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
                if (_tcCompra != null && _tcVenta != null) ...[
                  InfoChip(
                    borderRadius: 4,
                    borderColor: Colors.green.withValues(alpha: 0.3),
                    backgroundColor: Colors.green.withValues(alpha: 0.1),
                    textColor: Colors.green[800]!,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    text: 'USD C:${_tcCompra!.toStringAsFixed(3)} V:${_tcVenta!.toStringAsFixed(3)}',
                  ),
                  const SizedBox(width: 5),
                ],
                Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: InfoChip(
                    borderColor: AppColors.bluechip,
                    borderRadius: 4,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    text: _formatEstadoSuscripcion(empresa.estadoSuscripcion),
                    backgroundColor: _getEstadoColor(empresa.estadoSuscripcion),
                    textColor: AppColors.blue2,
                    icon: Icons.check_circle_outline_rounded,
                    iconSize: 12,
                  ),
                ),
                AnimatedRotation(
                  turns: _expandido ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.expand_more, size: 20, color: AppColors.blue1),
                ),
              ],
            ),
          ),
          // Contenido colapsable
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
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
                if (widget.empresaContext.permissions.canChangePlan) ...[
                  const SizedBox(height: 16),
                  CustomButton(
                    backgroundColor: AppColors.blue1,
                    borderWidth: 1,
                    height: 31,
                    text: 'Cambiar Plan',
                    textColor: AppColors.white,
                    onPressed: () {
                      context.push('/empresa/planes');
                    },
                    icon: const Icon(Icons.upgrade, color: AppColors.white),
                  ),
                ],
              ],
            ),
            crossFadeState: _expandido ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
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
    final localFecha = DateFormatter.toLocal(fecha);
    final difference = localFecha.difference(now).inDays;

    if (difference < 0) {
      return 'Vencida';
    } else if (difference == 0) {
      return 'Hoy';
    } else if (difference == 1) {
      return 'Mañana';
    } else if (difference <= 7) {
      return '$difference días';
    } else {
      return DateFormatter.formatDate(localFecha);
    }
  }
}


