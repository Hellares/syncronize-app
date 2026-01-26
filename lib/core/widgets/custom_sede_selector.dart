import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/widgets/chip_simple.dart'; // si lo necesitas

class CustomSedeSelector extends StatefulWidget {
  final List<dynamic> sedes;
  final dynamic currentSede;
  final ValueChanged<String> onSelected;

  final double menuWidth;
  final double borderRadius;
  final double screenMargin;
  final EdgeInsetsGeometry menuPadding;

  const CustomSedeSelector({
    super.key,
    required this.sedes,
    required this.currentSede,
    required this.onSelected,
    this.menuWidth = 230.0, // más ancho para subtítulo y badge
    this.borderRadius = 12.0,
    this.screenMargin = 16.0,
    this.menuPadding = const EdgeInsets.symmetric(vertical: 8),
  });

  @override
  State<CustomSedeSelector> createState() => _CustomSedeSelectorState();
}

class _CustomSedeSelectorState extends State<CustomSedeSelector> {
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
    // Aprox: 64px por ítem + padding + divisores
    return (widget.sedes.length * 60) + widget.menuPadding.vertical + (widget.sedes.length - 1) * 1;
  }

  void _showMenu() {
    final triggerRect = _getTriggerRect();
    final screenSize = MediaQuery.of(context).size;
    final menuHeight = _estimatedMenuHeight();

    // Alineación derecha (como menú de acciones)
    double left = triggerRect.right - widget.menuWidth;
    left = left.clamp(widget.screenMargin, screenSize.width - widget.menuWidth - widget.screenMargin);

    // Preferir abajo, si no hay espacio → arriba
    double top;
    if (triggerRect.bottom + menuHeight + widget.screenMargin <= screenSize.height) {
      top = triggerRect.bottom + 8; // pequeño gap
    } else {
      top = triggerRect.top - menuHeight - 8;
    }

    _entry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeMenu,
              behavior: HitTestBehavior.translucent,
            ),
          ),
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
    final List<Widget> items = [];
    for (int i = 0; i < widget.sedes.length; i++) {
      final sede = widget.sedes[i];
      final isSelected = sede.id == widget.currentSede.id;

      items.add(
        _SedeMenuRow(
          sede: sede,
          isSelected: isSelected,
          onTap: () {
            _removeMenu();
            if (!isSelected) {
              widget.onSelected(sede.id);
            }
          },
        ),
      );

      if (i < widget.sedes.length - 1) {
        items.add(
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
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final sedeActual = widget.currentSede;

    return InkWell(
      key: _triggerKey,
      onTap: _toggleMenu,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              IconData(
                sedeActual.tipoSedeIconCode,
                fontFamily: 'MaterialIcons',
              ),
              size: 14,
              color: Color(sedeActual.tipoSedeColor),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                sedeActual.nombre,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 10, // igual que tu versión original (compacta)
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_drop_down, size: 14),
          ],
        ),
      ),
    );
  }
}

class _SedeMenuRow extends StatelessWidget {
  final dynamic sede;
  final bool isSelected;
  final VoidCallback onTap;

  const _SedeMenuRow({
    required this.sede,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.check_circle
                  : IconData(
                      sede.tipoSedeIconCode,
                      fontFamily: 'MaterialIcons',
                    ),
              size: 16,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Color(sede.tipoSedeColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sede.nombre,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    sede.tipoSede.displayName,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (sede.esPrincipal)
              ChipSimple(label: 'Principal', color: AppColors.amberText)
          ],
        ),
      ),
    );
  }
}