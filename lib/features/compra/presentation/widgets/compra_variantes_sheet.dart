import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/utils/busqueda_texto.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';

import '../../../producto/domain/entities/producto_list_item.dart';
import '../../../producto/domain/entities/producto_variante.dart';
import '../../../producto/presentation/widgets/coleccion_disenos_card.dart';
import '../../../venta_rapida/presentation/widgets/cantidad_stepper.dart';

/// Elegir qué variantes se compran, desde la grilla de una compra.
///
/// Es propio y no el sheet de Venta Rápida por dos razones: ese muestra
/// PRECIOS DE VENTA —acá el número que decide es el costo— y agrupa las
/// variantes en un acordeón por atributo, donde una variante a la que le falta
/// algún atributo queda INALCANZABLE. Comprando, las variantes mal cargadas son
/// justo las que hay que reponer, así que la lista va PLANA: con buscador,
/// porque un producto puede tener 91. Lo único que se junta son los DISEÑOS
/// de una colección (D1, D2… de CRISTAL), en un renglón plegable con foto:
/// esos sí comparten todos los atributos y se identifican por la imagen.
/// [cantidades] y [onCantidad] van en unidad ATÓMICA (gramos), que es como se
/// guarda el stock; el sheet se encarga de mostrarlas y moverlas en la unidad
/// en la que se compra (kilos).
Future<void> showCompraVariantesSheet({
  required BuildContext context,
  required ProductoListItem producto,
  required String sedeId,
  required Map<String, int> cantidades,
  required void Function(ProductoVariante variante, int cantidad) onCantidad,
  Map<String, double> costos = const {},
  void Function(ProductoVariante variante, double? costo)? onCosto,
  Map<String, double> ventas = const {},
  void Function(ProductoVariante variante, double? venta)? onVenta,
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
      costosIniciales: costos,
      onCosto: onCosto,
      ventasIniciales: ventas,
      onVenta: onVenta,
    ),
  );
}

class _CompraVariantesSheet extends StatefulWidget {
  final ProductoListItem producto;
  final String sedeId;
  final Map<String, int> cantidadesIniciales;
  final void Function(ProductoVariante variante, int cantidad) onCantidad;

  /// Costo ya cargado por variante, en la unidad en la que se COMPRA.
  final Map<String, double> costosIniciales;
  final void Function(ProductoVariante variante, double? costo)? onCosto;

  /// Precio de venta nuevo ya cargado por variante, en la unidad en la que se
  /// COMPRA (el kilo). Se aplica al confirmar la compra.
  final Map<String, double> ventasIniciales;
  final void Function(ProductoVariante variante, double? venta)? onVenta;

  const _CompraVariantesSheet({
    required this.producto,
    required this.sedeId,
    required this.cantidadesIniciales,
    required this.onCantidad,
    this.costosIniciales = const {},
    this.onCosto,
    this.ventasIniciales = const {},
    this.onVenta,
  });

  @override
  State<_CompraVariantesSheet> createState() => _CompraVariantesSheetState();
}

class _CompraVariantesSheetState extends State<_CompraVariantesSheet> {
  final _buscarController = TextEditingController();
  late final Map<String, int> _cantidades;

  /// Un controller por variante, creado recién cuando la fila lo necesita
  /// (un producto puede tener 91) y dispuesto con el sheet: si se dispusiera
  /// al salir la fila de pantalla, el .builder lo mataría al scrollear.
  final Map<String, TextEditingController> _costoCtrls = {};
  final Map<String, TextEditingController> _ventaCtrls = {};
  String _query = '';
  bool _verBloqueadas = false;

  /// Colecciones desplegadas, por [claveColeccion].
  final Set<String> _abiertas = {};

  void _alternar(String clave) {
    setState(() {
      if (!_abiertas.remove(clave)) _abiertas.add(clave);
    });
  }

  @override
  void initState() {
    super.initState();
    _cantidades = Map<String, int>.from(widget.cantidadesIniciales);
    // Las colecciones que ya se están comprando arrancan abiertas: se vuelve
    // al sheet a corregir una cantidad, no a buscarla de nuevo.
    for (final v in widget.producto.variantes ?? const <ProductoVariante>[]) {
      if ((_cantidades[v.id] ?? 0) > 0 && valorDiseno(v) != null) {
        _abiertas.add(claveColeccion(v));
      }
    }
  }

