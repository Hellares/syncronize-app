import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_loading.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../mis_pedidos/presentation/widgets/pagar_yape_sheet.dart';

/// Cotización formal (respuesta de la empresa) vista por el CLIENTE del
/// marketplace: items con precios, totales, vigencia y — si la empresa pidió
/// un adelanto — el botón "Separar con Yape" (pago automático api-yape; el
/// webhook aprueba la cotización y reserva el stock solo).
class CotizacionClientePage extends StatefulWidget {
  final String solicitudId;

  const CotizacionClientePage({super.key, required this.solicitudId});

  @override
  State<CotizacionClientePage> createState() => _CotizacionClientePageState();
}

class _CotizacionClientePageState extends State<CotizacionClientePage> {
  static const Color _morado = Color(0xFF742284);

  Map<String, dynamic>? _cotizacion;
  bool _isLoading = true;
  bool _accionando = false;
  String? _error;

  String get _basePath =>
      '/marketplace/solicitudes-cotizacion/${widget.solicitudId}/cotizacion';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final resp = await locator<DioClient>().get(_basePath);
      if (mounted) {
        setState(() { _cotizacion = resp.data as Map<String, dynamic>; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'No se pudo cargar la cotización'; _isLoading = false; });
    }
  }

  /// Parseo defensivo: los Decimal de Prisma llegan como String en el JSON.
  double _n(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  Future<void> _accion(String path, String okMsg) async {
    setState(() => _accionando = true);
    try {
      await locator<DioClient>().post('$_basePath/$path');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(okMsg), backgroundColor: AppColors.green),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo completar la acción'), backgroundColor: AppColors.red),
      );
    } finally {
      if (mounted) setState(() => _accionando = false);
    }
  }

  /// Paga [monto] de la cotización con Yape/Plin (total o parcial). El
  /// webhook ACUMULA los pagos; "pagado" = el acumulado creció respecto a
  /// lo que había antes de abrir la hoja.
  Future<void> _pagarConYape(double monto) async {
    final antes = _n(_cotizacion?['adelantoMonto']);
    final pagado = await PagarYapeSheet.show(
      context,
      cobroPath: '$_basePath/cobro-yape',
      cobroBody: {'monto': monto},
      pollPath: _basePath,
      esPagado: (d) => _n(d['adelantoMonto']) > antes + 0.005,
    );
    if (!mounted) return;
    if (pagado == true) {
      final total = _n(_cotizacion?['total']);
      final completo = antes + monto >= total - 0.005;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(completo
              ? '¡Pago completo confirmado! Tus productos quedaron reservados.'
              : '¡Abono confirmado! Tus productos quedaron apartados.'),
          backgroundColor: Colors.green,
        ),
      );
      _load();
    }
  }

  /// Dialog para elegir un monto parcial (mín S/ 1, máx el saldo).
  Future<void> _pagarOtroMonto(double saldo) async {
    final controller = TextEditingController();
    final monto = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pagar otro monto',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Saldo pendiente: S/ ${saldo.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Monto S/',
                hintText: '0.00',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _morado, foregroundColor: Colors.white),
            onPressed: () {
              final v =
                  double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;
              if (v < 1) return;
              if (v > saldo + 0.005) return;
              Navigator.pop(ctx, v);
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    if (monto == null || !mounted) return;
    await _pagarConYape(monto);
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      style: GradientStyle.minimal,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const SmartAppBar(title: 'Cotización'),
        body: _isLoading
            ? CustomLoading.small(message: 'Cargando...')
            : _error != null
                ? Center(child: Text(_error!))
                : RefreshIndicator(onRefresh: _load, child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    final c = _cotizacion!;
    final codigo = c['codigo'] as String? ?? '';
    final estado = c['estado'] as String? ?? '';
    final detalles = c['detalles'] as List<dynamic>? ?? [];
    final total = _n(c['total']);
    final adelantoRequerido = _n(c['adelantoRequerido']);
    final adelantoPagado = _n(c['adelantoMonto']);
    final separada = adelantoPagado > 0;
    final vigente = estado == 'PENDIENTE' || estado == 'APROBADA';
    final fechaVenc = c['fechaVencimiento'] as String?;
    final condiciones = c['condiciones'] as String?;
    final sede = c['sede'] as Map<String, dynamic>?;
    // Venta resultante (cotización CONVERTIDA): el cliente ve el resumen
    // REAL de su compra — el total puede diferir del cotizado si la tienda
    // excluyó items (ej. sin stock) al convertir.
    final venta = c['venta'] as Map<String, dynamic>?;
    final convertida = estado == 'CONVERTIDA';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Cabecera: código + estado
        Row(
          children: [
            Expanded(child: AppTitle(codigo, fontSize: 16)),
            _estadoChip(estado, separada),
          ],
        ),
        if (sede != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('Atiende: ${sede['nombre'] ?? ''}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ),
        if (fechaVenc != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text('Válida hasta: ${fechaVenc.substring(0, 10)}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ),
        const SizedBox(height: 16),

        // Items cotizados — tabla tipo Excel (header + zebra + thumbnail),
        // mismo lenguaje visual que las tablas de la empresa.
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.greyLight),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                color: AppColors.bluechip,
                padding:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: Row(
                  children: [
                    SizedBox(
                        width: 22,
                        child: Center(child: _thCliente('#'))),
                    Expanded(flex: 6, child: _thCliente('PRODUCTO')),
                    Expanded(
                        flex: 2,
                        child: Center(child: _thCliente('CANT.'))),
                    Expanded(
                        flex: 3,
                        child: Align(
                            alignment: Alignment.centerRight,
                            child: _thCliente('P. UNIT.'))),
                    Expanded(
                        flex: 3,
                        child: Align(
                            alignment: Alignment.centerRight,
                            child: _thCliente('TOTAL'))),
                  ],
                ),
              ),
              for (int i = 0; i < detalles.length; i++)
                _itemTablaRow(
                  i,
                  detalles[i] as Map<String, dynamic>,
                  // Convertida + reserva LIBERADA = la tienda excluyó este
                  // item de la compra final (ej. sin stock).
                  noIncluido: convertida &&
                      (detalles[i] as Map<String, dynamic>)['reservaEstado'] ==
                          'LIBERADA',
                ),
              Divider(height: 1, color: Colors.grey.shade200),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Builder(builder: (context) {
                  // Ahorro COMPLETO: precio regular por línea (antes del
                  // nivel por mayor/VIP, campo precioRegular) + descuentos
                  // manuales. regular_linea = cantidad × precioRegular;
                  // el total ya viene neto de ambos efectos.
                  double regular = 0;
                  for (final d in detalles) {
                    final dd = d as Map<String, dynamic>;
                    final cant = _n(dd['cantidad']);
                    final precio = _n(dd['precioUnitario']);
                    final precioReg = dd['precioRegular'] != null
                        ? _n(dd['precioRegular'])
                        : precio;
                    regular +=
                        cant * (precioReg > precio ? precioReg : precio);
                  }
                  final ahorro = regular - total;
                  return Column(
                    children: [
                      if (ahorro > 0.005) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Precio regular',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500)),
                            Text(
                              'S/ ${regular.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Ahorras',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade700)),
                            Text(
                              '−S/ ${ahorro.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const AppSubtitle('Total', fontSize: 14),
                          AppSubtitle('S/ ${total.toStringAsFixed(2)}',
                              fontSize: 16, color: AppColors.blue1),
                        ],
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Pagos: estado de lo pagado + CTA de pago (total o parcial).
        // Con el primer pago confirmado la tienda reserva el stock.
        // Cotización CONVERTIDA → resumen de la COMPRA real (la venta),
        // que manda sobre el total cotizado.
        if (convertida) ...[
          _bannerCompraCompletada(
            venta: venta,
            detalles: detalles,
            adelantoPagado: adelantoPagado,
          ),
          const SizedBox(height: 12),
        ] else if (separada) ...[
          _bannerSeparada(adelantoPagado, total),
          const SizedBox(height: 12),
        ],
        if (vigente && (total - adelantoPagado) > 0.005)
          _cardPagos(
            adelantoRequerido: adelantoRequerido,
            adelantoPagado: adelantoPagado,
            total: total,
          ),

        if (condiciones != null && condiciones.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.greyLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSubtitle('Condiciones', fontSize: 12),
                const SizedBox(height: 6),
                Text(condiciones,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4)),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),

        // Acciones (solo mientras esté PENDIENTE y sin adelanto)
        if (estado == 'PENDIENTE' && !separada) ...[
          CustomButton(
            text: 'Aceptar cotización',
            onPressed: _accionando ? null : () => _accion('aceptar', 'Cotización aceptada'),
            backgroundColor: AppColors.green,
            borderColor: AppColors.green,
            isLoading: _accionando,
            icon: const Icon(Icons.check_circle_outline, color: AppColors.white, size: 18),
          ),
          const SizedBox(height: 10),
          CustomButton(
            text: 'Rechazar',
            onPressed: _accionando ? null : () => _accion('rechazar', 'Cotización rechazada'),
            // isOutlined: true,
            borderColor: AppColors.red,
            textColor: AppColors.red,
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _thCliente(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade800,
        letterSpacing: 0.3,
      ),
    );
  }

  /// Fila de la tabla de items: thumbnail + nombre (con ahorro y APARTADO
  /// como sub-líneas), cantidad, precio (regular tachado si hay precio
  /// especial) y total. [noIncluido] = la tienda excluyó el item al
  /// convertir a venta (se muestra atenuado con badge).
  Widget _itemTablaRow(int index, Map<String, dynamic> d,
      {bool noIncluido = false}) {
    final cantidad = _n(d['cantidad']);
    final precio = _n(d['precioUnitario']);
    final totalItem = _n(d['total']);
    final descuentoItem = _n(d['descuento']);
    // Precio antes del nivel por mayor / VIP (si la tienda lo aplicó).
    final precioRegular =
        d['precioRegular'] != null ? _n(d['precioRegular']) : precio;
    final tieneEspecial = precioRegular > precio + 0.005;
    // Precio normal de sede antes de la OFERTA pública (informativo).
    final antesOferta =
        d['precioAntesOferta'] != null ? _n(d['precioAntesOferta']) : precio;
    final enOferta = antesOferta > precio + 0.005;
    final reservado = d['reservaEstado'] == 'ACTIVA';
    final imagenUrl = d['imagenUrl'] as String?;

    return Container(
      color: index.isEven ? Colors.white : Colors.grey.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Opacity(
      opacity: noIncluido ? 0.45 : 1,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 22,
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 9,
                  height: 1.1,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: imagenUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imagenUrl,
                          width: 18,
                          height: 18,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                              width: 18,
                              height: 18,
                              color: Colors.grey.shade100),
                          errorWidget: (_, __, ___) => Container(
                            width: 18,
                            height: 18,
                            color: Colors.grey.shade100,
                            child: Icon(Icons.image,
                                size: 10, color: Colors.grey.shade400),
                          ),
                        )
                      : Container(
                          width: 18,
                          height: 18,
                          color: Colors.grey.shade100,
                          child: Icon(Icons.inventory_2_outlined,
                              size: 11, color: Colors.grey.shade400),
                        ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d['descripcion'] as String? ?? '',
                        style: const TextStyle(
                          fontSize: 10,
                          height: 1.1,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (enOferta)
                        Text(
                          'En oferta — antes S/ ${antesOferta.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 8,
                            height: 1.2,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      if (descuentoItem > 0.005 || reservado || noIncluido)
                        Row(
                          children: [
                            if (noIncluido)
                              Container(
                                margin: const EdgeInsets.only(right: 5),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  'NO INCLUIDO',
                                  style: TextStyle(
                                      fontSize: 7,
                                      height: 1.1,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey.shade700),
                                ),
                              ),
                            if (descuentoItem > 0.005)
                              Text(
                                'Desc. −S/ ${descuentoItem.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 8,
                                  height: 1.2,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            if (descuentoItem > 0.005 && reservado)
                              const SizedBox(width: 5),
                            if (reservado)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Text(
                                  'APARTADO',
                                  style: TextStyle(
                                      fontSize: 7,
                                      height: 1.1,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.green),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                cantidad.toStringAsFixed(cantidad % 1 == 0 ? 0 : 2),
                style: const TextStyle(fontSize: 10, height: 1.1),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (tieneEspecial)
                  Text(
                    precioRegular.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 9,
                      height: 1.1,
                      color: Colors.grey.shade400,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: Colors.grey.shade400,
                    ),
                  ),
                Text(
                  precio.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.1,
                    fontWeight:
                        tieneEspecial ? FontWeight.w600 : FontWeight.w400,
                    color: tieneEspecial ? Colors.green.shade700 : null,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                totalItem.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 10,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blue1,
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  /// Card de pagos: pagar el saldo completo, el adelanto sugerido por la
  /// tienda, u otro monto (abonos parciales acumulables). El primer pago
  /// confirmado reserva el stock.
  Widget _cardPagos({
    required double adelantoRequerido,
    required double adelantoPagado,
    required double total,
  }) {
    final saldo = ((total - adelantoPagado) * 100).round() / 100;
    final esPrimerPago = adelantoPagado <= 0.005;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _morado.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _morado.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_clock_rounded, color: _morado, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  esPrimerPago
                      ? 'Paga y reserva tus productos'
                      : 'Completa tu pago',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            esPrimerPago
                ? 'Paga con Yape o Plin el total o un abono. Con tu primer pago la tienda aparta el stock de tus productos.'
                : 'Ya pagaste S/ ${adelantoPagado.toStringAsFixed(2)} de S/ ${total.toStringAsFixed(2)}. Puedes abonar más o completar el saldo.',
            style: TextStyle(
                fontSize: 11.5, color: Colors.grey.shade700, height: 1.35),
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: esPrimerPago
                ? 'Pagar TODO — S/ ${saldo.toStringAsFixed(2)}'
                : 'Pagar saldo — S/ ${saldo.toStringAsFixed(2)}',
            onPressed: _accionando ? null : () => _pagarConYape(saldo),
            backgroundColor: _morado,
            borderColor: _morado,
            icon: const Icon(Icons.qr_code_2_rounded,
                color: AppColors.white, size: 18),
          ),
          // Adelanto sugerido por la tienda: solo antes del primer pago y
          // si es menor al saldo.
          if (esPrimerPago &&
              adelantoRequerido > 0 &&
              adelantoRequerido < saldo - 0.005) ...[
            const SizedBox(height: 8),
            CustomButton(
              text:
                  'Separar con adelanto — S/ ${adelantoRequerido.toStringAsFixed(2)}',
              onPressed: _accionando
                  ? null
                  : () => _pagarConYape(adelantoRequerido),
              isOutlined: true,
              borderColor: _morado,
              textColor: _morado,
              height: 42,
              icon: const Icon(Icons.lock_outline_rounded,
                  color: _morado, size: 17),
            ),
          ],
          const SizedBox(height: 4),
          TextButton(
            onPressed: _accionando ? null : () => _pagarOtroMonto(saldo),
            child: const Text(
              'Pagar otro monto',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: _morado),
            ),
          ),
        ],
      ),
    );
  }

  /// Banner de cotización CONVERTIDA: muestra la COMPRA real (venta) —
  /// código, total efectivo y cuántos items quedaron fuera (excluidos al
  /// convertir, ej. sin stock).
  Widget _bannerCompraCompletada({
    required Map<String, dynamic>? venta,
    required List<dynamic> detalles,
    required double adelantoPagado,
  }) {
    final ventaTotal = _n(venta?['total']);
    final ventaCodigo = venta?['codigo'] as String? ?? '';
    final excluidos = detalles
        .where((d) =>
            (d as Map<String, dynamic>)['reservaEstado'] == 'LIBERADA')
        .length;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blue2.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.blue2.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shopping_bag_rounded,
              color: AppColors.blue2, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('¡Compra completada!',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  venta != null
                      ? 'Venta $ventaCodigo · Total S/ ${ventaTotal.toStringAsFixed(2)}'
                          '${adelantoPagado > 0 ? ' (pagaste S/ ${adelantoPagado.toStringAsFixed(2)} por adelantado)' : ''}'
                      : 'Tu cotización se concretó en una compra.',
                  style:
                      TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                ),
                if (excluidos > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    excluidos == 1
                        ? '1 item no se incluyó en la compra final (marcado abajo).'
                        : '$excluidos items no se incluyeron en la compra final (marcados abajo).',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bannerSeparada(double adelanto, double total) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: AppColors.green, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    (total - adelanto) <= 0.005
                        ? 'Pagada por completo'
                        : 'Productos separados',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  (total - adelanto) <= 0.005
                      ? 'Pagaste el total (S/ ${adelanto.toStringAsFixed(2)}). Tus productos están reservados — coordina la entrega con la tienda.'
                      : 'Pagado: S/ ${adelanto.toStringAsFixed(2)} · Saldo: S/ ${(total - adelanto).toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _estadoChip(String estado, bool separada) {
    final (label, color) = switch (estado) {
      'PENDIENTE' => ('Por aceptar', Colors.orange.shade700),
      'APROBADA' => (separada ? 'Separada' : 'Aceptada', AppColors.green),
      'RECHAZADA' => ('Rechazada', AppColors.red),
      'VENCIDA' => ('Vencida', Colors.grey.shade500),
      'CONVERTIDA' => ('Completada', AppColors.blue2),
      _ => (estado, Colors.grey.shade500),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
