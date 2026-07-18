import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/cobrar_cotizacion_data.dart';
import '../../domain/usecases/cargar_datos_cobro_usecase.dart';
import '../../domain/usecases/cobrar_cotizacion_usecase.dart';
import '../../../venta/domain/entities/venta.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/comprobante_condicion_card.dart';
import '../../../../core/utils/caja_guard.dart';
import '../../../../core/widgets/currency/currency_formatter.dart';
import '../../../../core/widgets/numpad/numpad_controller.dart';
import '../../../../core/widgets/numpad/pos_numpad.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/snack_bar_helper.dart';
import '../../../../core/widgets/autorizacion_dialog.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/styled_dialog.dart';
import '../../../auth/presentation/bloc/auth/auth_bloc.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../cotizacion/domain/entities/cotizacion.dart';
import '../../../cotizacion/domain/entities/cotizacion_detalle_input.dart';
import '../../../cotizacion/presentation/widgets/cotizacion_item_selector.dart';
import '../../../servicio/presentation/widgets/firma_digital_sheet.dart';
import '../../../venta_rapida/domain/repositories/venta_rapida_repository.dart';
import '../../../venta_rapida/domain/usecases/buscar_cliente_por_dni_usecase.dart';
import '../../../venta_rapida/domain/usecases/buscar_cliente_por_ruc_usecase.dart';

class CobrarCotizacionPage extends StatefulWidget {
  final String cotizacionId;

  const CobrarCotizacionPage({super.key, required this.cotizacionId});

  @override
  State<CobrarCotizacionPage> createState() => _CobrarCotizacionPageState();
}

class _CobrarCotizacionPageState extends State<CobrarCotizacionPage> {
  Cotizacion? _cotizacion;
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _itemsSinStock = [];
  List<String> _excluirDetalleIds = [];
  Map<String, double> _ajustarCantidades = {};
  final List<CotizacionDetalleInput> _itemsAgregados = [];

  /// Descuentos aplicados al cobrar: por línea (detalleId → monto de la
  /// línea) y global (se resta del total final). Van al backend en el DTO.
  final Map<String, double> _ajustarDescuentos = {};
  double _descuentoGlobal = 0;
  double? _descuentoGlobalPct; // informativo, si se ingresó como %

  /// Cliente override: el cajero puede cambiar el cliente al cobrar
  /// (ej. cotización a CLIENTES VARIOS que al pagar pide FACTURA con RUC).
  /// Si quedan en null, la venta hereda el cliente de la cotización.
  String? _clienteIdOverride; // EmpresaPersona (resuelto por DNI)
  String? _clienteEmpresaIdOverride; // ClienteEmpresa (resuelto por RUC)
  String? _nombreClienteOverride;
  String? _documentoClienteOverride;
  String? _direccionClienteOverride;
  bool get _clienteCambiado => _nombreClienteOverride != null;

  /// Autorizador de VENTA BAJO COSTO (guard del backend cuando un descuento
  /// deja margen negativo sin liquidación). Se llena tras el rechazo
  /// `VENTA_BAJO_COSTO_NO_AUTORIZADA` y el reintento lo adjunta.
  String? _ventaBajoCostoAutorizadaPorId;

  /// Quién autorizó los descuentos de este cobro. Un ADMIN de empresa se
  /// auto-autoriza (sin credenciales); cualquier otro rol dispara el dialog
  /// de autorización (DNI + contraseña de un admin). Se pide UNA sola vez
  /// por cobro y viaja al backend como `descuentoAutorizadoPorId`.
  String? _descuentoAutorizadoPorId;
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _error;

  // Pagos múltiples
  final List<Map<String, dynamic>> _pagos = [];
  String _metodoActual = 'EFECTIVO';
  // ignore: unused_field
  String _monedaActual = 'PEN'; // mantenido por compatibilidad con dataset
  // ignore: unused_field
  double? _tipoCambioVenta;
  final _montoAgregarController = TextEditingController();
  final _referenciaAgregarController = TextEditingController();
  final _referenciaController = TextEditingController();
  final _observacionesController = TextEditingController();

  // Numpad para captura rápida del monto recibido. El controller refleja
  // su valor en `_montoAgregarController` para no cambiar el resto de la
  // lógica que ya lo lee.
  late final NumpadController _numpadController;

  // Comprobante
  String _tipoComprobante = 'BOLETA';
  // Cobro de cotización-a-venta siempre es CONTADO (el crédito vive en
  // otro flujo). Lo dejamos como `final` y ocultamos el selector.
  final String _condicionPago = 'CONTADO';
  final _plazoCreditoController = TextEditingController();
  final int _numeroCuotas = 1;

  // Firma
  Uint8List? _firmaBytes;

  /// Métodos digitales que normalmente requieren un N° de operación.
  /// Para no demorar al cajero, precargamos '000' como placeholder
  /// editable. Si el cajero quiere el real, lo escribe; si no, queda '000'.
  static const _metodosDigitales = {
    'YAPE',
    'PLIN',
    'TARJETA',
    'TRANSFERENCIA',
  };

  /// Si el método actual exige referencia y el campo está vacío,
  /// precarga '000'. Idempotente: respeta lo que ya tipeó el cajero.
  void _precargarReferenciaSiAplica() {
    if (_metodosDigitales.contains(_metodoActual) &&
        _referenciaAgregarController.text.trim().isEmpty) {
      _referenciaAgregarController.text = '000';
    }
  }

  @override
  void initState() {
    super.initState();
    _verificarCaja();
    _loadCotizacion();
    _numpadController = NumpadController(
      textController: _montoAgregarController,
    );
    _montoAgregarController.addListener(_onMontoChanged);
    _precargarReferenciaSiAplica();
  }