  @override
  void dispose() {
    _buscarController.dispose();
    for (final c in [..._costoCtrls.values, ..._ventaCtrls.values]) {
      c.dispose();
    }
    super.dispose();
  }

  /// El campo de costo de una variante, con lo que ya estuviera cargado.
  TextEditingController _costoCtrl(ProductoVariante v) =>
      _costoCtrls.putIfAbsent(v.id, () {
        final inicial = widget.costosIniciales[v.id];
        return TextEditingController(
          text: inicial != null && inicial > 0
              ? inicial.toStringAsFixed(2)
              : '',
        );
      });

  /// El campo de precio de venta de una variante. Vacío = se mantiene el de
  /// hoy (va de hint).
  TextEditingController _ventaCtrl(ProductoVariante v) =>
      _ventaCtrls.putIfAbsent(v.id, () {
        final inicial = widget.ventasIniciales[v.id];
        return TextEditingController(
          text: inicial != null && inicial > 0
              ? inicial.toStringAsFixed(2)
              : '',
        );
      });

  void _fijarVenta(ProductoVariante v, String texto) {
    final valor = double.tryParse(texto.trim().replaceAll(',', '.'));
    widget.onVenta?.call(v, valor != null && valor > 0 ? valor : null);
  }

  /// 🔑 Lo tecleado va en la unidad en la que se COMPRA (kg, saco), igual que
  /// la cantidad: quien carga una compra piensa "el kilo a S/8", no "el gramo
  /// a S/0.008". La conversión a unidad atómica la hace el carrito, que es
  /// quien sabe si la línea se carga por saco o por presentación.
  ///
  /// Vacío = el costo ACTUAL de la sede, igual que la venta vacía mantiene la
  /// de hoy. Solo una variante que nunca se compró acá queda sin costo (y la
  /// compra no se crea hasta ponérselo).
  void _fijarCosto(ProductoVariante v, String texto) {
    final valor = double.tryParse(texto.trim().replaceAll(',', '.'));
    if (valor != null && valor > 0) {
      widget.onCosto?.call(v, valor);
      return;
    }
    final actual = v.stockSedeInfo(widget.sedeId)?.precioCosto;
    widget.onCosto?.call(
      v,
      actual != null && actual > 0
          ? widget.producto.presentacionDeVariante(v).precio(actual)
          : null,
    );
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
    final out = <_Entrada>[];
    // Buscando también quedan plegadas (pedido del user): el renglón de la
    // colección ya dice que hay diseños que coinciden.
    for (final fila in agruparPorColeccion(comprables)) {
      switch (fila) {
        case FilaVariante(:final variante):
          out.add(_EntradaVariante(variante, bloqueada: false));
        case FilaColeccion(:final disenos):
          final clave = claveColeccion(disenos.first);
          final abierta = _abiertas.contains(clave);
          out.add(_EntradaColeccion(disenos, clave: clave, abierta: abierta));
      }
    }
    if (bloqueadas.isNotEmpty) {
      out.add(_EntradaEncabezado(bloqueadas.length));
      if (_verBloqueadas) {
        out.addAll(bloqueadas.map((v) => _EntradaVariante(v, bloqueada: true)));
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

  /// Lo tecleado en el stepper va en la unidad en la que se compra ("1.5" kg):
  /// se pasa a unidad atómica. Vacío o a medio escribir ("1.") no toca nada,
  /// así borrar para reescribir no saca la línea de la compra.
  void _escribir(ProductoVariante v, String texto) {
    final valor = double.tryParse(texto.trim().replaceAll(',', '.'));
    if (valor == null) return;
    final cantidad = (valor * _paso(v)).round();
    if (cantidad == (_cantidades[v.id] ?? 0)) return;
    _fijar(v, cantidad);
  }

  void _sumar(ProductoVariante v) =>
      _fijar(v, (_cantidades[v.id] ?? 0) + _paso(v));

  void _restar(ProductoVariante v) {
    final actual = _cantidades[v.id] ?? 0;
    if (actual <= 0) return;
    final nueva = actual - _paso(v);
    _fijar(v, nueva < 0 ? 0 : nueva);
  }

  Widget _fila(_EntradaVariante fila) => _FilaVariante(
        producto: widget.producto,
        variante: fila.variante,
        enColeccion: fila.enColeccion,
        sedeId: widget.sedeId,
        cantidad: _cantidades[fila.variante.id] ?? 0,
        bloqueada: fila.bloqueada,
        onSumar: () => _sumar(fila.variante),
        onRestar: () => _restar(fila.variante),
        onEscribir: (texto) => _escribir(fila.variante, texto),
        paso: _paso(fila.variante),
        // Solo las que se están comprando: crear un controller por cada una de
        // las 91 filas sería pura basura.
        costoCtrl: widget.onCosto == null ||
                fila.bloqueada ||
                (_cantidades[fila.variante.id] ?? 0) <= 0
            ? null
            : _costoCtrl(fila.variante),
        onCosto: widget.onCosto == null
            ? null
            : (texto) => _fijarCosto(fila.variante, texto),
        ventaCtrl: widget.onVenta == null ||
                fila.bloqueada ||
                (_cantidades[fila.variante.id] ?? 0) <= 0
            ? null
            : _ventaCtrl(fila.variante),
        onVenta: widget.onVenta == null
            ? null
            : (texto) => _fijarVenta(fila.variante, texto),
      );

  @override
  Widget build(BuildContext context) {
    final (comprables, bloqueadas) = _particion;
    final entradas = _entradas(comprables, bloqueadas);
    // Cuántas VARIANTES se eligieron, no cuántas unidades: con un granel en
    // gramos, sumar unidades diría "Listo (15000)".
    final elegidas = _cantidades.length;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
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
                              () => _verBloqueadas = !_verBloqueadas,
                            ),
                          );
                        }
                        if (entrada is _EntradaColeccion) {
                          return _EncabezadoColeccion(
                            disenos: entrada.disenos,
                            abierta: entrada.abierta,
                            elegidos: entrada.disenos
                                .where((d) => (_cantidades[d.id] ?? 0) > 0)
                                .length,
                            unidades: entrada.disenos.fold<int>(
                              0,
                              (t, d) => t + (_cantidades[d.id] ?? 0),
                            ),
                            onTap: () => _alternar(entrada.clave),
                            hijos: [
                              if (entrada.abierta)
                                for (final d in entrada.disenos)
                                  _fila(_EntradaVariante(
                                    d,
                                    bloqueada: false,
                                    enColeccion: true,
                                  )),
                            ],
                          );
                        }
                        return _fila(entrada as _EntradaVariante);
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
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
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

  /// Es un diseño que va debajo del renglón de su colección.
  final bool enColeccion;
  const _EntradaVariante(
    this.variante, {
    required this.bloqueada,
    this.enColeccion = false,
  });
}

class _EntradaColeccion extends _Entrada {
  final List<ProductoVariante> disenos;
  final String clave;
  final bool abierta;
  const _EntradaColeccion(
    this.disenos, {
    required this.clave,
    required this.abierta,
  });
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

/// Foto chica de una variante para reconocerla de un vistazo; sin foto, el
/// número de diseño (o un ícono).
class _Foto extends StatelessWidget {
  final ProductoVariante variante;
  final double lado;

