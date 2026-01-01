import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_background.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_button.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/bloc/auth/auth_bloc.dart';

/// Drawer adaptable del Marketplace
/// Muestra contenido diferente según el estado de autenticación
class MarketplaceDrawer extends StatelessWidget {
  const MarketplaceDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is Authenticated) {
          return _AuthenticatedDrawerContent(user: state.user);
        } else {
          return const _GuestDrawerContent();
        }
      },
    );
  }
}

/// Contenido del drawer para usuarios NO autenticados (Guest)
class _GuestDrawerContent extends StatelessWidget {
  const _GuestDrawerContent();

  @override
  Widget build(BuildContext context) {

    return Drawer(
      width: 260,
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header con call-to-action
          GradientBackground(
            style: GradientStyle.gjayli,
            // begin: Alignment.topLeft,
            // end: Alignment.bottomRight,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    child: Icon(
                      Icons.person_outline,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  AppTitle(
                    '¡Hola!',
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  const SizedBox(height: 4),
                  AppSubtitle(
                    'Inicia sesión para acceder a más funciones',

                    color: AppColors.white,
                    fontSize: 11,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: 'Iniciar Sesión', 
                      fontSize: 8,
                      fontFamily: AppFonts.getFontFamily(AppFont.pirulentBold),
                      borderRadius: 6,
                      height: 33,
                      backgroundColor: AppColors.blue2,
                      onPressed: () {
                      Navigator.pop(context);
                      context.push('/login');
                    },
                  ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: 'Crear Cuenta', 
                      fontSize: 8,
                      fontFamily: AppFonts.getFontFamily(AppFont.pirulentBold),
                      borderRadius: 6,
                      height: 32,
                      borderWidth: 0.7,
                      enableGlow: true,
                      glowColor: AppColors.blue2,
                      isOutlined: true,
                      borderColor: AppColors.blue2,
                      textColor: AppColors.blue2,
                      onPressed: () {
                      Navigator.pop(context);
                      context.push('/register');
                    },
                  ),
                  ),
                ],
              ),
            ),
          ),

          // Opciones públicas
          const SizedBox(height: 8),
          _DrawerSection(
            title: 'Explorar',
            
            children: [
              _DrawerItem(
                icon: Icons.store,
                title: 'Marketplace',
                textStyle: TextStyle(
                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                  fontSize: 10,
                  color: AppColors.blue,
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/marketplace');
                },
              ),
              _DrawerItem(
                icon: Icons.category,
                title: 'Categorías',
                textStyle: TextStyle(
                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                  fontSize: 10,
                  color: AppColors.blue,
                ),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navegar a categorías públicas
                },
              ),
              _DrawerItem(
                icon: Icons.local_offer,
                title: 'Ofertas',
                textStyle: TextStyle(
                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                  fontSize: 10,
                  color: AppColors.blue,
                ),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navegar a ofertas
                },
              ),
            ],
          ),

          const Divider(height: 1),

          _DrawerSection(
            title: 'Información',
            children: [
              _DrawerItem(
                icon: Icons.help_outline,
                title: 'Ayuda',
                textStyle: TextStyle(
                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                  fontSize: 10,
                  color: AppColors.blue,
                ),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navegar a ayuda
                },
              ),
              _DrawerItem(
                icon: Icons.info_outline,
                title: 'Acerca de',
                textStyle: TextStyle(
                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                  fontSize: 10,
                  color: AppColors.blue,
                ),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navegar a acerca de
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Contenido del drawer para usuarios autenticados
class _AuthenticatedDrawerContent extends StatelessWidget {
  final User user;

  const _AuthenticatedDrawerContent({required this.user});

  @override
  Widget build(BuildContext context) {

    return Drawer(
      width: 260,
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header con datos del usuario
          GradientBackground(
            style: GradientStyle.gjayli,
            child: UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                color: Colors.transparent,
              ),
              currentAccountPictureSize: const Size(50, 50),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  user.iniciales,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.blue2,
                  ),
                ),
              ),
              accountName: Text(
                user.nombreCompleto,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: AppFonts.getFontFamily(AppFont.pirulentBold),
                  fontSize: 9,
                  color: AppColors.blue3
                ),
              ),
              // accountEmail: Text(user.email),
              accountEmail: AppSubtitle(user.identificador),
            ),
          ),

          // Opciones de usuario autenticado
          _DrawerSection(
            title: 'Mi Cuenta',
            children: [
              _DrawerItem(
                icon: Icons.shopping_bag_outlined,
                title: 'Mis Compras',
                textStyle: TextStyle(
                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                  fontSize: 10,
                  color: AppColors.blue,
                ),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navegar a mis compras
                },
              ),
              _DrawerItem(
                icon: Icons.favorite_outline,
                title: 'Favoritos',
                textStyle: TextStyle(
                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                  fontSize: 10,
                  color: AppColors.blue,
                ),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navegar a favoritos
                },
              ),
              _DrawerItem(
                icon: Icons.person_outline,
                title: 'Mi Perfil',
                textStyle: TextStyle(
                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                  fontSize: 10,
                  color: AppColors.blue,
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/home');
                },
              ),
            ],
          ),

          const Divider(height: 1),

          // Opciones de empresa (si tiene)
          _DrawerSection(
            title: 'Mi Negocio',
            children: [
              _DrawerItem(
                icon: Icons.business_outlined,
                title: 'Mis Empresas',
                subtitle: 'Gestiona tus negocios',
                textStyle: TextStyle(
                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                  fontSize: 10,
                  color: AppColors.blue,
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Navegar a página que maneja la selección inteligente
                  context.push('/empresa/select');
                },
              ),
              _DrawerItem(
                icon: Icons.add_business,
                title: 'Crear Empresa',
                subtitle: 'Vende en el marketplace',
                textStyle: TextStyle(
                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                  fontSize: 10,
                  color: AppColors.blue,
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/create-empresa');
                },
              ),
            ],
          ),

          const Divider(height: 1),

          _DrawerSection(
            title: 'Explorar',
            children: [
              _DrawerItem(
                icon: Icons.store,
                title: 'Marketplace',
                textStyle: TextStyle(
                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                  fontSize: 10,
                  color: AppColors.blue,
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/marketplace');
                },
              ),
              _DrawerItem(
                icon: Icons.category,
                title: 'Categorías',
                textStyle: TextStyle(
                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                  fontSize: 10,
                  color: AppColors.blue,
                ),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navegar a categorías
                },
              ),
            ],
          ),

          const Divider(height: 1),

          _DrawerSection(
            title: 'Configuración',
            children: [
              _DrawerItem(
                icon: Icons.security_outlined,
                title: 'Seguridad de la cuenta',
                subtitle: 'Métodos de autenticación',

                textStyle: TextStyle(
                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                  fontSize: 10,
                  color: AppColors.blue,
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/account-security');
                },
              ),
              _DrawerItem(
                icon: Icons.settings_outlined,
                title: 'Configuración',
                textStyle: TextStyle(
                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                  fontSize: 10,
                  color: AppColors.blue,
                ),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navegar a configuración
                },
              ),
              _DrawerItem(
                icon: Icons.help_outline,
                title: 'Ayuda',
                textStyle: TextStyle(
                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                  fontSize: 10,
                  color: AppColors.blue,
                ),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navegar a ayuda
                },
              ),
            ],
          ),

          const Divider(height: 1),

          // Cerrar sesión
          ListTile(
            leading: Icon(
              Icons.logout,
              color: Colors.red.shade600,
            ),
            title: AppSubtitle( 'Cerrar Sesión',
              color: AppColors.red,
              fontSize: 8,
              font: AppFont.pirulentBold,
            ),
            onTap: () async {
              // Cerrar sesión de Google primero (si existe)
              try {
                final googleSignIn = GoogleSignIn();
                await googleSignIn.signOut();
              } catch (e) {
                // Ignorar errores si el usuario no inició sesión con Google
              }

              // Cerrar el drawer
              if (context.mounted) {
                Navigator.pop(context);
              }

              // Logout de la app
              if (context.mounted) {
                context.read<AuthBloc>().add(const LogoutRequestedEvent());
              }
            },
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Widget para una sección del drawer con título
class _DrawerSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DrawerSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 8,
              fontFamily: AppFonts.getFontFamily(AppFont.pirulentBold),
              // fontWeight: FontWeight.bold,
              color: AppColors.blue2,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

/// Widget para un item del drawer
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final TextStyle? textStyle;

  const _DrawerItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.blue2, size: 20),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      onTap: onTap,
      subtitleTextStyle: textStyle,
      titleTextStyle: textStyle,
    );
  }
}
