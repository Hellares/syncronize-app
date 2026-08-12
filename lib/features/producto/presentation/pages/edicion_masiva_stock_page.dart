import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_search_field.dart';
import '../../../../core/widgets/custom_sede_selector.dart';
import '../../../../core/utils/unidad_presentacion.dart';
import '../../../../core/widgets/styled_dialog.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../domain/entities/bulk_editar_stock_precios.dart';
import '../../domain/entities/producto_variante.dart';
import '../bloc/edicion_masiva_stock/edicion_masiva_stock_cubit.dart';
import '../bloc/edicion_masiva_stock/edicion_masiva_stock_state.dart';

/// Grilla tipo excel para editar stock y precios de todas las variantes
/// de un producto en una sede, en bloque. Cada ajuste de stock genera
/// movimiento de kardex y cada cambio de precio queda en el historial.
///
/// Todo lo que se ve y se escribe está en la unidad en la que se habla: un
/// granel guardado en gramos se lee y se edita en KILOS. Sin eso la pantalla
/// era inservible justo para esos productos — mostraba "15000" y "0.01" (un
/// precio redondeado que no existe) y el campo, de 2 decimales, no dejaba
/// escribir 0.015. La conversión pasa solo en los bordes: al pintar y al
/// guardar.
///
/// El margen va debajo del nombre y no como columna: en un teléfono no entra
/// una sexta columna sin dejar el nombre de la variante en dos letras.
class EdicionMasivaStockPage extends StatelessWidget {
  final String productoId;
  final String productoNombre;
  final String? sedeIdInicial;

  const EdicionMasivaStockPage({
    super.key,
    required this.productoId,
    required this.productoNombre,
    this.sedeIdInicial,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<EdicionMasivaStockCubit>(),
      child: _EdicionMasivaView(
        productoId: productoId,
        productoNombre: productoNombre,
        sedeIdInicial: sedeIdInicial,
      ),
    );
  }
}

class _EdicionMasivaView extends StatefulWidget {
  final String productoId;
  final String productoNombre;
  final String? sedeIdInicial;

  const _EdicionMasivaView({
    required this.productoId,
    required this.productoNombre,
    this.sedeIdInicial,
  });

  @override
  State<_EdicionMasivaView> createState() => _EdicionMasivaViewState();
}

/// Qué tiene de malo el precio por mayor tecleado en una fila.
///
/// [bajoCosto] es el que motivó todo esto: un precio por mayor plano aplicado
/// a variantes de costos distintos deja vendiendo bajo costo justo a las caras,
/// y no se nota porque en las baratas el nivel ni siquiera llega a aplicar.
enum _ProblemaMayor {
  bajoCosto,
  noBaja,
  incompleto,
  cantidadInvalida;

  /// Los que impiden guardar. `noBaja` no bloquea: el nivel es inofensivo
  /// (gana el menor), solo inútil, y puede ser intencional mientras se ajustan
  /// los precios de lista.
  bool get bloquea => this != _ProblemaMayor.noBaja;

  String get mensaje => switch (this) {
        _ProblemaMayor.bajoCosto => 'El precio por mayor está bajo el costo',
        _ProblemaMayor.noBaja =>
          'El precio por mayor no baja del precio de lista: no se aplicaría',
        _ProblemaMayor.incompleto =>
          'Faltan la cantidad mínima o el precio por mayor',
        _ProblemaMayor.cantidadInvalida =>
          'La cantidad mínima del precio por mayor debe ser al menos 2',
      };
}

/// Controllers de una fila de la grilla (una variante).
class _FilaEdicion {
  final stock = TextEditingController();
  final precio = TextEditingController();
  final costo = TextEditingController();

  /// Cantidad desde la que aplica el precio por mayor, y ese precio.
  /// El nivel es GLOBAL a la variante (no por sede) — ver el aviso de la barra.
  final mayorDesde = TextEditingController();
  final mayorPrecio = TextEditingController();

  bool get tieneCambios =>
      stock.text.trim().isNotEmpty ||
      precio.text.trim().isNotEmpty ||
      costo.text.trim().isNotEmpty ||
      mayorDesde.text.trim().isNotEmpty ||
      mayorPrecio.text.trim().isNotEmpty;

  void limpiar() {
    stock.clear();
    precio.clear();
    costo.clear();
    mayorDesde.clear();
    mayorPrecio.clear();
  }

