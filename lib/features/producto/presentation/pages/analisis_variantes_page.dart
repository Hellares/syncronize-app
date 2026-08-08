import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/utils/unidad_presentacion.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_sede_selector.dart';
import '../../../../core/widgets/snack_bar_helper.dart';
import '../../../../core/widgets/styled_dialog.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/producto_stock.dart';
import '../../domain/entities/producto_variante.dart';
import '../../domain/entities/stock_por_sede_info.dart';
import '../../domain/usecases/get_stock_variante_en_sede_usecase.dart';
import '../bloc/configurar_precios/configurar_precios_cubit.dart';
import '../bloc/producto_variante/producto_variante_cubit.dart';
import '../bloc/producto_variante/producto_variante_state.dart';
import '../widgets/abrir_bulto_dialog.dart';
import '../widgets/configurar_precios_dialog.dart';

/// Análisis de las variantes de un producto en una sede: dónde está la plata,
/// qué margen deja cada una y —para los productos que se venden cerrados y a
/// granel— cuánto hay realmente disponible sumando las dos formas.
///
/// El grueso sale de las variantes que ya trae `getVariantes` —`stocksPorSede`,
/// presentación, vínculo de apertura—; la única llamada extra es la rotación
/// (`/productos/:id/variantes/rotacion`), y su error se traga: si falla, el
/// resto del análisis sigue sirviendo.
///
/// Se lee, pero también se actúa: tocando una fila salen las acciones que
/// aplican a esa variante, y cada bulto tiene su botón de abrir. Detectar el
/// problema y tener que salir a otra pantalla para resolverlo era la mitad del
/// trabajo hecho.
class AnalisisVariantesPage extends StatelessWidget {
  final String productoId;
  final String productoNombre;
  final String? sedeIdInicial;

  const AnalisisVariantesPage({
    super.key,
    required this.productoId,
    required this.productoNombre,
    this.sedeIdInicial,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<ProductoVarianteCubit>(),
      child: _AnalisisVariantesView(
        productoId: productoId,
        productoNombre: productoNombre,
        sedeIdInicial: sedeIdInicial,
      ),
    );
  }
}

/// Cómo se ordena la tabla maestra.
enum _Orden { margen, valor, nombre }

const _estiloEncabezado = TextStyle(
  fontSize: 9,
  fontWeight: FontWeight.w700,
  color: Colors.black54,
);

/// Lo que salió de una variante en la ventana consultada. `cantidad` viene en
/// UNIDAD DE VENTA (gramos para un granel), igual que el stock.
class _Rotacion {
  final double cantidad;
  final int ventas;
  final DateTime? ultimaVenta;

  const _Rotacion({
    required this.cantidad,
    required this.ventas,
    this.ultimaVenta,
  });
}

class _AnalisisVariantesView extends StatefulWidget {
  final String productoId;
  final String productoNombre;
  final String? sedeIdInicial;

  const _AnalisisVariantesView({
    required this.productoId,
    required this.productoNombre,
    this.sedeIdInicial,
  });

  @override
  State<_AnalisisVariantesView> createState() => _AnalisisVariantesViewState();
}

class _AnalisisVariantesViewState extends State<_AnalisisVariantesView> {
  String? _empresaId;
  String? _sedeId;
  List<dynamic> _sedes = [];
  _Orden _orden = _Orden.margen;

  final DioClient _dio = locator<DioClient>();

  /// Ventana de rotación en días. 90 por defecto: 30 es demasiado ruidoso para
  /// un producto de baja frecuencia y 365 diluye lo que pasó hace poco.
  int _dias = 90;
  Map<String, _Rotacion> _rotacion = {};
  bool _cargandoRotacion = false;

