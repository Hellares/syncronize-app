
import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'app_fonts.dart';


/// Título principal (ej: AppBar, pantallas)
class AppTitle extends StatelessWidget {
  final String text;
  final AppFont font;
  final Color? color;
  final double? fontSize;
  final TextAlign? textAlign;

  const AppTitle(
    this.text, {
    super.key,
    this.font = AppFont.oxygenBold,
    this.color,
    this.fontSize,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: font.title.copyWith(
        color: color ?? AppColors.blue3,
        fontSize: fontSize,
      ),
      textAlign: textAlign,
    );
  }
}

/// Subtítulo (ej: secciones dentro de pantallas)
class AppSubtitle extends StatelessWidget {
  final String text;
  final AppFont font;
  final Color? color;
  final double? fontSize;
  final TextAlign? textAlign;
  final TextStyle? textStyle;

  const AppSubtitle(
    this.text, {
    super.key,
    this.font = AppFont.oxygenBold,
    this.color,
    this.fontSize,
    this.textAlign,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: font.subtitle.copyWith(
        color: color ?? AppColors.blue3,
        fontSize: fontSize,
      ),
      textAlign: textAlign,
    );
  }
}

/// Texto pequeño tipo caption
class CaptionItem {
  final IconData? icon;
  final String text;

  CaptionItem({required this.icon, required this.text});
}

class AppCaption extends StatelessWidget {
  final List<CaptionItem> items;
  final AppFont font;
  final Color? color;
  final double? fontSize;
  final TextAlign? textAlign;
  final double spacing; // Espacio entre cada item

  const AppCaption({
    super.key,
    required this.items,
    this.font = AppFont.oxygenRegular,
    this.color,
    this.fontSize,
    this.textAlign,
    this.spacing = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: items
          .map((item) => Row(
                children: [
                  Icon(item.icon, size: 12, color: color ?? AppColors.blueGrey),
                  const SizedBox(width: 4),
                  Text(
                    item.text,
                    style: font.caption.copyWith(
                      color: color ?? AppColors.blueGrey,
                      fontSize: fontSize,
                    ),
                  ),
                  SizedBox(width: spacing),
                ],
              ))
          .toList(),
    );
  }
}

/// Texto para botones
class AppButtonText extends StatelessWidget {
  final String text;
  final AppFont font;
  final Color? color;
  final double? fontSize;
  final TextAlign? textAlign;

  const AppButtonText(
    this.text, {
    super.key,
    this.font = AppFont.oxygenBold,
    this.color,
    this.fontSize,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: font.button.copyWith(
        color: color ?? Colors.white,
        fontSize: fontSize,
      ),
      textAlign: textAlign,
    );
  }

  
}

class AppHeadingText extends StatelessWidget {
  final String text;
  final AppFont font;
  final Color? color;
  final double? fontSize;
  final TextAlign? textAlign;

  const AppHeadingText(
    this.text, {
    super.key,
    this.font = AppFont.oxygenBold,
    this.color,
    this.fontSize,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: font.heading.copyWith(
        color: color ?? AppColors.blue3,
        fontSize: fontSize,
      ),
      textAlign: textAlign,
    );
  }
}

class AppLabelText extends StatelessWidget {
  final String text;
  final AppFont font;
  final Color? color;
  final double? fontSize;
  final TextAlign? textAlign;

  const AppLabelText(
    this.text, {
    super.key,
    this.font = AppFont.oxygenRegular,
    this.color,
    this.fontSize,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: font.label.copyWith(
        color: color ?? AppColors.blue3,
        fontSize: fontSize,
      ),
      textAlign: textAlign,
    );
  }

  
}