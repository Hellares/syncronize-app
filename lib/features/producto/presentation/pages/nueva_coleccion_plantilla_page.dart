import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';

import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/styled_dialog.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../data/variante_plantilla_api.dart';

/// Nueva colección desde una plantilla: "Edredones" + "DINOSAURIO" → las
/// combinaciones de la plantilla con esa colección, en 0 y con sus precios.
/// Después siguen "Agregar diseños" (las fotos) y la compra (las unidades).
///
/// Devuelve `true` si creó variantes, para recargar la lista.
class NuevaColeccionPlantillaPage extends StatefulWidget {
  final String productoId;
  final String productoNombre;

  /// Abre la gestión de plantillas (para crear la primera). Devuelve cuando
  /// se vuelve de ahí.
  final Future<void> Function(BuildContext context) onGestionarPlantillas;

  const NuevaColeccionPlantillaPage({
    super.key,
    required this.productoId,
    required this.productoNombre,
    required this.onGestionarPlantillas,
  });

  @override
  State<NuevaColeccionPlantillaPage> createState() => _NuevaColeccionPlantillaPageState();
}

class _NuevaColeccionPlantillaPageState extends State<NuevaColeccionPlantillaPage> {
  final _api = VariantePlantillaApi();
  final _nombreCtrl = TextEditingController();

  List<VariantePlantilla> _plantillas = const [];
  VariantePlantilla? _plantilla;

  /// Por combinación: si va, y su precio y costo (sugeridos, editables).
  final Map<String, bool> _elegidas = {};
  final Map<String, TextEditingController> _precio = {};
  final Map<String, TextEditingController> _costo = {};

