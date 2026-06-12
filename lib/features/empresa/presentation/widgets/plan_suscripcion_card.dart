import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/utils/date_formatter.dart';
import 'package:syncronize/core/widgets/info_chip.dart';
import 'package:syncronize/features/auth/presentation/widgets/widgets.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/animated_container.dart';
import '../../data/datasources/empresa_remote_datasource.dart';
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

  /// Storage fresco fetcheado al montar la card. Sobrescribe lo que viene
  /// en `empresaContext.planLimits` (que se hidrata sólo al login y queda
  /// stale después de subir/eliminar archivos).
  int? _freshUsadoBytes;
  int? _freshUsadoMB;
  int? _freshLimiteMB;

  @override
  void initState() {
    super.initState();
    _loadTipoCambio();
    _refreshStorage();
  }

  Future<void> _refreshStorage() async {
    try {
      final empresaId = widget.empresaContext.empresa.id;
      final response =
          await locator<EmpresaRemoteDataSource>().getPlanLimitsInfo(empresaId);
      if (!mounted || response == null) return;
      final almacenamiento =
          response['limites']?['almacenamiento'] as Map<String, dynamic>?;
      if (almacenamiento == null) return;
      setState(() {
        _freshUsadoBytes = (almacenamiento['actualBytes'] as num?)?.toInt();
        _freshUsadoMB = (almacenamiento['actualMB'] as num?)?.toInt();
        _freshLimiteMB = (almacenamiento['limiteMB'] as num?)?.toInt();
      });
    } catch (_) {
      // Falla silenciosa; nos quedamos con el valor cacheado de planLimits.
    }
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
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (siempre visible, tap para expandir/colapsar)
          GestureDetector(
            onTap: () => setState(() => _expandido = !_expandido),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                const Icon(Icons.workspace_premium, color: AppColors.blue1, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSubtitle(
                        plan != null ? 'PLAN:  ${plan.nombre}' : 'Sin Plan',
                        color: AppColors.blue1,
                        fontSize: 10,
                        font: AppFont.amazonEmberMedium
                      ),
                      if (plan != null)
                        AppSubtitle(
                          'S/${plan.precio.toStringAsFixed(2)} - ${plan.periodo}',
                          color: AppColors.green,
                          fontSize: 8,
                          font: AppFont.amazonEmberMediumItalic
                        )
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
                    fontSize: 8,
                    text: 'S/ C:${_tcCompra!.toStringAsFixed(3)} V:${_tcVenta!.toStringAsFixed(3)}',
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
                    fontSize: 8,
                    textColor: _getEstadoTextColor(empresa.estadoSuscripcion),
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
          // Storage (siempre visible, tap para ir a multimedia)
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => context.push('/empresa/multimedia'),
            child: _buildStorageBar(),
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          backgroundColor: AppColors.blue1,
                          borderWidth: 1,
                          height: 31,
                          text: 'Cambiar Plan',
                          fontSize: 10,
                          textColor: AppColors.white,
                          onPressed: () {
                            context.push('/empresa/planes');
                          },
                          icon: const Icon(Icons.upgrade, color: AppColors.white, size: 18),
                        ),
                      ),
                      if (plan != null && !plan.isFreePlan) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: CustomButton(
                            backgroundColor: AppColors.green,
                            borderWidth: 1,
                            height: 31,
                            text: 'Pagar',
                            fontSize: 10,
                            textColor: AppColors.white,
                            onPressed: () {
                              context.push('/empresa/pagar-plan', extra: {
                                'planId': empresa.planSuscripcionId,
                                'planNombre': plan.nombre,
                                'planPrecio': plan.precio,
                              });
                            },
                            icon: const Icon(Icons.payment, color: AppColors.white, size: 18),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => context.push('/empresa/mis-pagos'),
                    child: AppSubtitle(
                      'Ver historial de pagos',
                      color: AppColors.green,
                      fontSize: 10,
                      font: AppFont.amazonEmberMediumItalic,
                    ),
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

  Widget _buildStorageBar() {
    final storage = widget.empresaContext.planLimits?.almacenamiento;
    // Preferimos el dato fresco fetcheado al montar; caemos al cache.
    final usadoBytes = _freshUsadoBytes ?? storage?.actualBytes;
    final storageUsadoMB = _freshUsadoMB ?? storage?.actualMB ?? 0;
    final storageLimiteMB = _freshLimiteMB ?? storage?.limiteMB;

    // Para la barra usamos bytes si están disponibles (precisión); si no,
    // caemos a MB (puede sub-cuantizarse pero al menos refleja algo).
    double porcentaje = 0;
    if (storageLimiteMB != null && storageLimiteMB > 0) {
      final limiteBytes = storageLimiteMB * 1024 * 1024;
      if (usadoBytes != null && limiteBytes > 0) {
        porcentaje = (usadoBytes / limiteBytes).clamp(0.0, 1.0);
      } else {
        porcentaje = (storageUsadoMB / storageLimiteMB).clamp(0.0, 1.0);
      }
    }
    final esCritico = porcentaje > 0.85;

    final usadoLabel = _formatStorage(
      bytes: usadoBytes,
      fallbackMB: storageUsadoMB,
    );
    final limiteLabel = storageLimiteMB != null
        ? (storageLimiteMB >= 1024
            ? '${(storageLimiteMB / 1024).toStringAsFixed(0)} GB'
            : '$storageLimiteMB MB')
        : 'Ilimitado';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.cloud_outlined, size: 14, color: esCritico ? Colors.red : AppColors.blue1),
            const SizedBox(width: 6),
              AppSubtitle(
                'Almacenamiento:  $usadoLabel / $limiteLabel',
                fontSize: 9,
                font: AppFont.amazonEmberMedium,
                color: esCritico ? Colors.red : AppColors.blue1,
              ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: porcentaje,
            backgroundColor: AppColors.blue1.withValues(alpha: 0.1),
            color: esCritico ? Colors.red : AppColors.blue1,
            minHeight: 5,
          ),
        ),
      ],
    );
  }

  /// Formatea storage usando `bytes` (si está disponible) → KB / MB / GB con
  /// un decimal cuando aporta info. Cae a `fallbackMB` si no hay bytes.
  String _formatStorage({int? bytes, required int fallbackMB}) {
    if (bytes != null) {
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(0)} KB';
      }
      final mb = bytes / (1024 * 1024);
      if (mb < 1024) {
        return mb >= 100
            ? '${mb.toStringAsFixed(0)} MB'
            : '${mb.toStringAsFixed(1)} MB';
      }
      return '${(mb / 1024).toStringAsFixed(2)} GB';
    }
    return fallbackMB >= 1024
        ? '${(fallbackMB / 1024).toStringAsFixed(1)} GB'
        : '$fallbackMB MB';
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

  /// Texto blanco sobre los fondos sólidos del chip de estado (el azul
  /// no se lee sobre rojo).
  Color _getEstadoTextColor(String estado) {
    switch (estado) {
      case 'VENCIDA':
        return Colors.white;
      default:
        return AppColors.blue1;
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


