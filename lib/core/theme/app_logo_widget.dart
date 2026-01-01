import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/theme/app_colors.dart';

/// Enum para definir los diferentes estilos de logo
enum LogoStyle {
  /// Logo simple sin decoración
  simple,
  
  /// Logo con fondo circular y sombra
  circularBackground,
  
  /// Logo con efecto de resplandor (glow)
  glowEffect,
  
  /// Logo y texto en horizontal
  horizontal,
  
  /// Logo dentro de una card flotante
  floatingCard,
  
  /// Logo con fondo degradado circular
  gradientBackground,
  
  /// Logo con animación Hero
  heroAnimation,
  
  /// Logo compacto con título y subtítulo
  compact,
  
  /// Logo con elementos decorativos alrededor
  decorative,
}

/// Widget reutilizable para mostrar el logo de la app con diferentes estilos
/// 
/// Uso básico:
/// ```dart
/// AppLogo(
///   logoPath: 'assets/img/logo.svg',
///   style: LogoStyle.circularBackground,
/// )
/// ```
class AppLogo extends StatelessWidget {
  /// Ruta del archivo SVG del logo
  final String logoPath;
  
  /// Estilo de presentación del logo
  final LogoStyle style;
  
  /// Altura del logo (opcional, usa valores por defecto según el estilo)
  final double? logoSize;
  
  /// Nombre de la app (opcional, se muestra según el estilo)
  final String? appName;
  
  /// Subtítulo (opcional, se muestra según el estilo)
  final String? subtitle;
  
  /// Color primario para decoraciones
  final Color? primaryColor;
  
  /// Color secundario para decoraciones
  final Color? secondaryColor;
  
  /// Estilo de texto para el nombre de la app
  final TextStyle? appNameStyle;
  
  /// Estilo de texto para el subtítulo
  final TextStyle? subtitleStyle;
  
  /// Tag para Hero animation (solo usado en heroAnimation style)
  final String heroTag;
  
  /// Colorear el logo SVG (opcional)
  final Color? logoColor;

  const AppLogo({
    super.key,
    required this.logoPath,
    this.style = LogoStyle.simple,
    this.logoSize,
    this.appName,
    this.subtitle,
    this.primaryColor,
    this.secondaryColor,
    this.appNameStyle,
    this.subtitleStyle,
    this.heroTag = 'app_logo',
    this.logoColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectivePrimaryColor = primaryColor ?? theme.primaryColor;
    final effectiveSecondaryColor = secondaryColor ?? Colors.blue.shade600;
    
    final defaultAppNameStyle = appNameStyle ?? 
        theme.textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: effectivePrimaryColor,
          fontFamily: AppFonts.getFontFamily(AppFont.airstrikeBold3d),
          fontSize: 18
        );
       
    
    final defaultSubtitleStyle = subtitleStyle ?? 
        theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.blue2,
          fontFamily: AppFonts.getFontFamily(AppFont.pirulentBold),
          fontSize: 8
        );

