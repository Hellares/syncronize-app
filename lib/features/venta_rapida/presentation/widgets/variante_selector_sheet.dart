import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../producto/domain/entities/precio_nivel.dart';
import '../../../producto/domain/entities/producto_list_item.dart';
import '../../../producto/domain/entities/producto_variante.dart';
import '../../../venta/domain/entities/venta_detalle_input.dart';

/// Sheet de selección de variante POR ATRIBUTO.
///
/// En vez de listar cada combinación como una card suelta, agrupa los
/// atributos del producto (Talla, Forma, Modelo, ...) derivándolos de las
/// propias variantes y muestra un set de chips por atributo. La combinación
/// elegida resuelve a una variante concreta; el usuario fija la cantidad y
/// agrega al carrito.
///
/// [onAgregar] recibe la variante resuelta y la cantidad elegida. El caller
/// decide cómo materializarla en el carrito (típicamente llamando N veces a
/// `cubit.agregarVariante`).
Future<void> showVarianteSelectorSheet({
  required BuildContext context,
  required ProductoListItem producto,
  required String sedeId,
  required void Function(ProductoVariante variante, int cantidad) onAgregar,
  void Function(ProductoVariante variante)? onQuitarUnidad,
  Map<String, int> cantidadesEnCarrito = const {},
  Map<String, List<PrecioNivel>> nivelesVariantes = const {},
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    constraints: BoxConstraints(
      // Altura fija al 70% de la pantalla (min == max).
      minHeight: MediaQuery.of(context).size.height * 0.70,
      maxHeight: MediaQuery.of(context).size.height * 0.70,
    ),
    builder: (_) => _VarianteSelectorSheet(
      producto: producto,
      sedeId: sedeId,
      onAgregar: onAgregar,
      onQuitarUnidad: onQuitarUnidad,
      cantidadesEnCarrito: cantidadesEnCarrito,
      nivelesVariantes: nivelesVariantes,
    ),
  );
}

/// Grupo de atributo derivado de las variantes: clave única, nombre visible
/// y valores posibles (en orden de aparición).
class _AtributoGrupo {
  final String clave;
  final String nombre;
  final List<String> valores;
  _AtributoGrupo(this.clave, this.nombre, this.valores);
}

class _VarianteSelectorSheet extends StatefulWidget {
  final ProductoListItem producto;
  final String sedeId;
  final void Function(ProductoVariante variante, int cantidad) onAgregar;
  final void Function(ProductoVariante variante)? onQuitarUnidad;
  final Map<String, int> cantidadesEnCarrito;
  final Map<String, List<PrecioNivel>> nivelesVariantes;

  const _VarianteSelectorSheet({
    required this.producto,
    required this.sedeId,
    required this.onAgregar,
    this.onQuitarUnidad,
    this.cantidadesEnCarrito = const {},
    this.nivelesVariantes = const {},
  });

  @override
  State<_VarianteSelectorSheet> createState() => _VarianteSelectorSheetState();
}

/// Clave sintética usada cuando las variantes NO tienen atributos
/// estructurados: se selecciona la variante por su nombre directamente.
const String _kVarianteClave = '__variante__';

class _VarianteSelectorSheetState extends State<_VarianteSelectorSheet> {
  late final List<ProductoVariante> _variantes;
  late final List<_AtributoGrupo> _grupos;

  /// Valor elegido por clave de atributo (null = sin elegir).
  final Map<String, String?> _seleccion = {};
  int _cantidad = 1;

  /// Copia mutable de lo que ya está en el carrito (varianteId -> cantidad).
  /// Se actualiza localmente al "Limpiar" para refrescar el stock disponible.
  late Map<String, int> _enCarrito;

  @override
  void initState() {
    super.initState();
    _variantes = (widget.producto.variantes ?? const <ProductoVariante>[])
        .where((v) => v.isActive)
        .toList();
    _enCarrito = Map.of(widget.cantidadesEnCarrito);
    _grupos = _derivarGrupos(_variantes);
    _autoSeleccionInicial();
  }

  // ---- Derivación de atributos ---------------------------------------------

