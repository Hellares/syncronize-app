import 'dart:async';

import 'package:flutter/material.dart';

import '../fonts/app_fonts.dart';
import '../theme/app_colors.dart';

/// Enum para tipos de dropdown
enum DropdownStyle {
  standard, // Dropdown estándar
  searchable, // Con búsqueda
  multiSelect, // Selección múltiple
}

/// Clase para items del dropdown
class DropdownItem<T> {
  final T value;
  final String label;
  final Widget? leading;
  final Widget? trailing;
  final bool enabled;

  const DropdownItem({
    required this.value,
    required this.label,
    this.leading,
    this.trailing,
    this.enabled = true,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DropdownItem &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// CustomDropdown:
/// ✅ didUpdateWidget sincroniza value/selectedValues/items
/// ✅ FocusNode externo/interno sin fugas
/// ✅ Overlay con tap fuera + no interfiere dentro
/// ✅ Search (con debounce) y multi-select
/// ✅ Keyboard/viewport aware
/// ✅ FormField real (validator con Form)
/// ✅ Anchors (sin cálculo por item height)
/// ✅ FIX: evita "setState/markNeedsBuild during build" usando post-frame helpers
/// ✅ PERF (1000 items móvil): debounce + itemExtent + no overlay duplicado
class CustomDropdown<T> extends StatefulWidget {
  final String? label;
  final String? hintText;

  /// Para standard/searchable
  final T? value;
  final void Function(T?)? onChanged;

  /// Para multiSelect
  final List<T>? selectedValues;
  final void Function(List<T>)? onMultiChanged;

  final List<DropdownItem<T>> items;

  /// Validator real (para FormField)
  /// - standard/searchable: recibe T?
  /// - multiSelect: recibe List<T>
  final String? Function(dynamic)? validator;

  final bool enabled;
  final Color backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? textStyle;
  final TextStyle? labelStyle;
  final TextStyle? hintStyle;
  final bool filled;
  final FocusNode? focusNode;
  final double? height;
  final double? borderWidth;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final DropdownStyle dropdownStyle;

  /// Altura máxima del panel del dropdown (sin contar el campo)
  final int? maxHeight;

  /// Mostrar caja de búsqueda (además del estilo searchable)
  final bool showSearchBox;

  /// MultiSelect: si true, al seleccionar un item se cierra.
  final bool closeOnSelect;

  /// MultiSelect: mostrar botón "Listo" si closeOnSelect=false
  final bool showDoneButton;

  final String doneText;

  /// Si true, limpia búsqueda al cerrar
  final bool clearSearchOnClose;

  /// PERF: altura fija (itemExtent) para listas grandes
  final double itemExtent;

  /// PERF: debounce de búsqueda (ms)
  final int searchDebounceMs;

  const CustomDropdown({
    super.key,
    this.label,
    this.hintText,
    this.value,
    required this.items,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.backgroundColor = AppColors.white,
    this.borderColor,
    this.borderRadius = 6.0,
    this.contentPadding,
    this.textStyle,
    this.labelStyle,
    this.hintStyle,
    this.filled = true,
    this.focusNode,
    this.height = 35,
    this.borderWidth = 0.5,
    this.prefixIcon,
    this.suffixIcon,
    this.dropdownStyle = DropdownStyle.standard,
    this.maxHeight,
    this.showSearchBox = false,
    this.selectedValues,
    this.onMultiChanged,
    this.closeOnSelect = false,
    this.showDoneButton = true,
    this.doneText = 'Listo',
    this.clearSearchOnClose = true,
    this.itemExtent = 33,
    this.searchDebounceMs = 220,
  });

  @override
  State<CustomDropdown<T>> createState() => _CustomDropdownState<T>();
}

class _CustomDropdownState<T> extends State<CustomDropdown<T>>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  bool _isFocused = false;
  bool _isExpanded = false;

  T? _selectedValue;
  List<T> _selectedMultiValues = [];

  List<DropdownItem<T>> _filteredItems = [];
  final TextEditingController _searchController = TextEditingController();

  late FocusNode _focusNode;
  late bool _ownsFocusNode;

  late AnimationController _animationController;
  late Animation<double> _shadowAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  final GlobalKey<FormFieldState<dynamic>> _formFieldKey =
      GlobalKey<FormFieldState<dynamic>>();

  Timer? _searchDebounce;

  /// --- Helpers anti "during build" -----------------------------------------

  void _postFrame(VoidCallback fn) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      fn();
    });
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    // Siempre post-frame: evita setState durante build en escenarios con Bloc/Form.
    _postFrame(() {
      if (!mounted) return;
      setState(fn);
    });
  }

  void _safeOverlayRebuild() {
    _postFrame(() {
      _overlayEntry?.markNeedsBuild();
    });
  }

  void _safeFormDidChange(dynamic value) {
    _postFrame(() {
      _formFieldKey.currentState?.didChange(value);
    });
  }

  void _safeValidate() {
    _postFrame(() {
      _formFieldKey.currentState?.validate();
    });
  }

  /// ------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _selectedValue = widget.value;
    _selectedMultiValues = List<T>.from(widget.selectedValues ?? <T>[]);
    _filteredItems = List<DropdownItem<T>>.from(widget.items);

    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 260),
      vsync: this,
    );

    _shadowAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.985).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _searchController.addListener(_filterItems);
  }

  @override
  void didUpdateWidget(covariant CustomDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // FocusNode swap
    if (oldWidget.focusNode != widget.focusNode) {
      _focusNode.removeListener(_onFocusChange);
      if (_ownsFocusNode) {
        _focusNode.dispose();
      }
      _ownsFocusNode = widget.focusNode == null;
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_onFocusChange);
    }

    // Items update
    if (oldWidget.items != widget.items) {
      _filteredItems = _applyFilter(widget.items, _searchController.text);
      _safeOverlayRebuild();
    }

    // Value sync
    if (widget.dropdownStyle != DropdownStyle.multiSelect) {
      if (oldWidget.value != widget.value) {
        _selectedValue = widget.value;
        _safeFormDidChange(_selectedValue);
      }
    } else {
      final newValues = widget.selectedValues ?? <T>[];
      if (!_listEquals(oldWidget.selectedValues, newValues)) {
        _selectedMultiValues = List<T>.from(newValues);
        _safeFormDidChange(List<T>.from(_selectedMultiValues));
      }
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    WidgetsBinding.instance.removeObserver(this);

    _searchDebounce?.cancel();

    _searchController.removeListener(_filterItems);
    _searchController.dispose();

    _focusNode.removeListener(_onFocusChange);
    if (_ownsFocusNode) _focusNode.dispose();

    _animationController.dispose();
    super.dispose();
  }

  /// Teclado / métricas cambian: reconstruir overlay si está abierto
  @override
  void didChangeMetrics() {
    if (_isExpanded) {
      _safeOverlayRebuild();
    }
  }

  void _onFocusChange() {
    if (!mounted) return;

    _safeSetState(() {
      _isFocused = _focusNode.hasFocus;
    });

    if (_focusNode.hasFocus || _isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  /// PERF: debounce para búsqueda con 1000 items
  void _filterItems() {
    if (!mounted) return;

    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      Duration(milliseconds: widget.searchDebounceMs),
      () {
        if (!mounted) return;

        // En móvil se siente mejor actualizar inmediatamente (sin post-frame)
        setState(() {
          _filteredItems = _applyFilter(widget.items, _searchController.text);
        });

        if (_isExpanded) _safeOverlayRebuild();
      },
    );
  }

  List<DropdownItem<T>> _applyFilter(
    List<DropdownItem<T>> items,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return List<DropdownItem<T>>.from(items);
    return items.where((i) => i.label.toLowerCase().contains(q)).toList();
  }

  void _toggleDropdown() {
    if (!widget.enabled) return;
    _isExpanded ? _closeDropdown() : _openDropdown();
  }

  void _openDropdown() {
    if (!mounted) return;
    // Evita overlays duplicados (doble tap)
    if (_overlayEntry != null) return;

    _safeSetState(() => _isExpanded = true);

    _focusNode.requestFocus();
    _animationController.forward();

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);

    _safeValidate();
  }

  void _closeDropdown() {
    if (!mounted) return;

    _safeSetState(() => _isExpanded = false);

    _removeOverlay();

    if (widget.clearSearchOnClose) {
      _searchDebounce?.cancel();
      _searchController.clear();
      _filteredItems = List<DropdownItem<T>>.from(widget.items);
    }

    if (_focusNode.hasFocus) _focusNode.unfocus();
    _animationController.reverse();

    _safeValidate();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// Anchors + keyboard aware + fallback si el espacio es mínimo
  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    final mq = MediaQuery.of(context);
    final screenHeight = mq.size.height;
    final viewInsetsBottom = mq.viewInsets.bottom;
    final safeTop = mq.padding.top;
    final safeBottom = mq.padding.bottom;

    final maxDropdownHeight = (widget.maxHeight?.toDouble() ?? 300.0);

    final usableBottom = screenHeight - viewInsetsBottom - safeBottom;
    final fieldTop = position.dy;
    final fieldBottom = position.dy + renderBox.size.height;

    final spaceAbove = (fieldTop - safeTop).clamp(0.0, double.infinity);
    final spaceBelow = (usableBottom - fieldBottom).clamp(0.0, double.infinity);

    final bool showAbove =
        (spaceBelow < maxDropdownHeight && spaceAbove > spaceBelow);

    final available = showAbove ? spaceAbove : spaceBelow;

    const minUsableHeight = 80.0;
    final dropdownHeight = available.clamp(0.0, maxDropdownHeight).toDouble();

    if (dropdownHeight < minUsableHeight) {
      final otherSideIsBetter = showAbove
          ? (spaceBelow > spaceAbove)
          : (spaceAbove > spaceBelow);
      if (otherSideIsBetter) {
        final otherAvailable = showAbove ? spaceBelow : spaceAbove;
        final otherHeight = otherAvailable
            .clamp(0.0, maxDropdownHeight)
            .toDouble();
        if (otherHeight > dropdownHeight) {
          return _createOverlayEntryWithConfig(
            showAbove: !showAbove,
            dropdownHeight: otherHeight,
          );
        }
      }
    }

    return _createOverlayEntryWithConfig(
      showAbove: showAbove,
      dropdownHeight: dropdownHeight,
    );
  }

  OverlayEntry _createOverlayEntryWithConfig({
    required bool showAbove,
    required double dropdownHeight,
  }) {
    final hasSearch =
        widget.showSearchBox ||
        widget.dropdownStyle == DropdownStyle.searchable;

    final hasFooter =
        widget.dropdownStyle == DropdownStyle.multiSelect &&
        widget.showDoneButton &&
        !widget.closeOnSelect;

    const gap = 2.0;

    return OverlayEntry(
      builder: (context) {
        final renderBox2 = this.context.findRenderObject() as RenderBox;
        final size2 = renderBox2.size;

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeDropdown,
              ),
            ),
            Positioned(
              width: size2.width,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                targetAnchor: showAbove
                    ? Alignment.topCenter
                    : Alignment.bottomCenter,
                followerAnchor: showAbove
                    ? Alignment.bottomCenter
                    : Alignment.topCenter,
                offset: showAbove
                    ? const Offset(0, -gap)
                    : const Offset(0, gap),
                child: Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  child: Container(
                    constraints: BoxConstraints(maxHeight: dropdownHeight),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      border: Border.all(
                        color: widget.borderColor ?? const Color(0xFFE0E0E0),
                        width: widget.borderWidth ?? 0.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasSearch) ...[
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              height: 35,
                              child: TextField(
                                controller: _searchController,
                                autofocus: true,
                                decoration: InputDecoration(
                                  isDense: true,
                                  hintText: 'Buscar...',
                                  hintStyle: TextStyle(
                                    fontSize: 9,
                                    fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                                    fontWeight: FontWeight.w400,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    size: 16,
                                    color: AppColors.blue1,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!, // color sin foco (el que ya tenías)
                                      width: 0.6, // grosor sin foco
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: const BorderSide(
                                      color: Colors.blue, // ← cambia este color
                                      width:0.6, // ← cambia este grosor (ej: 2.0, 2.5, etc)
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                                  fontWeight: FontWeight.w600,

                                  color: AppColors.blue1
                                ),
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                        ],
                        Flexible(
                          child: _filteredItems.isEmpty
                              ? const _EmptyState(minHeight: 60)
                              : ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  // PERF: mejora scroll/layout para listas grandes
                                  itemExtent: widget.itemExtent,
                                  itemCount: _filteredItems.length,
                                  itemBuilder: (context, index) {
                                    final item = _filteredItems[index];
                                    final isSelected =
                                        widget.dropdownStyle ==
                                            DropdownStyle.multiSelect
                                        ? _selectedMultiValues.contains(
                                            item.value,
                                          )
                                        : _selectedValue == item.value;

                                    return InkWell(
                                      onTap: item.enabled
                                          ? () => _onItemSelected(item.value)
                                          : null,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? (widget.borderColor ??
                                                        AppColors.blue)
                                                    .withValues(alpha: 0.1)
                                              : null,
                                        ),
                                        child: Row(
                                          children: [
                                            if (widget.dropdownStyle ==
                                                DropdownStyle.multiSelect)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  right: 12,
                                                ),
                                                child: Icon(
                                                  isSelected
                                                      ? Icons.check_box
                                                      : Icons
                                                            .check_box_outline_blank,
                                                  size: 16,
                                                  color: isSelected
                                                      ? widget.borderColor ??
                                                            AppColors.blue
                                                      : Colors.grey,
                                                ),
                                              ),
                                            if (item.leading != null) ...[
                                              item.leading!,
                                              const SizedBox(width: 12),
                                            ],
                                            Expanded(
                                              child: Text(
                                                item.label,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: isSelected
                                                      ? FontWeight.w600
                                                      : FontWeight.w400,
                                                  color: item.enabled
                                                      ? (isSelected
                                                            ? widget.borderColor ??
                                                                  AppColors.blue
                                                            : Colors.black87)
                                                      : Colors.grey,
                                                ),
                                              ),
                                            ),
                                            if (item.trailing != null)
                                              item.trailing!,
                                            if (isSelected &&
                                                widget.dropdownStyle ==
                                                    DropdownStyle.standard)
                                              Icon(
                                                Icons.check,
                                                size: 16,
                                                color:
                                                    widget.borderColor ??
                                                    AppColors.blue,
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        if (hasFooter) ...[
                          const Divider(height: 1),
                          SizedBox(
                            height: 44,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: TextButton(
                                  onPressed: _closeDropdown,
                                  child: Text(
                                    widget.doneText,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: AppFonts.getFontFamily(
                                        AppFont.oxygenBold,
                                      ),
                                      color:
                                          widget.borderColor ?? AppColors.blue,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _onItemSelected(T value) {
    if (widget.dropdownStyle == DropdownStyle.multiSelect) {
      // UI update: post-frame para evitar colisión con build del padre (Bloc/Form)
      _safeSetState(() {
        if (_selectedMultiValues.contains(value)) {
          _selectedMultiValues.remove(value);
        } else {
          _selectedMultiValues.add(value);
        }
      });

      // Notificaciones + FormField update post-frame
      _postFrame(() {
        widget.onMultiChanged?.call(List<T>.from(_selectedMultiValues));
        _formFieldKey.currentState?.didChange(
          List<T>.from(_selectedMultiValues),
        );
        _formFieldKey.currentState?.validate();
      });

      _safeOverlayRebuild();

      if (widget.closeOnSelect) {
        _closeDropdown();
      }
    } else {
      _safeSetState(() => _selectedValue = value);

      _postFrame(() {
        widget.onChanged?.call(value);
        _formFieldKey.currentState?.didChange(_selectedValue);
        _formFieldKey.currentState?.validate();
      });

      _closeDropdown();
    }
  }

  String _getDisplayText() {
    if (widget.dropdownStyle == DropdownStyle.multiSelect) {
      if (_selectedMultiValues.isEmpty) {
        return widget.hintText ?? 'Seleccionar';
      }
      final labels = _selectedMultiValues
          .map(
            (v) => widget.items
                .firstWhere(
                  (item) => item.value == v,
                  orElse: () => DropdownItem<T>(value: v, label: v.toString()),
                )
                .label,
          )
          .join(', ');
      return labels;
    } else {
      if (_selectedValue == null) return widget.hintText ?? 'Seleccionar';
      return widget.items
          .firstWhere(
            (item) => item.value == _selectedValue,
            orElse: () => DropdownItem<T>(
              value: _selectedValue as T,
              label: _selectedValue.toString(),
            ),
          )
          .label;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHint = (_selectedValue == null && _selectedMultiValues.isEmpty);

    final dynamic initialFormValue =
        widget.dropdownStyle == DropdownStyle.multiSelect
        ? List<T>.from(_selectedMultiValues)
        : _selectedValue;

    return FormField<dynamic>(
      key: _formFieldKey,
      initialValue: initialFormValue,
      validator: widget.validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      builder: (state) {
        final hasError = state.errorText != null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.label != null) ...[
              Text(
                widget.label!,
                style:
                    widget.labelStyle ??
                    TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: AppColors.blue1,
                      fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                    ),
              ),
              const SizedBox(height: 1),
            ],
            CompositedTransformTarget(
              link: _layerLink,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      height: widget.height,
                      decoration: BoxDecoration(
                        color: widget.filled
                            ? widget.backgroundColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(
                          widget.borderRadius,
                        ),
                        boxShadow: widget.filled ? _buildShadows() : null,
                        border: Border.all(
                          color: hasError ? Colors.red : _getBorderColor(),
                          width: widget.borderWidth ?? 0.5,
                        ),
                      ),
                      child: InkWell(
                        onTap: _toggleDropdown,
                        borderRadius: BorderRadius.circular(
                          widget.borderRadius,
                        ),
                        child: Padding(
                          padding:
                              widget.contentPadding ??
                              const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                          child: Row(
                            children: [
                              if (widget.prefixIcon != null) ...[
                                widget.prefixIcon!,
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Text(
                                  _getDisplayText(),
                                  style: isHint
                                      ? (widget.hintStyle ??
                                            TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 10,
                                              fontFamily:
                                                  AppFonts.getFontFamily(
                                                    AppFont.oxygenRegular,
                                                  ),
                                            ))
                                      : (widget.textStyle ??
                                            TextStyle(
                                              color: AppColors.blue2,
                                              fontSize: 10,
                                              fontFamily:
                                                  AppFonts.getFontFamily(
                                                    AppFont.oxygenBold,
                                                  ),
                                            )),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              RotationTransition(
                                turns: _rotationAnimation,
                                child:
                                    widget.suffixIcon ??
                                    Icon(
                                      Icons.keyboard_arrow_down,
                                      color: _isFocused || _isExpanded
                                          ? const Color(0xFF666666)
                                          : Colors.grey[600],
                                      size: 20,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (hasError) ...[
              const SizedBox(height: 4),
              Text(
                state.errorText!,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.red[700],
                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Color _getBorderColor() {
    return widget.borderColor ??
        (_isFocused || _isExpanded
            ? const Color(0xFFE0E0E0)
            : const Color(0xFFF0F0F0));
  }

  List<BoxShadow> _buildShadows() {
    final double intensity = _shadowAnimation.value;
    final Color currentBorderColor = _getBorderColor();
    final Color shadowColor = _getShadowColorFromBorder(currentBorderColor);

    if (_isFocused || _isExpanded) {
      return [
        BoxShadow(
          color: currentBorderColor.withValues(alpha: 0.25 + (intensity * 0.2)),
          offset: const Offset(0, 1),
          blurRadius: 3,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.6),
          offset: const Offset(-1, -1),
          blurRadius: 2,
          spreadRadius: -1,
        ),
      ];
    }

    return [
      BoxShadow(
        color: shadowColor.withValues(alpha: 0.18),
        offset: const Offset(4, 4),
        blurRadius: 8,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: currentBorderColor.withValues(alpha: 0.15),
        offset: const Offset(1, 1),
        blurRadius: 4,
        spreadRadius: -1,
      ),
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.8),
        offset: const Offset(-2, -2),
        blurRadius: 4,
        spreadRadius: -1,
      ),
    ];
  }

  Color _getShadowColorFromBorder(Color borderColor) {
    if (borderColor == AppColors.blue ||
        borderColor == const Color(0xFF1976D2)) {
      return const Color(0xFF0D47A1);
    } else if (borderColor == Colors.red ||
        borderColor == const Color(0xFFD32F2F)) {
      return const Color(0xFF8D1E1E);
    } else if (borderColor == Colors.green ||
        borderColor == const Color(0xFF4CAF50)) {
      return const Color(0xFF1B5E20);
    } else if (borderColor == Colors.purple ||
        borderColor == const Color(0xFF9C27B0)) {
      return const Color(0xFF4A148C);
    } else {
      final hsl = HSLColor.fromColor(borderColor);
      return HSLColor.fromAHSL(
        1.0,
        hsl.hue,
        (hsl.saturation * 0.9).clamp(0.0, 1.0),
        (hsl.lightness * 0.25).clamp(0.0, 0.4),
      ).toColor();
    }
  }

  bool _listEquals(List<T>? a, List<T>? b) {
    if (identical(a, b)) return true;
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class _EmptyState extends StatelessWidget {
  final double minHeight;
  const _EmptyState({required this.minHeight});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Center(
        child: Text(
          'Sin resultados',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
          ),
        ),
      ),
    );
  }
}

/// Helpers para crear dropdowns comunes
class CustomDropdownHelpers {
  static CustomDropdown<T> standard<T>({
    required String label,
    required List<DropdownItem<T>> items,
    T? value,
    void Function(T?)? onChanged,
    Color? borderColor,
    String? hintText,
    String? Function(T?)? validator,
  }) {
    return CustomDropdown<T>(
      label: label,
      items: items,
      value: value,
      onChanged: onChanged,
      borderColor: borderColor,
      hintText: hintText,
      validator: validator == null ? null : (v) => validator(v as T?),
    );
  }

  static CustomDropdown<T> searchable<T>({
    required String label,
    required List<DropdownItem<T>> items,
    T? value,
    void Function(T?)? onChanged,
    Color? borderColor,
    String? hintText,
    String? Function(T?)? validator,
  }) {
    return CustomDropdown<T>(
      label: label,
      items: items,
      value: value,
      onChanged: onChanged,
      borderColor: borderColor,
      hintText: hintText,
      dropdownStyle: DropdownStyle.searchable,
      showSearchBox: true,
      validator: validator == null ? null : (v) => validator(v as T?),
    );
  }

  static CustomDropdown<T> multiSelect<T>({
    required String label,
    required List<DropdownItem<T>> items,
    List<T>? selectedValues,
    void Function(List<T>)? onMultiChanged,
    Color? borderColor,
    String? hintText,
    String? Function(List<T>)? validator,
    bool closeOnSelect = false,
    bool showDoneButton = true,
    String doneText = 'Listo',
  }) {
    return CustomDropdown<T>(
      label: label,
      items: items,
      selectedValues: selectedValues,
      onMultiChanged: onMultiChanged,
      borderColor: borderColor,
      hintText: hintText,
      dropdownStyle: DropdownStyle.multiSelect,
      closeOnSelect: closeOnSelect,
      showDoneButton: showDoneButton,
      doneText: doneText,
      validator: validator == null
          ? null
          : (v) => validator((v as List).cast<T>()),
    );
  }
}