    switch (style) {
      case LogoStyle.simple:
        return _buildSimple(defaultAppNameStyle, defaultSubtitleStyle);
        
      case LogoStyle.circularBackground:
        return _buildCircularBackground(
          effectivePrimaryColor,
          defaultAppNameStyle,
          defaultSubtitleStyle,
        );
        
      case LogoStyle.glowEffect:
        return _buildGlowEffect(
          effectivePrimaryColor,
          defaultAppNameStyle,
          defaultSubtitleStyle,
        );
        
      case LogoStyle.horizontal:
        return _buildHorizontal(
          defaultAppNameStyle,
          defaultSubtitleStyle,
        );
        
      case LogoStyle.floatingCard:
        return _buildFloatingCard(
          defaultAppNameStyle,
          defaultSubtitleStyle,
        );
        
      case LogoStyle.gradientBackground:
        return _buildGradientBackground(
          effectivePrimaryColor,
          effectiveSecondaryColor,
          defaultAppNameStyle,
          defaultSubtitleStyle,
        );
        
      case LogoStyle.heroAnimation:
        return _buildHeroAnimation(
          defaultAppNameStyle,
          defaultSubtitleStyle,
        );
        
      case LogoStyle.compact:
        return _buildCompact(theme, effectivePrimaryColor);
        
      case LogoStyle.decorative:
        return _buildDecorative(
          effectivePrimaryColor,
          defaultAppNameStyle,
          defaultSubtitleStyle,
        );
    }
  }

  // ========== Variante 1: Simple ==========
  Widget _buildSimple(TextStyle? appNameStyle, TextStyle? subtitleStyle) {
    final size = logoSize ?? 80;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSvgLogo(height: size, width: size),
        if (appName != null) ...[
          const SizedBox(height: 16),
          Text(
            appName!,
            style: appNameStyle,
            textAlign: TextAlign.center,
          ),
        ],
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: subtitleStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  // ========== Variante 2: Circular Background ==========
  Widget _buildCircularBackground(
    Color primaryColor,
    TextStyle? appNameStyle,
    TextStyle? subtitleStyle,
  ) {
    final containerSize = logoSize ?? 100;
    final padding = containerSize * 0.2;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: containerSize,
          height: containerSize,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha:0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: EdgeInsets.all(padding),
          child: _buildSvgLogo(fit: BoxFit.contain),
        ),
        if (appName != null) ...[
          const SizedBox(height: 20),
          Text(
            appName!,
            style: appNameStyle,
            textAlign: TextAlign.center,
          ),
        ],
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: subtitleStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  // ========== Variante 3: Glow Effect ==========
  Widget _buildGlowEffect(
    Color primaryColor,
    TextStyle? appNameStyle,
    TextStyle? subtitleStyle,
  ) {
    final size = logoSize ?? 90;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: _buildSvgLogo(height: size, width: size),
        ),
        if (appName != null) ...[
          const SizedBox(height: 5),
          Text(
            appName!,
            style: appNameStyle,
            textAlign: TextAlign.center,
          ),
        ],
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: subtitleStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  // ========== Variante 4: Horizontal ==========
  Widget _buildHorizontal(TextStyle? appNameStyle, TextStyle? subtitleStyle) {
    final size = logoSize ?? 50;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSvgLogo(height: size, width: size),
            if (appName != null) ...[
              const SizedBox(width: 12),
              Text(
                appName!,
                style: appNameStyle,
              ),
            ],
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: subtitleStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  // ========== Variante 5: Floating Card ==========
  Widget _buildFloatingCard(
    TextStyle? appNameStyle,
    TextStyle? subtitleStyle,
  ) {
    final size = logoSize ?? 80;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: _buildSvgLogo(height: size, width: size),
          ),
        ),
        if (appName != null) ...[
          const SizedBox(height: 20),
          Text(
            appName!,
            style: appNameStyle,
            textAlign: TextAlign.center,
          ),
        ],
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: subtitleStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  // ========== Variante 6: Gradient Background ==========
  Widget _buildGradientBackground(
    Color primaryColor,
    Color secondaryColor,
    TextStyle? appNameStyle,
    TextStyle? subtitleStyle,
  ) {
    final containerSize = logoSize ?? 120;
    final padding = containerSize * 0.208;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: containerSize,
          height: containerSize,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryColor,
                secondaryColor,
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha:0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: EdgeInsets.all(padding),
          child: _buildSvgLogo(
            fit: BoxFit.contain,
            color: Colors.white,
          ),
        ),
        if (appName != null) ...[
          const SizedBox(height: 24),
          Text(
            appName!,
            style: appNameStyle,
            textAlign: TextAlign.center,
          ),
        ],
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: subtitleStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  // ========== Variante 7: Hero Animation ==========
  Widget _buildHeroAnimation(
    TextStyle? appNameStyle,
    TextStyle? subtitleStyle,
  ) {
    final size = logoSize ?? 80;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Hero(
          tag: heroTag,
          child: _buildSvgLogo(height: size, width: size),
        ),
        if (appName != null) ...[
          const SizedBox(height: 16),
          Text(
            appName!,
            style: appNameStyle,
            textAlign: TextAlign.center,
          ),
        ],
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: subtitleStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  // ========== Variante 8: Compact ==========
  Widget _buildCompact(ThemeData theme, Color primaryColor) {
    final size = logoSize ?? 60;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSvgLogo(height: size, width: size),
        if (appName != null) ...[
          const SizedBox(height: 12),
          Text(
            appName!,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  // ========== Variante 9: Decorative ==========
  Widget _buildDecorative(
    Color primaryColor,
    TextStyle? appNameStyle,
    TextStyle? subtitleStyle,
  ) {
    final outerSize = logoSize ?? 140;
    final containerSize = outerSize * 0.643;
    final logoContainerSize = containerSize * 0.714;
    final padding = logoContainerSize * 0.2;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Círculo decorativo de fondo
            Container(
              width: outerSize,
              height: outerSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withValues(alpha:0.1),
              ),
            ),
            // Logo en contenedor blanco
            Container(
              width: containerSize,
              height: containerSize,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.all(padding),
              child: _buildSvgLogo(fit: BoxFit.contain),
            ),
          ],
        ),
        if (appName != null) ...[
          const SizedBox(height: 20),
          Text(
            appName!,
            style: appNameStyle,
            textAlign: TextAlign.center,
          ),
        ],
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: subtitleStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  // ========== Helper para construir el SVG ==========
  Widget _buildSvgLogo({
    double? height,
    double? width,
    BoxFit? fit,
    Color? color,
  }) {
    final effectiveColor = color ?? logoColor;
    
    // Si se especifican height y width, usar contain para mantener aspect ratio
    final effectiveFit = fit ?? 
        (height != null && width != null ? BoxFit.contain : BoxFit.none);
    
    return SvgPicture.asset(
      logoPath,
      height: height,
      width: width,
      fit: effectiveFit,
      colorFilter: effectiveColor != null
          ? ColorFilter.mode(effectiveColor, BlendMode.srcIn)
          : null,
      // Prevenir que el SVG se deforme
      allowDrawingOutsideViewBox: false,
    );
  }
}