import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/utils/busqueda_texto.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';

import '../../../producto/domain/entities/producto_list_item.dart';
import '../../../producto/domain/entities/producto_variante.dart';

/// Elegir qué variantes se compran, desde la grilla de una compra.
///
/// Es propio y no el sheet de Venta Rápida por dos razones: ese muestra
/// PRECIOS DE VENTA —acá el número que decide es el costo— y agrupa las
/// variantes en un acordeón por atributo, donde una variante a la que le falta
/// algún atributo queda INALCANZABLE. Comprando, las variantes mal cargadas son
/// justo las que hay que reponer, así que la lista va PLANA: con buscador,
/// porque un producto puede tener 91.
/// [cantidades] y [onCantidad] van en unidad ATÓMICA (gramos), que es como se
/// guarda el stock; el sheet se encarga de mostrarlas y moverlas en la unidad
/// en la que se compra (kilos).
Future<void> showCompraVariantesSheet({
  required BuildContext context,
  required ProductoListItem producto,
  required String sedeId,
  required Map<String, int> cantidades,
  required void Function(ProductoVariante variante, int cantidad) onCantidad,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CompraVariantesSheet(
      producto: producto,
      sedeId: sedeId,
      cantidadesIniciales: cantidades,
      onCantidad: onCantidad,
    ),
  );
}

class _CompraVariantesSheet extends StatefulWidget {
  final ProductoListItem producto;
  final String sedeId;
  final Map<String, int> cantidadesIniciales;
  final void Function(ProductoVariante variante, int cantidad) onCantidad;

  const _CompraVariantesSheet({
    required this.producto,
    required this.sedeId,
    required this.cantidadesIniciales,
    required this.onCantidad,
  });

  @override
  State<_CompraVariantesSheet> createState() => _CompraVariantesSheetState();
}

class _CompraVariantesSheetState extends State<_CompraVariantesSheet> {
  final _buscarController = TextEditingController();
  late final Map<String, int> _cantidades;
  String _query = '';
  bool _verBloqueadas = false;

  @override
  void initState() {
    super.initState();
    _cantidades = Map<String, int>.from(widget.cantidadesIniciales);
  }

  @override
  void dispose() {
    _buscarController.dispose();
    super.dispose();
  }

  /// Las que se compran y las que NO, ya pasadas por el buscador.
  ///
  /// El corte lo da el vinculo de apertura: un GRANEL al que apunta un SACO
  /// entra al stock ABRIENDO, no comprando. El set de destinos se resuelve UNA
  /// vez y no por fila, que un producto puede tener 91 variantes.
  (List<ProductoVariante>, List<ProductoVariante>) get _particion {
    final destinos = widget.producto.destinosDeApertura;
    final terminos = terminosBusqueda(_query);
    final comprables = <ProductoVariante>[];
    final bloqueadas = <ProductoVariante>[];
    for (final v in widget.producto.variantes ?? const <ProductoVariante>[]) {
      if (!v.isActive) continue;
      if (terminos.isNotEmpty &&
          !coincideTodosLosTerminos(
            '${v.nombre} ${v.sku} ${v.codigoEmpresa} ${v.codigoBarras ?? ''}',
            terminos,
          )) {
        continue;
      }
      (destinos.contains(v.id) ? bloqueadas : comprables).add(v);
    }
    return (comprables, bloqueadas);
  }

  /// La lista aplanada que consume el `.builder`: las comprables, y despues el
  /// encabezado de la seccion bloqueada con sus filas si esta desplegada.
  List<_Entrada> _entradas(
    List<ProductoVariante> comprables,
    List<ProductoVariante> bloqueadas,
  ) {
    final out = <_Entrada>[
      for (final v in comprables) _EntradaVariante(v, bloqueada: false),
    ];
    if (bloqueadas.isNotEmpty) {
      out.add(_EntradaEncabezado(bloqueadas.length));
      if (_verBloqueadas) {
        out.addAll(
          bloqueadas.map((v) => _EntradaVariante(v, bloqueada: true)),
        );
      }
    }
    return out;
  }

