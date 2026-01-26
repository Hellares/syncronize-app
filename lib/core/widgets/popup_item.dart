import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';

enum ActionMenuType { edit, delete, share, disable, stock, stockPorSede, alertasStock, transferencias }

class ActionMenuItem {
  final ActionMenuType type;
  final String label;
  final IconData icon;
  final Color color;

  final bool enabled;

  // confirmación opcional
  final bool requireConfirm;
  final String confirmTitle;
  final String confirmMessage;
  final String confirmOkText;
  final String confirmCancelText;

  final VoidCallback? onTap;

  const ActionMenuItem({
    required this.type,
    required this.label,
    required this.icon,
    required this.color,
    this.enabled = true,
    this.requireConfirm = false,
    this.confirmTitle = 'Confirmar',
    this.confirmMessage = '¿Estás seguro?',
    this.confirmOkText = 'Sí',
    this.confirmCancelText = 'Cancelar',
    this.onTap,
  });
}

/// Menú custom (Container + Overlay)
/// - Se dibuja ENCIMA del icono (tapa los puntos)
/// - Tocar fuera lo cierra
class CustomActionMenu extends StatefulWidget {
  final List<ActionMenuItem> items;
  final ValueChanged<ActionMenuType>? onSelected;

  // Botón (tres puntos)
  final IconData triggerIcon;
  final double triggerIconSize;
  final Color? triggerIconColor;

  // Card del menú
  final double menuWidth;
  final double borderRadius;
  final EdgeInsetsGeometry menuPadding;
  final bool showDividers;
  final List<BoxShadow>? boxShadow;
  final Color backgroundColor;

  // Items
  final double itemHeight;
  final double itemIconSize;
  final double fontSize;
  final double gap;
  final EdgeInsetsGeometry itemPadding;

  // Margen respecto a bordes de pantalla
  final double screenMargin;

  // Ajuste fino vertical (si lo quieres pegadísimo o un pelín arriba/abajo)
  final double yNudge;

  const CustomActionMenu({
    super.key,
    required this.items,
    this.onSelected,
    this.triggerIcon = Icons.more_vert,
    this.triggerIconSize = 16,
    this.triggerIconColor,
    this.menuWidth = 140,
    this.borderRadius = 10,
    this.menuPadding = const EdgeInsets.symmetric(vertical: 6),
    this.showDividers = true,
    this.boxShadow,
    this.backgroundColor = Colors.white,
    this.itemHeight = 34,
    this.itemIconSize = 16,
    this.fontSize = 9,
    this.gap = 8,
    this.itemPadding = const EdgeInsets.symmetric(horizontal: 8),
    this.screenMargin = 8,
    this.yNudge = 0, // 👈 pon -2 o +2 si quieres micro ajuste
  }) : assert(items.length <= 4, 'Máximo 4 items');

  @override
  State<CustomActionMenu> createState() => _CustomActionMenuState();
}

class _CustomActionMenuState extends State<CustomActionMenu> {
  final GlobalKey _triggerKey = GlobalKey();
  OverlayEntry? _entry;

  @override
  void dispose() {
    _removeMenu();
    super.dispose();
  }

  void _toggleMenu() {
    if (_entry != null) {
      _removeMenu();
    } else {
      _showMenu();
    }
  }

  void _removeMenu() {
    _entry?.remove();
    _entry = null;
  }

  double _estimatedMenuHeight() {
    final pad = (widget.menuPadding is EdgeInsets)
        ? (widget.menuPadding as EdgeInsets)
        : EdgeInsets.zero;

    final dividers = widget.showDividers ? (widget.items.length - 1) : 0;

    return (widget.itemHeight * widget.items.length) + dividers + pad.top + pad.bottom;
  }

  Rect _getTriggerRect() {
    final renderBox = _triggerKey.currentContext!.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    return offset & renderBox.size;
  }