  @override
  void initState() {
    super.initState();
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      _empresaId = empresaState.context.empresa.id;
      _sedes = List<dynamic>.from(
        empresaState.context.sedes.where((s) => s.isActive),
      );
      if (widget.sedeIdInicial != null &&
          _sedes.any((s) => s.id == widget.sedeIdInicial)) {
        _sedeId = widget.sedeIdInicial;
      } else if (_sedes.isNotEmpty) {
        _sedeId = _sedes
            .firstWhere((s) => s.esPrincipal, orElse: () => _sedes.first)
            .id;
      }
    }
    if (_empresaId != null) {
      context.read<ProductoVarianteCubit>().loadVariantes(
        productoId: widget.productoId,
        empresaId: _empresaId!,
      );
    }
    _cargarRotacion();
  }

  /// Rotación de la sede y ventana actuales. Es la única llamada extra de la
  /// pantalla; si falla, el resto del análisis sigue sirviendo, así que el
  /// error se traga y la sección simplemente no aparece.
  Future<void> _cargarRotacion() async {
    final sedeId = _sedeId;
    if (sedeId == null) return;
    setState(() => _cargandoRotacion = true);
    try {
      final resp = await _dio.get(
        '/productos/${widget.productoId}/variantes/rotacion',
        queryParameters: {'sedeId': sedeId, 'dias': _dias},
      );
      final items = (resp.data?['items'] as List<dynamic>? ?? []);
      final mapa = <String, _Rotacion>{};
      for (final raw in items) {
        final m = raw as Map<String, dynamic>;
        final id = m['varianteId'] as String?;
        if (id == null) continue;
        mapa[id] = _Rotacion(
          cantidad: (m['cantidad'] as num?)?.toDouble() ?? 0,
          ventas: (m['ventas'] as num?)?.toInt() ?? 0,
          ultimaVenta: m['ultimaVenta'] != null
              ? DateTime.tryParse(m['ultimaVenta'] as String)
              : null,
        );
      }
      if (!mounted) return;
      setState(() {
        _rotacion = mapa;
        _cargandoRotacion = false;
      });
    } catch (_) {
      if (mounted) setState(() => _cargandoRotacion = false);
    }
  }

  // ---- Acciones -------------------------------------------------------------
  //
  // La página detecta el problema —margen flaco, granel por agotarse— y hasta
  // acá había que salir, buscar la variante y entrar a otra pantalla para
  // resolverlo. Los diálogos ya existen; solo faltaba invocarlos desde donde se
  // ve el problema.

  void _recargar() {
    if (_empresaId == null) return;
    context.read<ProductoVarianteCubit>().loadVariantes(
      productoId: widget.productoId,
      empresaId: _empresaId!,
    );
    _cargarRotacion();
  }

  /// Pone el stock mínimo de todas las variantes que tienen rotación, a partir
  /// de la misma venta diaria con la que se calcula la cobertura: N días de
  /// venta. Es la única forma de hacerlo con criterio — poner el mismo número a
  /// todas es tan arbitrario como no ponerlo.
  ///
  /// Las variantes sin ventas quedan afuera: sin ritmo no hay nada que
  /// multiplicar, y meterles un número inventado sería peor que dejarlas sin
  /// mínimo.
  Future<void> _configurarMinimos(List<ProductoVariante> todas) async {
    final sedeId = _sedeId;
    if (sedeId == null) return;

    final calculables = todas
        .where(
          (v) => (_rotacion[v.id]?.cantidad ?? 0) > 0 && _stockRowId(v) != null,
        )
        .toList();
    final sinRitmo = todas.length - calculables.length;

    if (calculables.isEmpty) {
      SnackBarHelper.showError(
        context,
        'Ninguna variante vendió en los últimos $_dias días: no hay ritmo con '
        'el cual calcular un mínimo.',
      );
      return;
    }

    final diasCtrl = TextEditingController(text: '15');
    final confirmar = await StyledDialog.show<bool>(
      context,
      accentColor: AppColors.blue1,
      backgroundColor: Colors.white,
      icon: Icons.notifications_active_outlined,
      titulo: 'Configurar mínimos',
      content: [
        Text(
          'El mínimo se calcula como los días de venta que quieras cubrir, '
          'al ritmo de los últimos $_dias días.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 12),
        CustomText(
          controller: diasCtrl,
          label: 'Días de cobertura',
          hintText: '15',
          keyboardType: TextInputType.number,
          borderColor: AppColors.blue1,
        ),
        const SizedBox(height: 10),
        Text(
          'Se van a configurar ${calculables.length} variante(s).'
          '${sinRitmo > 0 ? '\n$sinRitmo quedan sin mínimo por no tener ventas en la ventana.' : ''}',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
      actions: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ),
        Expanded(
          child: CustomButton(
            text: 'Aplicar',
            backgroundColor: AppColors.blue1,
            textColor: Colors.white,
            onPressed: () => Navigator.pop(context, true),
          ),
        ),
      ],
    );

    final diasCobertura = int.tryParse(diasCtrl.text.trim()) ?? 15;
    diasCtrl.dispose();
    if (confirmar != true || !mounted) return;

    final items = calculables.map((v) {
      final porDia = _rotacion[v.id]!.cantidad / _dias;
      return {
        'productoStockId': _stockRowId(v),
        // Al menos 1: un mínimo en 0 es lo mismo que no tener mínimo.
        'stockMinimo': (porDia * diasCobertura).round().clamp(1, 1 << 31),
      };
    }).toList();

    try {
      await _dio.patch(
        '/producto-stock/sede/$sedeId/stock-minmax-bulk',
        data: {'items': items},
      );
      if (!mounted) return;
      SnackBarHelper.showSuccess(
        context,
        'Mínimo configurado en ${items.length} variante(s)',
      );
      _recargar();
    } catch (_) {
      if (mounted) {
        SnackBarHelper.showError(context, 'No se pudieron guardar los mínimos');
      }
    }
  }

  /// Menú de lo que se puede hacer con esta variante. Solo ofrece lo aplicable:
  /// "abrir" únicamente si es un bulto configurado y con stock.
  Future<void> _accionesDe(
    ProductoVariante v,
    List<ProductoVariante> todas,
  ) async {
    final esBultoAbrible = v.sePuedeAbrir && _stock(v) > 0;

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Text(
                v.nombre,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              dense: true,
              leading: const Icon(Icons.attach_money, size: 20),
              title: const Text(
                'Configurar precio y costo',
                style: TextStyle(fontSize: 13),
              ),
              onTap: () {
                Navigator.pop(sheetCtx);
                _configurarPrecio(v, todas);
              },
            ),
            if (esBultoAbrible)
              ListTile(
                dense: true,
                leading: const Icon(Icons.open_in_full, size: 20),
                title: const Text(
                  'Abrir bulto',
                  style: TextStyle(fontSize: 13),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _abrirBulto(v, todas);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _configurarPrecio(
    ProductoVariante v,
    List<ProductoVariante> todas,
  ) async {
    final sedeId = _sedeId;
    final empresaId = _empresaId;
    if (sedeId == null || empresaId == null) return;

    // Los bultos que se abren en esta variante, para el bloque "de dónde sale
    // este costo". Se arma ANTES del await: después el estado pudo cambiar.
    final costos = <CostoDesdeBulto>[];
    for (final b in _bultosDe(v, todas)) {
      final costo = _costo(b) ?? 0;
      final rinde = b.rendimientoApertura ?? 0;
      if (costo <= 0 || rinde <= 0) continue;
      costos.add(
        CostoDesdeBulto(
          nombre: b.nombre,
          costoBulto: costo,
          rendimiento: rinde,
        ),
      );
    }

    final result = await locator<GetStockVarianteEnSedeUseCase>()(
      varianteId: v.id,
      sedeId: sedeId,
    );
    if (!mounted) return;
    if (result is! Success<ProductoStock>) return;

    final guardado = await showDialog<bool>(
      context: context,
      builder: (_) => BlocProvider(
        create: (_) => locator<ConfigurarPreciosCubit>(),
        child: ConfigurarPreciosDialog(
          stock: result.data,
          empresaId: empresaId,
          unidadPresentacionSimbolo: v.unidadPresentacionSimbolo,
          factorPresentacion: v.factorPresentacion,
          costosDesdeBulto: costos,
        ),
      ),
    );
    if (guardado == true) _recargar();
  }

  Future<void> _abrirBulto(
    ProductoVariante bulto,
    List<ProductoVariante> todas,
  ) async {
    final sedeId = _sedeId;
    if (sedeId == null) return;

    ProductoVariante? destino;
    for (final v in todas) {
      if (v.id == bulto.varianteAperturaId) destino = v;
    }
    if (destino == null) return;

    final u = _presentacionDe(destino);
    final r = await AbrirBultoDialog.show(
      context: context,
      bultoVarianteId: bulto.id,
      bultoNombre: bulto.nombre,
      destinoNombre: destino.nombre,
      destinoFactor: destino.factorPresentacion,
      destinoSimbolo: u.simbolo,
      rendimiento: bulto.rendimientoApertura!,
      sedeId: sedeId,
      stockBultos: _stock(bulto),
      stockDestino: _stock(destino),
    );
    if (r != null) _recargar();
  }

  /// Cuántos días de venta cubre el stock actual al ritmo de la ventana.
  /// Null cuando no hubo ventas: no es "cobertura infinita", es que no se sabe.
  double? _cobertura(ProductoVariante v) {
    final r = _rotacion[v.id];
    if (r == null || r.cantidad <= 0) return null;
    final porDia = r.cantidad / _dias;
    if (porDia <= 0) return null;
    return _stock(v) / porDia;
  }

  // ---- Lecturas por variante ------------------------------------------------

  /// En qué unidad se lee esta variante: su presentación propia (el granel en
  /// kg) o su unidad propia (el saco en `und`). Sin ninguna de las dos, número
  /// crudo — esta pantalla carga variantes, no el producto, así que no conoce
  /// la presentación heredada.
  UnidadPresentacion _presentacionDe(ProductoVariante v) {
    if (v.tienePresentacionPropia) {
      return UnidadPresentacion(
        factor: v.factorPresentacion!,
        simbolo: v.unidadPresentacionSimbolo,
      );
    }
    return UnidadPresentacion(
      factor: 1,
      simbolo: v.unidadMedidaId != null ? v.unidadMedida?.displayCorto : null,
    );
  }

  int _stock(ProductoVariante v) =>
      _sedeId == null ? 0 : (v.stockEnSede(_sedeId!) ?? 0);

  double? _costo(ProductoVariante v) =>
      _sedeId == null ? null : v.stockSedeInfo(_sedeId!)?.precioCosto;

  double? _precio(ProductoVariante v) =>
      _sedeId == null ? null : v.stockSedeInfo(_sedeId!)?.precio;

  /// Plata inmovilizada en esta variante. En unidad de venta, que es donde
  /// vive el costo: stock × costo unitario.
  double _valor(ProductoVariante v) {
    final c = _costo(v);
    return c == null ? 0 : _stock(v) * c;
  }

  /// Margen sobre costo en %. Es un ratio, así que no importa la unidad
  /// mientras precio y costo estén en la misma.
  double? _margen(ProductoVariante v) {
    final p = _precio(v);
    final c = _costo(v);
    if (p == null || c == null || c <= 0) return null;
    return ((p - c) / c) * 100;
  }

  String? _stockRowId(ProductoVariante v) =>
      _sedeId == null ? null : v.stockSedeInfo(_sedeId!)?.productoStockId;

  int? _stockMinimo(ProductoVariante v) =>
      _sedeId == null ? null : v.stockSedeInfo(_sedeId!)?.stockMinimo;

  bool _bajoMinimo(ProductoVariante v) =>
      _sedeId != null && (v.stockSedeInfo(_sedeId!)?.esBajoMinimo ?? false);

  Color _colorMargen(double pct) {
    if (pct < 0) return Colors.red.shade700;
    if (pct < 15) return Colors.orange.shade800;
    return Colors.green.shade700;
  }

  static String _plata(double v) => 'S/${v.toStringAsFixed(2)}';

  // ---- Agrupaciones ---------------------------------------------------------

  List<ProductoVariante> _activas(List<ProductoVariante> vs) =>
      vs.where((v) => v.isActive).toList();

  /// Los bultos cerrados que se abren en [destino].
  List<ProductoVariante> _bultosDe(
    ProductoVariante destino,
    List<ProductoVariante> todas,
  ) => todas
      .where(
        (v) =>
            v.varianteAperturaId == destino.id &&
            (v.rendimientoApertura ?? 0) > 0,
      )
      .toList();

  /// Variantes que son destino de al menos un bulto: los graneles.
  List<ProductoVariante> _graneles(List<ProductoVariante> todas) =>
      todas.where((v) => _bultosDe(v, todas).isNotEmpty).toList();

  List<ProductoVariante> _ordenadas(List<ProductoVariante> vs) {
    final lista = [...vs];
    switch (_orden) {
      case _Orden.margen:
        // Sin margen (sin precio o sin costo) al final: no es "margen cero",
        // es "no se sabe", y arriba taparía a los que sí tienen problema.
        lista.sort((a, b) {
          final ma = _margen(a);
          final mb = _margen(b);
          if (ma == null && mb == null) return a.nombre.compareTo(b.nombre);
          if (ma == null) return 1;
          if (mb == null) return -1;
          return ma.compareTo(mb);
        });
        break;
      case _Orden.valor:
        lista.sort((a, b) => _valor(b).compareTo(_valor(a)));
        break;
      case _Orden.nombre:
        lista.sort((a, b) => a.nombre.compareTo(b.nombre));
        break;
    }
    return lista;
  }

  // ---- UI -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        title: Column(
          children: [
            const Text(
              'Análisis de Variantes',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
            Text(
              widget.productoNombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: AppColors.white),
            ),
          ],
        ),
      ),
      body: BlocBuilder<ProductoVarianteCubit, ProductoVarianteState>(
        builder: (context, state) {
          if (state is ProductoVarianteLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ProductoVarianteError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(state.message, textAlign: TextAlign.center),
              ),
            );
          }
          final todas = state is ProductoVarianteLoaded
              ? _activas(state.variantes)
              : <ProductoVariante>[];
          if (todas.isEmpty) {
            return const Center(child: Text('Sin variantes activas'));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
            children: [
              _buildSelectorSede(),
              const SizedBox(height: 10),
              _buildResumen(todas),
              const SizedBox(height: 12),
              _buildAlertas(todas),
              _buildTabla(todas),
              const SizedBox(height: 12),
              _buildRotacion(todas),
              ..._graneles(todas).map((g) => _buildFamilia(g, todas)),
              _buildPorSede(todas),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSelectorSede() {
    if (_sedes.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        Icon(Icons.store, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        const Text(
          'Sede:',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        CustomSedeSelector(
          sedes: _sedes,
          currentSede: _sedes.firstWhere(
            (s) => s.id == _sedeId,
            orElse: () => _sedes.first,
          ),
          onSelected: (id) {
            setState(() => _sedeId = id);
            // La rotación es por sede: cambiarla invalida lo que hay cargado.
            _cargarRotacion();
          },
        ),
      ],
    );
  }

  /// Cabecera: dónde está la plata del producto en esta sede.
  Widget _buildResumen(List<ProductoVariante> todas) {
    final valorTotal = todas.fold<double>(0, (s, v) => s + _valor(v));

    // Margen PONDERADO por plata invertida, no promedio simple: una variante
    // con 3 unidades y 50% no puede pesar lo mismo que otra con 105 kg y 10%.
    double costoTotal = 0;
    double gananciaTotal = 0;
    for (final v in todas) {
      final c = _costo(v);
      final p = _precio(v);
      if (c == null || p == null || c <= 0) continue;
      final unidades = _stock(v);
      costoTotal += c * unidades;
      gananciaTotal += (p - c) * unidades;
    }
    final margenPond = costoTotal > 0
        ? (gananciaTotal / costoTotal) * 100
        : null;

    // Stock agrupado POR UNIDAD: sacos y gramos no se suman.
    final porUnidad = <String, double>{};
    for (final v in todas) {
      final u = _presentacionDe(v);
      final simbolo = u.simboloVisible ?? 'u';
      porUnidad[simbolo] = (porUnidad[simbolo] ?? 0) + u.cantidad(_stock(v));
    }
    final stockTexto = porUnidad.entries
        .where((e) => e.value > 0)
        .map((e) => '${_num(e.value)} ${e.key}')
        .join('  ·  ');

    final sinPrecio = todas.where((v) => _precio(v) == null).length;
    final sinStock = todas.where((v) => _stock(v) <= 0).length;

    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      borderColor: AppColors.blueborder,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _dato(
                  'Valor en inventario',
                  _plata(valorTotal),
                  grande: true,
                ),
              ),
              if (margenPond != null)
                _dato(
                  'Margen ponderado',
                  '${margenPond >= 0 ? '+' : ''}${margenPond.toStringAsFixed(1)}%',
                  color: _colorMargen(margenPond),
                  grande: true,
                ),
            ],
          ),
          if (stockTexto.isNotEmpty) ...[
            const Divider(height: 16),
            _dato('Disponible', stockTexto),
          ],
          const SizedBox(height: 6),
          Text(
            '${todas.length} variantes activas'
            '${sinPrecio > 0 ? '  ·  $sinPrecio sin precio' : ''}'
            '${sinStock > 0 ? '  ·  $sinStock sin stock' : ''}',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _dato(
    String label,
    String valor, {
    Color? color,
    bool grande = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
        const SizedBox(height: 1),
        Text(
          valor,
          style: TextStyle(
            fontSize: grande ? 16 : 12,
            fontWeight: FontWeight.w800,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  /// Solo lo que se puede calcular con lo que ya está cargado. Nada de
  /// "vendido hace N días": eso necesita backend.
  Widget _buildAlertas(List<ProductoVariante> todas) {
    final avisos = <({IconData icono, Color color, String texto})>[];

    void agregar(
      List<ProductoVariante> vs,
      IconData i,
      Color c,
      String Function(int) t,
    ) {
      if (vs.isEmpty) return;
      avisos.add((icono: i, color: c, texto: t(vs.length)));
    }

    agregar(
      todas.where((v) => (_margen(v) ?? 1) < 0).toList(),
      Icons.trending_down,
      Colors.red.shade700,
      (n) => '$n variante(s) se venden POR DEBAJO del costo',
    );
    agregar(
      todas.where((v) {
        final m = _margen(v);
        return m != null && m >= 0 && m < 15;
      }).toList(),
      Icons.warning_amber_rounded,
      Colors.orange.shade800,
      (n) => '$n variante(s) con margen menor al 15%',
    );
    agregar(
      todas.where((v) => _precio(v) == null).toList(),
      Icons.price_change_outlined,
      Colors.blueGrey,
      (n) => '$n variante(s) sin precio: no se pueden vender',
    );
    agregar(
      todas.where((v) => _stock(v) > 0 && (_costo(v) ?? 0) <= 0).toList(),
      Icons.help_outline,
      Colors.blueGrey,
      (n) => '$n variante(s) con stock pero sin costo cargado',
    );
    agregar(
      todas.where(_bajoMinimo).toList(),
      Icons.inventory_2_outlined,
      Colors.deepOrange.shade700,
      (n) => '$n variante(s) por debajo del stock mínimo',
    );
    // Sin mínimo la alerta de reposición —y la de "abrí un saco"— no salta
    // NUNCA. Es silencioso: parece que todo está bien porque nadie avisa.
    agregar(
      todas.where((v) => (_stockMinimo(v) ?? 0) <= 0).toList(),
      Icons.notifications_off_outlined,
      Colors.blueGrey,
      (n) => '$n variante(s) sin stock mínimo: no van a avisar cuando falten',
    );

    // El botón acompaña al aviso de "sin mínimo": denunciar el problema sin
    // dar la salida era la mitad del trabajo.
    final faltanMinimos = todas
        .where((v) => (_stockMinimo(v) ?? 0) <= 0)
        .isNotEmpty;

    if (avisos.isEmpty && !faltanMinimos) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ...avisos.map(
            (a) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: a.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: a.color.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(a.icono, size: 14, color: a.color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      a.texto,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: a.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (faltanMinimos)
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => _configurarMinimos(todas),
                icon: const Icon(Icons.notifications_active_outlined, size: 15),
                label: const Text(
                  'Configurar mínimos según la rotación',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Anchos de la tabla. La suma pasa el ancho de un teléfono a propósito: es
  // una tabla de análisis, se lee de izquierda a derecha desplazándola. Meter
  // seis columnas en 400 px dejaría el nombre de la variante en dos letras.
  static const _wNombre = 150.0;
  static const _wStock = 74.0;
  static const _wCosto = 82.0;
  static const _wPrecio = 82.0;
  static const _wMargen = 62.0;
  static const _wValor = 82.0;

  Widget _buildTabla(List<ProductoVariante> todas) {
    final lista = _ordenadas(todas);
    return GradientContainer(
      borderColor: AppColors.blueborder,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 6, 4),
            child: Row(
              children: [
                const Expanded(child: AppSubtitle('POR VARIANTE')),
                _chipOrden('Margen', _Orden.margen),
                _chipOrden('Valor', _Orden.valor),
                _chipOrden('A-Z', _Orden.nombre),
              ],
            ),
          ),
          const Divider(height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEncabezadoTabla(),
                const Divider(height: 1),
                ...lista.map((v) => _buildFila(v, todas)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEncabezadoTabla() {
    const estilo = TextStyle(fontSize: 9, fontWeight: FontWeight.w700);
    Widget celda(String t, double w, {TextAlign a = TextAlign.right}) =>
        SizedBox(
          width: w,
          child: Text(t, style: estilo, textAlign: a),
        );

    return Container(
      color: AppColors.blue1.withValues(alpha: 0.07),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          celda('Variante', _wNombre, a: TextAlign.left),
          celda('Stock', _wStock),
          celda('Costo/u', _wCosto),
          celda('Precio/u', _wPrecio),
          celda('Margen', _wMargen),
          celda('Valor', _wValor),
        ],
      ),
    );
  }

  Widget _chipOrden(String label, _Orden valor) {
    final activo = _orden == valor;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: InkWell(
        onTap: () => setState(() => _orden = valor),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: activo ? AppColors.blue1 : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: activo ? AppColors.blue1 : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: activo ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFila(ProductoVariante v, List<ProductoVariante> todas) {
    final u = _presentacionDe(v);
    final costo = _costo(v);
    final precio = _precio(v);
    final margen = _margen(v);
    // El "/kg" va en la celda y no en el encabezado: cada variante habla en su
    // unidad, así que la columna no puede tener un rótulo único.
    final sufijo = u.simboloVisible != null ? '/${u.simboloVisible}' : '';

    Widget num(String t, double w, {Color? color, FontWeight? peso}) =>
        SizedBox(
          width: w,
          child: Text(
            t,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: peso ?? FontWeight.w500,
              color: color ?? Colors.black87,
            ),
          ),
        );

    return InkWell(
      // Tocar la fila abre lo que se puede hacer con esa variante: se ve el
      // problema y se resuelve sin salir de la pantalla.
      onTap: () => _accionesDe(v, todas),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          children: [
            SizedBox(
              width: _wNombre,
              child: Text(
                v.nombre,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            num(
              u.cantidadTexto(_stock(v)),
              _wStock,
              // Bajo mínimo en naranja: es la que hay que reponer, y en una
              // tabla de 24 filas el color es lo único que se lee de un vistazo.
              color: _bajoMinimo(v) ? Colors.deepOrange.shade700 : null,
              peso: _bajoMinimo(v) ? FontWeight.w800 : null,
            ),
            num(
              costo == null ? '—' : '${_plata(u.precio(costo))}$sufijo',
              _wCosto,
            ),
            num(
              precio == null ? '—' : '${_plata(u.precio(precio))}$sufijo',
              _wPrecio,
            ),
            num(
              margen == null
                  ? 'sin precio'
                  : '${margen >= 0 ? '+' : ''}${margen.toStringAsFixed(1)}%',
              _wMargen,
              color: margen == null
                  ? Colors.grey.shade500
                  : _colorMargen(margen),
              peso: FontWeight.w800,
            ),
            num(_plata(_valor(v)), _wValor, peso: FontWeight.w700),
          ],
        ),
      ),
    );
  }

  /// El cuadro que no existe en ningún otro lado: cuánto hay REALMENTE de este
  /// sabor sumando lo suelto y lo que sigue cerrado, y de qué bulto salió el
  /// costo del granel.
  Widget _buildFamilia(ProductoVariante granel, List<ProductoVariante> todas) {
    final bultos = _bultosDe(granel, todas);
    final u = _presentacionDe(granel);
    final costoGranel = _costo(granel);

    // Todo se lleva a la unidad del GRANEL, que es la única en la que sacos y
    // suelto se pueden sumar.
    var totalUnidadesVenta = _stock(granel).toDouble();
    var totalPlata = _valor(granel);

    return GradientContainer(
      borderColor: AppColors.blueborder,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 14,
                color: AppColors.blue1,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  granel.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blue1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _lineaFamilia(
            'Suelto',
            u.cantidadTexto(_stock(granel)),
            costoGranel != null
                ? '${_plata(u.precio(costoGranel))}/${u.simboloVisible ?? ''}'
                : '—',
            _plata(_valor(granel)),
          ),
          ...bultos.map((b) {
            final rinde = b.rendimientoApertura ?? 0;
            final stockB = _stock(b);
            final costoB = _costo(b);
            // Un saco de 15 kg son 15 000 unidades de venta del granel.
            final equivalente = stockB * rinde;
            totalUnidadesVenta += equivalente;
            totalPlata += _valor(b);
            final ub = _presentacionDe(b);
            return _lineaFamilia(
              b.nombre,
              '${ub.cantidadTexto(stockB)} = ${u.cantidadTexto(equivalente)}',
              costoB != null && rinde > 0
                  ? '${_plata(u.precio(costoB / rinde))}/${u.simboloVisible ?? ''}'
                  : '—',
              _plata(_valor(b)),
              // Acá es donde se piensa "me faltan kilos, abro un saco", así que
              // el botón va en la línea del saco y no escondido en la tabla.
              onAbrir: b.sePuedeAbrir && stockB > 0
                  ? () => _abrirBulto(b, todas)
                  : null,
            );
          }),
          const Divider(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Disponible total',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              Text(
                u.cantidadTexto(totalUnidadesVenta),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.blue1,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _plata(totalPlata),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          _buildAbrirVsCerrado(granel, bultos, u),
          _buildComparaCostos(bultos, u),
        ],
      ),
    );
  }

  /// La decisión diaria: ¿lo vendo cerrado o lo abro y lo vendo por kilo?
  ///
  /// El saco tiene precio por unidad y el granel por kilo, así que a simple
  /// vista no se comparan. Acá se llevan los dos al MISMO kilo y se muestra la
  /// plata que hay en juego con el stock que hay hoy.
  Widget _buildAbrirVsCerrado(
    ProductoVariante granel,
    List<ProductoVariante> bultos,
    UnidadPresentacion u,
  ) {
    final precioGranel = _precio(granel);
    if (precioGranel == null) return const SizedBox.shrink();

    var cerrado = 0.0;
    var suelto = 0.0;
    final lineas = <String>[];
    for (final b in bultos) {
      final precioB = _precio(b);
      final rinde = b.rendimientoApertura ?? 0;
      final stockB = _stock(b);
      if (precioB == null || rinde <= 0 || stockB <= 0) continue;
      cerrado += stockB * precioB;
      suelto += stockB * rinde * precioGranel;
      lineas.add(
        '${b.nombre}: ${_plata(u.precio(precioB / rinde))}/${u.simboloVisible ?? ''} cerrado',
      );
    }
    if (lineas.isEmpty) return const SizedBox.shrink();

    final diferencia = suelto - cerrado;
    final conviene = diferencia > 0;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: (conviene ? Colors.green : Colors.orange).withValues(
          alpha: 0.07,
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: (conviene ? Colors.green : Colors.orange).withValues(
            alpha: 0.35,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ABRIR O VENDER CERRADO',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: conviene ? Colors.green.shade800 : Colors.orange.shade900,
            ),
          ),
          const SizedBox(height: 4),
          ...lineas.map(
            (l) => Text(
              l,
              style: TextStyle(fontSize: 9, color: Colors.grey.shade700),
            ),
          ),
          Text(
            'Suelto: ${_plata(u.precio(precioGranel))}/${u.simboloVisible ?? ''}',
            style: TextStyle(fontSize: 9, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 4),
          Text(
            'Con el stock de hoy: cerrado ${_plata(cerrado)} · abierto ${_plata(suelto)}',
            style: const TextStyle(fontSize: 9),
          ),
          Text(
            conviene
                ? 'Abrir todo deja +${_plata(diferencia)}'
                : 'Vender cerrado deja +${_plata(-diferencia)}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: conviene ? Colors.green.shade800 : Colors.orange.shade900,
            ),
          ),
        ],
      ),
    );
  }

  /// Cuál formato de bulto compra mejor. El costo por kilo de cada saco ya
  /// está en las líneas de arriba, pero la diferencia entre formatos es una
  /// decisión de COMPRAS y merece decirse con el número en la mano.
  Widget _buildComparaCostos(
    List<ProductoVariante> bultos,
    UnidadPresentacion u,
  ) {
    final conCosto = bultos
        .where((b) => (_costo(b) ?? 0) > 0 && (b.rendimientoApertura ?? 0) > 0)
        .toList();
    if (conCosto.length < 2) return const SizedBox.shrink();

    conCosto.sort(
      (a, b) => (_costo(a)! / a.rendimientoApertura!).compareTo(
        _costo(b)! / b.rendimientoApertura!,
      ),
    );
    final barato = conCosto.first;
    final caro = conCosto.last;
    final cBarato = _costo(barato)! / barato.rendimientoApertura!;
    final cCaro = _costo(caro)! / caro.rendimientoApertura!;
    if (cBarato <= 0) return const SizedBox.shrink();
    final pct = ((cCaro - cBarato) / cBarato) * 100;
    if (pct < 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        '💡 ${caro.nombre} te cuesta ${pct.toStringAsFixed(0)}% más por '
        '${u.simboloVisible ?? 'unidad'} que ${barato.nombre} '
        '(${_plata(u.precio(cCaro))} vs ${_plata(u.precio(cBarato))}).',
        style: TextStyle(
          fontSize: 9,
          fontStyle: FontStyle.italic,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  /// Qué se mueve y qué está parado. Sin esto la página solo sabe mirar el
  /// saldo: una variante con buen margen y cero salida se ve igual de sana que
  /// una que vuela.
  Widget _buildRotacion(List<ProductoVariante> todas) {
    if (_cargandoRotacion) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    // Primero lo que se está por acabar; después lo que no se movió nunca.
    final lista = [...todas]
      ..sort((a, b) {
        final ca = _cobertura(a);
        final cb = _cobertura(b);
        if (ca == null && cb == null) return a.nombre.compareTo(b.nombre);
        if (ca == null) return 1;
        if (cb == null) return -1;
        return ca.compareTo(cb);
      });

    return GradientContainer(
      borderColor: AppColors.blueborder,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: AppSubtitle('ROTACIÓN')),
              _chipDias(30),
              _chipDias(90),
              _chipDias(365),
            ],
          ),
          Text(
            'Últimos $_dias días, en esta sede. La cobertura es cuánto dura el '
            'stock a ese ritmo.',
            style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          // Encabezado: sin él, "6 kg" y "45 d" en la misma fila no dicen qué
          // es cada uno. Mismos flex que las filas para que las columnas
          // queden alineadas.
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                const Expanded(
                  flex: 5,
                  child: Text('Variante', style: _estiloEncabezado),
                ),
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Ritmo',
                    textAlign: TextAlign.right,
                    style: _estiloEncabezado,
                  ),
                ),
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Cobertura',
                    textAlign: TextAlign.right,
                    style: _estiloEncabezado,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade300),
          const SizedBox(height: 6),
          ...lista.map((v) {
            final r = _rotacion[v.id];
            final u = _presentacionDe(v);
            final cobertura = _cobertura(v);
            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      v.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      r == null || r.cantidad <= 0
                          ? 'sin ventas'
                          : _ritmoTexto(u, r.cantidad / _dias),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 9,
                        color: r == null || r.cantidad <= 0
                            ? Colors.grey.shade500
                            : Colors.grey.shade800,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      _coberturaTexto(v, cobertura),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _colorCobertura(v, cobertura),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// "0.2 kg/día" · "1.5 und/día" · "0.0004 kg/día".
  ///
  /// Los decimales se ajustan al tamaño del número: con dos fijos, un producto
  /// de baja rotación se leería "0.00 kg/día" habiendo vendido, que es peor que
  /// no mostrar nada. Y los ceros sobrantes se recortan para que 0.20 quede en
  /// 0.2, que es como se dice.
  String _ritmoTexto(UnidadPresentacion u, double porDiaEnUnidadDeVenta) {
    final v = u.cantidad(porDiaEnUnidadDeVenta);
    final decimales = v >= 1
        ? 2
        : v >= 0.01
        ? 2
        : 4;
    var n = v.toStringAsFixed(decimales);
    if (n.contains('.')) {
      n = n.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    }
    final simbolo = u.simboloVisible;
    return simbolo != null ? '$n $simbolo/día' : '$n /día';
  }

  /// "12 d" · "+1 año" · "parado" · "agotada". Un "1890 días" es ruido: a
  /// partir del año lo único que importa es que sobra.
  String _coberturaTexto(ProductoVariante v, double? dias) {
    if (_stock(v) <= 0) return 'agotada';
    if (dias == null) return 'parado';
    if (dias > 365) return '+1 año';
    return '${dias.toStringAsFixed(0)} d';
  }

  Color _colorCobertura(ProductoVariante v, double? dias) {
    if (_stock(v) <= 0) return Colors.red.shade700;
    // Sin ventas y con stock: plata quieta. No es urgente pero es plata.
    if (dias == null) return Colors.blueGrey;
    if (dias < 15) return Colors.deepOrange.shade700;
    if (dias > 365) return Colors.blueGrey;
    return Colors.green.shade700;
  }

  Widget _chipDias(int dias) {
    final activo = _dias == dias;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: InkWell(
        onTap: () {
          setState(() => _dias = dias);
          _cargarRotacion();
        },
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: activo ? AppColors.blue1 : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: activo ? AppColors.blue1 : Colors.grey.shade300,
            ),
          ),
          child: Text(
            dias == 365 ? '1a' : '${dias}d',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: activo ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  /// Dónde está la mercadería. `stocksPorSede` ya trae TODAS las sedes en la
  /// misma respuesta, así que no hace falta cambiar el selector una por una.
  /// Con una sola sede no aporta nada y no se muestra.
  Widget _buildPorSede(List<ProductoVariante> todas) {
    final valor = <String, double>{};
    final nombre = <String, String>{};
    final unidades = <String, Map<String, double>>{};

    for (final v in todas) {
      final u = _presentacionDe(v);
      final simbolo = u.simboloVisible ?? 'u';
      for (final StockPorSedeInfo s in v.stocksPorSede ?? const []) {
        nombre[s.sedeId] = s.sedeNombre;
        valor[s.sedeId] =
            (valor[s.sedeId] ?? 0) + s.cantidad * (s.precioCosto ?? 0);
        final porUnidad = unidades.putIfAbsent(s.sedeId, () => {});
        porUnidad[simbolo] = (porUnidad[simbolo] ?? 0) + u.cantidad(s.cantidad);
      }
    }
    if (nombre.length < 2) return const SizedBox.shrink();

    final ids = nombre.keys.toList()
      ..sort((a, b) => (valor[b] ?? 0).compareTo(valor[a] ?? 0));

    return GradientContainer(
      borderColor: AppColors.blueborder,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSubtitle('POR SEDE'),
          const SizedBox(height: 6),
          ...ids.map((id) {
            final detalle = (unidades[id] ?? {}).entries
                .where((e) => e.value > 0)
                .map((e) => '${_num(e.value)} ${e.key}')
                .join('  ·  ');
            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre[id] ?? '—',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          detalle.isEmpty ? 'sin stock' : detalle,
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _plata(valor[id] ?? 0),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _lineaFamilia(
    String nombre,
    String cantidad,
    String costo,
    String plata, {
    VoidCallback? onAbrir,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          if (onAbrir != null)
            InkWell(
              onTap: onAbrir,
              borderRadius: BorderRadius.circular(3),
              child: const Padding(
                padding: EdgeInsets.only(right: 4, top: 2, bottom: 2),
                child: Icon(
                  Icons.open_in_full,
                  size: 13,
                  color: AppColors.blue1,
                ),
              ),
            ),
          Expanded(
            flex: 4,
            child: Text(
              nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              cantidad,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              costo,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              plata,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  static String _num(double v) =>
      v == v.truncateToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
}
