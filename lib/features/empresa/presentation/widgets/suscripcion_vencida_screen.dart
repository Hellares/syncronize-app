import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/sistema_config_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/empresa_info.dart';

/// Full-screen overlay que bloquea la app cuando la suscripcion ha vencido
/// mas alla del periodo de gracia (7 dias).
class SuscripcionVencidaScreen extends StatelessWidget {
  final EmpresaInfo empresa;

  const SuscripcionVencidaScreen({
    super.key,
    required this.empresa,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A237E), // indigo 900
              Color(0xFF283593), // indigo 800
              Color(0xFF303F9F), // indigo 700
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Warning icon
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.red,
                          size: 56,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title
                      const AppTitle(
                        'Tu suscripcion ha vencido',
                        fontSize: 18,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Plan info
                      if (empresa.planSuscripcion != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.blue1.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.workspace_premium,
                                  color: AppColors.blue1, size: 20),
                              const SizedBox(width: 8),
                              AppText(
                                'Plan ${empresa.planSuscripcion!.nombre}',
                                size: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.blue1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Expiration date
                      if (empresa.fechaVencimiento != null) ...[
                        AppText(
                          'Vencimiento: ${DateFormatter.formatDate(DateFormatter.toLocal(empresa.fechaVencimiento!))}',
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Message
                      const AppText(
                        'Renueva tu plan para continuar usando todas las funcionalidades de Syncronize.',
                        size: 13,
                        color: AppColors.textSecondary,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),

                      // Renovar button
                      CustomButton(
                        text: 'Renovar Plan',
                        textColor: AppColors.blue1,
                        borderColor: AppColors.blue1,
                        onPressed: () {
                          context.push('/empresa/pagar-plan', extra: {
                            'planId': empresa.planSuscripcionId,
                            'planNombre': empresa.planSuscripcion?.nombre,
                            'planPrecio': empresa.planSuscripcion?.precio,
                          });
                        },
                        icon: const Icon(Icons.upgrade,
                            color: AppColors.white, size: 20),
                      ),
                      const SizedBox(height: 12),

                      // Contactar soporte
                      CustomButton(
                        text: 'Contactar Soporte',
                        isOutlined: true,
                        backgroundColor: AppColors.white,
                        textColor: AppColors.blue1,
                        borderColor: AppColors.blue1,
                        onPressed: () => _contactarSoporte(),
                        height: 45,
                        borderRadius: 14,
                        icon: const Icon(Icons.support_agent,
                            color: AppColors.blue1, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _contactarSoporte() async {
    final phone = await locator<SistemaConfigService>().whatsappSoporte;
    const message =
        'Hola, necesito ayuda con mi suscripcion en Syncronize. Mi empresa es: ';
    final url = Uri.parse(
        'https://wa.me/$phone?text=${Uri.encodeComponent('$message${empresa.nombre}')}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
