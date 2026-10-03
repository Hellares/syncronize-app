import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';

import '../../../../core/widgets/custom_dropdown.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../data/variante_plantilla_api.dart';
import '../../domain/entities/producto_atributo.dart';
import 'separar_por_diseno_page.dart' show kClaveAtributoDiseno;

/// Crear o editar una plantilla de VARIANTES desde cero (la de peluches): el
/// nombre, cuál atributo es la colección, qué atributos llevan las
/// combinaciones y cada combinación con sus precios sugeridos.
///
/// Devuelve `true` si guardó.
class PlantillaVarianteEditorPage extends StatefulWidget {
  final List<ProductoAtributo> atributos;
  final VariantePlantilla? plantilla;

  const PlantillaVarianteEditorPage({super.key, required this.atributos, this.plantilla});

  @override
  State<PlantillaVarianteEditorPage> createState() => _PlantillaVarianteEditorPageState();
}

/// Una combinación en edición.
class _Fila {
  /// atributoId → valor (texto libre o el elegido en la lista).
  final Map<String, TextEditingController> valores = {};
  final TextEditingController precio;
  final TextEditingController costo;

  /// Los precios por mayor que traía (se conservan al guardar).
  final List<Map<String, dynamic>> niveles;

  _Fila({String precio = '', String costo = '', this.niveles = const []})
      : precio = TextEditingController(text: precio),
        costo = TextEditingController(text: costo);

  TextEditingController campo(String atributoId) =>
      valores.putIfAbsent(atributoId, () => TextEditingController());

  void dispose() {
    for (final c in [...valores.values, precio, costo]) {
      c.dispose();
    }
  }
}

class _PlantillaVarianteEditorPageState extends State<PlantillaVarianteEditorPage> {
  final _api = VariantePlantillaApi();
  final _nombreCtrl = TextEditingController();
  String? _coleccionId;
  final List<String> _atributoIds = [];

  /// El orden del NOMBRE que traía la plantilla (puede incluir la colección
  /// en su lugar: "2 PLAZAS / TELA / 3 PZS / HOMBRE / CRISTAL"). Al guardar
  /// se respeta; lo agregado entra antes de la colección.
  List<String> _ordenOriginal = const [];
  final List<_Fila> _filas = [];
  bool _guardando = false;
  String? _error;

  /// Activos y sin el Diseño (los diseños salen de las fotos, no de acá).
  late final List<ProductoAtributo> _disponibles = widget.atributos
      .where((a) => a.isActive && a.clave != kClaveAtributoDiseno)
      .toList()
    ..sort((a, b) => a.orden.compareTo(b.orden));

  ProductoAtributo? _atributo(String id) => _disponibles.where((a) => a.id == id).firstOrNull;

