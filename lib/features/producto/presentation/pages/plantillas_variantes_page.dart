import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';

import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../core/widgets/styled_dialog.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../data/variante_plantilla_api.dart';
import '../../domain/entities/producto_atributo.dart';
import '../../domain/entities/producto_variante.dart';
import 'plantilla_variante_editor_page.dart';
import 'separar_por_diseno_page.dart' show kClaveAtributoDiseno;

/// Las plantillas de VARIANTES de la empresa ("Edredones", "Peluches"):
/// crearlas desde una colección que ya existe en este producto o desde cero,
/// editarlas y eliminarlas.
class PlantillasVariantesPage extends StatefulWidget {
  final String productoId;
  final String productoNombre;

  /// Las variantes del producto: de ahí sale "desde una colección".
  final List<ProductoVariante> variantes;

  /// Los atributos de la empresa, para el editor.
  final List<ProductoAtributo> atributos;

  const PlantillasVariantesPage({
    super.key,
    required this.productoId,
    required this.productoNombre,
    required this.variantes,
    required this.atributos,
  });

  @override
  State<PlantillasVariantesPage> createState() => _PlantillasVariantesPageState();
}

class _PlantillasVariantesPageState extends State<PlantillasVariantesPage> {
  final _api = VariantePlantillaApi();
  List<VariantePlantilla> _plantillas = const [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = mensajeDeError(e, 'No se pudieron cargar las plantillas');
      });
    }
  }

  void _aviso(String texto, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(texto),
      backgroundColor: error ? AppColors.red : AppColors.blue1,
    ));
  }

  Future<void> _nueva() async {
    final opcion = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy_all_outlined, color: AppColors.blue1),
              title: const Text('Desde una colección de este producto'),
              subtitle: const Text('Copia sus combinaciones y precios (ej. CRISTAL)',
                  style: TextStyle(fontSize: 11)),
              enabled: widget.variantes.isNotEmpty,
              onTap: () => Navigator.pop(ctx, 'coleccion'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_note, color: AppColors.blue1),
              title: const Text('Desde cero'),
              subtitle: const Text('Elegís los atributos y armás las combinaciones',
                  style: TextStyle(fontSize: 11)),
              onTap: () => Navigator.pop(ctx, 'cero'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || opcion == null) return;
    if (opcion == 'coleccion') {
      await _desdeColeccion();
    } else {
      await _editar(null);
    }
  }

  Future<void> _editar(VariantePlantilla? p) async {
    final cambio = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PlantillaVarianteEditorPage(atributos: widget.atributos, plantilla: p),
      ),
    );
    if (cambio == true && mounted) _cargar();
  }

  Future<void> _eliminar(VariantePlantilla p) async {
    final ok = await ConfirmDialog.show(
      context: context,
      type: ConfirmDialogType.destructive,
      title: 'Eliminar plantilla',
      message: '¿Eliminar "${p.nombre}"? Las variantes ya creadas con ella no cambian.',
      confirmText: 'Eliminar',
    );
    if (ok != true || !mounted) return;
    try {
      await _api.eliminar(p.id);
      if (mounted) _cargar();
    } catch (e) {
      if (mounted) _aviso(mensajeDeError(e, 'No se pudo eliminar'), error: true);
    }
  }

  /// "Guardar como plantilla" una colección de este producto.
  Future<void> _desdeColeccion() async {
    // Atributos que tienen las variantes activas (sin el Diseño).
    final porId = <String, ({String nombre, String clave, Set<String> valores})>{};
    for (final v in widget.variantes.where((v) => v.isActive)) {
      for (final a in v.atributosValores) {
        if (a.atributo.clave == kClaveAtributoDiseno) continue;
        final actual = porId[a.atributoId];
        final valores = {...?actual?.valores, a.valor};
        porId[a.atributoId] = (nombre: a.atributo.nombre, clave: a.atributo.clave, valores: valores);
      }
    }
    if (porId.isEmpty) {
      _aviso('Las variantes de este producto no tienen atributos para copiar.', error: true);
      return;
    }
    // Por defecto, el que parece la colección.
    String atributoId = porId.entries
            .where((e) => e.value.clave == 'dise_o' || e.value.nombre.toLowerCase().contains('colec'))
            .map((e) => e.key)
            .firstOrNull ??
        porId.keys.first;
    String? valor;
    final nombreCtrl = TextEditingController(text: widget.productoNombre);

    final confirmado = await StyledDialog.show<bool>(
      context,
      accentColor: AppColors.blue1,
      icon: Icons.copy_all_outlined,
      titulo: 'Plantilla desde una colección',
      subtitulo: widget.productoNombre,
      backgroundColor: Colors.white,
      content: [
        StatefulBuilder(
          builder: (ctx, setD) {
            final valores = (porId[atributoId]?.valores.toList() ?? <String>[])..sort();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomDropdown<String>(
                  label: '¿Cuál atributo es la colección?',
                  value: atributoId,
                  borderColor: AppColors.blue1,
                  items: [
                    for (final e in porId.entries) DropdownItem(value: e.key, label: e.value.nombre),
                  ],
                  onChanged: (v) => setD(() {
                    atributoId = v ?? atributoId;
                    valor = null;
                  }),
                ),
                const SizedBox(height: 10),
                CustomDropdown<String>(
                  label: 'Colección modelo',
                  hintText: 'Elegí una (ej. CRISTAL)',
                  value: valor,
                  borderColor: AppColors.blue1,
                  items: [for (final v in valores) DropdownItem(value: v, label: v)],
                  onChanged: (v) => setD(() => valor = v),
                ),
                const SizedBox(height: 10),
                CustomText(
                  controller: nombreCtrl,
                  label: 'Nombre de la plantilla',
                  hintText: 'Ej. Edredones',
                  borderColor: AppColors.blue1,
                ),
              ],
            );
          },
        ),
      ],
      actions: [
        Expanded(
          child: CustomButton(
            text: 'Crear plantilla',
            backgroundColor: AppColors.blue1,
            textColor: Colors.white,
            onPressed: () => Navigator.pop(context, true),
          ),
        ),
      ],
    );
    final nombre = nombreCtrl.text.trim();
    nombreCtrl.dispose();
    if (confirmado != true || !mounted) return;
    if (valor == null || nombre.isEmpty) {
      _aviso('Elegí la colección modelo y el nombre de la plantilla.', error: true);
      return;
    }
    try {
      final p = await _api.desdeColeccion(
        nombre: nombre,
        productoId: widget.productoId,
        atributoColeccionId: atributoId,
        valorColeccion: valor!,
      );
      if (!mounted) return;
      _aviso('Plantilla "${p.nombre}" creada con ${p.combinaciones.length} combinaciones');
      _cargar();
    } catch (e) {
      if (mounted) _aviso(mensajeDeError(e, 'No se pudo crear la plantilla'), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(title: const Text('Plantillas de variantes', style: TextStyle(fontSize: 16))),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        onPressed: _nueva,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Nueva', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargar,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AppSubtitle(_error!, fontSize: 12, color: AppColors.red),
                    ),
                  if (_plantillas.isEmpty && _error == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: AppSubtitle(
                        'Sin plantillas todavía. Tocá "Nueva": desde una colección de este '
                        'producto (la más rápida) o desde cero.',
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  for (final p in _plantillas) _tarjeta(p),
                ],
              ),
            ),
    );
  }

  Widget _tarjeta(VariantePlantilla p) {
    // Sin la colección: ya se dice aparte (en la plantilla marca su lugar).
    final atributos = p.atributos
        .where((a) => a.id != p.atributoColeccion.id)
        .map((a) => a.nombre)
        .join(' · ');
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        onTap: () => _editar(p),
        title: AppSubtitle(p.nombre, fontSize: 13, fontWeight: FontWeight.w700),
        subtitle: AppSubtitle(
          '${p.combinaciones.length} combinaciones · colección: ${p.atributoColeccion.nombre}'
          '${atributos.isEmpty ? '' : '\n$atributos'}',
          fontSize: 10,
          color: Colors.grey.shade600,
        ),
        isThreeLine: atributos.isNotEmpty,
        trailing: IconButton(
          tooltip: 'Eliminar',
          icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
          onPressed: () => _eliminar(p),
        ),
      ),
    );
  }
}
