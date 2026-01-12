import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_colors.dart';

class CustomCheckboxTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final Color? checkColor;
  final Color? borderColor;
  final double? borderWidth;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final double scale;
  final OutlinedBorder? shape;

  const CustomCheckboxTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.activeColor,
    this.checkColor,
    this.borderColor,
    this.borderWidth,
    this.padding,
    this.height,
    this.titleStyle,
    this.subtitleStyle,
    this.scale = 0.8,
    this.shape,
  });

  @override
  Widget build(BuildContext context) {
    final callback = onChanged;
    final bool isEnabled = callback != null;

    return InkWell(
      onTap: isEnabled ? () => callback.call(!value) : null,
      borderRadius: BorderRadius.circular(4),
      child: Container(
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
            Transform.scale(
              scale: scale,
              child: Theme(
                data: ThemeData(
                  useMaterial3: true,
                  checkboxTheme: CheckboxThemeData(
                    fillColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return activeColor ?? AppColors.blue1;
                      }
                      return null;
                    }),
                    checkColor: WidgetStateProperty.all(
                      checkColor ?? Colors.white,
                    ),
                    side: borderColor != null || borderWidth != null
                        ? WidgetStateBorderSide.resolveWith((states) {
                            return BorderSide(
                              color: borderColor ?? Colors.grey[400]!,
                              width: borderWidth ?? 1.5,
                            );
                          })
                        : null,
                    shape: shape ??
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                  ),
                ),
                child: Checkbox(
                  value: value,
                  onChanged: callback != null
                    ? (bool? val) => callback(val ?? false)
                    : null,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