  List<_AtributoGrupo> _derivarGrupos(List<ProductoVariante> variantes) {
    final orden = <String>[];
    final nombre = <String, String>{};
    final valores = <String, List<String>>{};
    for (final v in variantes) {
      for (final av in v.atributosValores) {
        final clave = av.atributo.clave;
        if (!valores.containsKey(clave)) {
          valores[clave] = [];
          nombre[clave] = av.atributo.nombre;
          orden.add(clave);
        }
        if (!valores[clave]!.contains(av.valor)) {
          valores[clave]!.add(av.valor);
        }
      }
    }
    // Fallback: variantes "simples" sin atributos estructurados (ej. nombradas
    // AZUL/ROJA pero sin el atributo Color asignado). Sintetizamos un único
    // grupo "Variante" cuyos valores son los nombres de cada variante.
    if (orden.isEmpty && variantes.isNotEmpty) {
      final nombres = <String>[];
      for (final v in variantes) {
        if (!nombres.contains(v.nombre)) nombres.add(v.nombre);
      }
      return [_AtributoGrupo(_kVarianteClave, 'Variante', nombres)];
    }
    return orden
        .map((c) => _AtributoGrupo(c, nombre[c] ?? c, valores[c]!))
        .toList();
  }

  /// Pre-selecciona la primera variante con stock (o la primera a secas),
  /// para que el sheet abra con una combinación válida lista, como la imagen.
  void _autoSeleccionInicial() {
    final ordenadas = [..._variantes]..sort((a, b) => a.orden.compareTo(b.orden));
    ProductoVariante? candidata;
    for (final v in ordenadas) {
      if (_stockDisponible(v) > 0) {
        candidata = v;
        break;
      }
    }
    candidata ??= ordenadas.isNotEmpty ? ordenadas.first : null;
    if (candidata != null) {
      final esSintetico =
          _grupos.length == 1 && _grupos.first.clave == _kVarianteClave;
      if (esSintetico) {
        _seleccion[_kVarianteClave] = candidata.nombre;
      } else {
        for (final av in candidata.atributosValores) {
          _seleccion[av.atributo.clave] = av.valor;
        }
      }
    }
    _cantidad = _stockRestante > 0 ? 1 : 0;
  }

  // ---- Matching y disponibilidad -------------------------------------------

  int _stockDisponible(ProductoVariante v) {
    final real = v.stockEnSede(widget.sedeId) ?? 0;
    final enCarrito = _enCarrito[v.id] ?? 0;
    return (real - enCarrito).clamp(0, real);
  }

  /// ¿La variante satisface todas las claves no-nulas de [sel]?
  bool _coincide(ProductoVariante v, Map<String, String?> sel) {
    for (final entry in sel.entries) {
      final valor = entry.value;
      if (valor == null) continue;
      if (entry.key == _kVarianteClave) {
        // Modo sintético: se matchea directamente por nombre de variante.
        if (v.nombre != valor) return false;
        continue;
      }
      final match = v.atributosValores
          .where((a) => a.atributo.clave == entry.key)
          .map((a) => a.valor);
      if (match.isEmpty || match.first != valor) return false;
    }
    return true;
  }

  /// Variante resuelta cuando hay un valor elegido por cada atributo.
  ProductoVariante? get _varianteResuelta {
    if (_grupos.any((g) => _seleccion[g.clave] == null)) return null;
    for (final v in _variantes) {
      if (_coincide(v, _seleccion)) return v;
    }
    return null;
  }

  /// Un valor está disponible si, manteniendo las OTRAS selecciones actuales,
  /// existe al menos una variante con stock que lo use.
  bool _valorDisponible(String clave, String valor) {
    final tentativa = <String, String?>{};
    for (final g in _grupos) {
      tentativa[g.clave] = g.clave == clave ? valor : _seleccion[g.clave];
    }
    for (final v in _variantes) {
      if (_coincide(v, tentativa) && _stockDisponible(v) > 0) return true;
    }
    return false;
  }

  int get _stockRestante {
    final v = _varianteResuelta;
    return v == null ? 0 : _stockDisponible(v);
  }

  void _seleccionar(String clave, String valor) {
    HapticFeedback.selectionClick();
    setState(() {
      _seleccion[clave] = valor;
      // Reparar otros atributos cuya selección quedó incompatible con el
      // nuevo valor, eligiendo el primer valor disponible (UX e-commerce:
      // cambiar color a uno sin tu talla reajusta la talla).
      for (final g in _grupos) {
        if (g.clave == clave) continue;
        final actual = _seleccion[g.clave];
        if (actual == null || _valorDisponible(g.clave, actual)) continue;
        _seleccion[g.clave] = g.valores.firstWhere(
          (v) => _valorDisponible(g.clave, v),
          orElse: () => actual,
        );
      }
      final rest = _stockRestante;
      _cantidad = rest > 0 ? _cantidad.clamp(1, rest) : 0;
    });
  }

