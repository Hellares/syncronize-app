import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/producto_sede_selector/producto_sede_selector_exports.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../../producto/domain/entities/producto_list_item.dart';
import '../../data/datasources/compra_remote_datasource.dart';

/// Importa los bienes de una guía SUNAT del proveedor y los MAPEA a tu catálogo
/// (auto-mapeo por alias guardado + sugerencia por similitud; renombre in-line).
/// Devuelve (Navigator.pop) la lista de ítems para agregar a la recepción.
class ImportarGuiaPage extends StatefulWidget {
  final String empresaId;
  final String proveedorId;
  final String? sedeId;
  final String? rucProveedor; // pre-llena el RUC de la guía
  const ImportarGuiaPage({
    super.key,
    required this.empresaId,
    required this.proveedorId,
    this.sedeId,
    this.rucProveedor,
  });

  @override
  State<ImportarGuiaPage> createState() => _ImportarGuiaPageState();
}

class _MapeoRow {
  final String descripcion;
  final double? cantidadGuia;
  String? productoId;
  String? productoNombre;
  String? varianteId;
  double? factorCompra;
  String fuente;
  final TextEditingController cantidadCtrl;
  final TextEditingController precioCtrl;
  bool recordar = false;

  _MapeoRow({
    required this.descripcion,
    this.cantidadGuia,
    this.productoId,
    this.productoNombre,
    this.varianteId,
    this.factorCompra,
    this.fuente = '',
  })  : cantidadCtrl = TextEditingController(
          text: cantidadGuia != null ? _fmt(cantidadGuia) : '1',
        ),
        precioCtrl = TextEditingController();

  static String _fmt(double? v) =>
      v == null ? '' : (v % 1 == 0 ? v.toInt().toString() : v.toString());
}

class _ImportarGuiaPageState extends State<ImportarGuiaPage> {
  final _ds = locator<CompraRemoteDataSource>();
  late final TextEditingController _ctrl;
  String _tipo = '09';
  bool _loading = false;
  String? _error;
  List<_MapeoRow> _rows = [];

  @override
  void initState() {
    super.initState();
    final ruc = widget.rucProveedor ?? '';
    _ctrl = TextEditingController(text: ruc.isNotEmpty ? '$ruc-' : '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    for (final r in _rows) {
      r.cantidadCtrl.dispose();
      r.precioCtrl.dispose();
    }
    super.dispose();
  }

