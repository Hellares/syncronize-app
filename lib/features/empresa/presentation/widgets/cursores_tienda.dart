import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';

/// Cursores de la tienda web (`webConfig.cursor = {tipo, color, borde}`). Los dibujos
/// son los mismos de la web (`syncronize-web/src/lib/cursores.ts`): si se
/// cambia uno, cambiar los dos.
class CursorTienda {
  final String id;
  final String nombre;
  const CursorTienda(this.id, this.nombre);
}

const cursoresTienda = <CursorTienda>[
  CursorTienda('normal', 'Normal'),
  CursorTienda('flecha', 'Flecha'),
  CursorTienda('punto', 'Punto'),
  CursorTienda('anillo', 'Anillo'),
  CursorTienda('mira', 'Mira tech'),
  CursorTienda('corazon', 'Corazón'),
  CursorTienda('estrella', 'Estrella'),
  CursorTienda('carrito', 'Carrito'),
  CursorTienda('patita', 'Patita'),
  CursorTienda('craneo', 'Cráneo'),
];

const _p = {
  'flecha': 'M5 3 L5 25 L11 19 L15.5 28.5 L19.5 26.5 L15 17 L23 17 Z',
  'corazon': 'M16 27.5l-1.8-1.6C7.8 20.1 3.6 16.3 3.6 11.6 3.6 7.8 6.6 4.8 10.4 4.8c2.2 0 4.2 1 5.6 2.6 1.4-1.6 3.4-2.6 5.6-2.6 3.8 0 6.8 3 6.8 6.8 0 4.7-4.2 8.5-10.6 14.3z',
  'estrella': 'M16 23.1l7.6 4.6-2-8.7 6.7-5.8-8.9-.8L16 4.3l-3.4 8.1-8.9.8 6.7 5.8-2 8.7z',
  'carrito': 'M10 23.5a2.3 2.3 0 100 4.6 2.3 2.3 0 000-4.6zM3 4.5v2.6h2.6l4.6 9.7-1.7 3.1c-.2.4-.3.8-.3 1.2 0 1.4 1.1 2.6 2.6 2.6h15.3v-2.6H11.2a.3.3 0 01-.3-.3v-.2l1.2-2.1h9.5c1 0 1.8-.5 2.3-1.3l4.6-8.3a1.3 1.3 0 00-1.1-1.9H8.7L7.5 4.5zm20.4 19a2.3 2.3 0 100 4.6 2.3 2.3 0 000-4.6z',
  'patita': 'M7.2 12.4a3 3 0 110 6 3 3 0 010-6zm5.2-6.2a3 3 0 110 6 3 3 0 010-6zm7.2 0a3 3 0 110 6 3 3 0 010-6zm5.2 6.2a3 3 0 110 6 3 3 0 010-6zM22.8 20c-1.1-1.3-2-2.4-3.1-3.7-.6-.7-1.3-1.4-2.2-1.7-.7-.2-2.3-.2-3 0-.9.3-1.6 1-2.2 1.7-1.1 1.3-2 2.4-3.1 3.7-1.6 1.6-3.7 3.5-3.3 6 .4 1.3 1.3 2.6 2.9 2.9.9.2 3.9-.5 7-.5h.2c3.1 0 6.1.7 7 .5 1.6-.3 2.6-1.6 2.9-2.9.4-2.5-1.6-4.4-3.1-6z',
  'craneo': 'M16 3C9 3 5 8 5 14c0 4 2 6.5 4.5 7.5v4c0 1.1.9 2 2 2h9c1.1 0 2-.9 2-2v-4c2.5-1 4.5-3.5 4.5-7.5 0-6-4-11-11-11zM8.5 14.5a3 3 0 106 0 3 3 0 10-6 0zm9 0a3 3 0 106 0 3 3 0 10-6 0zM16 18l-1.5 2.7h3zM13.1 23.6h1.5v3.9h-1.5zm4.3 0h1.5v3.9h-1.5z',
};

const _punta = 'M2 2 L2 14 L5.8 10.5 L13.8 9.9 Z';

String _hex(Color c) {
  final v = c.toARGB32() & 0xFFFFFF;
  return '#${v.toRadixString(16).padLeft(6, '0')}';
}

/// El SVG del cursor (su forma normal, no la "de clic"), para la vista previa.
String cursorTiendaSvg(String id, Color color, {Color borde = Colors.white}) {
  final c = _hex(color);
  final b = _hex(borde);
  String body;
  switch (id) {
    case 'flecha':
      body = '<path d="${_p['flecha']}" fill="$c" stroke="$b" stroke-width="1.6" stroke-linejoin="round"/>';
      break;
    case 'punto':
      body = '<circle cx="16" cy="16" r="5.5" fill="$c" stroke="$b" stroke-width="2"/>';
      break;
    case 'anillo':
      body = '<circle cx="16" cy="16" r="11" fill="none" stroke="$b" stroke-width="4"/><circle cx="16" cy="16" r="11" fill="none" stroke="$c" stroke-width="2"/><circle cx="16" cy="16" r="3" fill="$c" stroke="$b" stroke-width="1"/>';
      break;
    case 'mira':
      const lineas = '<path d="M16 3v8M16 21v8M3 16h8M21 16h8"/>';
      body = '<g stroke="$b" stroke-width="4" stroke-linecap="round">$lineas</g>'
          '<g stroke="$c" stroke-width="2" stroke-linecap="round">$lineas</g>'
          '<circle cx="16" cy="16" r="1.6" fill="$c"/>';
      break;
    case 'corazon':
    case 'estrella':
    case 'carrito':
    case 'patita':
    case 'craneo':
      final huecos = id == 'craneo' ? ' fill-rule="evenodd"' : '';
      body = '<g transform="translate(4.4 4.4) scale(0.86)"><path d="${_p[id]}" fill="$c"$huecos stroke="$b" stroke-width="2.4" stroke-linejoin="round"/></g>'
          '<path d="$_punta" fill="$c" stroke="$b" stroke-width="1.2" stroke-linejoin="round"/>';
      break;
    default: // normal: la flecha del sistema
      body = '<path d="${_p['flecha']}" fill="#111" stroke="#fff" stroke-width="1.6" stroke-linejoin="round"/>';
  }
  return '<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32">$body</svg>';
}

/// Grilla de cursores con su vista previa pintada del color elegido.
class CursorTiendaSelector extends StatelessWidget {
  final String seleccionado;
  final Color color;
  final Color borde;
  final ValueChanged<String> onChanged;

  const CursorTiendaSelector({
    super.key,
    required this.seleccionado,
    required this.color,
    this.borde = Colors.white,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 0.82,
      children: [
        for (final cur in cursoresTienda)
          _Opcion(
            cursor: cur,
            color: color,
            borde: borde,
            activo: cur.id == seleccionado,
            onTap: () => onChanged(cur.id),
          ),
      ],
    );
  }
}

class _Opcion extends StatelessWidget {
  final CursorTienda cursor;
  final Color color;
  final Color borde;
  final bool activo;
  final VoidCallback onTap;

  const _Opcion({required this.cursor, required this.color, required this.borde, required this.activo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          // Fondo de color suave: los cursores llevan borde blanco.
          color: activo ? AppColors.blue1.withValues(alpha: 0.12) : const Color(0xFFE8EEF8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: activo ? AppColors.blue1 : Colors.transparent,
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.string(cursorTiendaSvg(cursor.id, color, borde: borde), width: 28, height: 28),
            const SizedBox(height: 4),
            Text(
              cursor.nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
                color: activo ? AppColors.blue2 : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
