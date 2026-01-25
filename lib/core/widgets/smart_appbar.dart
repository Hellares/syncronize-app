import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lottie/lottie.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/features/auth/domain/usecases/get_local_user_usecase.dart';
import 'package:syncronize/features/auth/domain/usecases/logout_usecase.dart';
import 'package:syncronize/features/auth/domain/entities/user.dart';
import 'package:syncronize/core/usecases/usecase.dart';
import 'package:syncronize/core/utils/resource.dart';

class SmartAppBar extends StatefulWidget implements PreferredSizeWidget {
  // === PROPIEDADES BÁSICAS ===
  final String? title;
  final TextStyle? titleStyle;
  final double elevation;
  final bool centerTitle;
  final SystemUiOverlayStyle? systemOverlayStyle;
  final double customHeight;
  final Color? backgroundColor;
  final Color? foregroundColor;

  // === LOGO ===
  final bool showLogo;
  final String? logoPath;
  final double logoSize;

  // === USUARIO (MODO AUTOMÁTICO) ===
  final bool showUserInfo;
  final VoidCallback? onUserInfoTap;
  final TextStyle? userInfoStyle;

  // === USUARIO (MODO MANUAL) ===
  final String? manualUserRole;
  final String? manualUserName;

  // === LEADING PERSONALIZADO ===
  final Widget? leftWidget;
  final IconData? leftIcon;
  final String? leftIconPath;
  final VoidCallback? onLeftTap;
  final Color? iconColor;

  // === ACTIONS Y BOTTOM ===
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  const SmartAppBar({
    super.key,
    // Básicas
    this.title,
    this.titleStyle,
    this.elevation = 0,
    this.centerTitle = true,
    this.systemOverlayStyle,
    this.customHeight = 35,
    this.backgroundColor,
    this.foregroundColor,
    // Logo
    this.showLogo = false,
    this.logoPath,
    this.logoSize = 21,
    // Usuario automático
    this.showUserInfo = false,
    this.onUserInfoTap,
    this.userInfoStyle,
    // Usuario manual
    this.manualUserRole,
    this.manualUserName,
    // Leading personalizado
    this.leftWidget,
    this.leftIcon,
    this.leftIconPath,
    this.onLeftTap,
    this.iconColor,
    // Actions y Bottom
    this.actions,
    this.bottom,
  });

  // === FACTORY CONSTRUCTORS ===

  /// AppBar básico sin usuario
  factory SmartAppBar.basic({
    String? title,
    bool showLogo = false,
    double customHeight = 35,
  }) {
    return SmartAppBar(
      title: title,
      showLogo: showLogo,
      showUserInfo: false,
      customHeight: customHeight,
    );
  }

  /// AppBar con usuario automático (carga desde storage)
  factory SmartAppBar.withUser({
    String? title,
    bool showLogo = false,
    VoidCallback? onUserTap,
    String? logoPath,
    double customHeight = 35,
  }) {
    return SmartAppBar(
      title: title,
      showLogo: showLogo,
      showUserInfo: true,
      onUserInfoTap: onUserTap,
      logoPath: logoPath,
      customHeight: customHeight,
    );
  }

  /// AppBar con usuario manual
  factory SmartAppBar.withManualUser({
    required String role,
    required String name,
    String? title,
    bool showLogo = false,
    VoidCallback? onUserTap,
    double customHeight = 35,
  }) {
    return SmartAppBar(
      title: title,
      showLogo: showLogo,
      manualUserRole: role,
      manualUserName: name,
      onUserInfoTap: onUserTap,
      customHeight: customHeight,
    );
  }

  /// AppBar con botón de regreso
  factory SmartAppBar.withBackButton({
    String? title,
    VoidCallback? onBack,
    bool showLogo = false,
    double customHeight = 35,
  }) {
    return SmartAppBar(
      title: title,
      showLogo: showLogo,
      leftIcon: Icons.arrow_back_ios,
      onLeftTap: onBack,
      customHeight: customHeight,
    );
  }

  /// AppBar con leading personalizado
  factory SmartAppBar.custom({
    String? title,
    Widget? leftWidget,
    IconData? leftIcon,
    VoidCallback? onLeftTap,
    bool showLogo = false,
    double customHeight = 35,
  }) {
    return SmartAppBar(
      title: title,
      showLogo: showLogo,
      leftWidget: leftWidget,
      leftIcon: leftIcon,
      onLeftTap: onLeftTap,
      customHeight: customHeight,
    );
  }

  @override
  State<SmartAppBar> createState() => _SmartAppBarState();

  @override
  Size get preferredSize {
    final double height = customHeight + (bottom?.preferredSize.height ?? 0.0);
    return Size.fromHeight(height);
  }
}