  bool _cargando = true;
  bool _enviando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    for (final c in [..._precio.values, ..._costo.values]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final lista = await _api.listar();
      if (!mounted) return;
      setState(() {
        _plantillas = lista;
        _cargando = false;
      });
      final actual = _plantilla == null ? null : lista.where((p) => p.id == _plantilla!.id).firstOrNull;
      _elegir(actual ?? (lista.length == 1 ? lista.first : null));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = mensajeDeError(e, 'No se pudieron cargar las plantillas');
      });
    }
  }

  void _elegir(VariantePlantilla? p) {
    setState(() {
      _plantilla = p;
      _elegidas.clear();
      for (final c in [..._precio.values, ..._costo.values]) {
        c.dispose();
      }
      _precio.clear();
      _costo.clear();
      for (final c in p?.combinaciones ?? const <CombinacionPlantilla>[]) {
        final id = c.id!;
        _elegidas[id] = true;
        _precio[id] = TextEditingController(text: c.precio?.toStringAsFixed(2) ?? '');
        _costo[id] = TextEditingController(text: c.precioCosto?.toStringAsFixed(2) ?? '');
      }
    });
  }

  double? _num(TextEditingController? c) =>
      c == null ? null : double.tryParse(c.text.replaceAll(',', '.'));

  List<CombinacionPlantilla> get _aCrear => [
        for (final c in _plantilla?.combinaciones ?? const <CombinacionPlantilla>[])
          if (_elegidas[c.id] == true) c,
      ];

  Future<void> _crear() async {
    final p = _plantilla;
    final nombre = _nombreCtrl.text.trim().toUpperCase();
    if (p == null || nombre.isEmpty) return;
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      final r = await _api.aplicar(
        plantillaId: p.id,
        productoId: widget.productoId,
        valorColeccion: nombre,
        combinaciones: [
          for (final c in _aCrear)
            (combinacionId: c.id!, precio: _num(_precio[c.id]), precioCosto: _num(_costo[c.id])),
        ],
      );
      if (!mounted) return;
      await _mostrarResultado(nombre, r);
      if (mounted) Navigator.pop(context, r.creadas.isNotEmpty);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _error = mensajeDeError(e, 'No se pudo crear la colección');
      });
    }
  }

  Future<void> _mostrarResultado(String nombre, ResultadoAplicar r) {
    return StyledDialog.show<void>(
      context,
      accentColor: AppColors.blue1,
      icon: Icons.auto_awesome,
      titulo: r.creadas.isEmpty
          ? 'No se creó ninguna'
          : '${r.creadas.length} variante${r.creadas.length == 1 ? '' : 's'} de $nombre',
      subtitulo: widget.productoNombre,
      backgroundColor: Colors.white,
      barrierDismissible: false,
      content: [
        for (final c in r.creadas)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: AppSubtitle(c, fontSize: 11, color: Colors.grey.shade800),
          ),
        if (r.omitidas.isNotEmpty) ...[
          const SizedBox(height: 8),
          AppSubtitle('Ya existían (no se duplicaron):',
              fontSize: 10, fontWeight: FontWeight.w700, color: Colors.orange.shade800),
          for (final o in r.omitidas) AppSubtitle(o, fontSize: 10, color: Colors.grey.shade600),
        ],
        const SizedBox(height: 8),
        AppSubtitle(
          'Nacen en 0: las unidades entran con la compra. Las fotos, con "Agregar diseños".',
          fontSize: 10,
          color: Colors.grey.shade600,
        ),
      ],
      actions: [
        Expanded(
          child: CustomButton(
            text: 'Listo',
            backgroundColor: AppColors.blue1,
            textColor: Colors.white,
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final n = _aCrear.length;
    final nombre = _nombreCtrl.text.trim().toUpperCase();
    return PopScope(
      canPop: !_enviando,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FB),
        appBar: AppBar(
          title: const Text('Nueva colección', style: TextStyle(fontSize: 16)),
          actions: [
            TextButton(
              onPressed: _enviando
                  ? null
                  : () async {
                      await widget.onGestionarPlantillas(context);
                      if (mounted) _cargar();
                    },
              child: const Text('Plantillas'),
            ),
          ],
        ),
        body: _cargando
            ? const Center(child: CircularProgressIndicator())
            : _plantillas.isEmpty
                ? _sinPlantillas()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      AppSubtitle(widget.productoNombre,
                          fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.blue1),
                      const SizedBox(height: 10),
                      AppSubtitle('1. PLANTILLA', fontSize: 10, color: Colors.grey.shade700),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final p in _plantillas)
                            ChoiceChip(
                              label: Text('${p.nombre} (${p.combinaciones.length})',
                                  style: const TextStyle(fontSize: 11)),
                              selected: _plantilla?.id == p.id,
                              onSelected: _enviando ? null : (_) => _elegir(p),
                            ),
                        ],
                      ),
                      if (_plantilla != null) ...[
                        const SizedBox(height: 16),
                        AppSubtitle('2. NOMBRE DE LA COLECCIÓN NUEVA',
                            fontSize: 10, color: Colors.grey.shade700),
                        const SizedBox(height: 6),
                        CustomText(
                          controller: _nombreCtrl,
                          label: _plantilla!.atributoColeccion.nombre,
                          hintText: 'Ej. DINOSAURIO',
                          borderColor: AppColors.blue1,
                          textCase: TextCase.upper,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                        AppSubtitle('3. COMBINACIONES (${_plantilla!.combinaciones.length})',
                            fontSize: 10, color: Colors.grey.shade700),
                        const SizedBox(height: 6),
                        for (final c in _plantilla!.combinaciones) _filaCombinacion(c),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        AppSubtitle(_error!, fontSize: 12, color: AppColors.red),
                      ],
                    ],
                  ),
        bottomNavigationBar: _plantilla == null
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.blue1,
                      minimumSize: const Size.fromHeight(46),
                    ),
                    onPressed: _enviando || n == 0 || nombre.isEmpty ? null : _crear,
                    child: Text(
                      _enviando
                          ? 'Creando…'
                          : nombre.isEmpty
                              ? 'Escribí el nombre de la colección'
                              : 'Crear $n variante${n == 1 ? '' : 's'} de $nombre',
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _filaCombinacion(CombinacionPlantilla c) {
    final id = c.id!;
    final va = _elegidas[id] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(4, 4, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: va ? AppColors.blue1 : Colors.grey.shade300, width: va ? 1.2 : 0.6),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Checkbox(
                value: va,
                onChanged: _enviando ? null : (v) => setState(() => _elegidas[id] = v ?? false),
              ),
              Expanded(
                child: AppSubtitle(c.etiqueta, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              if (c.niveles.isNotEmpty)
                Tooltip(
                  message: 'Trae su precio por mayor',
                  child: Icon(Icons.layers_outlined, size: 14, color: AppColors.greendark),
                ),
            ],
          ),
          if (va)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Row(
                children: [
                  Expanded(child: _campoPrecio(_precio[id]!, 'Precio de venta')),
                  const SizedBox(width: 8),
                  Expanded(child: _campoPrecio(_costo[id]!, 'Costo')),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _campoPrecio(TextEditingController ctrl, String label) {
    return CustomText(
      controller: ctrl,
      label: label,
      prefixText: 'S/ ',
      hintText: '0.00',
      borderColor: AppColors.blue1,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
    );
  }

  Widget _sinPlantillas() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_outlined, size: 44, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            AppSubtitle('Todavía no hay plantillas de variantes',
                fontSize: 13, fontWeight: FontWeight.w700, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            AppSubtitle(
              'Creá una desde una colección que ya tengas (por ejemplo CRISTAL) '
              'o desde cero, y después la usás para cada colección nueva.',
              fontSize: 11,
              color: Colors.grey.shade600,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.blue1),
              onPressed: () async {
                await widget.onGestionarPlantillas(context);
                if (mounted) _cargar();
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Crear plantilla'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              AppSubtitle(_error!, fontSize: 12, color: AppColors.red),
            ],
          ],
        ),
      ),
    );
  }
}
