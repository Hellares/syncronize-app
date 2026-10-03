import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';

import '../../domain/entities/producto_variante.dart';
import '../pages/separar_por_diseno_page.dart' show kClaveAtributoDiseno, esVarianteDiseno;

/// Un renglón de la hoja de Variantes: una variante suelta o una colección
/// con sus diseños juntos.
sealed class FilaVariantes {
  const FilaVariantes();
}

class FilaVariante extends FilaVariantes {
  final ProductoVariante variante;
  const FilaVariante(this.variante);
}

class FilaColeccion extends FilaVariantes {
  /// Ordenados por número: D1, D2, … D10.
  final List<ProductoVariante> disenos;
  const FilaColeccion(this.disenos);
}

/// Lo que identifica a una colección: los valores de los atributos SIN el
/// diseño. Misma regla que el backend (numeración de diseños) y que el
/// buscador de la venta.
String claveColeccion(ProductoVariante v) {
  final partes = [
    for (final a in v.atributosValores)
      if (a.atributo.clave != kClaveAtributoDiseno)
        '${a.atributoId}=${a.valor.trim().toUpperCase()}',
  ]..sort();
  return partes.join('|');
}

/// "D3" de un diseño (null si no es diseño).
String? valorDiseno(ProductoVariante v) {
  for (final a in v.atributosValores) {
    if (a.atributo.clave == kClaveAtributoDiseno) return a.valor;
  }
  return null;
}

int _numeroDiseno(ProductoVariante v) =>
    int.tryParse((valorDiseno(v) ?? '').replaceAll(RegExp(r'^\D+'), '')) ?? 0;

/// El nombre de la colección: el del diseño sin su " / D3" final.
String tituloColeccion(ProductoVariante v) {
  final d = valorDiseno(v);
  if (d == null) return v.nombre;
  return v.nombre.replaceFirst(RegExp(r'\s*/\s*' + RegExp.escape(d) + r'\s*$'), '');
}

/// Junta los diseños de cada colección en un renglón, en el lugar donde
/// aparece el primero. Lo que no es diseño queda suelto (incluida la
/// variante de la colección si todavía tiene unidades sin separar: tiene su
/// propia acción de separar).
List<FilaVariantes> agruparPorColeccion(List<ProductoVariante> variantes) {
  final filas = <FilaVariantes>[];
  final grupos = <String, List<ProductoVariante>>{};
  for (final v in variantes) {
    if (!esVarianteDiseno(v)) {
      filas.add(FilaVariante(v));
      continue;
    }
    final clave = claveColeccion(v);
    final grupo = grupos[clave];
    if (grupo != null) {
      grupo.add(v);
    } else {
      final nuevo = [v];
      grupos[clave] = nuevo;
      filas.add(FilaColeccion(nuevo));
    }
  }
  for (final g in grupos.values) {
    g.sort((a, b) => _numeroDiseno(a).compareTo(_numeroDiseno(b)));
  }
  return filas;
}

/// La colección en una sola card: título, stock sumado y una fila de
/// miniaturas, una por diseño con su stock. Cada miniatura sigue siendo SU
/// variante: tocarla abre su detalle y el clip gestiona sus fotos. Al final,
/// "Agregar" para los diseños nuevos que llegan.
class ColeccionDisenosCard extends StatelessWidget {
  final List<ProductoVariante> disenos;
  final ValueChanged<ProductoVariante> onTapDiseno;
  final ValueChanged<ProductoVariante> onFotosDiseno;
  final VoidCallback onAgregar;

  const ColeccionDisenosCard({
    super.key,
    required this.disenos,
    required this.onTapDiseno,
    required this.onFotosDiseno,
    required this.onAgregar,
  });

  static const keyAgregar = ValueKey('coleccion-disenos:agregar');
  static const anchoMiniatura = 64.0;

  @override
  Widget build(BuildContext context) {
    final primero = disenos.first;
    final stock = disenos.fold<int>(0, (s, d) => s + d.stockTotal);
    final precio = _precio(primero);
    final n = disenos.length;

    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      borderRadius: BorderRadius.circular(8),
      shadowStyle: ShadowStyle.glow,
      borderColor: AppColors.blueborder,
      borderWidth: 0.8,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tituloColeccion(primero),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$n diseño${n == 1 ? '' : 's'}'
                        '${precio != null ? ' · S/ ${precio.toStringAsFixed(2)}' : ''}',
                        style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                _BadgeStock(stock: stock),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: anchoMiniatura + 18,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final d in disenos)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _Miniatura(
                        diseno: d,
                        onTap: () => onTapDiseno(d),
                        onFotos: () => onFotosDiseno(d),
                      ),
                    ),
                  _BotonAgregar(onTap: onAgregar),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// El precio de la colección: el de la primera sede configurada del primer
  /// diseño (todos se venden al precio de su colección).
  double? _precio(ProductoVariante v) {
    final stocks = v.stocksPorSede;
    if (stocks == null || stocks.isEmpty) return null;
    final s = stocks.where((s) => s.precioConfigurado && s.precio != null).firstOrNull ??
        stocks.first;
    return s.precioEfectivo;
  }
}

class _Miniatura extends StatelessWidget {
  final ProductoVariante diseno;
  final VoidCallback onTap;
  final VoidCallback onFotos;

  const _Miniatura({required this.diseno, required this.onTap, required this.onFotos});

