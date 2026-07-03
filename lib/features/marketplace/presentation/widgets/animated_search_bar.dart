import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:syncronize/core/theme/app_colors.dart';

/// Barra de búsqueda **display-only** del home del marketplace: se ve igual que
/// el `CustomSearchField` pero muestra un hint ROTATIVO estilo Temu — distintas
/// sugerencias con su ícono que suben/desvanecen cada pocos segundos. Al tocarla
/// dispara [onTap] (abre la página de búsqueda real).
///
/// Si [query] tiene texto (hay una búsqueda activa), muestra ese texto fijo en
/// vez de animar.
class AnimatedSearchBar extends StatefulWidget {
  final VoidCallback onTap;
  final String? query;
  final double height;
  final double borderRadius;

  const AnimatedSearchBar({
    super.key,
    required this.onTap,
    this.query,
    this.height = 33,
    this.borderRadius = 24,
  });

  @override
  State<AnimatedSearchBar> createState() => _AnimatedSearchBarState();
}

class _AnimatedSearchBarState extends State<AnimatedSearchBar> {
  // Sugerencias rotativas (ícono + texto). Ajustar libremente.
  static const List<(IconData, String)> _sugerencias = [
    (Icons.local_fire_department_rounded, 'Ofertas del día'),
    (Icons.checkroom_rounded, 'conjuntos para niños'),
    (Icons.headphones_rounded, 'audífonos bluetooth'),
    (Icons.toys_rounded, 'juguetes'),
    (Icons.chair_rounded, 'muebles para el hogar'),
    (Icons.phone_iphone_rounded, 'celulares y accesorios'),
    (Icons.watch_rounded, 'relojes y accesorios'),
  ];

  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2800), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _sugerencias.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tieneQuery = widget.query != null && widget.query!.isNotEmpty;
    final actual = _sugerencias[_index];

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(color: const Color(0xFFF0F0F0), width: 0.5),
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            // Logo animado (Lottie) a la izquierda.
            SizedBox(
              width: 20,
              height: 20,
              child: Lottie.asset(
                'assets/animations/logo1.json',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 8),
            // Texto/hint a la izquierda.
            Expanded(
              child: tieneQuery
                  // Búsqueda activa → texto fijo (estilo del input real).
                  ? Text(
                      widget.query!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.blue2,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  // Hint rotativo animado (sube + desvanece).
                  : ClipRect(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.9),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        child: Row(
                          key: ValueKey(_index),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(actual.$1, size: 13, color: AppColors.blue2),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                actual.$2,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.blue2,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 6),
            // Lupa a la derecha, en azul de marca.
            const Icon(Icons.search_rounded, size: 20, color: AppColors.blue2),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}
