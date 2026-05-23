import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Switch compacto con el estilo estándar del formulario de productos
/// (y demás formularios donde se necesite un toggle sin título embebido).
///
/// **OFF**: track blanco, borde `activeColor` (1 px), thumb `activeColor`.
/// **ON**: track `activeColor`, borde `activeColor` (1 px), thumb blanco.
///
/// Escalado a `0.7` por defecto — mismo tamaño que los switches de
/// "Producto Combo" / "Producto con Variantes" del `CustomSwitchTile`.
///
/// Para casos con título + subtítulo + switch (item de configuración
/// completo) usar `CustomSwitchTile` en su lugar.
///
/// Uso básico:
/// ```dart
/// CustomSwitch(
///   value: _expandido,
///   onChanged: (v) => setState(() => _expandido = v),
/// )
/// ```
class CustomSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Color del track cuando está ON y del borde / thumb cuando está OFF.
  /// Por defecto `AppColors.blue1`. Cambialo para tener variantes en
  /// otros formularios (ej. `AppColors.green` para confirmaciones).
  final Color activeColor;

  /// Escala del switch — 0.7 lo deja compacto. Subí a 1.0 para tamaño
  /// nativo de Material.
  final double scale;

  const CustomSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor = AppColors.blue1,
    this.scale = 0.7,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Theme(
        data: ThemeData(
          useMaterial3: true,
          switchTheme: SwitchThemeData(
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.white;
              }
              return activeColor;
            }),
            trackColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return activeColor;
              }
              return Colors.white;
            }),
            trackOutlineColor: WidgetStateProperty.all(activeColor),
            trackOutlineWidth: WidgetStateProperty.all(1),
          ),
        ),
        child: Switch(
          value: value,
          onChanged: onChanged,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