  void dispose() {
    stock.dispose();
    precio.dispose();
    costo.dispose();
    mayorDesde.dispose();
    mayorPrecio.dispose();
  }
}

class _EdicionMasivaViewState extends State<_EdicionMasivaView> {
  String? _empresaId;
  String? _sedeId;
  List<dynamic> _sedes = [];
  final Map<String, _FilaEdicion> _filas = {};
  final _searchController = TextEditingController();

  static const _wStockActual = 52.0;
  static const _wAgregarStock = 68.0;
  static const _wPrecio = 78.0;
  static const _wCosto = 78.0;
  static const _wMayorDesde = 58.0;
  static const _wMayorPrecio = 82.0;

  @override
  void initState() {
    super.initState();
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      _empresaId = empresaState.context.empresa.id;
      // Copia tipada como List<dynamic>: la lista original es List<SedeModel>
      // y un orElse que devuelve dynamic rompería firstWhere en runtime.
      _sedes =
          List<dynamic>.from(empresaState.context.sedes.where((s) => s.isActive));
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
      context.read<EdicionMasivaStockCubit>().loadVariantes(
            productoId: widget.productoId,
            empresaId: _empresaId!,
          );
    }
  }

  @override
  void dispose() {
    for (final fila in _filas.values) {
      fila.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  _FilaEdicion _filaDe(String varianteId) =>
      _filas.putIfAbsent(varianteId, () => _FilaEdicion());

  int get _totalCambios => _filas.values.where((f) => f.tieneCambios).length;

  /// Qué le pasa al precio por mayor tecleado en esta fila. Todo en unidad de
  /// PRESENTACIÓN, que es en la que se teclea y en la que se muestra el costo.
  ///
  /// `null` = no hay nada que objetar (o no se tecleó nada).
  _ProblemaMayor? _problemaMayor(ProductoVariante v) {
    final fila = _filas[v.id];
    if (fila == null) return null;

    final desdeTxt = fila.mayorDesde.text.trim();
    final precioTxt = fila.mayorPrecio.text.trim();
    if (desdeTxt.isEmpty && precioTxt.isEmpty) return null;

    // Las dos mitades o ninguna: un precio sin cantidad no se sabe desde
    // cuándo aplica, y una cantidad sin precio no crea ningún nivel.
    if (desdeTxt.isEmpty || precioTxt.isEmpty) {
      return _ProblemaMayor.incompleto;
    }

    final desde = _parseNum(desdeTxt);
    final precioMayor = _parseNum(precioTxt);
    if (desde == null || desde < 2) return _ProblemaMayor.cantidadInvalida;
    if (precioMayor == null) return _ProblemaMayor.incompleto;

    final u = _presentacionDe(v);
    final stockInfo = _sedeId != null ? v.stockSedeInfo(_sedeId!) : null;

    // El costo efectivo es el tecleado en ESTA fila si lo hay; si no, el
    // vigente. Comparar contra el viejo dejaría pasar un mayorista bajo costo
    // cuando se cargan los dos juntos.
    final costo = _parseNum(fila.costo.text) ??
        (stockInfo?.precioCosto != null ? u.precio(stockInfo!.precioCosto!) : null);
    if (costo != null && precioMayor < costo) return _ProblemaMayor.bajoCosto;

    // Un nivel solo entra si BAJA el precio ("gana el menor"), así que uno por
    // encima del precio de lista no hace absolutamente nada. No es peligroso,
    // pero el usuario cree que dejó un mayorista cargado.
    final precioLista = _parseNum(fila.precio.text) ??
        (stockInfo?.precio != null ? u.precio(stockInfo!.precio!) : null);
    if (precioLista != null && precioMayor >= precioLista) {
      return _ProblemaMayor.noBaja;
    }

    return null;
  }

  /// Variantes visibles cuyo precio por mayor NO se puede guardar.
  List<ProductoVariante> _bloqueantes(List<ProductoVariante> variantes) {
    return variantes.where((v) {
      final p = _problemaMayor(v);
      return p != null && p.bloquea;
    }).toList();
  }

  List<ProductoVariante> _filtrar(List<ProductoVariante> variantes) {
    final term = _searchController.text.trim().toLowerCase();
    if (term.isEmpty) return variantes;
    return variantes
        .where((v) =>
            v.nombre.toLowerCase().contains(term) ||
            v.sku.toLowerCase().contains(term))
        .toList();
  }

  void _limpiarEdiciones() {
    for (final fila in _filas.values) {
      fila.limpiar();
    }
    setState(() {});
  }

  Future<void> _cambiarSede(String? nuevaSedeId) async {
    if (nuevaSedeId == null || nuevaSedeId == _sedeId) return;

    if (_totalCambios > 0) {
      final confirmar = await StyledDialog.show<bool>(
        context,
        accentColor: Colors.orange,
        backgroundColor: Colors.white,
        icon: Icons.store_outlined,
        titulo: 'Cambiar de sede',
        content: [
          const Text(
            'Tienes cambios sin guardar. Al cambiar de sede se descartarán. ¿Continuar?',
            style: TextStyle(fontSize: 13),
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
              text: 'Descartar',
              backgroundColor: Colors.orange,
              textColor: Colors.white,
              onPressed: () => Navigator.pop(context, true),
            ),
          ),
        ],
      );
      if (confirmar != true) return;
      _limpiarEdiciones();
    }

    setState(() => _sedeId = nuevaSedeId);
  }

  Future<void> _aplicarATodas(List<ProductoVariante> visibles) async {
    final stockCtrl = TextEditingController();
    final precioCtrl = TextEditingController();
    final costoCtrl = TextEditingController();
    final mayorDesdeCtrl = TextEditingController();
    final mayorPrecioCtrl = TextEditingController();

    final aplicar = await StyledDialog.show<bool>(
      context,
      accentColor: AppColors.blue1,
      backgroundColor: Colors.white,
      icon: Icons.copy_all,
      titulo: 'Aplicar a ${visibles.length} variante(s)',
      content: [
        const Text(
          'Los campos vacíos no se aplican. Afecta solo a las variantes '
          'visibles (según el filtro).\n\n'
          'Cada valor se toma en la unidad de SU variante: un mismo "15.00" es '
          'S/15 por kilo en un granel y S/15 por unidad en un saco.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 14),
        CustomText(
          controller: stockCtrl,
          label: 'Agregar stock (+/-)',
          hintText: '0',
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          inputFormatters: [_soloEnteroConSigno],
          borderColor: AppColors.blue1.withValues(alpha: 0.4),
        ),
        const SizedBox(height: 10),
        CustomText(
          controller: precioCtrl,
          label: 'Precio (S/)',
          hintText: '0.00',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [_soloDecimal],
          borderColor: AppColors.blue1.withValues(alpha: 0.4),
        ),
        const SizedBox(height: 10),
        CustomText(
          controller: costoCtrl,
          label: 'Costo (S/)',
          hintText: '0.00',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [_soloDecimal],
          borderColor: AppColors.blue1.withValues(alpha: 0.4),
        ),
        const SizedBox(height: 14),
        const Divider(height: 1),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.public, size: 14, color: Colors.orange.shade800),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                'El precio por mayor NO es por sede: se aplica a todas. '
                'Las variantes cuyo precio quede bajo costo se marcan y no '
                'dejan guardar.',
                style: TextStyle(
                    fontSize: 11, color: Colors.orange.shade900),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: CustomText(
                controller: mayorDesdeCtrl,
                label: 'Desde (cant.)',
                hintText: '3',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [_soloDecimal],
                borderColor: AppColors.blue1.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: CustomText(
                controller: mayorPrecioCtrl,
                label: 'Precio por mayor (S/)',
                hintText: '0.00',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [_soloDecimal],
                borderColor: AppColors.blue1.withValues(alpha: 0.4),
              ),
            ),
          ],
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

    if (aplicar == true) {
      for (final v in visibles) {
        final fila = _filaDe(v.id);
        if (stockCtrl.text.trim().isNotEmpty) fila.stock.text = stockCtrl.text.trim();
        if (precioCtrl.text.trim().isNotEmpty) fila.precio.text = precioCtrl.text.trim();
        if (costoCtrl.text.trim().isNotEmpty) fila.costo.text = costoCtrl.text.trim();
        if (mayorDesdeCtrl.text.trim().isNotEmpty) {
          fila.mayorDesde.text = mayorDesdeCtrl.text.trim();
        }
        if (mayorPrecioCtrl.text.trim().isNotEmpty) {
          fila.mayorPrecio.text = mayorPrecioCtrl.text.trim();
        }
      }
      setState(() {});
    }

    stockCtrl.dispose();
    precioCtrl.dispose();
    costoCtrl.dispose();
    mayorDesdeCtrl.dispose();
    mayorPrecioCtrl.dispose();
  }

  Future<void> _guardar(List<ProductoVariante> variantes) async {
    if (_sedeId == null || _empresaId == null) return;

    // Nada se guarda si hay un precio por mayor inválido: la transacción del
    // backend es todo-o-nada, así que dejarlo llegar solo cambia un error de
    // pantalla por un 400 con las demás filas sin aplicar.
    final bloqueantes = _bloqueantes(variantes);
    if (bloqueantes.isNotEmpty) {
      final detalle = bloqueantes.take(5).map((v) {
        final p = _problemaMayor(v)!;
        return '• ${v.nombre}\n   ${p.mensaje}';
      }).join('\n');
      final resto = bloqueantes.length > 5
          ? '\n\n…y ${bloqueantes.length - 5} más.'
          : '';
      await StyledDialog.show<void>(
        context,
        accentColor: Colors.red.shade700,
        backgroundColor: Colors.white,
        icon: Icons.price_check,
        titulo: 'Revisá el precio por mayor',
        content: [
          Text(
            'No se guardó nada. ${bloqueantes.length} variante(s) tienen un '
            'precio por mayor que no se puede aplicar:\n\n$detalle$resto',
            style: const TextStyle(fontSize: 12),
          ),
        ],
        actions: [
          Expanded(
            child: CustomButton(
              text: 'Entendido',
              backgroundColor: Colors.red.shade700,
              textColor: Colors.white,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      );
      return;
    }

    final items = <BulkEditarItem>[];
    for (final v in variantes) {
      final fila = _filas[v.id];
      if (fila == null || !fila.tieneCambios) continue;

      // Lo tecleado viene en unidad de PRESENTACIÓN (kilos); el backend
      // trabaja en unidad de venta (gramos). La conversión pasa solo acá.
      final u = _presentacionDe(v);
      final agregarPres = _parseNum(fila.stock.text);
      final precioPres = _parseNum(fila.precio.text);
      final costoPres = _parseNum(fila.costo.text);

      // El precio por mayor sigue la misma regla que el precio de lista, y la
      // cantidad mínima la del stock: "desde 3 kg" son 3000 g en unidad de
      // venta, que es contra lo que el backend compara la cantidad vendida.
      final mayorDesdePres = _parseNum(fila.mayorDesde.text);
      final mayorPrecioPres = _parseNum(fila.mayorPrecio.text);

      final item = BulkEditarItem(
        varianteId: v.id,
        // El stock es entero en unidad de venta: 1.5 kg son 1500 g.
        agregarStock:
            agregarPres == null ? null : (agregarPres * u.factor).round(),
        precio: precioPres == null ? null : precioPres / u.factor,
        precioCosto: costoPres == null ? null : costoPres / u.factor,
        mayorCantidadMinima:
            mayorDesdePres == null ? null : (mayorDesdePres * u.factor).round(),
        mayorPrecio:
            mayorPrecioPres == null ? null : mayorPrecioPres / u.factor,
      );
      if (item.tieneCambios) items.add(item);
    }

    if (items.isEmpty) return;

    final sedeNombre =
        _sedes.firstWhere((s) => s.id == _sedeId, orElse: () => null)?.nombre ??
            '';

    final confirmar = await StyledDialog.show<bool>(
      context,
      accentColor: AppColors.blue1,
      backgroundColor: Colors.white,
      icon: Icons.save_outlined,
      titulo: 'Confirmar cambios',
      content: [
        Text(
          'Se aplicarán cambios a ${items.length} variante(s) en la sede "$sedeNombre".\n\n'
          'Los ajustes de stock quedarán registrados en el kardex y los '
          'cambios de precio en el historial.',
          style: const TextStyle(fontSize: 13),
        ),
        // El stock y los precios son por sede; el nivel por mayor NO. Si no se
        // dice acá, se descubre el día que la empresa abre una segunda sede.
        if (items.any((i) => i.mayorPrecio != null)) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.public, size: 15, color: Colors.orange.shade800),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'El precio por mayor de '
                    '${items.where((i) => i.mayorPrecio != null).length} '
                    'variante(s) se aplica a TODAS las sedes, no solo a '
                    '"$sedeNombre".',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
            text: 'Guardar',
            icon: const Icon(Icons.save_outlined, size: 14, color: Colors.white),
            backgroundColor: AppColors.blue1,
            textColor: Colors.white,
            onPressed: () => Navigator.pop(context, true),
          ),
        ),
      ],
    );

    if (confirmar != true || !mounted) return;

    context.read<EdicionMasivaStockCubit>().guardarCambios(
          sedeId: _sedeId!,
          empresaId: _empresaId!,
          productoId: widget.productoId,
          items: items,
          motivo: 'Edición masiva de inventario',
        );
  }

  static final _soloEnteroConSigno =
      FilteringTextInputFormatter.allow(RegExp(r'^-?\d*'));
  /// Con presentación el stock se escribe en kilos y ahí sí hacen falta
  /// decimales: "1.5" son 1500 g. Sin presentación se sigue exigiendo entero,
  /// porque medio saco no existe.
  static final _decimalConSigno =
      FilteringTextInputFormatter.allow(RegExp(r'^-?\d*[.,]?\d{0,3}'));
  static final _soloDecimal =
      FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}'));

  /// El teclado numérico deja escribir coma: "0,5" tiene que valer lo mismo
  /// que "0.5" y no caerse a null.
  static double? _parseNum(String texto) {
    final t = texto.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t.replaceAll(',', '.'));
  }

  /// En qué unidad se lee y se escribe esta variante.
  ///
  /// Presentación propia (el granel: kg ×1000) → esa. Si no, su unidad propia
  /// (el saco: `und`, factor 1). Si no tiene ninguna de las dos, hereda la del
  /// producto y esta pantalla no la conoce —el cubit carga variantes, no el
  /// producto—, así que se muestra el número crudo sin símbolo, igual que
  /// antes.
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

  /// Margen sobre costo en %. Es un RATIO, así que da igual en qué unidad
  /// estén los dos números mientras sea la misma.
  double? _margenPct(double? precio, double? costo) {
    if (precio == null || costo == null || costo <= 0) return null;
    return ((precio - costo) / costo) * 100;
  }

  /// Rojo bajo cero (se vende perdiendo), ámbar hasta 15% (flaco) y verde
  /// arriba. Los cortes son para que salte a la vista, no una regla contable.
  Color _colorMargen(double pct) {
    if (pct < 0) return Colors.red.shade700;
    if (pct < 15) return Colors.orange.shade800;
    return Colors.green.shade700;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Edición masiva',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white)),
            Text(
              widget.productoNombre,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: AppColors.white),
            ),
          ],
        ),
      ),
      body: BlocConsumer<EdicionMasivaStockCubit, EdicionMasivaStockState>(
        listener: (context, state) {
          if (state is EdicionMasivaStockSuccess) {
            _limpiarEdiciones();
            final r = state.resumen;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text([
                  'Guardado: ${r.stockAjustado} ajuste(s) de stock',
                  '${r.preciosActualizados} precio(s) actualizados',
                  if (r.nivelesActualizados > 0)
                    '${r.nivelesActualizados} precio(s) por mayor',
                  if (r.nivelesEliminados > 0)
                    '${r.nivelesEliminados} nivel(es) eliminados',
                ].join(', ')),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is EdicionMasivaStockError &&
              state.variantes.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is EdicionMasivaStockLoading ||
              state is EdicionMasivaStockInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is EdicionMasivaStockError && state.variantes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(state.message),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => context
                        .read<EdicionMasivaStockCubit>()
                        .loadVariantes(
                          productoId: widget.productoId,
                          empresaId: _empresaId!,
                        ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final variantes = switch (state) {
            EdicionMasivaStockLoaded s => s.variantes,
            EdicionMasivaStockSaving s => s.variantes,
            EdicionMasivaStockSuccess s => s.variantes,
            EdicionMasivaStockError s => s.variantes,
            _ => <ProductoVariante>[],
          };
          final visibles = _filtrar(variantes);
          final guardando = state is EdicionMasivaStockSaving;

          return Column(
            children: [
              _buildBarraSuperior(visibles),
              const Divider(height: 1),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final anchoMinimo = _wStockActual +
                        _wAgregarStock +
                        _wPrecio +
                        _wCosto +
                        _wMayorDesde +
                        _wMayorPrecio +
                        160 + // columna variante
                        24; // padding
                    final ancho = constraints.maxWidth < anchoMinimo
                        ? anchoMinimo
                        : constraints.maxWidth;
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: ancho,
                        child: Column(
                          children: [
                            _buildHeaderGrilla(),
                            Expanded(
                              child: visibles.isEmpty
                                  ? const Center(
                                      child: Text('Sin variantes que mostrar'))
                                  : ListView.builder(
                                      itemCount: visibles.length,
                                      itemBuilder: (context, i) =>
                                          _buildFila(visibles[i], i),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              _buildBarraGuardar(variantes, guardando),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBarraSuperior(List<ProductoVariante> visibles) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.store, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              const Text('Sede:',
                  style:
                      TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              if (_sedes.isNotEmpty)
                CustomSedeSelector(
                  sedes: _sedes,
                  currentSede: _sedes.firstWhere(
                    (s) => s.id == _sedeId,
                    orElse: () => _sedes.first,
                  ),
                  onSelected: _cambiarSede,
                ),
              const Spacer(),
              IconButton.filledTonal(
                tooltip: 'Aplicar valor a todas las visibles',
                icon: const Icon(Icons.copy_all, size: 20),
                onPressed:
                    visibles.isEmpty ? null : () => _aplicarATodas(visibles),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CustomSearchField(
            controller: _searchController,
            hintText: 'Buscar por nombre o SKU...',
            debounceDelay: const Duration(milliseconds: 200),
            onChanged: (_) => setState(() {}),
            onClear: () => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderGrilla() {
    const estilo = TextStyle(fontSize: 11, fontWeight: FontWeight.w600);
    return Container(
      color: AppColors.blue1.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: const Row(
        children: [
          Expanded(child: Text('Variante', style: estilo)),
          SizedBox(
              width: _wStockActual,
              child: Text('Stock', style: estilo, textAlign: TextAlign.center)),
          SizedBox(
              width: _wAgregarStock,
              child:
                  Text('+ Stock', style: estilo, textAlign: TextAlign.center)),
          SizedBox(
              width: _wPrecio,
              child: Text('Precio S/',
                  style: estilo, textAlign: TextAlign.center)),
          SizedBox(
              width: _wCosto,
              child:
                  Text('Costo S/', style: estilo, textAlign: TextAlign.center)),
          SizedBox(
              width: _wMayorDesde,
              child: Text('Desde', style: estilo, textAlign: TextAlign.center)),
          SizedBox(
              width: _wMayorPrecio,
              child: Text('Mayor S/',
                  style: estilo, textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _buildFila(ProductoVariante variante, int index) {
    final fila = _filaDe(variante.id);
    final stockInfo = _sedeId != null ? variante.stockSedeInfo(_sedeId!) : null;
    final stockActual = stockInfo?.cantidad;
    final precioActual = stockInfo?.precio;
    final costoActual = stockInfo?.precioCosto;
    final editada = fila.tieneCambios;
    final u = _presentacionDe(variante);
    final nivel = variante.nivelPorMayor;
    final problema = _problemaMayor(variante);

    // El margen se calcula sobre lo que QUEDARÍA: si ya se tecleó un precio o
    // un costo nuevo, manda ese. Así se ve el efecto antes de guardar.
    final precioEfectivo =
        _parseNum(fila.precio.text) ?? (precioActual != null ? u.precio(precioActual) : null);
    final costoEfectivo =
        _parseNum(fila.costo.text) ?? (costoActual != null ? u.precio(costoActual) : null);
    final margen = _margenPct(precioEfectivo, costoEfectivo);

    return Container(
      color: editada
          ? Colors.amber.withValues(alpha: 0.12)
          : index.isEven
              ? Colors.transparent
              : Colors.grey.withValues(alpha: 0.05),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(variante.nombre,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                Row(
                  children: [
                    Flexible(
                      child: Text(variante.sku,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(fontSize: 9, color: Colors.grey[600])),
                    ),
                    if (margen != null) ...[
                      const SizedBox(width: 5),
                      Text(
                        '${margen >= 0 ? '+' : ''}${margen.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: _colorMargen(margen),
                        ),
                      ),
                    ],
                  ],
                ),
                // El motivo va debajo del nombre y no como tooltip: con la
                // grilla scrolleada a la derecha, la celda en rojo puede
                // quedar fuera de la vista y el usuario no sabría por qué no
                // lo deja guardar.
                if (problema != null)
                  Text(
                    problema.mensaje,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: problema.bloquea
                          ? Colors.red.shade700
                          : Colors.orange.shade800,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: _wStockActual,
            child: Text(
              stockActual == null ? '—' : u.cantidadTexto(stockActual),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: (stockActual ?? 0) == 0 ? Colors.red : Colors.black87,
              ),
            ),
          ),
          SizedBox(
            width: _wAgregarStock,
            child: _celdaEditable(
              controller: fila.stock,
              hint: '0',
              // Con presentación el stock se teclea en kilos y admite
              // decimales; sin ella sigue siendo entero.
              formatter: u.activa ? _decimalConSigno : _soloEnteroConSigno,
              signed: true,
            ),
          ),
          SizedBox(
            width: _wPrecio,
            child: _celdaEditable(
              controller: fila.precio,
              hint: precioActual == null
                  ? '—'
                  : u.precio(precioActual).toStringAsFixed(2),
              formatter: _soloDecimal,
            ),
          ),
          SizedBox(
            width: _wCosto,
            child: _celdaEditable(
              controller: fila.costo,
              hint: costoActual == null
                  ? '—'
                  : u.precio(costoActual).toStringAsFixed(2),
              formatter: _soloDecimal,
            ),
          ),
          SizedBox(
            width: _wMayorDesde,
            child: _celdaEditable(
              controller: fila.mayorDesde,
              // El hint muestra el nivel VIGENTE: sin esto no se distingue
              // "no tiene mayorista" de "ya tiene uno y lo estoy pisando".
              hint: nivel == null
                  ? '—'
                  : u.cantidadTexto(nivel.cantidadMinima).replaceAll(' ', ''),
              formatter: _soloDecimal,
            ),
          ),
          SizedBox(
            width: _wMayorPrecio,
            child: _celdaEditable(
              controller: fila.mayorPrecio,
              hint: nivel?.precio == null
                  ? '—'
                  : u.precio(nivel!.precio!).toStringAsFixed(2),
              formatter: _soloDecimal,
              errorColor: problema != null && problema.bloquea,
            ),
          ),
        ],
      ),
    );
  }

  Widget _celdaEditable({
    required TextEditingController controller,
    required String hint,
    required TextInputFormatter formatter,
    bool signed = false,
    bool errorColor = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: CustomText(
        controller: controller,
        hintText: hint,
        onChanged: (_) => setState(() {}),
        keyboardType: TextInputType.numberWithOptions(
            signed: signed, decimal: !signed),
        inputFormatters: [formatter],
        height: 34,
        borderColor: errorColor
            ? Colors.red.shade600
            : AppColors.blue1.withValues(alpha: 0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        textStyle: const TextStyle(fontSize: 11),
        hintStyle: TextStyle(fontSize: 10, color: Colors.grey[400]),
        showValidationIndicator: false,
      ),
    );
  }

  Widget _buildBarraGuardar(List<ProductoVariante> variantes, bool guardando) {
    final cambios = _totalCambios;
    // Se cuenta sobre TODAS las variantes, no sobre las visibles: una fila con
    // problema puede quedar escondida por el filtro y el botón tiene que
    // seguir explicando por qué no guarda.
    final bloqueantes = _bloqueantes(variantes).length;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (cambios > 0)
              TextButton.icon(
                onPressed: guardando ? null : _limpiarEdiciones,
                icon: const Icon(Icons.undo, size: 16),
                label: const Text('Descartar', style: TextStyle(fontSize: 12)),
              ),
            const Spacer(),
            if (bloqueantes > 0) ...[
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 15, color: Colors.red.shade700),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '$bloqueantes con precio por mayor inválido',
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
            FilledButton.icon(
              onPressed: cambios == 0 || guardando || bloqueantes > 0
                  ? null
                  : () => _guardar(variantes),
              icon: guardando
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save, size: 18),
              label: Text(
                guardando ? 'Guardando...' : 'Guardar ($cambios)',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
