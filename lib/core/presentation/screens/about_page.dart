import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_background.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(title: 'Acerca de'),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              // Logo y nombre
              GradientContainer(
                shadowStyle: ShadowStyle.glow,
                borderColor: AppColors.blueborder,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/iconapp/iconapp.png',
                          width: 90,
                          height: 90,
                        ),
                      ),
                      AppTitle(
                        'SYNCRONIZE',
                        fontSize: 20,
                        font: AppFont.airstrikeBold3d,
                        color: AppColors.blue2,
                      ),
                      const SizedBox(height: 6),
                      AppSubtitle(
                        'Plataforma SaaS de gestión empresarial y marketplace',
                        color: AppColors.blueGrey,
                        fontSize: 11,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'v1.0.0',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Equipo
              GradientContainer(
                gradient: AppGradients.blueWhiteBlue(),
                borderColor: AppColors.blueborder,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.groups_outlined, size: 18, color: AppColors.blue2),
                          const SizedBox(width: 8),
                          AppSubtitle(
                            'NUESTRO EQUIPO',
                            fontSize: 10,
                            font: AppFont.pirulentBold,
                            color: AppColors.blue2,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _TeamMember(
                        name: 'James Torres',
                        role: 'CEO & Fundador',
                        icon: Icons.star_rounded,
                        iconColor: Colors.amber,
                      ),
                      const SizedBox(height: 10),
                      _TeamMember(
                        name: 'Jayli Azul Flores',
                        role: 'Consultor',
                        icon: Icons.lightbulb_outline,
                        iconColor: AppColors.blue2,
                      ),
                      const SizedBox(height: 10),
                      _TeamMember(
                        name: 'Antonio Zarsoza',
                        role: 'Consultor',
                        icon: Icons.lightbulb_outline,
                        iconColor: AppColors.blue2,
                      ),
                      const SizedBox(height: 10),
                      _TeamMember(
                        name: 'Cristian Ucañan',
                        role: 'Consultor',
                        icon: Icons.lightbulb_outline,
                        iconColor: AppColors.blue2,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Disclaimer
              GradientContainer(
                gradient: AppGradients.gray(),
                borderColor: Colors.orange.shade200,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 20,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Aviso Legal',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.orange.shade800,
                                fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Syncronize es una plataforma tecnológica que facilita la gestión empresarial y la conexión entre negocios y clientes. '
                              'No somos directamente responsables de la información, productos o servicios publicados por los clientes y empresas registradas en la plataforma. '
                              'Cada empresa es responsable de la veracidad y exactitud de los datos que proporciona.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                                height: 1.5,
                                fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Licencias
              GradientContainer(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      showLicensePage(
                        context: context,
                        applicationName: 'Syncronize',
                        applicationVersion: '1.0.0',
                        applicationIcon: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Image.asset(
                            'assets/iconapp/iconapp.png',
                            width: 50,
                            height: 50,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.description_outlined, size: 18, color: AppColors.blue2),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Licencias de código abierto',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.blue1,
                                fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Footer
              Text(
                '\u00a9 2026 Syncronize. Todos los derechos reservados.',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamMember extends StatelessWidget {
  final String name;
  final String role;
  final IconData icon;
  final Color iconColor;

  const _TeamMember({
    required this.name,
    required this.role,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blue1,
                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                ),
              ),
              Text(
                role,
                style: TextStyle(
                  fontSize: 10.5,
                  color: Colors.grey.shade600,
                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
