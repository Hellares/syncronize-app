import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_logo_widget.dart';

/// Pantalla de splash que se muestra durante la inicialización
///
/// Esta pantalla se renderiza INMEDIATAMENTE (sin bloqueo del thread principal)
/// mientras se inicializan las dependencias en segundo plano
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  final LogoStyle _logoStyle = LogoStyle.glowEffect;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blue2,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppLogo(
              logoPath: 'assets/img/logo.svg',
              logoSize: 110,
              style: _logoStyle,
              appName: 'Syncronize',
              subtitle: 'Red de Emprendedores',
              primaryColor: AppColors.white,
            ),
            const SizedBox(height: 48),
            // Indicador de carga
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
            ),
          ],
        ),
      ),
    );
  }
}