  @override
  Widget build(BuildContext context) {
    const lado = ColeccionDisenosCard.anchoMiniatura;
    final stock = diseno.stockTotal;
    final url = diseno.thumbnailPrincipal;
    return SizedBox(
      width: lado,
      child: Column(
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: onTap,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: lado,
                    height: lado,
                    color: Colors.grey[200],
                    child: url != null
                        ? CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const _SinFoto(),
                          )
                        : const _SinFoto(),
                  ),
                ),
              ),
              // Asignar o cambiar la foto de ESTE diseño.
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onFotos,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(6),
                        bottomLeft: Radius.circular(6),
                      ),
                    ),
                    child: const Icon(Icons.attach_file, size: 12, color: AppColors.blue1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          // Una línea de alto fijo: con letra grande del sistema partía en
          // dos y desbordaba la franja.
          Text(
            '${valorDiseno(diseno) ?? ''} · $stock',
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              height: 1.2,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: stock > 0 ? AppColors.blue1 : Colors.red[400],
            ),
          ),
        ],
      ),
    );
  }
}

class _SinFoto extends StatelessWidget {
  const _SinFoto();

  @override
  Widget build(BuildContext context) =>
      Center(child: Icon(Icons.image_not_supported_outlined, size: 20, color: Colors.grey[400]));
}

class _BotonAgregar extends StatelessWidget {
  final VoidCallback onTap;
  const _BotonAgregar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    const lado = ColeccionDisenosCard.anchoMiniatura;
    return SizedBox(
      width: lado,
      child: Column(
        children: [
          InkWell(
            key: ColeccionDisenosCard.keyAgregar,
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: lado,
              height: lado,
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.greendark.withValues(alpha: 0.5), width: 0.8),
              ),
              child: const Icon(Icons.add_photo_alternate_outlined,
                  size: 22, color: AppColors.greendark),
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Agregar',
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                height: 1.2, fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.greendark),
          ),
        ],
      ),
    );
  }
}

class _BadgeStock extends StatelessWidget {
  final int stock;
  const _BadgeStock({required this.stock});

  @override
  Widget build(BuildContext context) {
    final color = stock > 0 ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.6),
      ),
      child: Text(
        'Stock: $stock',
        style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// La colección en UNA fila de la tabla densa de "Variantes" (la página de
/// gestión): título, "N diseños", precio (desde
/// el más bajo si un diseño cuesta distinto), stock sumado y la tira de
/// miniaturas. Tocarla despliega sus diseños; el botón de la derecha agrega
/// diseños nuevos.
class ColeccionFilaCompacta extends StatelessWidget {
  final List<ProductoVariante> disenos;
  final bool abierta;
  final bool ultima;
  final VoidCallback onTap;
  final VoidCallback onAgregar;

  const ColeccionFilaCompacta({
    super.key,
    required this.disenos,
    required this.abierta,
    required this.ultima,
    required this.onTap,
    required this.onAgregar,
  });

  static const _divisor = Color(0xFFEEF2F6);
  static const _textoTenue = Color(0xFF7D97B3);

  @override
  Widget build(BuildContext context) {
    final primero = disenos.first;
    final stock = disenos.fold<int>(0, (s, d) => s + d.stockTotal);
    final precios = [
      for (final d in disenos)
        if (_precioDe(d) case final p?) p,
    ];
    final minimo = precios.isEmpty ? null : precios.reduce((a, b) => a < b ? a : b);
    final variados = precios.any((p) => (p - (minimo ?? p)).abs() > 0.0001);
    final n = disenos.length;

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border(
            left: BorderSide(
              color: stock > 0 ? AppColors.blue1 : const Color(0xFFCFD8E3),
              width: 3,
            ),
            bottom: ultima && !abierta
                ? BorderSide.none
                : const BorderSide(color: _divisor, width: 1),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(6, 6, 2, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedRotation(
                  turns: abierta ? 0.25 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: const Icon(Icons.chevron_right, size: 18, color: _textoTenue),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppSubtitle(
                        tituloColeccion(primero),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      AppLabelText(
                        '$n diseño${n == 1 ? '' : 's'}',
                        fontSize: 9,
                        color: _textoTenue,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppSubtitle(
                      minimo == null
                          ? '—'
                          : '${variados ? 'desde ' : ''}S/${minimo.toStringAsFixed(2)}',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blue3,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      stock > 0 ? '$stock u' : 'agotada',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: stock > 0 ? AppColors.greendark : _textoTenue,
                      ),
                    ),
                  ],
                ),
                // 44×44 de área táctil, como el menú de las filas.
                SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    tooltip: 'Agregar diseños',
                    onPressed: onAgregar,
                    icon: const Icon(Icons.add_photo_alternate_outlined,
                        size: 18, color: AppColors.greendark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: SizedBox(
                height: 30,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final d in disenos)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: _miniatura(d),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniatura(ProductoVariante d) {
    final url = d.thumbnailPrincipal;
    final agotada = d.stockTotal == 0;
    return Tooltip(
      message: '${valorDiseno(d) ?? ''} · ${d.stockTotal} u',
      child: Opacity(
        opacity: agotada ? 0.45 : 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 30,
            height: 30,
            color: const Color(0xFFF1F4F8),
            alignment: Alignment.center,
            child: url != null
                ? CachedNetworkImage(
                    imageUrl: url,
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _etiqueta(d),
                  )
                : _etiqueta(d),
          ),
        ),
      ),
    );
  }

  Widget _etiqueta(ProductoVariante d) => Text(
        valorDiseno(d) ?? '',
        style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: _textoTenue),
      );

  /// Precio vigente del diseño (oferta/liquidación incluidas).
  double? _precioDe(ProductoVariante v) {
    final stocks = v.stocksPorSede;
    if (stocks == null || stocks.isEmpty) return null;
    final s = stocks.where((s) => s.precioConfigurado && s.precio != null).firstOrNull;
    return s?.precioEfectivo;
  }
}
