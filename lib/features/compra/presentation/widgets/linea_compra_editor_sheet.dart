import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';

import '../../domain/entities/linea_compra_draft.dart';
import 'historial_compras_producto_panel.dart';

/// Editor de UNA línea de compra: cantidad, precio, descuento, empaque y el
/// ajuste del precio de venta que se aplica al confirmar.
///
/// Devuelve la línea editada, o `null` si se salió sin guardar.
Future<LineaCompraDraft?> showLineaCompraEditorSheet({
  required BuildContext context,
  required LineaCompraDraft linea,
  required String empresaId,
}) {
  return showModalBottomSheet<LineaCompraDraft>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _LineaCompraEditorSheet(linea: linea, empresaId: empresaId),
  );
}

class _LineaCompraEditorSheet extends StatefulWidget {
  final LineaCompraDraft linea;
  final String empresaId;

  const _LineaCompraEditorSheet({required this.linea, required this.empresaId});

  @override
  State<_LineaCompraEditorSheet> createState() =>
      _LineaCompraEditorSheetState();
}

class _LineaCompraEditorSheetState extends State<_LineaCompraEditorSheet> {
  late final TextEditingController _cantidad;
  late final TextEditingController _precio;
  late final TextEditingController _descuento;
  late final TextEditingController _factor;
  late final TextEditingController _nuevoPrecioVenta;

  late bool _usaUnidadCompra;

  @override
  void initState() {
    super.initState();
    final l = widget.linea;
    // Los campos van en la unidad en la que se COMPRA (15 kg a S/8.00), no en
    // la que se guarda (15000 g a S/0.008).
    _cantidad = TextEditingController(text: _num(l.cantidadCarga));
    _precio = TextEditingController(
        text: l.precioUnitario != null ? _num(l.precioCarga) : '');
    _descuento = TextEditingController(text: _num(l.descuento));
    _factor = TextEditingController(
        text: l.factorCompra != null ? _num(l.factorCompra!) : '');
    // El campo se escribe en unidad de PRESENTACIÓN (S/9 el kilo) y la línea lo
    // guarda por unidad de venta: se multiplica al entrar y se divide al salir.
    _nuevoPrecioVenta = TextEditingController(
      text: l.nuevoPrecioVenta != null
          ? (l.nuevoPrecioVenta! * l.factorPresentacionEfectivo)
              .toStringAsFixed(2)
          : '',
    );
    _usaUnidadCompra = l.usaUnidadCompra;
  }

  @override
  void dispose() {
    _cantidad.dispose();
    _precio.dispose();
    _descuento.dispose();
    _factor.dispose();
    _nuevoPrecioVenta.dispose();
    super.dispose();
  }

