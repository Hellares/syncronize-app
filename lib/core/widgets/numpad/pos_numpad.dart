import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import 'numpad_controller.dart';

/// Acción configurable del numpad (ej. "Exacto", "Cobrar", "Atrás", "Aplicar").
///
/// Las acciones son la API de extensión del numpad: cualquier pantalla
/// (cobro, arqueo, caja chica, ajuste, etc.) define las suyas con su
/// propia lógica. El numpad solo las renderiza con estilo consistente.
class NumpadAction {
  final String label;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;
  /// Botón con estilo destacado (verde elevado, ej. acción primaria "Cobrar").
  final bool destacado;
  /// Si false, deshabilita visualmente y bloquea el tap.
  final bool enabled;
  /// Si true, reemplaza icono+label por un spinner (acción en progreso).
  final bool loading;

  const NumpadAction({
    required this.label,
    this.icon,
    this.color,
    this.onTap,
    this.destacado = false,
    this.enabled = true,
    this.loading = false,
  });
}

/// Teclado numérico personalizado para POS.
///
/// Reutilizable en cobro de venta rápida, arqueo de caja, caja chica,
/// ajustes manuales, etc. El widget es agnóstico al uso: recibe un
/// [NumpadController] y emite los cambios a través de él.
///
/// Layout (en orden):
///  - Chips de [quickAmounts] (opcional, default S/10/20/50/100/200).
///  - Grid 4x4 con dígitos 0-9, "00", ".", ⌫, C.
///  - Barra de [acciones] (opcional, ej. "Exacto").
///
/// El teclado se diseña para uso con dedo: botones grandes, espaciado
/// generoso, feedback táctil.
class PosNumpad extends StatelessWidget {
  final NumpadController controller;

  /// Montos para chips rápidos. Si null → no se muestran chips.
  final List<double>? quickAmounts;

  /// Acciones inferiores (ej. "Exacto", "Cobrar").
  final List<NumpadAction> acciones;

  /// Etiqueta superior opcional (ej. "Pago efectivo", "Conteo S/100").
  final String? titulo;

  /// Color de los botones de dígito.
  final Color colorDigito;

  /// Color del botón backspace.
  final Color colorBorrar;

  /// Si false, oculta el botón "00" (default true).
  final bool mostrarDobleZero;

  /// Si false, oculta el botón ".".
  final bool permiteDecimal;