  /// Foto de la colección entera: sin foto no se pone "D1", que se leería
  /// como si el renglón fuera ese diseño.
  final bool esColeccion;

  const _Foto(this.variante, {this.lado = 36, this.esColeccion = false});

  @override
  Widget build(BuildContext context) {
    final url = variante.thumbnailPrincipal;
    final diseno = esColeccion ? null : valorDiseno(variante);
    final sinFoto = Center(
      child: diseno != null
          ? Text(
              diseno,
              maxLines: 1,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade500,
              ),
            )
          : Icon(
              esColeccion
                  ? Icons.collections_outlined
                  : Icons.image_not_supported_outlined,
              size: lado * 0.45,
              color: Colors.grey.shade400,
            ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: lado,
        height: lado,
        color: const Color(0xFFF1F4F8),
        child: url != null
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                memCacheWidth: (lado * 3).round(),
                errorWidget: (_, __, ___) => sinFoto,
              )
            : sinFoto,
      ),
    );
  }
}

/// El renglón plegable de una colección: foto, nombre corto, cuántos diseños
/// y lo que ya se está comprando de ella, para no tener que abrirla.
class _EncabezadoColeccion extends StatelessWidget {
  final List<ProductoVariante> disenos;
  final bool abierta;
  final int elegidos;
  final int unidades;
  final VoidCallback onTap;