  void _showMenu() {
    if (widget.items.isEmpty) return;

    final overlay = Overlay.of(context, rootOverlay: true);
    final triggerRect = _getTriggerRect();
    final screenSize = MediaQuery.of(context).size;

    final menuHeight = _estimatedMenuHeight();

    // ✅ X: alinear el menú para que su borde derecho coincida con el borde derecho del icono.
    // Esto hace que el menú "se meta" por la izquierda y tape el icono.
    double left = triggerRect.right - widget.menuWidth;

    // clamp para no salirse horizontalmente
    final minLeft = widget.screenMargin;
    final maxLeft = screenSize.width - widget.menuWidth - widget.screenMargin;
    left = left.clamp(minLeft, maxLeft);

    // ✅ Y: colocar el menú "encima" del icono (tapa los puntos)
    // Lo centramos verticalmente respecto al trigger:
    double top = triggerRect.top - ((menuHeight - triggerRect.height) / 2) + widget.yNudge;

    // clamp para no salirse verticalmente
    final minTop = widget.screenMargin;
    final maxTop = screenSize.height - menuHeight - widget.screenMargin;
    top = top.clamp(minTop, maxTop);

    _entry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // ✅ Tap afuera cierra el menú
            Positioned.fill(
              child: GestureDetector(
                onTap: _removeMenu,
                behavior: HitTestBehavior.translucent,
                child: const SizedBox.expand(),
              ),
            ),

            // ✅ Menú encima del icono
            Positioned(
              left: left,
              top: top,
              width: widget.menuWidth,
              child: Material(
                color: Colors.transparent,
                child: _MenuCard(
                  width: widget.menuWidth,
                  borderRadius: widget.borderRadius,
                  padding: widget.menuPadding,
                  backgroundColor: widget.backgroundColor,
                  boxShadow: widget.boxShadow ??
                      [
                        BoxShadow(
                          blurRadius: 12,
                          spreadRadius: 0,
                          offset: const Offset(0, 6),
                          color: Colors.black.withValues(alpha: 0.12),
                        ),
                      ],
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _buildMenuItems(context),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_entry!);
  }

  List<Widget> _buildMenuItems(BuildContext context) {
    final widgets = <Widget>[];

    for (int i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];

      widgets.add(
        _MenuRow(
          height: widget.itemHeight,
          padding: widget.itemPadding,
          iconSize: widget.itemIconSize,
          fontSize: widget.fontSize,
          gap: widget.gap,
          item: item,
          onTap: () async {
            if (!item.enabled) return;

            if (item.requireConfirm) {
              final ok = await _confirm(context, item);
              if (ok != true) return;
            }

            _removeMenu();
            widget.onSelected?.call(item.type);
            item.onTap?.call();
          },
        ),
      );

      if (widget.showDividers && i < widget.items.length - 1) {
        widgets.add(
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey.withValues(alpha: 0.15),
          ),
        );
      }
    }

    return widgets;
  }

  Future<bool?> _confirm(BuildContext context, ActionMenuItem item) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item.confirmTitle),
        content: Text(item.confirmMessage),
        actions: [
          // TextButton(
          //   // onPressed: () => Navigator.pop(context, false),
          //   child: Text(item.confirmCancelText),
          // ),
          // ElevatedButton(
          //   // onPressed: () => Navigator.pop(context, true),
          //   child: Text(item.confirmOkText),
          // ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return InkWell(
      key: _triggerKey,
      onTap: _toggleMenu,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(
          widget.triggerIcon,
          size: widget.triggerIconSize,
          color: widget.triggerIconColor ?? Colors.grey[600],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final double width;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final List<BoxShadow> boxShadow;
  final Color backgroundColor;
  final Widget child;

  const _MenuCard({
    required this.width,
    required this.borderRadius,
    required this.padding,
    required this.boxShadow,
    required this.backgroundColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      shadowStyle: ShadowStyle.glow,
      child: child,
    );
  }
}

class _MenuRow extends StatelessWidget {
  final ActionMenuItem item;
  final VoidCallback onTap;

  final double height;
  final double iconSize;
  final double fontSize;
  final double gap;
  final EdgeInsetsGeometry padding;

  const _MenuRow({
    required this.item,
    required this.onTap,
    required this.height,
    required this.iconSize,
    required this.fontSize,
    required this.gap,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = !item.enabled;

    return InkWell(
      onTap: disabled ? null : onTap,
      child: Container(
        height: height,
        padding: padding,
        child: Opacity(
          opacity: disabled ? 0.45 : 1,
          child: Row(
            children: [
              Icon(item.icon, size: iconSize, color: item.color),
              SizedBox(width: gap),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: TextStyle(
                    color: item.color,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