  const PosNumpad({
    super.key,
    required this.controller,
    this.quickAmounts = const [10, 20, 50, 100, 200],
    this.acciones = const [],
    this.titulo,
    this.colorDigito = const Color(0xFFF5F7FA),
    this.colorBorrar = const Color(0xFFFFE8E8),
    this.mostrarDobleZero = true,
    this.permiteDecimal = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (titulo != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.blue1,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      titulo!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            if (quickAmounts != null && quickAmounts!.isNotEmpty)
              _QuickAmountsRow(
                amounts: quickAmounts!,
                onTap: controller.addAmount,
              ),
            if (quickAmounts != null && quickAmounts!.isNotEmpty)
              const SizedBox(height: 6),
            _DigitGrid(
              controller: controller,
              colorDigito: colorDigito,
              colorBorrar: colorBorrar,
              mostrarDobleZero: mostrarDobleZero,
              permiteDecimal: permiteDecimal,
            ),
            if (acciones.isNotEmpty) ...[
              const SizedBox(height: 6),
              _AccionesRow(acciones: acciones),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickAmountsRow extends StatelessWidget {
  final List<double> amounts;
  final void Function(double) onTap;

  const _QuickAmountsRow({required this.amounts, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: amounts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final v = amounts[i];
          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              HapticFeedback.selectionClick();
              onTap(v);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.blue1.withValues(alpha: 0.08),
                border: Border.all(color: AppColors.blue1.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                '+ S/ ${v.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blue1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DigitGrid extends StatelessWidget {
  final NumpadController controller;
  final Color colorDigito;
  final Color colorBorrar;
  final bool mostrarDobleZero;
  final bool permiteDecimal;

  const _DigitGrid({
    required this.controller,
    required this.colorDigito,
    required this.colorBorrar,
    required this.mostrarDobleZero,
    required this.permiteDecimal,
  });

  @override
  Widget build(BuildContext context) {
    // Layout adaptativo estilo calculadora POS. La columna derecha
    // concentra las acciones destructivas (⌫, C) con color distintivo.
    // Cuando una celda no aplica (sin decimal o sin "00"), las vecinas
    // se expanden en lugar de dejar huecos vacíos.
    //
    // Layout default (ambos true):
    //   [7][8][9][⌫]
    //   [4][5][6][C]
    //   [1][2][3][.]
    //   [00][__0__][⌫]   ← 0 ocupa 2 cols
    //
    // Layout doc (ambos false):
    //   [7][8][9][⌫]
    //   [4][5][6][C]
    //   [1][2][3][⌫]     ← 2do ⌫ por alcance (más fácil de tocar)
    //   [_____0_____][⌫] ← 0 ocupa 3 cols
    final accionBorrar = _accion(
      icon: Icons.backspace_outlined,
      color: colorBorrar,
      onTap: controller.backspace,
      onLongPress: controller.clear,
      tooltip: 'Borrar (mantener para limpiar todo)',
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _fila([
          _c(_digito('7')),
          _c(_digito('8')),
          _c(_digito('9')),
          _c(accionBorrar),
        ]),
        _fila([
          _c(_digito('4')),
          _c(_digito('5')),
          _c(_digito('6')),
          _c(_accion(
            label: 'C',
            color: colorBorrar,
            onTap: controller.clear,
            destacado: true,
            tooltip: 'Limpiar todo',
          )),
        ]),
        _fila([
          _c(_digito('1')),
          _c(_digito('2')),
          _c(_digito('3')),
          // En modo decimal: punto. En modo doc: 2do backspace para alcance.
          _c(permiteDecimal ? _puntoDecimal() : accionBorrar),
        ]),
        _fila(_filaCero()),
      ],
    );
  }

  /// Fila inferior adaptativa según los toggles. El "0" se expande a las
  /// celdas libres para acceso rápido (es el dígito más usado).
  List<_Cell> _filaCero() {
    final accionBorrar = _accion(
      icon: Icons.backspace_outlined,
      color: colorBorrar,
      onTap: controller.backspace,
      onLongPress: controller.clear,
      tooltip: 'Borrar',
    );
    if (mostrarDobleZero) {
      // [00][__0__][⌫]
      return [
        _c(_dobleZero()),
        _c(_digito('0'), flex: 2),
        _c(accionBorrar),
      ];
    }
    // [_____0_____][⌫]
    return [
      _c(_digito('0'), flex: 3),
      _c(accionBorrar),
    ];
  }

  /// Helper para crear celdas con flex.
  _Cell _c(Widget w, {int flex = 1}) => _Cell(w, flex);

  Widget _fila(List<_Cell> cells) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: cells
            .map((c) => Expanded(
                  flex: c.flex,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: c.widget,
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _digito(String d) {
    return _NumpadButton(
      label: d,
      color: colorDigito,
      onTap: () {
        HapticFeedback.selectionClick();
        controller.appendDigit(d);
      },
    );
  }

  Widget _puntoDecimal() {
    return _NumpadButton(
      label: '.',
      color: colorDigito,
      onTap: () {
        HapticFeedback.selectionClick();
        controller.appendDecimal();
      },
    );
  }

  Widget _dobleZero() {
    return _NumpadButton(
      label: '00',
      color: colorDigito,
      onTap: () {
        HapticFeedback.selectionClick();
        controller.appendDigits('00');
      },
    );
  }

  Widget _accion({
    String? label,
    IconData? icon,
    required Color color,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    String? tooltip,
    bool destacado = false,
  }) {
    return _NumpadButton(
      label: label,
      icon: icon,
      color: color,
      tooltip: tooltip,
      destacado: destacado,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      onLongPress: onLongPress,
    );
  }
}

class _Cell {
  final Widget widget;
  final int flex;
  const _Cell(this.widget, this.flex);
}

class _NumpadButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final String? tooltip;
  final bool destacado;

  const _NumpadButton({
    this.label,
    this.icon,
    required this.color,
    required this.onTap,
    this.onLongPress,
    this.tooltip,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    final isClear = label == 'C';
    final fg = destacado || isClear ? Colors.red.shade700 : Colors.black87;
    final btn = Material(
      color: color,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          height: 35,
          alignment: Alignment.center,
          child: icon != null
              ? Icon(icon,
                  size: 20, color: destacado ? Colors.red.shade700 : Colors.black87)
              : Text(
                  label ?? '',
                  style: TextStyle(
                    fontSize: destacado ? 18 : 16,
                    fontWeight:
                        destacado ? FontWeight.w800 : FontWeight.w600,
                    color: fg,
                    letterSpacing: destacado ? 0.5 : 0,
                  ),
                ),
        ),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip!, child: btn) : btn;
  }
}

class _AccionesRow extends StatelessWidget {
  final List<NumpadAction> acciones;

  const _AccionesRow({required this.acciones});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: acciones.map((a) {
        final fg = a.destacado || a.color != null
            ? Colors.white
            : AppColors.blue1;
        final bg = a.color ??
            (a.destacado
                ? Colors.green.shade500
                : AppColors.blue1.withValues(alpha: 0.1));
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: ElevatedButton(
              onPressed: (a.enabled && !a.loading) ? a.onTap : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: bg,
                foregroundColor: fg,
                disabledBackgroundColor: Colors.grey.shade200,
                disabledForegroundColor: Colors.grey.shade500,
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: a.destacado ? 1 : 0,
              ),
              child: a.loading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: fg,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (a.icon != null) ...[
                          Icon(a.icon, size: 16),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            a.label,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