class _SmartAppBarState extends State<SmartAppBar> {
  // Cache interno para datos del usuario
  Map<String, String>? _cachedUserInfo;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Solo cargar si showUserInfo es true
    if (widget.showUserInfo) {
      _loadUserInfo();
    }
  }

  Future<void> _loadUserInfo() async {
    // Si ya está cargado, no volver a cargar
    if (_cachedUserInfo != null) return;

    setState(() => _isLoading = true);

    try {
      final getUserUseCase = locator<GetLocalUserUseCase>();
      final result = await getUserUseCase(NoParams());

      if (result is Success<User?>) {
        final user = result.data;
        if (user != null && mounted) {
          setState(() {
            _cachedUserInfo = {
              'role': user.rolGlobal ?? 'Usuario',
              'name': user.nombreCompleto,
              'email': user.identificador,
            };
            _isLoading = false;
          });
        } else {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        }
      } else {
        // Error o cualquier otro estado
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveForegroundColor = widget.foregroundColor ?? widget.iconColor ?? AppColors.blue3;

    return AppBar(
      backgroundColor: widget.backgroundColor ?? Colors.transparent,
      elevation: widget.elevation,
      centerTitle: widget.centerTitle,
      automaticallyImplyLeading: false,
      systemOverlayStyle:
          widget.systemOverlayStyle ?? _defaultSystemOverlayStyle,
      title: _buildTitle(),
      leading: _buildLeading(context),
      leadingWidth: _getLeadingWidth(),
      actions: _buildActions(),
      bottom: widget.bottom,
      iconTheme: IconThemeData(color: effectiveForegroundColor),
      foregroundColor: effectiveForegroundColor,
      toolbarHeight: widget.customHeight,
      surfaceTintColor: Colors.transparent,
    );
  }

  // === BUILDERS ===

  Widget? _buildTitle() {
    if (widget.title == null) return null;

    final effectiveForegroundColor = widget.foregroundColor ?? widget.iconColor ?? AppColors.blue3;

    return Text(
      widget.title!,
      style:
          widget.titleStyle ??
          AppFont.pirulentBold.style(fontSize: 10, color: effectiveForegroundColor),
    );
  }

// Widget? _buildTitle() {
//   if (widget.title == null) return null;

//   final effectiveForegroundColor = widget.foregroundColor ?? widget.iconColor ?? AppColors.blue3;

//   final titleText = Text(
//     widget.title!,
//     style: widget.titleStyle ??
//         AppFont.pirulentBold.style(
//           fontSize: 10, // Más legible y equilibrado (antes 8→10→ahora 18)
//           color: effectiveForegroundColor,
//         ),
//     overflow: TextOverflow.ellipsis, // Evita desborde si el título es largo
//   );

//   // Si está centrado → devolver normal
//   if (widget.centerTitle) {
//     return titleText;
//   }

//   // Si NO está centrado → alineado izquierda con padding mínimo
//   return Padding(
//     padding: const EdgeInsets.only(left: 1.0), // ← Ajusta este valor: 8 px queda muy pegado pero natural
//     // Si quieres aún más pegado: left: 4 o left: 0
//     child: Align(
//       alignment: Alignment.centerLeft,
//       child: titleText,
//     ),
//   );
// }

  Widget? _buildLeading(BuildContext context) {
    // 1. Usuario manual tiene prioridad
    if (widget.manualUserRole != null || widget.manualUserName != null) {
      return _buildUserInfoWidget(
        role: widget.manualUserRole ?? '',
        name: widget.manualUserName ?? '',
        context: context,
      );
    }

    // 2. Usuario automático con cache
    if (widget.showUserInfo) {
      if (_isLoading) {
        return _buildLoadingUserInfo();
      }

      if (_cachedUserInfo != null && _cachedUserInfo!.isNotEmpty) {
        return _buildUserInfoWidget(
          role: _cachedUserInfo!['role'] ?? '',
          name: _cachedUserInfo!['name'] ?? '',
          context: context,
          userData: _cachedUserInfo,
        );
      }

      return const SizedBox.shrink();
    }

    // 3. Leading personalizado
    if (widget.leftWidget != null) {
      return GestureDetector(
        onTap: widget.onLeftTap,
        child: widget.leftWidget!,
      );
    }

    // 4. Icono personalizado
    if (widget.leftIcon != null) {
      final effectiveForegroundColor = widget.foregroundColor ?? widget.iconColor ?? AppColors.blue3;
      return IconButton(
        icon: Icon(
          widget.leftIcon!,
          color: effectiveForegroundColor,
        ),
        onPressed: widget.onLeftTap,
      );
    }

    // 5. Path de imagen
    if (widget.leftIconPath != null) {
      final effectiveForegroundColor = widget.foregroundColor ?? widget.iconColor ?? AppColors.blue3;
      return GestureDetector(
        onTap: widget.onLeftTap,
        child: Container(
          margin: const EdgeInsets.all(8),
          child: Image.asset(
            widget.leftIconPath!,
            width: 20,
            height: 20,
            color: effectiveForegroundColor,
          ),
        ),
      );
    }

    // 6. Botón de regreso por defecto
    if (Navigator.of(context).canPop()) {
      final effectiveForegroundColor = widget.foregroundColor ?? widget.iconColor ?? AppColors.blue3;
      return IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: effectiveForegroundColor,
          size: 20,
        ),
        onPressed: widget.onLeftTap ?? () => Navigator.of(context).pop(),
      );
    }

    return null;
  }

  /// Widget de información del usuario
  Widget _buildUserInfoWidget({
    required String role,
    required String name,
    required BuildContext context,
    Map<String, String>? userData,
  }) {
    final effectiveForegroundColor = widget.foregroundColor ?? widget.iconColor ?? AppColors.blue3;

    return GestureDetector(
      onTap: () {
        if (widget.onUserInfoTap != null) {
          widget.onUserInfoTap!();
        } else if (userData != null) {
          _showUserMenu(context, userData);
        }
      },
      child: Container(
        padding: const EdgeInsets.only(left: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: effectiveForegroundColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: effectiveForegroundColor.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: Icon(Icons.person, size: 12, color: effectiveForegroundColor),
            ),
            const SizedBox(width: 8),
            // Rol y Nombre
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (role.isNotEmpty)
                    Text(
                      role,
                      style:
                          widget.userInfoStyle ??
                          AppFont.oxygenBold.style(
                            fontSize: 8,
                            color: effectiveForegroundColor,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (name.isNotEmpty)
                    Text(
                      name,
                      style: AppFont.oxygenRegular.style(
                        fontSize: 7,
                        color: effectiveForegroundColor.withValues(alpha: 0.7),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingUserInfo() {
    return Container(
      padding: const EdgeInsets.only(left: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 40,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    if (widget.logoPath == null) return const SizedBox.shrink();

    final path = widget.logoPath!;
    final size = widget.logoSize;

    Widget logoWidget;

    if (path.endsWith('.json')) {
      // Lottie
      logoWidget = Lottie.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    } else if (path.endsWith('.svg')) {
      // SVG
      logoWidget = SvgPicture.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    } else {
      // Imagen normal (png, jpg, etc.)
      logoWidget = Image.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }

    return Container(
      margin: const EdgeInsets.only(right: 20),
      child: Center(child: logoWidget),
    );
  }

  /// Combina las actions personalizadas con el logo
  List<Widget>? _buildActions() {
    final List<Widget> actionsList = [];

    // Agregar actions personalizadas primero
    if (widget.actions != null) {
      actionsList.addAll(widget.actions!);
    }

    // Agregar logo al final si está habilitado
    if (widget.showLogo && widget.logoPath != null) {
      actionsList.add(_buildLogo());
    }

    return actionsList.isEmpty ? null : actionsList;
  }

  // === HELPERS ===

  double? _getLeadingWidth() {
    if (widget.showUserInfo ||
        widget.manualUserRole != null ||
        widget.manualUserName != null) {
      return 200;
    }
    return null;
  }

  SystemUiOverlayStyle get _defaultSystemOverlayStyle {
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    );
  }

  // === MENÚ DE USUARIO SIMPLIFICADO ===

  void _showUserMenu(BuildContext context, Map<String, String> userData) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (modalContext) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.4,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.blue3.withValues(alpha: 0.1),
                      child: const Icon(Icons.person, size: 18, color: AppColors.blue1),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userData['name'] ?? '',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            userData['email'] ?? '',
                            style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 5),
                          // Rol del usuario
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.blue3.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              userData['role'] ?? '',
                              style: TextStyle(
                                fontSize: 8,
                                color: AppColors.blue3,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                const Divider(),
                const SizedBox(height: 5),

                // Opciones
                Theme(
                  data: Theme.of(context).copyWith(
                    listTileTheme: ListTileThemeData(
                      visualDensity: VisualDensity.compact,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      dense: true,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Mi Perfil
                      ListTile(
                        leading: const Icon(Icons.person_outline, size: 18, color: AppColors.blue3),
                        title: const Text('Mi Perfil', style: TextStyle(fontSize: 12)),
                        onTap: () {
                          Navigator.pop(modalContext);
                          // TODO: Navegar a perfil
                        },
                      ),

                      // Configuración
                      ListTile(
                        leading: const Icon(Icons.settings_outlined, size: 18, color: AppColors.blue3),
                        title: const Text('Configuración', style: TextStyle(fontSize: 12)),
                        onTap: () {
                          Navigator.pop(modalContext);
                          // TODO: Navegar a configuración
                        },
                      ),
                    ],
                  ),
                ),

                const Divider(),

                // Logout
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  leading: const Icon(Icons.logout, size: 18, color: AppColors.red),
                  title: const Text(
                    'Cerrar Sesión',
                    style: TextStyle(fontSize: 12, color: AppColors.red),
                  ),
                  onTap: () async {
                    Navigator.pop(modalContext);
                    await _handleLogout(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      final logoutUseCase = locator<LogoutUseCase>();
      await logoutUseCase(NoParams());

      if (context.mounted) {
        // Navegar al login
        // TODO: Ajusta la ruta según tu configuración de navegación
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }
}