  static String _num(double v) {
    if ((v - v.truncateToDouble()).abs() < 1e-9) return v.toStringAsFixed(0);
    return v
        .toStringAsFixed(4)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  double _leer(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.').trim()) ?? 0;

  /// La línea como quedaría con lo que hay escrito AHORA. De acá salen el costo
  /// proyectado, las sugerencias y el aviso de vender bajo costo, así que se
  /// recalcula en cada tecla.
  LineaCompraDraft get _provisional {
    final factorEscrito = _leer(_factor);
    return widget.linea.conCarga(
      cantidad: _leer(_cantidad),
      precio: _leer(_precio),
      usaUnidadCompra: _usaUnidadCompra,
      factor: factorEscrito > 0 ? factorEscrito : null,
    ).copyWith(
      descuento: _leer(_descuento),
      nuevoPrecioVenta: _nuevoPrecioVentaPorUnidadDeVenta,
      limpiarNuevoPrecioVenta: _nuevoPrecioVentaPorUnidadDeVenta == null,
    );
  }

  double? get _nuevoPrecioVentaPorUnidadDeVenta {
    final escrito = _leer(_nuevoPrecioVenta);
    if (escrito <= 0) return null;
    return escrito / widget.linea.factorPresentacionEfectivo;
  }

  /// Cambia la unidad en la que se escribe (el saco ↔ el kilo) SIN cambiar lo
  /// que entra al stock: se pasa por la cantidad atómica y se vuelve a expresar
  /// con el factor nuevo. 3 sacos de 50 quedan como 150 und, no como 3.
  void _cambiarUnidad(bool aUnidadDeCompra) {
    if (aUnidadDeCompra == _usaUnidadCompra) return;
    final actual = _provisional;
    final factorEscrito = _leer(_factor);
    final nuevoFactor = aUnidadDeCompra
        ? (factorEscrito > 0 ? factorEscrito : widget.linea.factorEfectivo)
        : widget.linea.factorPresentacionEfectivo;
    setState(() {
      _usaUnidadCompra = aUnidadDeCompra;
      if (nuevoFactor > 0) {
        _cantidad.text = _num(actual.cantidadAtomica / nuevoFactor);
        if (actual.precioAtomico > 0) {
          _precio.text = _num(actual.precioAtomico * nuevoFactor);
        }
      }
    });
  }

  /// Una sugerencia viene por unidad de venta; el campo se escribe en
  /// presentación.
  void _aplicarSugerencia(double porUnidadDeVenta) {
    setState(() {
      _nuevoPrecioVenta.text =
          (porUnidadDeVenta * widget.linea.factorPresentacionEfectivo)
              .toStringAsFixed(2);
    });
  }

  void _guardar() {
    final linea = _provisional;
    if (linea.cantidad <= 0) {
      _avisar('La cantidad debe ser mayor a 0');
      return;
    }
    if (linea.sinCosto) {
      _avisar('Falta el precio de compra');
      return;
    }
    // 🔴 Bloqueante, igual que en el formulario de a una línea: con el costo
    // por encima de la venta, guardar la línea es dejar el producto vendiéndose
    // a pérdida sin que nadie se entere hasta el cierre.
    if (linea.costoSuperaVenta) {
      _avisar('El costo supera el precio de venta: actualizá el precio abajo');
      return;
    }
    Navigator.of(context).pop(linea);
  }

  void _avisar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = _provisional;
    final base = widget.linea;
    // En qué unidad se escribe: el saco, o aquella en la que se le habla al
    // usuario (kilos para un granel que se guarda en gramos).
    final simboloCarga = _usaUnidadCompra
        ? base.unidadCompraSimbolo
        : base.presentacion.simboloVisible;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
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
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      base.descripcion.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.blue1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: CustomText(
                          controller: _cantidad,
                          borderColor: AppColors.blue1,
                          label: simboloCarga != null
                              ? 'Cantidad en $simboloCarga'
                              : 'Cantidad',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomText(
                          controller: _precio,
                          borderColor: AppColors.blue1,
                          label: simboloCarga != null
                              ? 'P. Unit x $simboloCarga'
                              : 'Precio Unit.',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomText(
                          controller: _descuento,
                          borderColor: AppColors.blue1,
                          label: 'Descuento',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  // Solo cuando lo que se escribe NO es lo que se guarda: con
                  // unidades iguales sería un renglón repitiendo el campo.
                  if (l.factorCarga > 1) _buildEquivalencia(l),
                  if (base.soportaUnidadCompra) _buildUnidadCompra(l),
                  _buildAjustePrecioVenta(l),
                  HistorialComprasProductoPanel(
                    empresaId: widget.empresaId,
                    productoId: base.productoId,
                    varianteId: base.varianteId,
                    precioCompra: l.precioAtomico,
                    precioVenta: base.precioVentaActualSede,
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          foregroundColor: Colors.grey.shade700,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.blue1,
                          minimumSize: const Size(0, 44),
                        ),
                        onPressed: _guardar,
                        child: Text(
                          'Guardar · S/ ${l.subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "Comprar por": el saco o la unidad suelta, con el empaque editable para
  /// esta compra (el lote pudo venir con otra cantidad que la configurada).
  Widget _buildUnidadCompra(LineaCompraDraft l) {
    final base = widget.linea;
    final simboloCompra = base.unidadCompraSimbolo ?? '?';
    final simboloVenta = base.unidadVentaSimbolo ?? 'UNID';
    // La alternativa al saco es la unidad en la que se le habla al usuario
    // (kg), no la de stock (g): comprar granel "por gramo" no existe.
    final pres = base.presentacion;
    final simboloSuelto = pres.simboloVisible ?? simboloVenta;
    final factorSuelto = base.factorPresentacionEfectivo;
    final configurado = base.factorCompra ?? 1;
    final factorUsado = l.factorEfectivo;
    final difiere = (factorUsado - configurado).abs() > 1e-9;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.blue1.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.blue1.withValues(alpha: 0.2),
          width: 0.6,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comprar por:',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _ChipUnidad(
                  label: simboloCompra,
                  detalle: '×${_num(factorUsado)} $simboloVenta',
                  seleccionado: _usaUnidadCompra,
                  onTap: () => _cambiarUnidad(true),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _ChipUnidad(
                  label: simboloSuelto,
                  detalle: factorSuelto > 1
                      ? '×${_num(factorSuelto)} $simboloVenta'
                      : '×1',
                  seleccionado: !_usaUnidadCompra,
                  onTap: () => _cambiarUnidad(false),
                ),
              ),
            ],
          ),
          if (_usaUnidadCompra) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: CustomText(
                    controller: _factor,
                    borderColor: AppColors.blue1,
                    label: '$simboloVenta por $simboloCompra',
                    hintText: _num(configurado),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            if (difiere)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Empaque distinto al configurado (${_num(configurado)}). '
                  'Aplica solo a esta compra.',
                  style: TextStyle(
                      fontSize: 9, color: Colors.orange.shade800, height: 1.3),
                ),
              ),
          ],
        ],
      ),
    );
  }

  /// Qué entra realmente al stock, en la unidad en la que se guarda. Sin esto,
  /// cargar 3 sacos y ver "150" recién en la tabla se lee como un error de
  /// tipeo, y con un granel el salto de 15 a 15000 asusta todavía más.
  Widget _buildEquivalencia(LineaCompraDraft l) {
    final simboloVenta = widget.linea.unidadVentaSimbolo ?? 'UNID';
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        'Entran ${l.cantidadAtomica} $simboloVenta '
        '@ S/ ${_fmtPrecioUnitario(l.precioAtomico)}/$simboloVenta',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.green.shade800,
        ),
      ),
    );
  }

  /// Por debajo del centavo, dos decimales redondean a "0.01" y el usuario cree
  /// que le cobraron de más: S/0.006727 el gramo son S/6.73 el kilo, no S/10.
  static String _fmtPrecioUnitario(double v) {
    if (v >= 0.01 || v <= 0) return v.toStringAsFixed(2);
    return v
        .toStringAsFixed(6)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  Widget _buildAjustePrecioVenta(LineaCompraDraft l) {
    final base = widget.linea;
    final pres = base.factorPresentacionEfectivo;
    final simbolo = base.unidadPresentacionSimbolo;
    final tienePres = pres > 1 && simbolo != null;
    final sufijo = tienePres ? '/$simbolo' : '';

    String enPresentacion(double? porUnidadDeVenta) => porUnidadDeVenta == null
        ? '—'
        : (porUnidadDeVenta * pres).toStringAsFixed(2);

    final costoNuevo = l.costoProyectado;
    final margen = l.margenActualPct;
    final mantener = l.precioVentaMantenerMargen;
    final mas10 = l.precioVentaMas10;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.amber.shade200, width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.price_change_outlined,
                  size: 14, color: Colors.amber.shade900),
              const SizedBox(width: 6),
              Text(
                'Ajustar precio venta al confirmar (opcional)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.amber.shade900,
                ),
              ),
            ],
          ),
          if (l.costoSuperaVenta) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 16, color: Colors.red.shade700),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'El costo nuevo supera el precio de venta. Actualizalo '
                      'para no vender con pérdida.',
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.3,
                        color: Colors.red.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Costo: S/${enPresentacion(base.costoActualSede)}$sufijo',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade800),
                ),
              ),
              if (costoNuevo != null && costoNuevo != base.costoActualSede)
                Text(
                  '→ S/${enPresentacion(costoNuevo)}$sufijo (nuevo)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.deepOrange.shade700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Venta: S/${enPresentacion(base.precioVentaActualSede)}$sufijo',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade800),
                ),
              ),
              if (margen != null)
                Text(
                  'margen ${margen.toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: CustomText(
                  controller: _nuevoPrecioVenta,
                  borderColor: AppColors.blue1,
                  label: 'Nuevo precio venta$sufijo',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          if (mantener != null || mas10 != null) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (mantener != null)
                  _ChipSugerencia(
                    label: 'Mantener margen',
                    valor: 'S/${enPresentacion(mantener)}',
                    onTap: () => _aplicarSugerencia(mantener),
                  ),
                if (mas10 != null)
                  _ChipSugerencia(
                    label: '+10%',
                    valor: 'S/${enPresentacion(mas10)}',
                    onTap: () => _aplicarSugerencia(mas10),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ChipUnidad extends StatelessWidget {
  final String label;
  final String detalle;
  final bool seleccionado;
  final VoidCallback onTap;

  const _ChipUnidad({
    required this.label,
    required this.detalle,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: seleccionado ? AppColors.blue1 : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: seleccionado ? AppColors.blue1 : Colors.grey.shade300,
            width: 0.8,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: seleccionado ? Colors.white : Colors.grey.shade800,
              ),
            ),
            Text(
              detalle,
              style: TextStyle(
                fontSize: 9,
                color: seleccionado ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipSugerencia extends StatelessWidget {
  final String label;
  final String valor;
  final VoidCallback onTap;

  const _ChipSugerencia({
    required this.label,
    required this.valor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.blue1.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.blue1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