  void _cambiarCantidad(int delta) {
    final rest = _stockRestante;
    final nueva = (_cantidad + delta).clamp(0, rest);
    if (nueva == _cantidad) return;
    HapticFeedback.lightImpact();
    setState(() => _cantidad = nueva);
  }

  /// Resetea toda la selección (deselecciona cada atributo), la cantidad y
  /// QUITA del carrito lo ya agregado de este producto. Para empezar de cero
  /// cuando ninguna combinación encaja.
  void _limpiarSeleccion() {
    HapticFeedback.lightImpact();
    // Quitar del carrito cada variante de este producto que tenga unidades.
    if (widget.onQuitarUnidad != null) {
      _enCarrito.forEach((vid, qty) {
        if (qty <= 0) return;
        ProductoVariante? variante;
        for (final v in _variantes) {
          if (v.id == vid) {
            variante = v;
            break;
          }
        }
        if (variante != null) {
          for (var k = 0; k < qty; k++) {
            widget.onQuitarUnidad!(variante);
          }
        }
      });
    }
    setState(() {
      _enCarrito.clear();
      for (final g in _grupos) {
        _seleccion[g.clave] = null;
      }
      _cantidad = 0;
    });
  }

  void _agregar() {
    final v = _varianteResuelta;
    if (v == null || _cantidad <= 0) return;
    HapticFeedback.mediumImpact();
    widget.onAgregar(v, _cantidad);
    Navigator.pop(context);
  }

  // ---- Precio resuelto ------------------------------------------------------

  ({double? precio, double? base, String? nivel}) _precioInfo() {
    final v = _varianteResuelta;
    if (v == null) return (precio: null, base: null, nivel: null);
    final base = v.precioEfectivoEnSede(widget.sedeId) ??
        v.precioEnSede(widget.sedeId);
    if (base == null) return (precio: null, base: null, nivel: null);
    final niveles = widget.nivelesVariantes[v.id] ?? const <PrecioNivel>[];
    final nivel = _cantidad > 0 && niveles.isNotEmpty
        ? VentaDetalleInput.nivelAplicableParaCantidad(niveles, _cantidad.toDouble())
        : null;
    if (nivel != null) {
      return (precio: nivel.calcularPrecioFinal(base), base: base, nivel: nivel.nombre);
    }
    return (precio: base, base: null, nivel: null);
  }

