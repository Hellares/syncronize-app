import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
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
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 10,),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: esCritico
              ? [const Color(0xFFC62828), const Color(0xFFD32F2F)]
              : [const Color(0xFFEF6C00), const Color(0xFFF57C00)],
        ),
        boxShadow: [
          BoxShadow(
            color: (esCritico ? Colors.red : Colors.orange).withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Lottie.asset(
              'assets/animations/skull.json',
              width: 50,
              height: 50,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            Expanded(
            child: AppSubtitle(
              diasVencida == 0
                  ? 'Tu plan vence hoy. Renueva para evitar la suspensión.'
                  : 'Tu plan venció hace $diasVencida ${diasVencida == 1 ? 'día' : 'días'}. Renueva para evitar la suspensión.',
              color: AppColors.white,
              fontSize: 10,
              font: AppFont.amazonEmberMedium,
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
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text(
                'Renovar',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
