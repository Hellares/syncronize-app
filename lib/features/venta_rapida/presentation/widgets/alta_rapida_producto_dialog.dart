import 'package:flutter/material.dart';

import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_button.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';

import '../../../producto/data/datasources/producto_remote_datasource.dart';
import '../../../producto/domain/entities/producto_list_item.dart';

/// Alta RÁPIDA de un producto sin salir del mostrador.
///
/// El caso: viene un cliente, pide algo que está en el estante pero no en el
/// catálogo, y la cola no espera. Se cargan nombre, precio y cantidad, y el
/// producto queda listo para cobrarse en el mismo movimiento.
///
/// Categoría, marca, unidad y costo quedan NULL a propósito. Para el
/// comprobante da igual —sin unidad el mapper de SUNAT declara NIU— y quien
/// vende en el mostrador no ve ni carga costos: se completan después desde la
/// ficha del producto.
///
/// Exige el granular `producto.alta-rapida-venta` (`canAltaRapidaVenta`). El
/// endpoint lo valida igual; el gate de la UI solo evita ofrecer algo que va a
/// rebotar.
Future<ProductoListItem?> showAltaRapidaProductoDialog(
  BuildContext context, {
  required String empresaId,
  required String sedeId,
  String nombreInicial = '',
}) {
  return showDialog<ProductoListItem>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _AltaRapidaProductoDialog(
      empresaId: empresaId,
      sedeId: sedeId,
      nombreInicial: nombreInicial,
    ),
  );
}

class _AltaRapidaProductoDialog extends StatefulWidget {
  final String empresaId;
  final String sedeId;
  final String nombreInicial;

  const _AltaRapidaProductoDialog({
    required this.empresaId,
    required this.sedeId,
    required this.nombreInicial,
  });

  @override
  State<_AltaRapidaProductoDialog> createState() =>
      _AltaRapidaProductoDialogState();
}

class _AltaRapidaProductoDialogState extends State<_AltaRapidaProductoDialog> {
  late final TextEditingController _nombre;
  final _precio = TextEditingController();
  final _cantidad = TextEditingController(text: '1');
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Lo que el cajero ya tecleó en el buscador: casi siempre ES el nombre.
    _nombre = TextEditingController(text: widget.nombreInicial.trim());
  }

  @override
  void dispose() {
    _nombre.dispose();
    _precio.dispose();
    _cantidad.dispose();
    super.dispose();
  }

  double _leer(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.')) ?? 0;

  Future<void> _guardar() async {
    final nombre = _nombre.text.trim();
    final precio = _leer(_precio);
    final cantidad = _leer(_cantidad);

    if (nombre.isEmpty) {
      setState(() => _error = 'El producto necesita un nombre');
      return;
    }
    if (precio <= 0) {
      setState(() => _error = 'El precio de venta tiene que ser mayor a 0');
      return;
    }
    if (cantidad < 0) {
      setState(() => _error = 'La cantidad no puede ser negativa');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final creado = await locator<ProductoRemoteDataSource>().altaRapidaVenta(
        empresaId: widget.empresaId,
        sedeId: widget.sedeId,
        // El backend lo normaliza a MAYÚSCULAS igual; se manda tal cual.
        nombre: nombre,
        precio: precio,
        cantidad: cantidad,
      );
      if (!mounted) return;
      Navigator.of(context).pop(creado);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = 'No se pudo crear el producto. $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      titlePadding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      contentPadding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      title: const Text(
        'Producto nuevo',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppColors.blue1,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Para cobrarlo ahora. La categoría, la marca y el costo se '
              'completan después desde la ficha.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            CustomText(
              controller: _nombre,
              borderColor: AppColors.blue1,
              label: 'Nombre',
              hintText: 'MOUSE LOGITECH M170',
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: CustomText(
                    controller: _precio,
                    borderColor: AppColors.blue1,
                    label: 'Precio de venta',
                    hintText: '0.00',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomText(
                    controller: _cantidad,
                    borderColor: AppColors.blue1,
                    label: 'Cantidad',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(fontSize: 11, color: Colors.red.shade700),
                ),
              ),
            ],
            const SizedBox(height: 4),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
      actions: [
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Cancelar',
                isOutlined: true,
                borderColor: Colors.grey.shade400,
                textColor: Colors.grey.shade700,
                onPressed:
                    _guardando ? null : () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: CustomButton(
                text: _guardando ? 'Creando…' : 'Crear y agregar',
                backgroundColor: AppColors.blue1,
                textColor: Colors.white,
                onPressed: _guardando ? null : _guardar,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
