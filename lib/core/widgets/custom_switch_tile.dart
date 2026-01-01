import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_colors.dart';

class CustomSwitchTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final Color? activeTrackColor;
  final Color? inactiveTrackColor;
  final Color? trackOutlineColor;
  final double? trackOutlineWidth;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
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

    return Container(
      height: height,
      padding: padding ?? const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
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
                            : AppColors.blue1.withValues(alpha:0.5),
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
          Transform.scale(
            scale: scale,
            child: Theme(
              data: ThemeData(
                useMaterial3: true,
                switchTheme: SwitchThemeData(
                  thumbColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return activeColor ?? AppColors.blue1;
                    }
                    return null;
                  }),
                  trackColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return activeTrackColor ?? activeColor?.withValues(alpha: 0.5);
                    }
                    return inactiveTrackColor;
                  }),
                  trackOutlineColor: trackOutlineColor != null
                      ? WidgetStateProperty.all(trackOutlineColor)
                      : null,
                  trackOutlineWidth: trackOutlineWidth != null
                      ? WidgetStateProperty.all(trackOutlineWidth)
                      : null,
                ),
              ),
              child: Switch(
                value: value,
                onChanged: onChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