  /// Las filas de los diseños, ya armadas (vacío si está plegada): van DENTRO
  /// de la misma card, como ramas, para que la colección se lea como un todo.
  final List<Widget> hijos;

  const _EncabezadoColeccion({
    required this.disenos,
    required this.abierta,
    required this.elegidos,
    required this.unidades,
    required this.onTap,
    this.hijos = const [],
  });

  @override
  Widget build(BuildContext context) {
    final conFoto = disenos.firstWhere(
      (d) => d.thumbnailPrincipal != null,
      orElse: () => disenos.first,
    );
    final enCarrito = elegidos > 0;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: enCarrito
            ? AppColors.blue1.withValues(alpha: 0.04)
            : const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: enCarrito
              ? AppColors.blue1.withValues(alpha: 0.35)
              : Colors.grey.shade300,
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
          child: Row(
            children: [
              _Foto(conFoto, lado: 40, esColeccion: true),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombreColeccion(disenos.first),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.blue1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${tituloColeccion(disenos.first)} · ${disenos.length} diseños',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (enCarrito)
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.blue1,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    // Los diseños se compran por unidad: sumar sirve.
                    '$unidades u',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              Icon(
                abierta ? Icons.expand_less : Icons.expand_more,
                size: 20,
                color: Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
          if (hijos.isNotEmpty) ...[
            Divider(height: 1, thickness: 0.5, color: Colors.grey.shade300),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 2, 0, 4),
              child: Column(children: hijos),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilaVariante extends StatelessWidget {
  final ProductoListItem producto;
  final ProductoVariante variante;
  final String sedeId;
  final int cantidad;

  /// Diseño debajo de su colección: va sangrado y se nombra solo "D3", que el
  /// resto del nombre ya lo dice el renglón de arriba.
  final bool enColeccion;

  /// Es un granel: entra al stock por la apertura de un bulto, no por compra.
  final bool bloqueada;
  final VoidCallback onSumar;
  final VoidCallback onRestar;

  /// Lo tecleado en el número del stepper, en la unidad en la que se compra.
  final ValueChanged<String>? onEscribir;

  /// Unidades atómicas por unidad de compra (1000 g = 1 kg; 1 sin presentación).
  final int paso;

  /// Campo de costo de ESTA variante. Null = el sheet se abrió sin permitir
  /// cargar costos (no todos los llamadores lo necesitan).
  final TextEditingController? costoCtrl;
  final void Function(String texto)? onCosto;

  /// Campo de precio de venta nuevo. Null = el llamador no lo ofrece.
  final TextEditingController? ventaCtrl;
  final void Function(String texto)? onVenta;

  const _FilaVariante({
    required this.producto,
    required this.variante,
    required this.sedeId,
    required this.cantidad,
    required this.onSumar,
    required this.onRestar,
    this.onEscribir,
    this.paso = 1,
    this.enColeccion = false,
    this.bloqueada = false,
    this.costoCtrl,
    this.onCosto,
    this.ventaCtrl,
    this.onVenta,
  });

  static const anchoStepper = 88.0;

  @override
  Widget build(BuildContext context) {
    final info = variante.stockSedeInfo(sedeId);
    // La presentación sale de la VARIANTE: un saco cerrado se compra por
    // unidad aunque el producto se guarde en gramos.
    final presentacion = producto.presentacionDeVariante(variante);
    final costo = info?.precioCosto;
    final venta = info?.precio;
    final unidad =
        presentacion.activa ? '/${presentacion.simboloVisible}' : null;
    final enCarrito = cantidad > 0;

    return Container(
      margin: EdgeInsets.fromLTRB(enColeccion ? 6 : 0, enColeccion ? 0 : 3, 0, enColeccion ? 0 : 3),
      padding: EdgeInsets.fromLTRB(enColeccion ? 0 : 8, enColeccion ? 3 : 6, 6, enColeccion ? 3 : 6),
      // Debajo de su colección va como rama de un árbol, sin card propia:
      // card dentro de card se ve recargado.
      decoration: enColeccion ? null : BoxDecoration(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (enColeccion) ...[
                Icon(
                  Icons.subdirectory_arrow_right,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(width: 4),
              ],
              _Foto(variante),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      enColeccion
                          ? (valorDiseno(variante) ?? variante.nombre)
                          : variante.nombre,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: bloqueada ? Colors.grey.shade600 : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Wrap y no Row: costo, venta y stock no entran en una
                    // línea al lado de la foto y el stepper; lo que no entra
                    // baja, en vez de cortarse.
                    Wrap(
                      spacing: 8,
                      runSpacing: 1,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (bloqueada)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lock_outline,
                                size: 11,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                // No se dice el costo: el del granel lo escribe
                                // la apertura por promedio ponderado, y
                                // mostrarlo acá invita a "corregirlo" en la
                                // compra, que es justo lo que ensucia el margen.
                                'sale de abrir un saco',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          )
                        else ...[
                          Text(
                            // Sin costo se dice: es una variante que nunca se
                            // compró en esta sede, no una que sale gratis.
                            costo == null || costo <= 0
                                ? 'sin costo'
                                : 'Costo ${presentacion.precioTexto(costo)}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: costo == null || costo <= 0
                                  ? Colors.orange.shade800
                                  : Colors.grey.shade800,
                            ),
                          ),
                          // El de venta al lado, para ver el margen mientras se
                          // carga el costo nuevo.
                          if (venta != null && venta > 0)
                            Text(
                              'Venta ${presentacion.precioTexto(venta)}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.green.shade700,
                              ),
                            ),
                        ],
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
              const SizedBox(width: 6),
              if (bloqueada && !enCarrito)
                // Sin stepper: no hay nada que sumar. Se reserva su ancho para
                // que las filas de las dos secciones queden alineadas y la
                // lista no baile al desplegar.
                const SizedBox(
                  width: _FilaVariante.anchoStepper,
                  height: CantidadStepper.alto,
                )
              else
                SizedBox(
                  width: _FilaVariante.anchoStepper,
                  // El mismo `[−] N [+]` del carrito de Venta Rápida, con el
                  // número escribible: 24 unidades se tipean, no se tocan 24
                  // veces.
                  child: _CantidadCompra(
                    key: ValueKey('cantidad-compra:${variante.id}'),
                    cantidad: cantidad,
                    paso: paso,
                    decimales: presentacion.activa && paso > 1,
                    onEscribir: onEscribir ?? (_) {},
                    onMas: onSumar,
                    onMenos: onRestar,
                    // Un granel que YA venía cargado se puede SACAR pero no
                    // sumar: bloquear también el menos lo dejaría trabado
                    // adentro de la compra sin forma de quitarlo.
                    puedeMas: !bloqueada,
                    puedeMenos: enCarrito,
                    soloLectura: bloqueada,
                  ),
                ),
            ],
          ),
          // El costo se carga ACÁ, en la misma pasada que la cantidad: si no,
          // hay que abrir el editor de cada línea una por una. Solo aparece en
          // lo que se está comprando; en el resto sería ruido.
          if (enCarrito && !bloqueada && (costoCtrl != null || ventaCtrl != null)) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (costoCtrl != null)
                  Expanded(
                    child: CustomText(
                      controller: costoCtrl,
                      label: 'Costo',
                      prefixText: 'S/ ',
                      // La unidad en la que se teclea: sin esto un granel se
                      // carga con el precio del gramo.
                      suffixText: unidad,
                      // Vacío se usa el costo de hoy: va de hint, como en la
                      // venta.
                      hintText: costo != null && costo > 0
                          ? presentacion.precio(costo).toStringAsFixed(2)
                          : '0.00',
                      borderColor: AppColors.blue1,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      onChanged: onCosto,
                    ),
                  ),
                if (costoCtrl != null && ventaCtrl != null)
                  const SizedBox(width: 8),
                if (ventaCtrl != null)
                  Expanded(
                    child: CustomText(
                      controller: ventaCtrl,
                      label: 'Venta',
                      prefixText: 'S/ ',
                      suffixText: unidad,
                      // Vacío se mantiene el de hoy: va de hint para que se
                      // vea a cuánto se vende sin tener que escribirlo.
                      hintText: venta != null && venta > 0
                          ? presentacion.precio(venta).toStringAsFixed(2)
                          : '0.00',
                      borderColor: Colors.green.shade700,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      onChanged: onVenta,
                    ),
                  ),
              ],
            ),
            // Repetir el costo anterior es el caso normal: se ofrece de un
            // toque en vez de obligar a tipearlo.
            if (costoCtrl != null && costo != null && costo > 0)
              InkWell(
                onTap: () {
                  final anterior =
                      presentacion.precio(costo).toStringAsFixed(2);
                  costoCtrl!.text = anterior;
                  onCosto?.call(anterior);
                },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Text(
                    'usar costo anterior ${presentacion.precioTexto(costo)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blue1,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// El [CantidadStepper] de una fila de la compra, con su controller y su foco.
///
/// El número va en la unidad en la que se compra (cantidad / [paso]). Mientras
/// se escribe no se pisa lo tecleado; si la cantidad cambia por los botones,
/// el texto se pone al día.
class _CantidadCompra extends StatefulWidget {
  final int cantidad;
  final int paso;
  final bool decimales;
  final ValueChanged<String> onEscribir;
  final VoidCallback onMas;
  final VoidCallback onMenos;
  final bool puedeMas;
  final bool puedeMenos;

  /// Granel ya cargado: se puede bajar con el `−` pero no escribir.
  final bool soloLectura;

  const _CantidadCompra({
    super.key,
    required this.cantidad,
    required this.paso,
    required this.decimales,
    required this.onEscribir,
    required this.onMas,
    required this.onMenos,
    required this.puedeMas,
    required this.puedeMenos,
    this.soloLectura = false,
  });

  @override
  State<_CantidadCompra> createState() => _CantidadCompraState();
}

class _CantidadCompraState extends State<_CantidadCompra> {
  late final TextEditingController _ctrl =
      TextEditingController(text: _texto(widget.cantidad));
  final FocusNode _foco = FocusNode();

  String _texto(int cantidad) {
    final n = cantidad / widget.paso;
    if (n == n.roundToDouble()) return n.toInt().toString();
    return n
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  double? _valor(String texto) =>
      double.tryParse(texto.trim().replaceAll(',', '.'));

  @override
  void didUpdateWidget(covariant _CantidadCompra old) {
    super.didUpdateWidget(old);
    // Solo si de verdad cambió el número: "1." a medio escribir vale 1 y no se
    // pisa, pero un toque al `+` sí se refleja aunque el campo tenga el foco.
    final esperado = widget.cantidad / widget.paso;
    if (_valor(_ctrl.text) != esperado) {
      _ctrl.text = _texto(widget.cantidad);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _foco.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stepper = CantidadStepper(
      controller: _ctrl,
      focusNode: _foco,
      decimales: widget.decimales,
      onChanged: widget.onEscribir,
      onMas: widget.onMas,
      onMenos: widget.onMenos,
      puedeMas: widget.puedeMas,
      puedeMenos: widget.puedeMenos,
    );
    if (!widget.soloLectura) return stepper;
    // El número no se escribe, pero el `−` sigue andando.
    return Stack(
      children: [
        stepper,
        Positioned.fill(
          left: CantidadStepper.anchoBoton,
          right: CantidadStepper.anchoBoton,
          child: const AbsorbPointer(child: SizedBox.expand()),
        ),
      ],
    );
  }
}
