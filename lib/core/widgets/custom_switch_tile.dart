import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_colors.dart';

import 'custom_switch.dart';

/// Item de configuración con título + subtítulo a la izquierda y un
/// [CustomSwitch] a la derecha.
///
/// Estilo unificado (blue1/blanco por defecto). Si necesitás un acento
/// distinto (verde para confirmaciones, indigo para insumos, etc),
/// pasá [activeColor].
///
/// **Nota:** los parámetros `activeTrackColor`, `inactiveTrackColor`,
/// `trackOutlineColor` y `trackOutlineWidth` se conservan por
/// compatibilidad con call sites existentes, pero se ignoran — el estilo
/// está fijo en el `CustomSwitch` para mantener consistencia visual en
/// toda la app.
class CustomSwitchTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Color del track ON, borde y thumb OFF. Default `AppColors.blue1`.
  final Color? activeColor;

  /// @deprecated Ignorado — el track ON usa [activeColor]. Se mantiene
  /// para compatibilidad con call sites antiguos.
  final Color? activeTrackColor;

  /// @deprecated Ignorado — el track OFF es siempre blanco. Se mantiene
  /// para compatibilidad con call sites antiguos.
  final Color? inactiveTrackColor;

  /// @deprecated Ignorado — el borde usa [activeColor]. Se mantiene
  /// para compatibilidad con call sites antiguos.
  final Color? trackOutlineColor;

  /// @deprecated Ignorado — el borde es siempre de 1 px. Se mantiene
  /// para compatibilidad con call sites antiguos.
  final double? trackOutlineWidth;

  final EdgeInsetsGeometry? padding;
  final double? height;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  /// Escala del switch dentro del tile. Default 0.7 (compacto).
  final double scale;

  const CustomSwitchTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.activeColor,
    this.activeTrackColor,
    this.inactiveTrackColor,
    this.trackOutlineColor,
    this.trackOutlineWidth,
    this.padding,
    this.height,
    this.titleStyle,
    this.subtitleStyle,
    this.scale = 0.7,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onChanged != null;
    final Color accent = activeColor ?? AppColors.blue1;

    return Container(
      height: height,
      padding:
          padding ?? const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: titleStyle ??
                      TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isEnabled
                            ? AppColors.blue1
                            : AppColors.blue1.withValues(alpha: 0.5),
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: subtitleStyle ??
                        TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                          height: 1.2,
                        ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          CustomSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: accent,
            scale: scale,
          ),
        ],
      ),
    );
  }
}