  @override
  void initState() {
    super.initState();
    final p = widget.plantilla;
    if (p != null) {
      _nombreCtrl.text = p.nombre;
      _coleccionId = p.atributoColeccion.id;
      _ordenOriginal = p.atributos.map((a) => a.id).toList();
      _atributoIds.addAll(_ordenOriginal.where((id) => id != _coleccionId));
      for (final c in p.combinaciones) {
        final f = _Fila(
          precio: c.precio?.toStringAsFixed(2) ?? '',
          costo: c.precioCosto?.toStringAsFixed(2) ?? '',
          niveles: c.niveles,
        );
        for (final v in c.valores) {
          f.campo(v.atributoId).text = v.valor;
        }
        _filas.add(f);
      }
    } else {
      _coleccionId = _disponibles
          .where((a) => a.clave == 'dise_o' || a.nombre.toLowerCase().contains('colec'))
          .map((a) => a.id)
          .firstOrNull;
      _filas.add(_Fila());
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    for (final f in _filas) {
      f.dispose();
    }
    super.dispose();
  }

  double? _num(TextEditingController c) => double.tryParse(c.text.replaceAll(',', '.'));

  /// El orden con que se van a nombrar las variantes: el que traía la
  /// plantilla (con la colección en su lugar), y lo nuevo antes de la
  /// colección; sin orden previo, los elegidos y la colección al final.
  List<String> _ordenNombre(String coleccion) {
    final elegidos = {..._atributoIds, coleccion};
    final orden = [for (final id in _ordenOriginal) if (elegidos.contains(id)) id];
    if (!orden.contains(coleccion)) orden.add(coleccion);
    final nuevos = _atributoIds.where((id) => !orden.contains(id)).toList();
    orden.insertAll(orden.indexOf(coleccion), nuevos);
    return orden;
  }

  Future<void> _guardar() async {
    final nombre = _nombreCtrl.text.trim();
    final coleccion = _coleccionId;
    String? falta;
    if (nombre.isEmpty) {
      falta = 'Poné un nombre a la plantilla.';
    } else if (coleccion == null) {
      falta = 'Elegí cuál atributo es la colección.';
    } else if (_atributoIds.isEmpty) {
      falta = 'Elegí al menos un atributo para las combinaciones.';
    } else if (_filas.isEmpty) {
      falta = 'Agregá al menos una combinación.';
    } else if (_filas.any((f) => _atributoIds.any((id) => f.campo(id).text.trim().isEmpty))) {
      falta = 'Hay combinaciones con atributos sin valor.';
    }
    if (falta != null) {
      setState(() => _error = falta);
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await _api.guardar(
        id: widget.plantilla?.id,
        nombre: nombre,
        atributoColeccionId: coleccion!,
        atributoIds: _ordenNombre(coleccion),
        combinaciones: [
          for (final f in _filas)
            CombinacionPlantilla(
              valores: [for (final id in _atributoIds) ValorPlantilla(id, f.campo(id).text.trim())],
              precio: _num(f.precio),
              precioCosto: _num(f.costo),
              niveles: f.niveles,
            ),
        ],
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = mensajeDeError(e, 'No se pudo guardar la plantilla');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final candidatos = _disponibles.where((a) => a.id != _coleccionId).toList();
    return PopScope(
      canPop: !_guardando,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FB),
        appBar: AppBar(
          title: Text(widget.plantilla == null ? 'Nueva plantilla' : 'Editar plantilla',
              style: const TextStyle(fontSize: 16)),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            CustomText(
              controller: _nombreCtrl,
              label: 'Nombre de la plantilla',
              hintText: 'Ej. Peluches',
              borderColor: AppColors.blue1,
            ),
            const SizedBox(height: 12),
            CustomDropdown<String>(
              label: '¿Cuál atributo es la colección?',
              hintText: 'El que cambia en cada colección nueva',
              value: _coleccionId,
              borderColor: AppColors.blue1,
              items: [for (final a in _disponibles) DropdownItem(value: a.id, label: a.nombre)],
              onChanged: _guardando
                  ? null
                  : (v) => setState(() {
                        _coleccionId = v;
                        _atributoIds.remove(v);
                      }),
            ),
            const SizedBox(height: 14),
            AppSubtitle('ATRIBUTOS DE LAS COMBINACIONES', fontSize: 10, color: Colors.grey.shade700),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final a in candidatos)
                  FilterChip(
                    label: Text(a.nombre, style: const TextStyle(fontSize: 11)),
                    selected: _atributoIds.contains(a.id),
                    onSelected: _guardando
                        ? null
                        : (s) => setState(() {
                              if (s) {
                                _atributoIds.add(a.id);
                                // En el orden de los atributos: es el del nombre.
                                _atributoIds.sort((x, y) =>
                                    (_atributo(x)?.orden ?? 0).compareTo(_atributo(y)?.orden ?? 0));
                              } else {
                                _atributoIds.remove(a.id);
                              }
                            }),
                  ),
              ],
            ),
            if (_atributoIds.isNotEmpty) ...[
              const SizedBox(height: 16),
              AppSubtitle('COMBINACIONES (${_filas.length})', fontSize: 10, color: Colors.grey.shade700),
              const SizedBox(height: 6),
              for (final (i, f) in _filas.indexed) _fila(i, f),
              TextButton.icon(
                onPressed: _guardando ? null : () => setState(() => _filas.add(_Fila())),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agregar combinación'),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 10),
              AppSubtitle(_error!, fontSize: 12, color: AppColors.red),
            ],
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue1,
                minimumSize: const Size.fromHeight(46),
              ),
              onPressed: _guardando ? null : _guardar,
              child: Text(_guardando ? 'Guardando…' : 'Guardar plantilla'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fila(int i, _Fila f) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 6, 4, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: AppSubtitle('Combinación ${i + 1}',
                    fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.blue1),
              ),
              IconButton(
                tooltip: 'Quitar',
                icon: Icon(Icons.close, size: 18, color: Colors.red.shade400),
                onPressed: _guardando
                    ? null
                    : () => setState(() {
                          _filas.removeAt(i).dispose();
                        }),
              ),
            ],
          ),
          for (final id in _atributoIds) ...[
            _campoValor(f, id),
            const SizedBox(height: 8),
          ],
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Row(
              children: [
                Expanded(child: _campoPrecio(f.precio, 'Precio de venta')),
                const SizedBox(width: 8),
                Expanded(child: _campoPrecio(f.costo, 'Costo')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Lista cerrada → desplegable; texto libre → campo.
  Widget _campoValor(_Fila f, String atributoId) {
    final a = _atributo(atributoId);
    final ctrl = f.campo(atributoId);
    final opciones = a?.valores ?? const <String>[];
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: opciones.isNotEmpty
          ? CustomDropdown<String>(
              label: a?.nombre ?? 'Atributo',
              value: opciones.contains(ctrl.text) ? ctrl.text : null,
              borderColor: AppColors.blue1,
              items: [for (final o in opciones) DropdownItem(value: o, label: o)],
              onChanged: _guardando ? null : (v) => setState(() => ctrl.text = v ?? ''),
            )
          : CustomText(
              controller: ctrl,
              label: a?.nombre ?? 'Atributo',
              borderColor: AppColors.blue1,
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
}