  // ---- UI -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final resuelta = _varianteResuelta;
    final precioInfo = _precioInfo();
    final imagen = resuelta?.thumbnailPrincipal;
    final puedeAgregar = resuelta != null && _cantidad > 0;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        // Altura fija: el cuerpo (Flexible) llena y el footer queda abajo.
        mainAxisSize: MainAxisSize.max,
        // stretch: los hijos ocupan todo el ancho → el cuerpo de atributos
        // alinea a la izquierda real (antes, con el default center, quedaba
        // centrado a su ancho intrínseco y parecía tener padding izquierdo).
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              width: 30,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          _buildHeader(imagen, precioInfo, resuelta),
          const Divider(height: 1),
          // Cuerpo scrolleable: secciones de atributos
          Flexible(
            child: _variantes.isEmpty || _grupos.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(25),
                    child: Text(
                      'No hay variantes disponibles',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Elige la variante',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            InkWell(
                              onTap: _limpiarSeleccion,
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.refresh,
                                        size: 14, color: Colors.grey.shade600),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Limpiar',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ..._grupos.map(_buildGrupo),
                      ],
                    ),
                  ),
          ),
          const Divider(height: 1),
          _buildFooter(resuelta, puedeAgregar),
        ],
      ),
    );
  }

  Widget _buildHeader(
    String? imagen,
    ({double? precio, double? base, String? nivel}) precioInfo,
    ProductoVariante? resuelta,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
      child: Row(
        children: [
          GestureDetector(
            onLongPress: () => _verImagenCompleta(resuelta, imagen),
            child: imagen != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: imagen,
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                          width: 110, height: 110, color: Colors.grey.shade100),
                      errorWidget: (_, __, ___) => _placeholderImg(),
                    ),
                  )
                : _placeholderImg(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.producto.nombre,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                if (precioInfo.precio != null)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'S/ ${precioInfo.precio!.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: precioInfo.nivel != null
                              ? AppColors.blue1
                              : Colors.grey.shade800,
                        ),
                      ),
                      if (precioInfo.base != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          'S/ ${precioInfo.base!.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  )
                else
                  Text(
                    'Selecciona una combinación',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                if (resuelta != null) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 13,
                        color: _stockRestante > 0
                            ? Colors.green.shade600
                            : Colors.red.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _stockRestante > 0
                            ? 'Stock disponible: $_stockRestante'
                            : 'Sin stock',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _stockRestante > 0
                              ? Colors.green.shade700
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
                if (resuelta != null) _buildBadges(resuelta),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 20),
            color: Colors.grey.shade500,
          ),
        ],
      ),
    );
  }

  Widget _buildBadges(ProductoVariante v) {
    final enLiq = v.enLiquidacionEnSede(widget.sedeId);
    final enOferta = v.enOfertaEnSede(widget.sedeId);
    if (!enLiq && !enOferta) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: enLiq ? Colors.deepOrange.shade700 : Colors.green.shade700,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          enLiq ? 'LIQUIDACIÓN' : 'OFERTA',
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildGrupo(_AtributoGrupo g) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            g.nombre.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: g.valores.map((valor) {
              final disponible = _valorDisponible(g.clave, valor);
              final seleccionado = _seleccion[g.clave] == valor;
              return _AtributoValorChip(
                label: valor,
                selected: seleccionado,
                enabled: disponible || seleccionado,
                onTap: () => _seleccionar(g.clave, valor),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ProductoVariante? resuelta, bool puedeAgregar) {
    final sinStock = resuelta != null && _stockRestante <= 0;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      child: Row(
        children: [
          // Stepper de cantidad
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _stepBtn(
                  Icons.remove,
                  onTap: puedeAgregar && _cantidad > 1
                      ? () => _cambiarCantidad(-1)
                      : null,
                ),
                Container(
                  constraints: const BoxConstraints(minWidth: 36),
                  alignment: Alignment.center,
                  child: Text(
                    '$_cantidad',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _stepBtn(
                  Icons.add,
                  onTap: puedeAgregar && _cantidad < _stockRestante
                      ? () => _cambiarCantidad(1)
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Botón agregar (design system)
          Expanded(
            child: CustomButton(
              text: sinStock
                  ? 'Sin stock'
                  : resuelta == null
                      ? 'Elige una combinación'
                      : 'Agregar al carrito',
              onPressed: _agregar,
              enabled: puedeAgregar,
              backgroundColor: AppColors.blue1,
              icon: Icon(
                Icons.add_shopping_cart,
                size: 16,
                color: puedeAgregar ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepBtn(IconData icon, {VoidCallback? onTap}) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppColors.blue1 : Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _placeholderImg() => Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: AppColors.blue1.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.style,
            size: 30, color: AppColors.blue1.withValues(alpha: 0.5)),
      );

  void _verImagenCompleta(ProductoVariante? v, String? thumb) {
    final fullUrl = v?.imagenPrincipal ?? thumb;
    if (fullUrl == null) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        pageBuilder: (_, __, ___) => Scaffold(
          backgroundColor: Colors.black87,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              v?.nombre ?? widget.producto.nombre,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          body: InteractiveViewer(
            minScale: 0.5,
            maxScale: 5.0,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: fullUrl,
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(color: Colors.white)),
                errorWidget: (_, __, ___) => const Icon(Icons.broken_image,
                    size: 48, color: Colors.white54),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip tipo radio para un valor de atributo (mimetiza el patrón de la imagen:
/// círculo radio + label, acento al seleccionar, atenuado si no disponible).
class _AtributoValorChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _AtributoValorChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AppColors.blue1
        : (enabled ? Colors.grey.shade300 : Colors.grey.shade200);
    final textColor = selected
        ? AppColors.blue1
        : (enabled ? Colors.grey.shade800 : Colors.grey.shade400);

    return Opacity(
      opacity: enabled ? 1.0 : 0.6,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.fromLTRB(10, 9, 12, 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.blue1.withValues(alpha: 0.06) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _radio(),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: textColor,
                  decoration:
                      enabled ? null : TextDecoration.lineThrough,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _radio() {
    final color = selected
        ? AppColors.blue1
        : (enabled ? Colors.grey.shade400 : Colors.grey.shade300);
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.blue1,
                ),
              ),
            )
          : null,
    );
  }
}
