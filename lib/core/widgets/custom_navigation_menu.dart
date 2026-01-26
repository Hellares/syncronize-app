import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/theme/app_gradients.dart';

/// Item de menú de navegación
class NavigationMenuItem {
  final String id;
  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const NavigationMenuItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });
}

/// Menú de navegación personalizado que se posiciona automáticamente
/// debajo del trigger (o arriba si no hay espacio)
class CustomNavigationMenu extends StatefulWidget {
  final List<NavigationMenuItem> items;

  // Trigger button
  final IconData triggerIcon;
  final double triggerIconSize;
  final Color? triggerIconColor;
  final String? tooltip;

  // Menu appearance
  final double menuWidth;
  final double borderRadius;
  final double screenMargin;
  final EdgeInsetsGeometry menuPadding;
  final bool showDividers;

  const CustomNavigationMenu({
    super.key,
    required this.items,
    this.triggerIcon = Icons.menu,
    this.triggerIconSize = 16,
    this.triggerIconColor,
    this.tooltip,
    this.menuWidth = 220.0,
    this.borderRadius = 12.0,
    this.screenMargin = 16.0,
    this.menuPadding = const EdgeInsets.symmetric(vertical: 8),
    this.showDividers = true,
  });

  @override
  State<CustomNavigationMenu> createState() => _CustomNavigationMenuState();
}

class _CustomNavigationMenuState extends State<CustomNavigationMenu> {
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

  Rect _getTriggerRect() {
    final renderBox = _triggerKey.currentContext!.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    return offset & renderBox.size;
  }

  double _estimatedMenuHeight() {
    // Aproximadamente: 50px por ítem + padding + divisores
    final itemsHeight = widget.items.length * 50.0;
    final dividersHeight = widget.showDividers ? (widget.items.length - 1) * 1.0 : 0.0;
    final paddingHeight = (widget.menuPadding is EdgeInsets)
        ? (widget.menuPadding as EdgeInsets).vertical
        : 16.0;

    return itemsHeight + dividersHeight + paddingHeight;
  }

  void _showMenu() {
    if (widget.items.isEmpty) return;

    final triggerRect = _getTriggerRect();
    final screenSize = MediaQuery.of(context).size;
    final menuHeight = _estimatedMenuHeight();

    // Alineación derecha (como menú de acciones en AppBar)
    double left = triggerRect.right - widget.menuWidth;
    left = left.clamp(
      widget.screenMargin,
      screenSize.width - widget.menuWidth - widget.screenMargin,
    );

    // Posicionar debajo del trigger si hay espacio, sino arriba
    double top;
    if (triggerRect.bottom + menuHeight + widget.screenMargin <= screenSize.height) {
      // Hay espacio abajo
      top = triggerRect.bottom + 8;
    } else {
      // No hay espacio, colocar arriba
      top = triggerRect.top - menuHeight - 8;
    }

    // Clamp para no salirse de la pantalla
    top = top.clamp(widget.screenMargin, screenSize.height - menuHeight - widget.screenMargin);

    _entry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Tap afuera cierra el menú
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeMenu,
              behavior: HitTestBehavior.translucent,
            ),
          ),
          // Menú
          Positioned(
            left: left,
            top: top,
            width: widget.menuWidth,
            child: Material(
              color: Colors.transparent,
              child: GradientContainer(
                borderColor: AppColors.blueborder,
                shadowStyle: ShadowStyle.colorful,
                gradient: AppGradients.blueWhiteBlue(),
                child: Padding(
                  padding: widget.menuPadding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _buildMenuItems(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context, rootOverlay: true).insert(_entry!);
  }

  List<Widget> _buildMenuItems() {
    final List<Widget> widgets = [];

    for (int i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];

      widgets.add(
        _NavigationMenuRow(
          item: item,
          onTap: () {
            _removeMenu();
            item.onTap();
          },
        ),
      );

      if (widget.showDividers && i < widget.items.length - 1) {
        widgets.add(
          Divider(
            height: 1,
            thickness: 1,
            indent: 12,
            endIndent: 12,
            color: Colors.grey.withValues(alpha: 0.2),
          ),
        );
      }
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return IconButton(
      key: _triggerKey,
      icon: Icon(
        widget.triggerIcon,
        size: widget.triggerIconSize,
      ),
      color: widget.triggerIconColor,
      tooltip: widget.tooltip,
      onPressed: _toggleMenu,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

/// Widget interno para cada item del menú
class _NavigationMenuRow extends StatelessWidget {
  final NavigationMenuItem item;
  final VoidCallback onTap;

  const _NavigationMenuRow({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric( horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 16,
              color: item.iconColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
