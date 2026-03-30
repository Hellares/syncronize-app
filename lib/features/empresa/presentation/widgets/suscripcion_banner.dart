import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/empresa_info.dart';

/// Persistent banner para el periodo de gracia (primeros 7 dias despues del vencimiento).
/// Muestra una barra roja/ambar en la parte superior con un boton "Renovar".
class SuscripcionBanner extends StatelessWidget {
  final EmpresaInfo empresa;

  const SuscripcionBanner({
    super.key,
    required this.empresa,
  });

  @override
  Widget build(BuildContext context) {
    // Solo mostrar si la suscripcion esta vencida
    if (!empresa.isSubscriptionExpired) return const SizedBox.shrink();

    final diasVencida = empresa.fechaVencimiento != null
        ? DateTime.now().difference(empresa.fechaVencimiento!).inDays
        : 0;

    // Solo mostrar el banner durante el periodo de gracia (7 dias)
    // Despues de 7 dias se muestra la pantalla completa de bloqueo
    if (diasVencida > 7) return const SizedBox.shrink();

    final esCritico = diasVencida > 4;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: esCritico
              ? [const Color(0xFFC62828), const Color(0xFFD32F2F)]
              : [const Color(0xFFEF6C00), const Color(0xFFF57C00)],
        ),
        boxShadow: [
          BoxShadow(
            color: (esCritico ? Colors.red : Colors.orange).withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Icon(
              esCritico ? Icons.error_outline : Icons.warning_amber_rounded,
              color: AppColors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                diasVencida == 0
                    ? 'Tu plan vence hoy. Renueva para evitar la suspension.'
                    : 'Tu plan vencio hace $diasVencida ${diasVencida == 1 ? 'dia' : 'dias'}. Renueva para evitar la suspension.',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                context.push('/empresa/pagar-plan', extra: {
                  'planId': empresa.planSuscripcionId,
                  'planNombre': empresa.planSuscripcion?.nombre,
                  'planPrecio': empresa.planSuscripcion?.precio,
                });
              },
              style: TextButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: esCritico ? Colors.red : Colors.orange,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Renovar',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