  /// Listener del monto del numpad. Hace dos cosas:
  /// 1. Rebuild para refrescar display recibido/vuelto y habilitar COBRAR.
  /// 2. Si el monto tipeado lleva el recibido a coincidir EXACTAMENTE con
  ///    el total (no excede), auto-agrega el pago a la lista. Así el
  ///    cajero ve el último método antes de procesar, sin tener que tocar
  ///    "Agregar pago" o "Exacto". Si excede el total (cajero quiere dar
  ///    vuelto en efectivo), NO auto-agrega — eso queda al COBRAR.
  void _onMontoChanged() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final monto = _numpadController.value;
      if (monto <= 0) return;
      final recibidoTotal = _totalPagado + monto;
      // Cubre exacto el saldo a cobrar hoy (total - adelanto, ±0.005):
      // auto-agregar para que el cajero vea el método antes de procesar.
      if ((recibidoTotal - _totalACobrar).abs() <= 0.005) {
        _agregarPago();
        _numpadController.clear();
        _referenciaAgregarController.clear();
        _precargarReferenciaSiAplica();
      }
    });
  }

  @override
  void dispose() {
    _numpadController.dispose();
    _montoAgregarController.dispose();
    _referenciaAgregarController.dispose();
    _referenciaController.dispose();
    _observacionesController.dispose();
    _plazoCreditoController.dispose();
    super.dispose();
  }

  Future<void> _verificarCaja() async {
    final tieneCaja = await verificarCajaAbierta(context);
    if (!tieneCaja && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _loadCotizacion() async {
    final result = await locator<CargarDatosCobroUseCase>()(
      cotizacionId: widget.cotizacionId,
    );

    if (!mounted) return;

    if (result is Success<CobrarCotizacionData>) {
      final data = result.data;
      setState(() {
        _cotizacion = data.cotizacion;
        _items = data.items;
        _itemsSinStock = data.itemsSinStock;
        _tipoCambioVenta = data.tipoCambioVenta;
        _isLoading = false;
      });

      if (data.itemsSinStock.isNotEmpty && mounted) {
        _mostrarDialogoSinStock(data.itemsSinStock);
      }
    } else if (result is Error<CobrarCotizacionData>) {
      setState(() {
        _error = result.message;
        _isLoading = false;
      });
    }
  }

  void _mostrarDialogoSinStock(List<Map<String, dynamic>> sinStock) {
    // Separar: sin stock (disponible=0) vs stock parcial (disponible>0)
    final sinNada = sinStock.where((i) => _toDouble(i['stockDisponible']) <= 0).toList();
    final parcial = sinStock.where((i) => _toDouble(i['stockDisponible']) > 0).toList();
    final hayParcial = parcial.isNotEmpty;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StyledDialog(
        accentColor: Colors.orange.shade700,
        icon: Icons.warning_amber_rounded,
        titulo: 'Stock insuficiente',
        content: [
          // Items sin stock
          if (sinNada.isNotEmpty) ...[
            Text('Sin stock:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red[700])),
            const SizedBox(height: 6),
            ...sinNada.map((item) => _buildStockItemRow(item, Colors.red)),
          ],
          // Items con stock parcial
          if (parcial.isNotEmpty) ...[
            if (sinNada.isNotEmpty) const SizedBox(height: 10),
            Text('Stock parcial:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange[700])),
            const SizedBox(height: 6),
            ...parcial.map((item) => _buildStockItemRow(item, Colors.orange)),
          ],
          const SizedBox(height: 10),
          Text(
            'Elige como proceder:',
            style: TextStyle(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 12),
          // Botones apilados full-width (van en el content: la fila de
          // actions del StyledDialog no acomoda labels largos).
          // Volver
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(ctx, 'volver'),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Volver para cambiar productos'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[600],
                side: BorderSide(color: Colors.grey[300]!),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Continuar con stock disponible (solo si hay parcial)
          if (hayParcial) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(ctx, 'ajustar'),
                icon: const Icon(Icons.tune, size: 16),
                label: const Text('Ajustar a stock disponible'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue1,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
          // Continuar sin estos items
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(ctx, 'quitar'),
              icon: const Icon(Icons.remove_shopping_cart, size: 16),
              label: const Text('Quitar todos estos items'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    ).then((result) {
      if (result == 'volver') {
        if (mounted) context.pop();
      } else if (result == 'ajustar') {
        _ajustarStockDisponible();
      } else if (result == 'quitar') {
        _removerItemsSinStock();
      }
    });
  }

  Widget _buildStockItemRow(Map<String, dynamic> item, MaterialColor color) {
    final disponible = _toDouble(item['stockDisponible']).toInt();
    final requerido = _toDouble(item['cantidad']).toInt();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            disponible > 0 ? Icons.warning_amber : Icons.cancel,
            size: 16,
            color: color[400],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['descripcion']?.toString() ?? '',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  disponible > 0
                      ? 'Pedido: $requerido → Disponible: $disponible'
                      : 'Pedido: $requerido → Sin stock',
                  style: TextStyle(fontSize: 11, color: color[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Ajustar cantidades al stock disponible y quitar los que tienen 0
  void _ajustarStockDisponible() {
    final stockMap = <String, double>{};
    for (final item in _itemsSinStock) {
      final id = item['detalleId']?.toString();
      if (id != null) {
        stockMap[id] = _toDouble(item['stockDisponible']);
      }
    }

    final idsARemover = <String>[];
    final ajustes = <String, double>{};

    setState(() {
      for (var i = _items.length - 1; i >= 0; i--) {
        final itemId = _items[i]['id']?.toString();
        if (itemId != null && stockMap.containsKey(itemId)) {
          final disponible = stockMap[itemId]!;
          if (disponible <= 0) {
            // Sin stock: quitar
            idsARemover.add(itemId);
            _items.removeAt(i);
          } else {
            // Stock parcial: ajustar cantidad
            ajustes[itemId] = disponible;
            _items[i]['cantidad'] = disponible;
            // Recalcular subtotal del item
            final precio = _toDouble(_items[i]['precioUnitario']);
            _items[i]['subtotal'] = disponible * precio;
          }
        }
      }
      _excluirDetalleIds = idsARemover;
      _ajustarCantidades = ajustes;
      _itemsSinStock = [];
    });
  }

  /// Aplica (o quita, con 0) un descuento de línea: muta el item para que
  /// los totales de la página se recalculen y lo registra para el DTO.
  void _aplicarDescuentoItem(int index, double monto) {
    final item = _items[index];
    final id = item['id']?.toString();
    if (id == null) return;
    final cantidad = _toDouble(item['cantidad']);
    final precio = _toDouble(item['precioUnitario']);
    final bruto = cantidad * precio;
    final desc = monto.clamp(0, bruto).toDouble();
    final igvPct = _toDouble(item['porcentajeIGV']) / 100;
    final subtotal = bruto - desc;
    final igv = double.parse((subtotal * igvPct).toStringAsFixed(2));

    setState(() {
      item['descuento'] = desc;
      item['subtotal'] = subtotal;
      item['igv'] = igv;
      item['total'] = subtotal + igv;
      if (desc > 0) {
        _ajustarDescuentos[id] = desc;
      } else {
        _ajustarDescuentos.remove(id);
      }
    });
  }

  /// Garantiza que haya un autorizador para aplicar descuentos. Un ADMIN
  /// de empresa (EMPRESA_ADMIN/SUPER_ADMIN) se auto-autoriza con su propio
  /// id, sin pedir credenciales. Cualquier otro rol abre el dialog de
  /// autorización (DNI + contraseña, validado por el backend). Devuelve
  /// `true` si se puede continuar.
  /// Autorización gerencial para VENTA BAJO COSTO: el backend rechazó con
  /// `VENTA_BAJO_COSTO_NO_AUTORIZADA` (un descuento dejó margen negativo y
  /// el producto no está en liquidación). Mismo criterio que el descuento:
  /// admin auto-autoriza; otro rol → credenciales de un autorizador.
  Future<bool> _autorizarVentaBajoCosto(String motivoBackend) async {
    final ctxState = context.read<EmpresaContextCubit>().state;
    final authState = context.read<AuthBloc>().state;
    if (ctxState is EmpresaContextLoaded &&
        ctxState.context.esAdminEmpresa &&
        authState is Authenticated) {
      // Admin: confirma explícitamente (vender bajo costo es pérdida real).
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => StyledDialog(
          accentColor: Colors.orange.shade800,
          icon: Icons.warning_amber_rounded,
          titulo: 'Venta bajo costo',
          content: [
            Text(
              motivoBackend,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              '¿Autorizar esta venta con pérdida?',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.orange.shade800,
              ),
            ),
          ],
          actions: [
            Expanded(
              child: CustomButton(
                text: 'Cancelar',
                isOutlined: true,
                borderColor: Colors.grey.shade400,
                textColor: Colors.grey.shade700,
                enableShadows: false,
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
            ),
            Expanded(
              child: CustomButton(
                text: 'Autorizar',
                backgroundColor: Colors.orange.shade800,
                textColor: Colors.white,
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
            ),
          ],
        ),
      );
      if (ok != true) return false;
      _ventaBajoCostoAutorizadaPorId = authState.user.id;
      return true;
    }

    final auth = await showAutorizacionDialog(
      context,
      operacion: 'VENTA_BAJO_COSTO',
      titulo: 'Autorizar venta bajo costo',
      descripcion: motivoBackend,
    );
    if (auth == null || !auth.authorized) return false;
    _ventaBajoCostoAutorizadaPorId = auth.autorizadoPorId;
    return true;
  }

  Future<bool> _asegurarAutorizacionDescuento() async {
    if (_descuentoAutorizadoPorId != null) return true;

    final ctxState = context.read<EmpresaContextCubit>().state;
    final authState = context.read<AuthBloc>().state;
    if (ctxState is EmpresaContextLoaded &&
        ctxState.context.esAdminEmpresa &&
        authState is Authenticated) {
      _descuentoAutorizadoPorId = authState.user.id;
      return true;
    }

    final auth = await showAutorizacionDialog(
      context,
      operacion: 'APLICAR_DESCUENTO',
      titulo: 'Autorizar descuento',
      descripcion:
          'Un administrador debe autorizar los descuentos de esta venta',
    );
    if (auth == null || !auth.authorized) return false;
    _descuentoAutorizadoPorId = auth.autorizadoPorId;
    return true;
  }

  /// Dialog de descuento para una línea (monto en S/, tope = importe bruto).
  Future<void> _dialogDescuentoItem(int index) async {
    if (!await _asegurarAutorizacionDescuento()) return;
    if (!mounted) return;

    final item = _items[index];
    final nombre = item['descripcion']?.toString() ?? 'Item';
    final cantidad = _toDouble(item['cantidad']);
    final precio = _toDouble(item['precioUnitario']);
    final bruto = cantidad * precio;
    final actual = _toDouble(item['descuento']);
    final controller = TextEditingController(
      text: actual > 0 ? actual.toStringAsFixed(2) : '',
    );

    final aplicado = await showDialog<double>(
      context: context,
      builder: (ctx) => StyledDialog(
        accentColor: AppColors.blue1,
        icon: Icons.discount_outlined,
        titulo: 'Descuento — $nombre',
        content: [
          Text('Importe de la línea: S/ ${bruto.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 10),
          CustomText(
            controller: controller,
            label: 'Descuento S/',
            hintText: '0.00',
            borderColor: AppColors.blue1,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
        actions: [
          if (actual > 0)
            Expanded(
              child: CustomButton(
                text: 'Quitar',
                isOutlined: true,
                borderColor: Colors.red.shade300,
                textColor: Colors.red.shade700,
                enableShadows: false,
                // OJO: 0.0 (double) — pop(0) con int crasheaba el navigator
                // (showDialog<double> hace cast del result) y congelaba la app.
                onPressed: () => Navigator.of(ctx).pop(0.0),
              ),
            ),
          Expanded(
            child: CustomButton(
              text: 'Cancelar',
              isOutlined: true,
              borderColor: Colors.grey.shade400,
              textColor: Colors.grey.shade700,
              enableShadows: false,
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ),
          Expanded(
            child: CustomButton(
              text: 'Aplicar',
              backgroundColor: AppColors.blue1,
              textColor: Colors.white,
              onPressed: () {
                final v =
                    double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;
                if (v > bruto) {
                  SnackBarHelper.showError(
                      ctx, 'El descuento supera el importe de la línea');
                  return;
                }
                Navigator.of(ctx).pop(v);
              },
            ),
          ),
        ],
      ),
    );

    if (aplicado != null) _aplicarDescuentoItem(index, aplicado);
  }

  /// Dialog del descuento GLOBAL (S/ o %). Valida que no deje el total por
  /// debajo del adelanto ya pagado ni en cero.
  Future<void> _dialogDescuentoGlobal() async {
    if (!await _asegurarAutorizacionDescuento()) return;
    if (!mounted) return;

    var esPorcentaje = _descuentoGlobalPct != null;
    final controller = TextEditingController(
      text: _descuentoGlobal > 0
          ? (esPorcentaje
              ? _descuentoGlobalPct!.toStringAsFixed(0)
              : _descuentoGlobal.toStringAsFixed(2))
          : '',
    );

    final result = await showDialog<({double monto, double? pct})>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => StyledDialog(
          accentColor: AppColors.blue1,
          icon: Icons.percent,
          titulo: 'Descuento global',
          content: [
            Text('Total actual: S/ ${_total.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 10),
            // Toggle S/ / % — mismo patrón que el dialog de descuento del
            // carrito de venta rápida (segmento sólido = seleccionado).
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setSheet(() => esPorcentaje = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !esPorcentaje
                            ? AppColors.blue1
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text('S/',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: !esPorcentaje
                                  ? Colors.white
                                  : Colors.grey.shade600,
                            )),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setSheet(() => esPorcentaje = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: esPorcentaje
                            ? AppColors.blue1
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text('%',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: esPorcentaje
                                  ? Colors.white
                                  : Colors.grey.shade600,
                            )),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            CustomText(
              controller: controller,
              label: esPorcentaje ? 'Descuento %' : 'Descuento S/',
              hintText: esPorcentaje ? '0' : '0.00',
              borderColor: AppColors.blue1,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
          actions: [
            if (_descuentoGlobal > 0)
              Expanded(
                child: CustomButton(
                  text: 'Quitar',
                  isOutlined: true,
                  borderColor: Colors.red.shade300,
                  textColor: Colors.red.shade700,
                  enableShadows: false,
                  onPressed: () =>
                      Navigator.of(ctx).pop((monto: 0.0, pct: null)),
                ),
              ),
            Expanded(
              child: CustomButton(
                text: 'Cancelar',
                isOutlined: true,
                borderColor: Colors.grey.shade400,
                textColor: Colors.grey.shade700,
                enableShadows: false,
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
            Expanded(
              child: CustomButton(
                text: 'Aplicar',
                backgroundColor: AppColors.blue1,
                textColor: Colors.white,
                onPressed: () {
                  final v =
                      double.tryParse(controller.text.replaceAll(',', '.')) ??
                          0;
                  final monto = esPorcentaje
                      ? double.parse((_total * v / 100).toStringAsFixed(2))
                      : v;
                  if (monto >= _total) {
                    SnackBarHelper.showError(ctx,
                        'El descuento no puede igualar o superar el total');
                    return;
                  }
                  if (_total - monto < _adelanto) {
                    SnackBarHelper.showError(ctx,
                        'El total con descuento no puede ser menor al adelanto ya pagado (S/ ${_adelanto.toStringAsFixed(2)})');
                    return;
                  }
                  Navigator.of(ctx)
                      .pop((monto: monto, pct: esPorcentaje ? v : null));
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _descuentoGlobal = result.monto;
        _descuentoGlobalPct = result.pct;
      });
    }
  }

  /// Quitar todos los items sin stock suficiente
  void _removerItemsSinStock() {
    final sinStockIds = _itemsSinStock
        .map((item) => item['detalleId']?.toString())
        .where((id) => id != null)
        .cast<String>()
        .toList();

    setState(() {
      _items.removeWhere((item) => sinStockIds.contains(item['id']?.toString()));
      _excluirDetalleIds = sinStockIds;
      _itemsSinStock = [];
    });
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  /// Usa los valores ya calculados por el backend (subtotal, igv, total por item)
  double get _total => _items.fold(0.0, (sum, item) => sum + _toDouble(item['total']));
  double get _subtotal => _items.fold(0.0, (sum, item) => sum + _toDouble(item['subtotal']));
  double get _impuestos => _items.fold(0.0, (sum, item) => sum + _toDouble(item['igv']));

  double get _descuentoTotal {
    return _items.fold(0.0, (sum, item) => sum + _toDouble(item['descuento']));
  }

  /// Adelanto registrado en la cotización (pago previo al crearla con reserva).
  /// El backend lo aplica como PagoVenta adicional al convertir a venta.
  double get _adelanto => _cotizacion?.adelantoMonto ?? 0;

  /// Total tras aplicar el descuento GLOBAL del cajero.
  double get _totalConDescuentoGlobal {
    final v = _total - _descuentoGlobal;
    return v > 0 ? v : 0;
  }

  /// Total que el cajero debe cobrar HOY al cliente = total con descuento
  /// global − adelanto. Sin descuento ni adelanto, equivale a `_total`.
  double get _totalACobrar {
    final v = _totalConDescuentoGlobal - _adelanto;
    return v > 0 ? v : 0;
  }

  double get _totalPagado => _pagos.fold(0.0, (sum, p) => sum + (p['monto'] as double));
  double get _saldoPendiente => _totalACobrar - _totalPagado;

  void _agregarPago() {
    final monto = CurrencyUtilsImproved.parseToDouble(_montoAgregarController.text);
    if (monto <= 0) {
      SnackBarHelper.showError(context, 'Ingresa un monto valido');
      return;
    }

    if (_monedaActual == 'USD' && _tipoCambioVenta == null) {
      SnackBarHelper.showError(context, 'Tipo de cambio no disponible');
      return;
    }

    final montoEnSoles = _monedaActual == 'USD'
        ? double.parse((monto * _tipoCambioVenta!).toStringAsFixed(2))
        : monto;

    setState(() {
      _pagos.add({
        'metodo': _metodoActual,
        'monto': montoEnSoles,
        'referencia': _referenciaAgregarController.text.trim(),
        'monedaOriginal': _monedaActual,
        'montoOriginal': monto,
        'tipoCambio': _monedaActual == 'USD' ? _tipoCambioVenta : null,
      });
      _montoAgregarController.clear();
      _referenciaAgregarController.clear();
      _monedaActual = 'PEN';
    });
  }

  void _removerPago(int index) {
    setState(() => _pagos.removeAt(index));
  }

  Future<void> _capturarFirma() async {
    final bytes = await showModalBottomSheet<Uint8List>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const FirmaDigitalSheet(),
    );
    if (bytes != null && mounted) {
      setState(() => _firmaBytes = bytes);
    }
  }

  Future<void> _subirFirma(String ventaId, String empresaId) async {
    if (_firmaBytes == null) return;
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/firma_venta_$ventaId.png');
      await tempFile.writeAsBytes(_firmaBytes!);

      final storageService = locator<StorageService>();
      await storageService.uploadFile(
        file: tempFile,
        empresaId: empresaId,
        entidadTipo: 'VENTA',
        entidadId: ventaId,
        categoria: 'FIRMA',
      );

      try { await tempFile.delete(); } catch (_) {}
    } catch (_) {}
  }

  void _agregarProducto() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                CotizacionItemSelector(
                  onItemSelected: (item) {
                    Navigator.pop(context);
                    setState(() {
                      _itemsAgregados.add(item);
                      // Agregar a la lista visual (guardando la referencia
                      // al input para poder quitarlo del payload con el ✕).
                      _items.add({
                        '_input': item,
                        'id': 'nuevo_${DateTime.now().millisecondsSinceEpoch}',
                        'descripcion': item.descripcion,
                        'cantidad': item.cantidad,
                        'precioUnitario': item.precioUnitario,
                        'descuento': item.descuento,
                        'porcentajeIGV': item.porcentajeIGV,
                        'igv': item.igv,
                        'subtotal': item.subtotal,
                        'total': item.total,
                        'productoId': item.productoId,
                        'varianteId': item.varianteId,
                        'servicioId': item.servicioId,
                        '_esNuevo': true,
                      });
                    });
                    SnackBarHelper.showSuccess(context, 'Producto agregado');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Quita un item de la venta. No basta con sacarlo de la lista visual:
  /// el backend arma la venta desde los DETALLES DE LA COTIZACIÓN, así que
  /// hay que registrar la exclusión (`excluirDetalleIds`) — sin esto el
  /// item "quitado" igual se vendía (y reventaba por stock si no había).
  void _removeItem(int index) {
    setState(() {
      final item = _items[index];
      if (item['_esNuevo'] == true) {
        // Item agregado por el cajero en esta pantalla → quitarlo del
        // payload de adicionales.
        final input = item['_input'];
        if (input != null) _itemsAgregados.remove(input);
      } else {
        final detalleId = item['id']?.toString();
        if (detalleId != null && detalleId.isNotEmpty) {
          if (!_excluirDetalleIds.contains(detalleId)) {
            _excluirDetalleIds.add(detalleId);
          }
          // Limpiar ajustes/descuentos que apuntaban a esta línea.
          _ajustarCantidades.remove(detalleId);
          _ajustarDescuentos.remove(detalleId);
          // Y el aviso de stock insuficiente si era por este item.
          _itemsSinStock.removeWhere(
            (s) => s['detalleId']?.toString() == detalleId,
          );
        }
      }
      _items.removeAt(index);
    });
  }

  /// Cambiar el cliente al cobrar: busca por DNI (RENIEC) o RUC (SUNAT),
  /// reutilizando los usecases de venta rápida (registran el cliente si no
  /// existía, idempotente). El resultado reemplaza al cliente de la
  /// cotización en la venta y el comprobante.
  Future<void> _dialogCambiarCliente() async {
    // Si el comprobante elegido es FACTURA, arrancar en RUC.
    var esRuc = _tipoComprobante == 'FACTURA';
    final controller = TextEditingController();
    var buscando = false;

    final result = await showDialog<
        ({
          String? clienteId,
          String? clienteEmpresaId,
          String nombre,
          String documento,
          String? direccion,
        })>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => StyledDialog(
          accentColor: AppColors.blue1,
          icon: Icons.person_search,
          titulo: 'Cambiar cliente',
          content: [
            // Toggle DNI / RUC — mismo patrón segmentado del descuento S/ ↔ %.
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: buscando
                        ? null
                        : () => setSheet(() => esRuc = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color:
                            !esRuc ? AppColors.blue1 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text('DNI',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: !esRuc
                                  ? Colors.white
                                  : Colors.grey.shade600,
                            )),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap:
                        buscando ? null : () => setSheet(() => esRuc = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: esRuc ? AppColors.blue1 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text('RUC',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: esRuc
                                  ? Colors.white
                                  : Colors.grey.shade600,
                            )),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            CustomText(
              controller: controller,
              label: esRuc ? 'RUC (11 dígitos)' : 'DNI (8 dígitos)',
              hintText: esRuc ? '20...' : '12345678',
              borderColor: AppColors.blue1,
              keyboardType: TextInputType.number,
            ),
          ],
          actions: [
            Expanded(
              child: CustomButton(
                text: 'Cancelar',
                isOutlined: true,
                borderColor: Colors.grey.shade400,
                textColor: Colors.grey.shade700,
                enableShadows: false,
                onPressed:
                    buscando ? null : () => Navigator.of(ctx).pop(),
              ),
            ),
            Expanded(
              child: CustomButton(
                text: buscando ? 'Buscando...' : 'Buscar',
                backgroundColor: AppColors.blue1,
                textColor: Colors.white,
                onPressed: buscando
                    ? null
                    : () async {
                        final doc = controller.text.trim();
                        final largoOk =
                            esRuc ? doc.length == 11 : doc.length == 8;
                        if (!largoOk) {
                          SnackBarHelper.showError(
                              ctx,
                              esRuc
                                  ? 'El RUC debe tener 11 dígitos'
                                  : 'El DNI debe tener 8 dígitos');
                          return;
                        }
                        setSheet(() => buscando = true);
                        if (esRuc) {
                          final r =
                              await locator<BuscarClientePorRucUseCase>()(doc);
                          if (!ctx.mounted) return;
                          if (r is Success<ClienteResueltoRuc>) {
                            final c = r.data;
                            Navigator.of(ctx).pop((
                              clienteId: null,
                              clienteEmpresaId: c.clienteEmpresaId,
                              nombre: c.razonSocial,
                              documento: c.ruc,
                              direccion: c.direccion,
                            ));
                          } else {
                            setSheet(() => buscando = false);
                            SnackBarHelper.showError(
                                ctx, (r as Error).message);
                          }
                        } else {
                          final r =
                              await locator<BuscarClientePorDniUseCase>()(doc);
                          if (!ctx.mounted) return;
                          if (r is Success<ClienteResueltoDni>) {
                            final c = r.data;
                            Navigator.of(ctx).pop((
                              // El usecase de DNI resuelve una persona: su
                              // id viaja como clienteId (EmpresaPersona),
                              // igual que en venta rápida.
                              clienteId: c.clienteEmpresaId,
                              clienteEmpresaId: null,
                              nombre: c.nombreCompleto,
                              documento: c.dni,
                              direccion: c.direccion,
                            ));
                          } else {
                            setSheet(() => buscando = false);
                            SnackBarHelper.showError(
                                ctx, (r as Error).message);
                          }
                        }
                      },
              ),
            ),
          ],
        ),
      ),
    );

    if (result == null || !mounted) return;
    setState(() {
      _clienteIdOverride = result.clienteId;
      _clienteEmpresaIdOverride = result.clienteEmpresaId;
      _nombreClienteOverride = result.nombre;
      _documentoClienteOverride = result.documento;
      _direccionClienteOverride = result.direccion;
    });
  }

  /// Vuelve al cliente original de la cotización.
  void _restaurarClienteOriginal() {
    setState(() {
      _clienteIdOverride = null;
      _clienteEmpresaIdOverride = null;
      _nombreClienteOverride = null;
      _documentoClienteOverride = null;
      _direccionClienteOverride = null;
    });
  }

  Future<void> _procesarVenta() async {
    if (_isProcessing) return;

    final esCredito = _condicionPago == 'CREDITO';
    // Cotización YA PAGADA por completo (adelantos digitales acumulados =
    // total): se convierte a venta SIN pagos nuevos — solo emite el
    // comprobante y descuenta el stock reservado. El dinero ya está en
    // Tesorería (Caja Central), no debe tocar la caja del cajero.
    final yaPagada = _totalACobrar <= 0.005;
    if (!esCredito && _pagos.isEmpty && !yaPagada) {
      SnackBarHelper.showError(context, 'Agrega al menos un pago');
      return;
    }

    // FACTURA exige RUC (11 dígitos) del cliente efectivo. Guiar al cajero
    // antes de que el backend lo rechace.
    if (_tipoComprobante == 'FACTURA') {
      final docEfectivo =
          _documentoClienteOverride ?? _cotizacion?.documentoCliente ?? '';
      if (docEfectivo.length != 11) {
        SnackBarHelper.showError(context,
            'FACTURA requiere un cliente con RUC. Usa "Cambiar" en la sección Cliente.');
        return;
      }
    }

    setState(() => _isProcessing = true);

    try {
      final data = <String, dynamic>{
        'tipoComprobante': _tipoComprobante,
        'condicionPago': _condicionPago,
        'esCredito': esCredito,
        if (!esCredito && _pagos.isNotEmpty) ...{
          // Enviar el primer método como principal (para compatibilidad) y el total pagado
          'metodoPago': _pagos.first['metodo'],
          'montoRecibido': _totalPagado,
          // Array de pagos múltiples
          'pagos': _pagos.map((p) => {
            'metodoPago': p['metodo'],
            'monto': p['monto'],
            if ((p['referencia'] as String).isNotEmpty) 'referencia': p['referencia'],
            if (p['monedaOriginal'] == 'USD') ...{
              'monedaOriginal': 'USD',
              'montoOriginal': p['montoOriginal'],
              'tipoCambio': p['tipoCambio'],
            },
          }).toList(),
        },
        if (esCredito && _plazoCreditoController.text.isNotEmpty) ...{
          'plazoCredito': int.tryParse(_plazoCreditoController.text),
          'fechaVencimientoPago': DateTime.now()
              .add(Duration(days: int.tryParse(_plazoCreditoController.text) ?? 30))
              .toIso8601String(),
        },
        if (esCredito && _numeroCuotas > 0)
          'numeroCuotas': _numeroCuotas,
      };

      // Tipo de documento según comprobante (9 dígitos = CE extranjero).
      if (_tipoComprobante == 'FACTURA') {
        data['tipoDocumentoCliente'] = '6'; // RUC
      } else {
        final docCliente =
            _documentoClienteOverride ?? _cotizacion?.documentoCliente ?? '';
        data['tipoDocumentoCliente'] = docCliente.length == 9 ? '4' : '1';
      }

      if (_observacionesController.text.trim().isNotEmpty) {
        data['observaciones'] = _observacionesController.text.trim();
      }
      if (_excluirDetalleIds.isNotEmpty) {
        data['excluirDetalleIds'] = _excluirDetalleIds;
      }
      if (_ajustarCantidades.isNotEmpty) {
        data['ajustarCantidades'] = _ajustarCantidades;
      }
      if (_itemsAgregados.isNotEmpty) {
        data['itemsAdicionales'] = _itemsAgregados.map((item) => item.toMap()).toList();
      }
      // Descuentos del cajero (por línea y/o global).
      if (_ajustarDescuentos.isNotEmpty) {
        data['ajustarDescuentos'] = _ajustarDescuentos;
      }
      if (_descuentoGlobal > 0) {
        data['descuentoGlobal'] = _descuentoGlobal;
        if (_descuentoGlobalPct != null) {
          data['descuentoGlobalPorcentaje'] = _descuentoGlobalPct;
        }
      }
      // Quién autorizó los descuentos (admin auto-autorizado o el
      // autorizador validado por credenciales).
      if ((_ajustarDescuentos.isNotEmpty || _descuentoGlobal > 0) &&
          _descuentoAutorizadoPorId != null) {
        data['descuentoAutorizadoPorId'] = _descuentoAutorizadoPorId;
      }
      // Autorización de venta bajo costo (reintento tras el rechazo del guard).
      if (_ventaBajoCostoAutorizadaPorId != null) {
        data['ventaBajoCostoAutorizadaPorId'] = _ventaBajoCostoAutorizadaPorId;
      }
      // Cliente cambiado al cobrar (reemplaza al de la cotización en la
      // venta y el comprobante).
      if (_clienteCambiado) {
        if (_clienteIdOverride != null) {
          data['clienteId'] = _clienteIdOverride;
        }
        if (_clienteEmpresaIdOverride != null) {
          data['clienteEmpresaId'] = _clienteEmpresaIdOverride;
        }
        data['nombreCliente'] = _nombreClienteOverride;
        data['documentoCliente'] = _documentoClienteOverride;
        if (_direccionClienteOverride != null) {
          data['direccionCliente'] = _direccionClienteOverride;
        }
      }

      final result = await locator<CobrarCotizacionUseCase>()(
        cotizacionId: widget.cotizacionId,
        data: data,
      );

      if (!mounted) return;

      if (result is Error<Venta>) {
        setState(() => _isProcessing = false);
        // Venta BAJO COSTO (descuento dejó margen negativo sin liquidación):
        // pedir autorización gerencial y reintentar — mismo flujo que VR.
        if (result.errorCode == 'VENTA_BAJO_COSTO_NO_AUTORIZADA' &&
            _ventaBajoCostoAutorizadaPorId == null) {
          final autorizado = await _autorizarVentaBajoCosto(result.message);
          if (autorizado && mounted) {
            await _procesarVenta(); // reintenta con la autorización adjunta
          }
          return;
        }
        SnackBarHelper.showError(context, result.message);
        return;
      }

      final venta = (result as Success<Venta>).data;
      final ventaId = venta.id;
      final empresaId = venta.empresaId;

      // Subir firma si fue capturada
      await _subirFirma(ventaId, empresaId);

      if (!mounted) return;
      SnackBarHelper.showSuccess(context, 'Venta registrada exitosamente');
      // Navegar al ticket reemplazando esta página, para que al volver regrese a la cola POS
      context.pop(true);
      context.push('/empresa/ventas/$ventaId/ticket');
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        SnackBarHelper.showError(context, 'Error al procesar la venta');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Código + total se muestran en el SmartAppBar; ahorra una card al inicio.
    // Si la cotización aún está PENDIENTE, mostramos un banner ámbar delgado
    // dentro del body avisando que se aprobará al cobrar.
    final codigo = _cotizacion?.codigo ?? '';
    final esPendiente = _cotizacion?.estado == EstadoCotizacion.pendiente;
    final tituloAppBar = _isLoading || codigo.isEmpty
        ? 'Cobrar'
        : '$codigo  ·  S/ ${_total.toStringAsFixed(2)}';

    return Scaffold(
      appBar: SmartAppBar(
        title: tituloAppBar,
        leftIcon: Icons.arrow_back_rounded,
        onLeftTap: () => context.pop(),
        actions: [
          // Acceso rápido a firma del cliente. Tap abre el bottom sheet
          // de captura. Si ya hay firma, muestra un badge verde con check
          // y long-press limpia. Reemplaza la card "Firma del cliente"
          // que vivía en el body.
          IconButton(
            tooltip: _firmaBytes != null
                ? 'Firma capturada (toca para reemplazar)'
                : 'Capturar firma del cliente',
            onPressed: _capturarFirma,
            onLongPress: _firmaBytes != null
                ? () => setState(() => _firmaBytes = null)
                : null,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.draw_outlined, size: 18,),
                if (_firmaBytes != null)
                  Positioned(
                    right: -3,
                    top: -3,
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.green.shade500,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: const Icon(Icons.check,
                          size: 8, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: GradientBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : ListView(
                    padding: const EdgeInsets.all(6),
                    children: [
                      if (esPendiente) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: Colors.amber.shade300, width: 0.6),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.pending_outlined,
                                  size: 14, color: Colors.amber.shade800),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Cotización pendiente — se aprobará al cobrar.',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Cliente + Productos en una sola card unificada
                      // (datos del cliente arriba, divider, lista de items
                      // abajo). Reduce ruido visual al cobrar.
                      GradientContainer(
                        borderColor: AppColors.blueborder,
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Cliente ──
                            // El cajero puede cambiarlo al cobrar (ej.
                            // cotización a CLIENTES VARIOS que pide FACTURA).
                            Row(
                              children: [
                                Icon(Icons.person,
                                    size: 16, color: AppColors.blue1),
                                const SizedBox(width: 6),
                                AppSubtitle('Cliente',
                                    color: AppColors.blue1),
                                const Spacer(),
                                if (_clienteCambiado) ...[
                                  GestureDetector(
                                    onTap: _restaurarClienteOriginal,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6),
                                      child: Icon(Icons.undo,
                                          size: 16,
                                          color: Colors.grey.shade600),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                GestureDetector(
                                  onTap: _dialogCambiarCliente,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 4),
                                    decoration: BoxDecoration(
                                      // color: AppColors.green,
                                      border: Border.all(
                                          color: AppColors.green, width: 0.6),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.edit,
                                            size: 12, color: AppColors.green,),
                                        SizedBox(width: 4),
                                        Text('Cambiar',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: AppColors.green,
                                                fontWeight:
                                                    FontWeight.w500)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            _infoRow(
                                'Nombre',
                                _nombreClienteOverride ??
                                    _cotizacion?.nombreCliente ??
                                    'Sin cliente'),
                            if ((_documentoClienteOverride ??
                                    _cotizacion?.documentoCliente) !=
                                null)
                              _infoRow(
                                  'Documento',
                                  _documentoClienteOverride ??
                                      _cotizacion!.documentoCliente!),
                            if (!_clienteCambiado &&
                                _cotizacion?.telefonoCliente != null)
                              _infoRow(
                                  'Teléfono', _cotizacion!.telefonoCliente!),
                            const Divider(height: 10),
                            // ── Productos ──
                            Row(
                              children: [
                                Icon(Icons.shopping_cart, size: 16, color: AppColors.blue1),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text('Productos (${_items.length})',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.blue1)),
                                ),
                                GestureDetector(
                                  onTap: _agregarProducto,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.blue1,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.add, size: 14, color: Colors.white),
                                        SizedBox(width: 4),
                                        Text('Agregar', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Tabla tipo Excel (mismo patrón que el detalle
                            // de cotización): header bluechip + zebra
                            // striping en el body. Última columna es la
                            // acción ✕ para quitar el item.
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.blueborder
                                      .withValues(alpha: 0.5),
                                  width: 0.6,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                children: [
                                  // Header
                                  Container(
                                    color: AppColors.bluechip,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 5, horizontal: 8),
                                    child: const Row(
                                      children: [
                                        SizedBox(
                                            width: 26,
                                            child:
                                                Center(child: _ThItem('#'))),
                                        Expanded(
                                            flex: 6,
                                            child: _ThItem('PRODUCTO')),
                                        Expanded(
                                            flex: 2,
                                            child: Center(
                                                child: _ThItem('CANT.'))),
                                        Expanded(
                                            flex: 3,
                                            child: Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child:
                                                    _ThItem('P. UNIT.'))),
                                        Expanded(
                                            flex: 3,
                                            child: Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: _ThItem('TOTAL'))),
                                        SizedBox(width: 28),
                                      ],
                                    ),
                                  ),
                                  // Body (tap en la fila = descuento de línea)
                                  for (var i = 0; i < _items.length; i++)
                                    _ItemTablaRow(
                                      index: i,
                                      item: _items[i],
                                      onRemove: () => _removeItem(i),
                                      onTap: () => _dialogDescuentoItem(i),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            _resumenRow('Subtotal', _subtotal),
                            if (_impuestos > 0)
                              _resumenRow(
                                'IGV${_items.isNotEmpty && _items.every((it) => _toDouble(it['porcentajeIGV']) == _toDouble(_items.first['porcentajeIGV'])) ? ' (${_toDouble(_items.first['porcentajeIGV']).toStringAsFixed(0)}%)' : ''}',
                                _impuestos,
                              ),
                            if (_descuentoTotal > 0)
                              _resumenRow('Descuento', -_descuentoTotal, color: Colors.red),
                            const Divider(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                Text('S/ ${_total.toStringAsFixed(2)}',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.blue1)),
                              ],
                            ),
                            // Descuento GLOBAL del cajero (además del de línea,
                            // que se aplica tocando cada item de la tabla).
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: _dialogDescuentoGlobal,
                                icon: const Icon(Icons.percent, size: 14),
                                label: AppSubtitle(
                                  font: AppFont.amazonEmberMediumItalic,
                                  _descuentoGlobal > 0
                                      ? 'Editar descuento global'
                                      : 'Aplicar descuento global',
                                  color: AppColors.blue2,
                                  fontSize: 11,
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.blue2,
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  minimumSize: const Size(0, 28),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ),
                            if (_descuentoGlobal > 0) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Descuento global${_descuentoGlobalPct != null ? ' (${_descuentoGlobalPct!.toStringAsFixed(0)}%)' : ''}',
                                    style: TextStyle(fontSize: 11, color: Colors.red.shade700),
                                  ),
                                  Text('- S/ ${_descuentoGlobal.toStringAsFixed(2)}',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.red.shade700)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total a pagar',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                  Text('S/ ${_totalConDescuentoGlobal.toStringAsFixed(2)}',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.blue1)),
                                ],
                              ),
                            ],
                            // Adelanto + saldo a cobrar hoy (solo si hubo adelanto).
                            // El cajero cobra solo el saldo; el adelanto ya se
                            // registró en caja al crear la cotización.
                            if (_adelanto > 0) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Adelanto',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green[700])),
                                  Text(
                                      '- S/ ${_adelanto.toStringAsFixed(2)}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.green[700])),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.greenContainer,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: AppColors.greenBorder,
                                      width: 0.6),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Saldo a cobrar',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.greendark)),
                                    Text(
                                        'S/ ${_totalACobrar.toStringAsFixed(2)}',
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.greendark)),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      _PagoMetodoCard(
                        // Comprobante y método de pago comparten un solo
                        // card (antes eran dos separados).
                        header: ComprobanteCondicionCard(
                          embedded: true,
                          tipoComprobante: _tipoComprobante,
                          onComprobanteChanged: (v) =>
                              setState(() => _tipoComprobante = v),
                          condicionPago: _condicionPago,
                          // En el cobro de cotización-a-venta siempre es
                          // CONTADO, así que ocultamos el selector. El crédito
                          // se gestiona desde otra pantalla (factura con
                          // plazo).
                          onCondicionChanged: (_) {},
                          showMixto: false,
                          showCondicionPago: false,
                        ),
                        // Saldo a cobrar (descuenta adelanto si existe).
                        // El total bruto se ve arriba con desglose.
                        total: _totalACobrar,
                        totalPagado: _totalPagado,
                        metodoActual: _metodoActual,
                        onMetodoChanged: (v) {
                          setState(() => _metodoActual = v);
                          // Si el nuevo método exige referencia y el
                          // campo está vacío (caso típico al pasar de
                          // EFECTIVO → YAPE), precargamos '000'.
                          _precargarReferenciaSiAplica();
                        },
                        pagos: _pagos,
                        onRemoverPago: _removerPago,
                        numpadController: _numpadController,
                        tipoComprobante: _tipoComprobante,
                        referenciaController: _referenciaAgregarController,
                        onAgregarPago: () {
                          _agregarPago();
                          _numpadController.clear();
                          _referenciaAgregarController.clear();
                          _precargarReferenciaSiAplica();
                        },
                      ),
                      const SizedBox(height: 12),

                      // Card "Datos adicionales" (referencia general +
                      // observaciones) ocultada por solicitud del usuario:
                      // la referencia ya se captura por línea de pago, y las
                      // observaciones rara vez se usan en cobro de cotización.
                      // Si más adelante se necesita, reactivar este bloque.
                      // GradientContainer(
                      //   borderColor: AppColors.blueborder,
                      //   padding: const EdgeInsets.all(10),
                      //   child: Column(
                      //     crossAxisAlignment: CrossAxisAlignment.start,
                      //     children: [
                      //       Row(
                      //         children: [
                      //           Icon(Icons.note_alt,
                      //               size: 16, color: AppColors.blue1),
                      //           const SizedBox(width: 6),
                      //           AppSubtitle('Datos adicionales',
                      //               color: AppColors.blue1),
                      //         ],
                      //       ),
                      //       const SizedBox(height: 10),
                      //       CustomText(
                      //         controller: _referenciaController,
                      //         borderColor: AppColors.blue1,
                      //         label: 'Referencia de pago',
                      //         hintText: 'N° operación, voucher, etc.',
                      //       ),
                      //       const SizedBox(height: 10),
                      //       CustomText(
                      //         controller: _observacionesController,
                      //         borderColor: AppColors.blue1,
                      //         label: 'Observaciones',
                      //         hintText: 'Notas adicionales...',
                      //         maxLines: 2,
                      //       ),
                      //     ],
                      //   ),
                      // ),

                      // Card "Firma del cliente" trasladada al SmartAppBar:
                      // ahora el cajero captura/limpia la firma desde el
                      // icono ✏️ del header. La lógica de captura/upload
                      // (`_capturarFirma`, `_subirFirma`, `_firmaBytes`)
                      // sigue intacta.
                      // const SizedBox(height: 12),
                      // GradientContainer(
                      //   borderColor: _firmaBytes != null
                      //       ? AppColors.blue1
                      //       : AppColors.blueborder,
                      //   padding: const EdgeInsets.all(10),
                      //   child: Column(
                      //     crossAxisAlignment: CrossAxisAlignment.start,
                      //     children: [
                      //       Row(children: [
                      //         Icon(Icons.draw_outlined,
                      //             size: 16, color: AppColors.blue1),
                      //         const SizedBox(width: 6),
                      //         AppSubtitle('Firma del cliente',
                      //             color: AppColors.blue1),
                      //         const Spacer(),
                      //         if (_firmaBytes != null)
                      //           GestureDetector(
                      //             onTap: () =>
                      //                 setState(() => _firmaBytes = null),
                      //             child: Container(...),
                      //           ),
                      //       ]),
                      //       if (_firmaBytes != null) ...preview...
                      //       else OutlinedButton.icon(
                      //         onPressed: _capturarFirma,
                      //         icon: Icon(Icons.draw_outlined),
                      //         label: Text('Capturar firma'),
                      //       ),
                      //     ],
                      //   ),
                      // ),

                      // Vuelto (si aplica): se calcula sobre el saldo a
                      // cobrar hoy, no contra el total de la venta —
                      // cuando hay adelanto, el cliente solo entrega el
                      // saldo, y el vuelto es contra ese saldo.
                      if (_totalPagado > _totalACobrar + 0.01) ...[
                        const SizedBox(height: 12),
                        GradientContainer(
                          borderColor: Colors.green.shade300,
                          borderRadius: BorderRadius.circular(12),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Vuelto', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.green[700])),
                              Text('S/ ${(_totalPagado - _totalACobrar).toStringAsFixed(2)}',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.green[700])),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),
                    ],
                  ),
      ),
      // Solo el PosNumpad (digit grid + acciones) pegado al final.
      // La sección de chips de método + display recibido/vuelto queda
      // arriba dentro del scroll para no saturar el bottomNavigationBar.
      bottomNavigationBar: _isLoading || _error != null
          ? null
          : SafeArea(
              top: false,
              child: _NumpadCobrarBar(
                // El "Total" de la barra del numpad debe coincidir con el
                // saldo que el cliente paga HOY: si hubo adelanto, no se
                // suma de nuevo. El total bruto S/150 se ve arriba con el
                // desglose "Adelanto + Saldo a cobrar".
                total: _totalACobrar,
                totalPagado: _totalPagado,
                saldoPendiente: _saldoPendiente,
                numpadController: _numpadController,
                onExacto: () =>
                    _numpadController.setValue(_saldoPendiente),
                onCobrar: _isProcessing
                    ? null
                    : () {
                        if (_numpadController.value > 0) {
                          _agregarPago();
                          _numpadController.clear();
                          _referenciaAgregarController.clear();
                          _precargarReferenciaSiAplica();
                        }
                        _procesarVenta();
                      },
                isProcessing: _isProcessing,
              ),
            ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text('$label: ', style: TextStyle(fontSize: 10, color: Colors.grey[500]))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _resumenRow(String label, double monto, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          Text('S/ ${monto.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
        ],
      ),
    );
  }

}

/// Tarjeta superior con chips de método + display recibido/vuelto + lista
/// de pagos múltiples. Vive en el scroll porque se ve poco cuando el cobro
/// es simple y no es necesario que esté sticky.
///
/// El numpad real (digit grid + acciones) vive en `_NumpadCobrarBar` y
/// está pegado al fondo de la pantalla.
class _PagoMetodoCard extends StatelessWidget {
  /// Contenido opcional arriba del método de pago (selector de comprobante),
  /// para que ambos vivan en un solo card.
  final Widget? header;
  final double total;
  final double totalPagado;
  final String metodoActual;
  final ValueChanged<String> onMetodoChanged;
  final List<Map<String, dynamic>> pagos;
  final ValueChanged<int> onRemoverPago;
  final NumpadController numpadController;
  final TextEditingController referenciaController;
  final VoidCallback onAgregarPago;

  /// Tipo de comprobante elegido (BOLETA/FACTURA/TICKET) — se muestra en el
  /// display del monto para que el cajero vea qué documento va a emitir.
  final String tipoComprobante;

  const _PagoMetodoCard({
    this.header,
    required this.total,
    required this.totalPagado,
    required this.metodoActual,
    required this.onMetodoChanged,
    required this.pagos,
    required this.onRemoverPago,
    required this.numpadController,
    required this.referenciaController,
    required this.tipoComprobante,
    required this.onAgregarPago,
  });

  static const _metodos = [
    ('EFECTIVO', 'Efectivo', Icons.payments_outlined),
    ('YAPE', 'Yape', Icons.qr_code_scanner_outlined),
    ('TARJETA', 'Tarjeta', Icons.credit_card_outlined),
    ('PLIN', 'Plin', Icons.qr_code_2_outlined),
    ('TRANSFERENCIA', 'Transf.', Icons.account_balance_outlined),
  ];

  /// Métodos digitales que requieren un N° de operación / voucher / etc.
  static bool _requiereReferencia(String metodo) =>
      metodo == 'YAPE' ||
      metodo == 'PLIN' ||
      metodo == 'TARJETA' ||
      metodo == 'TRANSFERENCIA';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: numpadController,
      builder: (_, __) {
        final montoActual = numpadController.value;
        final recibidoTotal = totalPagado + montoActual;
        final faltante = (total - recibidoTotal).clamp(0, double.infinity);
        final vuelto = (recibidoTotal - total).clamp(0, double.infinity);

        return GradientContainer(
          borderColor: AppColors.blueborder,
          padding: const EdgeInsets.fromLTRB(12, 5, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (header != null) ...[
                header!,
                const Divider(height: 20),
              ],
              // Display recibido / vuelto / faltante
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.blueborder, width: 0.6),
                ),
                child: Column(
                  children: [
                    _DisplayRow(
                      label: 'Total',
                      value: 'S/ ${total.toStringAsFixed(2)}',
                      strong: true,
                    ),
                    const SizedBox(height: 2),
                    _DisplayRow(
                      label: 'Recibido',
                      value: 'S/ ${recibidoTotal.toStringAsFixed(2)}',
                      color: AppColors.blue1,
                    ),
                    const SizedBox(height: 2),
                    if (vuelto > 0.005)
                      _DisplayRow(
                        label: 'Vuelto',
                        value: 'S/ ${vuelto.toStringAsFixed(2)}',
                        color: Colors.green.shade700,
                      )
                    else
                      _DisplayRow(
                        label: 'Faltante',
                        value: 'S/ ${faltante.toStringAsFixed(2)}',
                        color: faltante > 0.005
                            ? Colors.red.shade600
                            : Colors.grey.shade500,
                      ),
                  ],
                ),
              ),

              // Chips de método de pago: entre el resumen y el monto a
              // agregar, para elegir el medio antes de tipear el monto.
              const SizedBox(height: 10),
              AppSubtitle('Método de Pago', color: AppColors.blue1),
              const SizedBox(height: 8),
              SizedBox(
                height: 30,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _metodos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, i) {
                    final (value, label, icon) = _metodos[i];
                    final selected = metodoActual == value;
                    return GestureDetector(
                      onTap: () => onMetodoChanged(value),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.green : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: selected
                                ? AppColors.green
                                : Colors.grey.shade300,
                            width: selected ? 1.5 : 0.6,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon,
                                size: 14,
                                color: selected
                                    ? Colors.white
                                    : Colors.grey.shade700),
                            const SizedBox(width: 6),
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? Colors.white
                                    : Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ── Inputs de Monto y Referencia + botón Agregar ──
              // Mostramos los inputs solo cuando todavía falta monto por
              // cubrir, contando también lo que está tipeado en el numpad.
              // Al tocar "Exacto" el numpad se setea al saldo, recibidoTotal
              // cubre el total y los inputs/botón se ocultan. Si el cajero
              // quita un pago, vuelve a faltar y reaparecen.
              if ((total - recibidoTotal) > 0.005) ...[
                const SizedBox(height: 10),
                // Display estilo POS del monto tipeado en el numpad
                // (reemplaza al CustomText readOnly: parecía un input
                // editable pero el monto se tipea abajo) + botón Agregar
                // en la misma fila. IntrinsicHeight: permite stretch (botón
                // = altura del display) dentro de un scroll sin altura
                // acotada.
                IntrinsicHeight(
                  child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: montoActual > 0
                                ? AppColors.blue1
                                : AppColors.blueborder,
                            width: montoActual > 0 ? 1.2 : 0.6,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(
                              // Comprobante visible al momento de pagar:
                              // "MONTO A PAGAR - BOLETA/FACTURA/TICKET"
                              // (el tipo resaltado en azul).
                              TextSpan(
                                text: 'MONTO A PAGAR - ',
                                children: [
                                  TextSpan(
                                    text: tipoComprobante,
                                    style: TextStyle(color: AppColors.blue1),
                                  ),
                                ],
                              ),
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'S/ ${montoActual.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                  color: montoActual > 0
                                      ? AppColors.blue1
                                      : Colors.grey.shade400,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: montoActual > 0 ? onAgregarPago : null,
                      icon: const Icon(Icons.add_card, size: 16),
                      label: Text(
                        pagos.isEmpty ? 'Agregar' : 'Otro pago',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.blue1,
                        side: BorderSide(
                            color: montoActual > 0
                                ? AppColors.blue1
                                : Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                  ),
                ),
                if (_requiereReferencia(metodoActual)) ...[
                  const SizedBox(height: 8),
                  CustomText(
                    controller: referenciaController,
                    label: 'Referencia / N° op.',
                    hintText: 'Ej. 8XYZ12',
                    borderColor: AppColors.blue1,
                  ),
                ],
              ] else ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.check_circle,
                        size: 12, color: Colors.green.shade700),
                    const SizedBox(width: 6),
                    Text(
                      'Total cubierto. Toca COBRAR para procesar.',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ],

              // Lista de pagos ya agregados (MIXTO)
              if (pagos.isNotEmpty) ...[
                const SizedBox(height: 10),
                AppSubtitle('Pagos registrados',
                    color: AppColors.blue1, fontSize: 11),
                const SizedBox(height: 6),
                ...pagos.asMap().entries.map((entry) {
                  final i = entry.key;
                  final p = entry.value;
                  final ref = (p['referencia'] as String?) ?? '';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.bluechip,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            size: 14, color: Colors.green.shade700),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${p['metodo']} · S/ ${(p['monto'] as num).toDouble().toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600),
                              ),
                              if (ref.isNotEmpty)
                                Text(
                                  'Ref: $ref',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => onRemoverPago(i),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Icon(Icons.close,
                                size: 14, color: Colors.red.shade400),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Numpad pegado al fondo: digit grid + chips quick amounts + acciones
/// (Exacto / Otro método / COBRAR). Reactivo al `numpadController` para
/// habilitar el COBRAR cuando el monto cubre el total.
class _NumpadCobrarBar extends StatelessWidget {
  final double total;
  final double totalPagado;
  final double saldoPendiente;
  final NumpadController numpadController;
  final VoidCallback onExacto;
  final VoidCallback? onCobrar;
  final bool isProcessing;

  const _NumpadCobrarBar({
    required this.total,
    required this.totalPagado,
    required this.saldoPendiente,
    required this.numpadController,
    required this.onExacto,
    required this.onCobrar,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: numpadController,
      builder: (_, __) {
        final montoActual = numpadController.value;
        final recibidoTotal = totalPagado + montoActual;

        return PosNumpad(
          controller: numpadController,
          quickAmounts: const [10, 20, 50, 100, 200],
          acciones: [
            NumpadAction(
              label: 'Exacto',
              icon: Icons.check,
              onTap: onExacto,
            ),
            NumpadAction(
              label: isProcessing ? 'Procesando' : 'COBRAR',
              icon: Icons.point_of_sale,
              color: Colors.green.shade600,
              destacado: true,
              onTap: onCobrar,
              enabled:
                  onCobrar != null && (recibidoTotal + 0.01 >= total),
              loading: isProcessing,
            ),
          ],
        );
      },
    );
  }
}

class _DisplayRow extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;
  final Color? color;
  const _DisplayRow({
    required this.label,
    required this.value,
    this.strong = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: strong ? 13 : 12,
      fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
      color: color ?? Colors.black87,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}

/// Header de columna para la tabla de items en cobrar cotización.
/// Mismo estilo que la tabla del detalle de cotización: uppercase compacto,
/// peso 700 y color gris oscuro sobre el fondo bluechip.
class _ThItem extends StatelessWidget {
  final String text;
  const _ThItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade800,
        letterSpacing: 0.3,
      ),
    );
  }
}

/// Fila de la tabla de items con zebra striping y botón ✕ a la derecha.
class _ItemTablaRow extends StatelessWidget {
  final int index;
  final Map<String, dynamic> item;
  final VoidCallback onRemove;

  /// Tap en la fila → descuento de la línea.
  final VoidCallback? onTap;

  const _ItemTablaRow({
    required this.index,
    required this.item,
    required this.onRemove,
    this.onTap,
  });

  static String _fmtCantidad(double n) {
    if (n.truncateToDouble() == n) return n.toStringAsFixed(0);
    return n.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final nombre = item['descripcion']?.toString() ??
        (item['producto'] as Map?)?['nombre']?.toString() ??
        'Producto';
    final cantidad =
        _CobrarCotizacionPageState._toDouble(item['cantidad']);
    final precio = _CobrarCotizacionPageState._toDouble(
        item['precioUnitario']);
    final descuento =
        _CobrarCotizacionPageState._toDouble(item['descuento']);
    final total = cantidad * precio - descuento;

    return InkWell(
      onTap: onTap,
      child: Container(
      color: index.isEven ? Colors.white : Colors.grey.shade50,
      // Sin padding vertical: la altura la marca el texto (~11px); el botón
      // ✕ se mantiene por debajo para no estirar la fila.
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 26,
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
            // Debe coincidir con el flex del header PRODUCTO para que
            // CANT./P.UNIT./TOTAL queden alineadas con sus cabeceras.
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    fontSize: 10,
                    height: 1.1,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (descuento > 0)
                  Text(
                    'Desc. -S/ ${descuento.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 8,
                      height: 1.1,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade600,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                _fmtCantidad(cantidad),
                style: const TextStyle(fontSize: 10, height: 1.1),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                precio.toStringAsFixed(2),
                style: const TextStyle(fontSize: 10, height: 1.1),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                total.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 10,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blue1,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 28,
            child: InkWell(
              onTap: onRemove,
              child: Center(
                child: Icon(Icons.close,
                    size: 11, color: Colors.red.shade400),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
