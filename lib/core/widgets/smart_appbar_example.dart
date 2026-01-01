// Ejemplos de uso del SmartAppBar adaptado
// Este archivo es solo para referencia, puedes eliminarlo cuando ya sepas usar el widget

import 'package:flutter/material.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';

class SmartAppBarExamples extends StatelessWidget {
  const SmartAppBarExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // === EJEMPLO 1: AppBar básico ===
      // appBar: SmartAppBar.basic(
      //   title: 'Mi Página',
      // ),

      // === EJEMPLO 2: AppBar con botón de regreso ===
      // appBar: SmartAppBar.withBackButton(
      //   title: 'Detalles',
      //   onBack: () {
      //     // Acción personalizada al presionar back
      //     Navigator.pop(context);
      //   },
      // ),

      // === EJEMPLO 3: AppBar con información de usuario automática ===
      // (Carga los datos del usuario desde el storage local)
      appBar: SmartAppBar.withUser(
        title: 'Dashboard',
        showLogo: true,
        logoPath: 'assets/animations/logo.json', // Cambia a tu logo
      ),

      // === EJEMPLO 4: AppBar con usuario manual ===
      // appBar: SmartAppBar.withManualUser(
      //   role: 'Administrador',
      //   name: 'Juan Pérez',
      //   title: 'Panel Admin',
      // ),

      // === EJEMPLO 5: AppBar personalizado con icono personalizado ===
      // appBar: SmartAppBar.custom(
      //   title: 'Configuración',
      //   leftIcon: Icons.menu,
      //   onLeftTap: () {
      //     // Abrir drawer o menú
      //     Scaffold.of(context).openDrawer();
      //   },
      // ),

      // === EJEMPLO 6: AppBar completamente personalizado ===
      // appBar: SmartAppBar(
      //   title: 'Mi App',
      //   backgroundColor: Colors.white,
      //   elevation: 1,
      //   showLogo: true,
      //   logoPath: 'assets/img/logo.png',
      //   logoSize: 30,
      //   showUserInfo: true,
      //   iconColor: Colors.blue,
      //   customHeight: 60, // Altura personalizada
      // ),

      body: const Center(
        child: Text('Contenido de la página'),
      ),
    );
  }
}