  Future<void> _traer() async {
    final partes =
        _ctrl.text.trim().toUpperCase().split('-').where((p) => p.isNotEmpty).toList();
    String? ruc, serie, nro;
    if (partes.length == 4) {
      ruc = partes[0];
      serie = partes[2];
      nro = partes[3];
    } else if (partes.length == 3) {
      ruc = partes[0];
      serie = partes[1];
      nro = partes[2];
    }
    if (ruc == null || !RegExp(r'^\d{11}$').hasMatch(ruc) || serie == null || nro == null) {
      setState(() => _error = 'Ingresá RUC-serie-número (ej. 20132373958-T290-120).');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _rows = [];
    });
    try {
      final guia = await _ds.consultarGuiaRemision('$ruc-$_tipo-$serie-$nro');
      final bienes = guia.bienes
          .map((b) => {
                'descripcion': b.descripcion ?? '',
                'cantidad': b.cantidad,
                'unidad': b.unidad,
              })
          .toList();
      if (bienes.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'La guía no tiene bienes.';
        });
        return;
      }
      final sug = await _ds.sugerirMapeoGuia(
        empresaId: widget.empresaId,
        proveedorId: widget.proveedorId,
        bienes: bienes,
      );
      final rows = sug.map((s) {
        return _MapeoRow(
          descripcion: s['descripcion'] as String? ?? '',
          cantidadGuia: (s['cantidadGuia'] as num?)?.toDouble(),
          productoId: s['productoId'] as String?,
          productoNombre: s['productoNombre'] as String?,
          varianteId: s['varianteId'] as String?,
          factorCompra: (s['factorCompra'] as num?)?.toDouble(),
          fuente: s['fuente'] as String? ?? '',
        );
      }).toList();
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'No se pudo traer la guía. Verificá el número.';
        });
      }
    }
  }

  Future<void> _cambiarProducto(_MapeoRow row) async {
    final p = await showModalBottomSheet<ProductoListItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 12,
          right: 12,
          top: 12,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: ProductoSedeSelector(
            empresaId: widget.empresaId,
            sedeIdInicial: widget.sedeId,
            mostrarSelectorSede: false,
            onProductoSeleccionado: ({required producto, required sedeId, variante}) =>
                Navigator.pop(context, producto),
          ),
        ),
      ),
    );
    if (p != null) {
      setState(() {
        row.productoId = p.id;
        row.productoNombre = p.nombre;
        row.varianteId = null;
        row.factorCompra = p.factorCompra;
        row.fuente = 'manual';
      });
    }
  }

  Future<void> _agregar() async {
    final mapeados = _rows.where((r) => r.productoId != null).toList();
    if (mapeados.isEmpty) {
      setState(() => _error = 'Mapeá al menos un producto.');
      return;
    }
    // Guardar alias de los marcados "recordar".
    final aliases = mapeados
        .where((r) => r.recordar)
        .map((r) => {
              'descripcionProveedor': r.descripcion,
              'productoId': r.productoId,
              if (r.varianteId != null) 'varianteId': r.varianteId,
            })
        .toList();
    if (aliases.isNotEmpty) {
      try {
        await _ds.guardarAliasProveedor(
          empresaId: widget.empresaId,
          proveedorId: widget.proveedorId,
          items: aliases,
        );
      } catch (_) {/* no bloquear el import si falla el alias */}
    }
    // Construir ítems para la recepción.
    final items = mapeados.map((r) {
      final cant = int.tryParse(r.cantidadCtrl.text.trim()) ??
          (r.cantidadGuia?.round() ?? 1);
      final precio = double.tryParse(r.precioCtrl.text.trim().replaceAll(',', '.')) ?? 0;
      return {
        'productoId': r.productoId,
        'varianteId': r.varianteId,
        'descripcion': r.productoNombre ?? r.descripcion,
        'cantidad': cant,
        'precioUnitario': precio,
        'descuento': 0,
      };
    }).toList();
    if (!mounted) return;
    Navigator.of(context).pop(items);
  }

  @override
  Widget build(BuildContext context) {
    final mapeados = _rows.where((r) => r.productoId != null).length;
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Importar de guía',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
      ),
      body: GradientBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: CustomText(
                      label: 'Guía (RUC-serie-número)',
                      controller: _ctrl,
                      hintText: '20132373958-T290-120',
                      borderColor: AppColors.blueborder,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _tipoBtn('Remisión', '09'),
                  const SizedBox(width: 6),
                  _tipoBtn('Transp.', '31'),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 33,
                    child: CustomButton(
                      text: 'Traer',
                      backgroundColor: AppColors.blue1,
                      textColor: Colors.white,
                      isLoading: _loading,
                      onPressed: _loading ? null : _traer,
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
            Expanded(
              child: _rows.isEmpty
                  ? Center(
                      child: AppSubtitle(
                        'Ingresá la guía del proveedor y tocá "Traer".',
                        fontSize: 12,
                        color: AppColors.blueGrey,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
                      itemCount: _rows.length,
                      itemBuilder: (_, i) => _buildRow(_rows[i]),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _rows.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: CustomButton(
                  text: 'Agregar $mapeados ítem${mapeados != 1 ? 's' : ''} a la compra',
                  backgroundColor: AppColors.blue1,
                  textColor: Colors.white,
                  onPressed: mapeados == 0 ? null : _agregar,
                ),
              ),
            ),
    );
  }

  Widget _tipoBtn(String label, String val) {
    final sel = _tipo == val;
    return GestureDetector(
      onTap: () => setState(() => _tipo = val),
      child: Container(
        height: 33,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: sel ? AppColors.blue1 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: sel ? AppColors.blue1 : Colors.grey.shade300),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: sel ? Colors.white : AppColors.blue1)),
      ),
    );
  }

  Widget _buildRow(_MapeoRow r) {
    final mapeado = r.productoId != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: mapeado ? AppColors.blueborder : Colors.orange.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lo que dice la guía del proveedor.
          Row(
            children: [
              const Icon(Icons.receipt_long, size: 13, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${r.descripcion}${r.cantidadGuia != null ? '  (${_MapeoRow._fmt(r.cantidadGuia)})' : ''}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Producto del catálogo (mapeo).
          InkWell(
            onTap: () => _cambiarProducto(r),
            child: Row(
              children: [
                Icon(mapeado ? Icons.check_circle : Icons.add_circle_outline,
                    size: 16, color: mapeado ? Colors.teal : Colors.orange),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    r.productoNombre ?? 'Tocá para mapear tu producto',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: mapeado ? AppColors.blue1 : Colors.orange.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (r.fuente.isNotEmpty && mapeado)
                  Text(
                    r.fuente == 'alias'
                        ? '✓ alias'
                        : r.fuente == 'similitud'
                            ? '~ sugerido'
                            : '',
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                  ),
                const Icon(Icons.edit, size: 13, color: Colors.grey),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 90,
                child: CustomText(
                  label: 'Cantidad',
                  controller: r.cantidadCtrl,
                  fieldType: FieldType.number,
                  borderColor: AppColors.blueborder,
                ),
              ),
              const SizedBox(width: 8),
              if (r.factorCompra != null && r.factorCompra! > 1)
                GestureDetector(
                  onTap: () {
                    final base = r.cantidadGuia ?? 1;
                    r.cantidadCtrl.text = (base * r.factorCompra!).round().toString();
                  },
                  child: Container(
                    height: 33,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    margin: const EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.teal.withValues(alpha: 0.4)),
                    ),
                    child: Text('×${_MapeoRow._fmt(r.factorCompra)}',
                        style: TextStyle(fontSize: 10, color: Colors.teal.shade700, fontWeight: FontWeight.w700)),
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomText(
                  label: 'Precio unit.',
                  controller: r.precioCtrl,
                  fieldType: FieldType.number,
                  hintText: '0.00',
                  borderColor: AppColors.blueborder,
                ),
              ),
            ],
          ),
          if (mapeado && r.fuente != 'alias')
            Row(
              children: [
                Checkbox(
                  value: r.recordar,
                  visualDensity: VisualDensity.compact,
                  onChanged: (v) => setState(() => r.recordar = v ?? false),
                ),
                Expanded(
                  child: Text('Recordar "${r.descripcion}" para este proveedor',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
