import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_button.dart';

class DashboardFinancieroWidget extends StatefulWidget {
  final VoidCallback? onVerResumenCompleto;

  const DashboardFinancieroWidget({
    super.key,
    this.onVerResumenCompleto,
  });

  @override
  State<DashboardFinancieroWidget> createState() => _DashboardFinancieroWidgetState();
}

class _DashboardFinancieroWidgetState extends State<DashboardFinancieroWidget> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final dio = locator<DioClient>();
      final now = DateTime.now();
      final inicio = DateTime(now.year, now.month, now.day);
      final fin = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final response = await dio.get(
        '/resumen-financiero',
        queryParameters: {
          'fechaInicio': inicio.toIso8601String(),
          'fechaFin': fin.toIso8601String(),
        },
      );

      if (mounted) {
        setState(() {
          _data = response.data as Map<String, dynamic>?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      padding: const EdgeInsets.all(14),
      child: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blue1),
                ),
              ),
            )
          : _hasError
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return SizedBox(
      height: 80,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 24, color: Colors.grey.shade400),
            const SizedBox(height: 6),
            Text(
              'No se pudo cargar el resumen',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: _load,
              child: const Text(
                'Reintentar',
                style: TextStyle(fontSize: 10, color: AppColors.blue1, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final ventasHoyCount = _data?['ventasHoyCount'] as int? ?? 0;
    final ventasHoyMonto = double.tryParse(_data?['ventasHoyMonto']?.toString() ?? '') ?? 0;
    final ingresosHoy = double.tryParse(_data?['ingresosHoy']?.toString() ?? '') ?? 0;
    final egresosHoy = double.tryParse(_data?['egresosHoy']?.toString() ?? '') ?? 0;
    final flujoCaja = ingresosHoy - egresosHoy;
    final cuentasVencidas = _data?['cuentasVencidas'] as int? ?? 0;
    final cuotasProximas = _data?['cuotasProximas'] as int? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.dashboard, size: 16, color: AppColors.blue1),
            const SizedBox(width: 6),
            const AppSubtitle('Resumen Financiero Hoy', fontSize: 13, color: AppColors.blue3),
            const Spacer(),
            Text(
              DateFormat('dd/MM/yyyy').format(DateTime.now()),
              style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 1: Ventas hoy + Flujo caja
        Row(
          children: [
            Expanded(
              child: _MiniMetric(
                icon: Icons.point_of_sale,
                iconColor: AppColors.blue1,
                label: 'Ventas hoy',
                value: 'S/ ${ventasHoyMonto.toStringAsFixed(2)}',
                subtitle: '$ventasHoyCount venta${ventasHoyCount != 1 ? 's' : ''}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniMetric(
                icon: Icons.account_balance_wallet,
                iconColor: flujoCaja >= 0 ? AppColors.green : AppColors.red,
                label: 'Flujo caja hoy',
                value: 'S/ ${flujoCaja.toStringAsFixed(2)}',
                valueColor: flujoCaja >= 0 ? AppColors.green : AppColors.red,
                subtitle: null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Row 2: Alertas
        if (cuentasVencidas > 0 || cuotasProximas > 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.orange.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, size: 16, color: AppColors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    spacing: 12,
                    children: [
                      if (cuentasVencidas > 0)
                        Text(
                          '$cuentasVencidas cuenta${cuentasVencidas != 1 ? 's' : ''} vencida${cuentasVencidas != 1 ? 's' : ''}',
                          style: const TextStyle(fontSize: 10, color: AppColors.red, fontWeight: FontWeight.w500),
                        ),
                      if (cuotasProximas > 0)
                        Text(
                          '$cuotasProximas cuota${cuotasProximas != 1 ? 's' : ''} proxima${cuotasProximas != 1 ? 's' : ''}',
                          style: const TextStyle(fontSize: 10, color: AppColors.orange, fontWeight: FontWeight.w500),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 10),

        // Button: Ver resumen completo
        SizedBox(
          width: double.infinity,
          child: CustomButton(
            text: 'Ver resumen completo',
            backgroundColor: AppColors.blue1,
            textColor: Colors.white,
            height: 34,
            fontSize: 11,
            icon: const Icon(Icons.arrow_forward, size: 14, color: Colors.white),
            onPressed: widget.onVerResumenCompleto ?? () {
              Navigator.of(context).pushNamed('/empresa/resumen-financiero');
            },
          ),
        ),
      ],
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color? valueColor;
  final String? subtitle;

  const _MiniMetric({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueColor,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: iconColor.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? AppColors.blue3,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