  /// Cuánto suma o resta un toque, en unidades atómicas: **una unidad de la
  /// unidad en la que se compra**. Para un granel en gramos eso es 1 kg = 1000,
  /// no 1 gramo — a razón de un gramo por toque, cargar un saco serían 22 000
  /// toques.
  int _paso(ProductoVariante v) {
    final factor = widget.producto.presentacionDeVariante(v).factor;
    return factor > 1 ? factor.round() : 1;
  }

  void _fijar(ProductoVariante v, int cantidad) {
    setState(() {
      if (cantidad <= 0) {
        _cantidades.remove(v.id);
      } else {
        _cantidades[v.id] = cantidad;
      }
    });
    widget.onCantidad(v, cantidad < 0 ? 0 : cantidad);
  }

  void _sumar(ProductoVariante v) =>
      _fijar(v, (_cantidades[v.id] ?? 0) + _paso(v));

  void _restar(ProductoVariante v) {
    final actual = _cantidades[v.id] ?? 0;
    if (actual <= 0) return;
    final nueva = actual - _paso(v);
    _fijar(v, nueva < 0 ? 0 : nueva);
  }

  @override
  Widget build(BuildContext context) {
    final (comprables, bloqueadas) = _particion;
    final entradas = _entradas(comprables, bloqueadas);
    // Cuántas VARIANTES se eligieron, no cuántas unidades: con un granel en
    // gramos, sumar unidades diría "Listo (15000)".
    final elegidas = _cantidades.length;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              child: Row(
                children: [
                  Icon(Icons.style, size: 16, color: AppColors.blue1),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.producto.nombre.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.blue1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    // Con bultos el numero honesto es cuantas se COMPRAN: decir
                    // "28 variantes" y ofrecer 16 se lee como si faltaran.
                    bloqueadas.isEmpty
                        ? '${comprables.length} variantes'
                        : '${comprables.length} se compran',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: CustomText(
                controller: _buscarController,
                borderColor: AppColors.blue1,
                hintText: 'Filtrar variantes...',
                prefixIcon: const Icon(Icons.search, size: 18),
                onChanged: (valor) => setState(() => _query = valor),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: entradas.isEmpty
                  ? Center(
                      child: Text(
                        'Ninguna variante coincide',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    )
                  // .builder porque un producto puede tener decenas de
                  // variantes y construirlas todas de una traba el scroll.
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemCount: entradas.length,
                      itemBuilder: (_, i) {
                        final entrada = entradas[i];
                        if (entrada is _EntradaEncabezado) {
                          return _EncabezadoBloqueadas(
                            cuantas: entrada.cuantas,
                            abierto: _verBloqueadas,
                            onTap: () => setState(
                                () => _verBloqueadas = !_verBloqueadas),
                          );
                        }
                        final fila = entrada as _EntradaVariante;
                        return _FilaVariante(
                          producto: widget.producto,
                          variante: fila.variante,
                          sedeId: widget.sedeId,
                          cantidad: _cantidades[fila.variante.id] ?? 0,
                          bloqueada: fila.bloqueada,
                          onSumar: () => _sumar(fila.variante),
                          onRestar: () => _restar(fila.variante),
                        );
                      },
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.blue1,
                      minimumSize: const Size(0, 44),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      elegidas > 0 ? 'Listo ($elegidas)' : 'Listo',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Una entrada de la lista: o una variante, o el encabezado de la seccion de
/// las que no se compran.
sealed class _Entrada {
  const _Entrada();
}

class _EntradaVariante extends _Entrada {
  final ProductoVariante variante;
  final bool bloqueada;
  const _EntradaVariante(this.variante, {required this.bloqueada});
}

class _EntradaEncabezado extends _Entrada {
  final int cuantas;
  const _EntradaEncabezado(this.cuantas);
}

/// Separador plegable de los graneles.
///
/// Se muestran y no se esconden a proposito: si desaparecieran, el que busca
/// "POLLO GRANEL" y no lo encuentra concluye que el sheet esta roto o que la
/// variante se borro. Aca dice por que no se compra y donde sale.
class _EncabezadoBloqueadas extends StatelessWidget {
  final int cuantas;
  final bool abierto;
  final VoidCallback onTap;

  const _EncabezadoBloqueadas({
    required this.cuantas,
    required this.abierto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        // 44 de alto para que el dedo no falle al plegar.
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
        child: Row(
          children: [
            Icon(Icons.lock_outline, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'No se compran · entran al abrir un saco ($cuantas)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            Icon(
              abierto ? Icons.expand_less : Icons.expand_more,
              size: 18,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaVariante extends StatelessWidget {
  final ProductoListItem producto;
  final ProductoVariante variante;
  final String sedeId;
  final int cantidad;

  /// Es un granel: entra al stock por la apertura de un bulto, no por compra.
  final bool bloqueada;
  final VoidCallback onSumar;
  final VoidCallback onRestar;

  const _FilaVariante({
    required this.producto,
    required this.variante,
    required this.sedeId,
    required this.cantidad,
    required this.onSumar,
    required this.onRestar,
    this.bloqueada = false,
  });

  @override
  Widget build(BuildContext context) {
    final info = variante.stockSedeInfo(sedeId);
    // La presentación sale de la VARIANTE: un saco cerrado se compra por
    // unidad aunque el producto se guarde en gramos.
    final presentacion = producto.presentacionDeVariante(variante);
    final costo = info?.precioCosto;
    final enCarrito = cantidad > 0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
      decoration: BoxDecoration(
        color: bloqueada
            ? Colors.grey.shade50
            : enCarrito
                ? AppColors.blue1.withValues(alpha: 0.04)
                : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: bloqueada
              ? Colors.grey.shade200
              : enCarrito
                  ? AppColors.blue1.withValues(alpha: 0.35)
                  : Colors.grey.shade300,
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  variante.nombre,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: bloqueada ? Colors.grey.shade600 : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (bloqueada) ...[
                      Icon(Icons.lock_outline,
                          size: 11, color: Colors.grey.shade500),
                      const SizedBox(width: 3),
                      Text(
                        // No se dice el costo: el del granel lo escribe la
                        // apertura por promedio ponderado, y mostrarlo acá
                        // invita a "corregirlo" en la compra, que es justo lo
                        // que ensucia el margen.
                        'sale de abrir un saco',
                        style:
                            TextStyle(fontSize: 10, color: Colors.grey.shade600),
                      ),
                    ] else
                      Text(
                        // Sin costo se dice: es una variante que nunca se
                        // compró en esta sede, no una que sale gratis.
                        costo == null || costo <= 0
                            ? 'sin costo'
                            : presentacion.precioTexto(costo),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: costo == null || costo <= 0
                              ? Colors.orange.shade800
                              : Colors.grey.shade800,
                        ),
                      ),
                    Text(
                      '  ·  ',
                      style:
                          TextStyle(fontSize: 10, color: Colors.grey.shade400),
                    ),
                    Text(
                      info == null
                          ? 'NUEVA en esta sede'
                          : 'Stock ${presentacion.cantidadTexto(info.cantidad)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: info == null
                            ? Colors.orange.shade800
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (bloqueada && !enCarrito)
            // Sin stepper: no hay nada que sumar. Se reserva el ancho de los
            // tres controles para que las filas de las dos secciones queden
            // alineadas y la lista no baile al desplegar.
            const SizedBox(width: 128, height: 40)
          else ...[
            // Los toques van a 40x40: por debajo de eso el dedo falla y se
            // termina sumando de más.
            IconButton(
              onPressed: enCarrito ? onRestar : null,
              iconSize: 18,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.remove_circle_outline),
              color: AppColors.blue1,
            ),
            SizedBox(
              width: 48,
              child: Text(
                // En la unidad en la que se compra: "2 kg", no "2000".
                enCarrito ? presentacion.cantidadTexto(cantidad) : '0',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: enCarrito ? AppColors.blue1 : Colors.grey.shade400,
                ),
              ),
            ),
            IconButton(
              // Un granel que YA venia cargado se puede SACAR pero no sumar:
              // bloquear tambien el menos lo dejaria trabado adentro de la
              // compra sin forma de quitarlo.
              onPressed: bloqueada ? null : onSumar,
              iconSize: 18,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.add_circle_outline),
              color: AppColors.blue1,
            ),
          ],
        ],
      ),
    );
  }
}
