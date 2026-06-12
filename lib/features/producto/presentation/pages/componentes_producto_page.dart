import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/currency/currency_textfield.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../core/widgets/custom_search_field.dart';
import '../../../../core/widgets/styled_dialog.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../../empresa/domain/entities/sede.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';

/// Pantalla completa para gestionar la receta (BOM) de un producto
/// compuesto. Permite agregar/quitar/editar componentes y ver el costo
/// calculado. El botón "Aplicar al producto" actualiza el `precioCosto`
/// del producto en la sede seleccionada vía `/producto-stock/:id/precios`.
class ComponentesProductoPage extends StatefulWidget {
  /// ID del producto final (peluche, PC armada, etc.).
  final String productoId;
  final String productoNombre;

  /// Sede inicial. Si null, se elige la primera disponible. La elección
  /// determina de qué sede se toma el `precioCosto` de cada componente y
  /// a qué `productoStock` se aplicará el costo al pulsar "Aplicar".
  final String? sedeIdInicial;

  /// Si el producto está marcado como insumo, no se permite "Fabricar"
  /// (el backend lo rechaza igual, pero ocultamos el botón).
  final bool esInsumo;

  /// Si el producto tiene variantes, la receta y la fabricación se manejan
  /// POR variante (cada talla/modelo consume distinta cantidad de insumos).
  final bool tieneVariantes;

  /// Variantes activas del producto: cada entrada {'id', 'nombre'}.
  final List<Map<String, dynamic>> variantes;

  const ComponentesProductoPage({
    super.key,
    required this.productoId,
    required this.productoNombre,
    this.sedeIdInicial,
    this.esInsumo = false,
    this.tieneVariantes = false,
    this.variantes = const [],
  });

  @override
  State<ComponentesProductoPage> createState() =>
      _ComponentesProductoPageState();
}

class _ComponentesProductoPageState extends State<ComponentesProductoPage> {
  // Valor sentinela del dropdown para la "receta base" (varianteId null).
  static const String _kBaseReceta = '__BASE__';

  final DioClient _dio = locator<DioClient>();

  List<Sede> _sedes = const [];
  String? _sedeId;
  String? _sedeNombre;

  // Variante activa cuyo receta se está editando (null = receta base, solo
  // para productos sin variantes). Para productos con variantes arranca en
  // la primera.
  String? _varianteId;

  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _items = const [];
  bool _aplicando = false;
  bool _copiando = false;

  String? get _varianteNombre {
    if (_varianteId == null) return null;
    final m = widget.variantes.where((v) => v['id'] == _varianteId);
    return m.isNotEmpty ? m.first['nombre'] as String? : null;
  }

  @override
  void initState() {
    super.initState();
    final state = context.read<EmpresaContextCubit>().state;
    if (state is EmpresaContextLoaded) {
      _sedes = state.context.sedes;
      _sedeId = widget.sedeIdInicial ??
          (_sedes.isNotEmpty ? _sedes.first.id : null);
      if (_sedeId != null) {
        final match = _sedes.where((s) => s.id == _sedeId);
        _sedeNombre = match.isNotEmpty ? match.first.nombre : null;
      }
    }
    if (widget.tieneVariantes && widget.variantes.isNotEmpty) {
      _varianteId = widget.variantes.first['id'] as String?;
    }
    _cargar();
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await _dio.get(
        '/productos/${widget.productoId}/componentes',
        queryParameters: {
          if (_sedeId != null) 'sedeId': _sedeId,
          if (_varianteId != null) 'varianteId': _varianteId,
        },
      );
      if (!mounted) return;
      setState(() {
        _items = (resp.data as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is DioException
            ? (e.response?.data?['message']?.toString() ?? e.message ?? 'Error')
            : e.toString();
        _loading = false;
      });
    }
  }

  double get _costoTotal {
    double t = 0;
    for (final item in _items) {
      final subtotal = (item['subtotal'] as num?)?.toDouble();
      if (subtotal != null) t += subtotal;
    }
    return t;
  }

  bool get _algunoSinCosto => _items.any((i) => i['subtotal'] == null);

  Future<void> _agregar() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _AgregarComponenteDialog(
        productoId: widget.productoId,
        varianteId: _varianteId,
        sedeId: _sedeId,
        idsYaUsados: _items.map((i) => i['componenteId'] as String).toSet(),
      ),
    );
    if (result == true) _cargar();
  }

  Future<void> _editarCantidad(Map<String, dynamic> item) async {
    final controller =
        TextEditingController(text: '${item['cantidad'] ?? ''}');
    final um = item['componente']['unidadMedida'] as String?;
    try {
      final ok = await ConfirmDialog.show(
        context: context,
        type: ConfirmDialogType.info,
        icon: Icons.edit_outlined,
        title: () {
          final nombre = item['componente']['nombre'] as String;
          final vNom = item['componente']['varianteNombre'] as String?;
          return vNom != null ? '$nombre — $vNom' : nombre;
        }(),
        customContent: CustomText(
          controller: controller,
          label: 'Cantidad por unidad fabricada (${um ?? '—'})',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          borderColor: AppColors.blue1,
        ),
        confirmText: 'Guardar',
      );
      if (ok != true) return;
      final nueva = double.tryParse(controller.text.replaceAll(',', '.'));
      if (nueva == null || nueva <= 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cantidad inválida')),
        );
        return;
      }
      await _dio.patch(
        '/productos/${widget.productoId}/componentes/${item['id']}',
        data: {'cantidad': nueva},
      );
      _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _eliminar(Map<String, dynamic> item) async {
    final ok = await ConfirmDialog.show(
      context: context,
      type: ConfirmDialogType.destructive,
      title: 'Quitar componente',
      message:
          '¿Quitar "${item['componente']['nombre']}" de la receta de este producto?',
      confirmText: 'Quitar',
    );
    if (ok != true) return;
    try {
      await _dio.delete(
        '/productos/${widget.productoId}/componentes/${item['id']}',
      );
      _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// Aplica el costo total calculado al `precioCosto` del producto en la
  /// sede actual. Resuelve primero el `productoStockId` correspondiente
  /// y llama a PATCH /producto-stock/:id/precios con tipoCambio=COSTO.
  Future<void> _aplicarAlProducto() async {
    if (_sedeId == null || _items.isEmpty || _costoTotal <= 0) return;
    final nuevoCosto = double.parse(_costoTotal.toStringAsFixed(2));
    setState(() => _aplicando = true);
    try {
      // 1. Resolver stock para esta sede. Si hay variante activa, se aplica
      //    al stock de la VARIANTE; si no, al del producto base.
      final stockResp = await _dio.get(
        _varianteId != null
            ? '/producto-stock/variante/$_varianteId/sede/$_sedeId'
            : '/producto-stock/producto/${widget.productoId}/sede/$_sedeId',
      );
      final data = stockResp.data as Map?;
      final stockId = data?['id'] as String?;
      if (stockId == null) {
        throw 'No se encontró stock en esta sede';
      }
      // precioCosto viene como String (Decimal de Prisma serializado);
      // stockActual como número. Parseo defensivo de ambos.
      final stockRaw = data?['stockActual'];
      final stockActual = stockRaw is num
          ? stockRaw.toInt()
          : int.tryParse('${stockRaw ?? ''}') ?? 0;
      final costoRaw = data?['precioCosto'];
      final costoActual = costoRaw is num
          ? costoRaw.toDouble()
          : (costoRaw is String ? double.tryParse(costoRaw) : null);

      // 2. Advertencia inteligente: "Aplicar a Costo" REEMPLAZA el costo.
      //    Si hay unidades en stock valorizadas a otro costo, eso pisa el
      //    valor real de ese inventario (mejor dejar que la fabricación
      //    pondere). Pedimos confirmación mostrando el impacto.
      final hayImpacto = stockActual > 0 &&
          costoActual != null &&
          (costoActual - nuevoCosto).abs() >= 0.01;
      if (hayImpacto) {
        setState(() => _aplicando = false);
        final confirmar = await _confirmarReemplazoCosto(
          stockActual: stockActual,
          costoActual: costoActual,
          costoNuevo: nuevoCosto,
        );
        if (confirmar != true) return;
        if (!mounted) return;
        setState(() => _aplicando = true);
      }

      final sufijo =
          _varianteNombre != null ? ' [$_varianteNombre]' : '';
      // 3. Aplicar (reemplaza el precioCosto) + auditar como cálculo BOM.
      await _dio.patch(
        '/producto-stock/$stockId/precios',
        data: {
          'precioCosto': nuevoCosto,
          'tipoCambio': 'COSTO',
          'razon':
              'Recalculo desde ${_items.length} componente(s) (BOM) - $_sedeNombre$sufijo',
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Precio Costo actualizado: S/ ${nuevoCosto.toStringAsFixed(2)}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Error al aplicar: ${e is DioException ? (e.response?.data?['message'] ?? e.message) : e}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _aplicando = false);
    }
  }

  /// Advertencia inteligente antes de REEMPLAZAR el costo de un stock que ya
  /// tiene unidades valorizadas a otro costo. Muestra el impacto en el valor
  /// del inventario y recuerda que la fabricación pondera (mejor para
  /// trazabilidad). Devuelve true si el usuario decide reemplazar igual.
  Future<bool?> _confirmarReemplazoCosto({
    required int stockActual,
    required double costoActual,
    required double costoNuevo,
  }) {
    final valorAntes = stockActual * costoActual;
    final valorDespues = stockActual * costoNuevo;
    final diff = (valorAntes - valorDespues).abs();
    final baja = costoNuevo < costoActual;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => StyledDialog(
        accentColor: AppColors.red,
        icon: Icons.warning_amber_rounded,
        titulo: 'Reemplazar costo existente',
        content: [
          Text(
            'Este ${_varianteNombre != null ? 'variante' : 'producto'} ya tiene '
            '$stockActual unidad(es) en stock valorizadas a '
            'S/ ${costoActual.toStringAsFixed(2)} c/u. Aplicar el costo de la '
            'receta las re-valoriza a S/ ${costoNuevo.toStringAsFixed(2)} c/u.',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 10),
          _filaImpacto('Valor inventario actual', valorAntes),
          _filaImpacto('Valor tras reemplazar', valorDespues),
          _filaImpacto(
            baja ? 'Costo real que se descarta' : 'Costo que se agrega',
            diff,
            destacar: true,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Text(
              '💡 Si esas unidades realmente costaron S/ ${costoActual.toStringAsFixed(2)} '
              '(compra/producción previa), NO reemplaces: deja que la '
              'fabricación pondere el costo. Reemplaza solo si el costo anterior '
              'estaba mal cargado.',
              style: TextStyle(fontSize: 10, color: Colors.blue.shade900),
            ),
          ),
        ],
        actions: [
          Expanded(
            child: CustomButton(
              text: 'Cancelar',
              isOutlined: true,
              textColor: AppColors.red,
              borderColor: AppColors.red.withValues(alpha: 0.4),
              enableShadows: false,
              height: 36,
              onPressed: () => Navigator.pop(ctx, false),
            ),
          ),
          Expanded(
            child: CustomButton(
              text: 'Reemplazar',
              backgroundColor: AppColors.red,
              textColor: Colors.white,
              enableShadows: false,
              height: 36,
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filaImpacto(String label, double valor, {bool destacar = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
          Text(
            'S/ ${valor.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: destacar ? FontWeight.bold : FontWeight.w600,
              color: destacar ? AppColors.red : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// Copia la receta base (varianteId null) del producto a la variante
  /// activa, como plantilla inicial. Solo aplica con una variante seleccionada.
  Future<void> _copiarRecetaBase() async {
    if (_varianteId == null) return;
    setState(() => _copiando = true);
    try {
      final resp = await _dio.post(
        '/productos/${widget.productoId}/componentes/copiar-a-variante',
        data: {'varianteId': _varianteId},
      );
      final copiados = (resp.data as Map?)?['copiados'] ?? 0;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Receta base copiada: $copiados componente(s)'),
          backgroundColor: Colors.green,
        ),
      );
      _cargar();
    } catch (e) {
      if (!mounted) return;
      final msg = e is DioException
          ? (e.response?.data?['message']?.toString() ?? e.message ?? 'Error')
          : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _copiando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(
          title: 'Componentes',
          backgroundColor: AppColors.blue1,
          foregroundColor: Colors.white,
          showLogo: false,
          actions: !widget.esInsumo
              ? [
                  IconButton(
                    icon: const Icon(Icons.history),
                    tooltip: 'Historial de fabricaciones',
                    onPressed: _verHistorial,
                  ),
                ]
              : null,
        ),
        body: Column(
          children: [
            _buildHeader(),
            _buildBaseBanner(),
            Expanded(child: _buildBody()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  /// Banner explicativo cuando se está editando la receta BASE (plantilla)
  /// de un producto con variantes. Aclara que es común, editable y se copia
  /// a las variantes (actuales o nuevas).
  Widget _buildBaseBanner() {
    if (!(widget.tieneVariantes && _varianteId == null)) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.indigo.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.copy_all_outlined, size: 18, color: Colors.indigo.shade400),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                    fontSize: 10.5, color: Colors.indigo.shade900, height: 1.35),
                children: [
                  const TextSpan(
                    text: 'Plantilla base. ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(
                    text:
                        'Definí esta receta común una vez; luego, desde cada variante '
                        '(actual o nueva) usá ',
                  ),
                  const TextSpan(
                    text: '"Copiar receta base"',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(
                    text:
                        ' y ajustá las cantidades. No se vende ni se fabrica directamente.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _verHistorial() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HistorialFabricacionesSheet(
        productoId: widget.productoId,
        productoNombre: widget.productoNombre,
        varianteId: _varianteId,
        varianteNombre: _varianteNombre,
        sedeId: _sedeId,
        sedeNombre: _sedeNombre,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.productoNombre,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          if (_sedes.length > 1)
            CustomDropdown<String>(
              label: 'Sede (toma costos desde aquí)',
              hintText: 'Selecciona sede',
              value: _sedeId,
              borderColor: AppColors.blue1,
              prefixIcon: Icon(Icons.store,
                  size: 16, color: Colors.grey.shade600),
              items: _sedes
                  .map((s) => DropdownItem<String>(
                        value: s.id,
                        label: s.nombre,
                      ))
                  .toList(),
              onChanged: (v) {
                if (v == null || v == _sedeId) return;
                setState(() {
                  _sedeId = v;
                  _sedeNombre = _sedes.firstWhere((s) => s.id == v).nombre;
                });
                _cargar();
              },
            )
          else if (_sedeNombre != null)
            Row(
              children: [
                Icon(Icons.store, size: 12, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  _sedeNombre!,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ],
            ),

          // Selector de variante: cada variante tiene su propia receta.
          if (widget.tieneVariantes && widget.variantes.isNotEmpty) ...[
            const SizedBox(height: 8),
            CustomDropdown<String>(
              label: 'Receta de la variante',
              hintText: 'Selecciona variante',
              // _varianteId null = receta base → mostramos el sentinela.
              value: _varianteId ?? _kBaseReceta,
              borderColor: Colors.indigo,
              prefixIcon: const Icon(Icons.widgets,
                  size: 16, color: Colors.indigo),
              items: [
                // Plantilla común (varianteId null). Se define una vez y se
                // copia a cada variante con "Copiar receta base".
                const DropdownItem<String>(
                  value: _kBaseReceta,
                  label: 'Base (plantilla común)',
                ),
                ...widget.variantes.map((v) => DropdownItem<String>(
                      value: v['id'] as String,
                      label: (v['nombre'] as String?) ?? '—',
                    )),
              ],
              onChanged: (v) {
                final nuevo = (v == null || v == _kBaseReceta) ? null : v;
                if (nuevo == _varianteId) return;
                setState(() => _varianteId = nuevo);
                _cargar();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  color: Colors.red.shade400, size: 40),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _cargar,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_outlined,
                  size: 60, color: Colors.indigo.shade300),
              const SizedBox(height: 12),
              const Text(
                'Sin componentes definidos',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                _varianteId != null
                    ? 'Esta variante aún no tiene receta.\nAgregá insumos o copiá la receta base como punto de partida.'
                    : widget.tieneVariantes
                        ? 'Receta base (plantilla común).\nDefiníla una vez y luego copiala a cada variante.'
                        : 'Agregá los insumos que componen este producto.\nEl costo se calculará sumando cantidad × precio costo.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              ),
              // Atajo para variantes: copiar la receta base (varianteId null)
              // a esta variante y luego ajustar cantidades por talla.
              if (_varianteId != null) ...[
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _copiando ? null : _copiarRecetaBase,
                  icon: _copiando
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.copy_all_outlined, size: 16),
                  label: const Text('Copiar receta base'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.indigo,
                    side: BorderSide(color: Colors.indigo.shade200),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.indigo.shade100, width: 0.6),
      ),
      child: Column(
        children: [
          // Header tabla
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8)),
            ),
            child: Row(
              children: const [
                Expanded(flex: 5, child: _Hcell('Componente')),
                Expanded(flex: 3, child: _Hcell('Cantidad', right: true)),
                Expanded(flex: 3, child: _Hcell('Costo', right: true)),
                Expanded(flex: 3, child: _Hcell('Subtotal', right: true)),
                SizedBox(width: 64),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (_, i) => _buildFila(_items[i]),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(8)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      flex: 11,
                      child: Text(
                        'TOTAL',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'S/ ${_costoTotal.toStringAsFixed(2)}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 64),
                  ],
                ),
                if (_algunoSinCosto)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Algunos componentes no tienen precio costo en esta sede — el total es parcial.',
                      style: TextStyle(
                          fontSize: 9,
                          color: Colors.orange.shade800,
                          fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFila(Map<String, dynamic> item) {
    final cantidad = (item['cantidad'] as num).toDouble();
    final costoUnit = (item['precioCostoUnitario'] as num?)?.toDouble();
    final subtotal = (item['subtotal'] as num?)?.toDouble();
    final um = item['componente']['unidadMedida'] as String?;
    // Costo equivalente en la unidad de compra (derivado = costo × factor).
    final factorCompra =
        (item['componente']['factorCompra'] as num?)?.toDouble();
    final simboloCompra =
        item['componente']['unidadCompraSimbolo'] as String?;
    final costoCompra = (costoUnit != null &&
            factorCompra != null &&
            factorCompra > 0)
        ? costoUnit * factorCompra
        : null;
    return InkWell(
      onTap: () => _editarCantidad(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    () {
                      final nombre = item['componente']['nombre'] as String;
                      final vNom =
                          item['componente']['varianteNombre'] as String?;
                      return vNom != null ? '$nombre — $vNom' : nombre;
                    }(),
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    (item['componente']['codigoEmpresa'] as String?) ?? '',
                    style: TextStyle(
                        fontSize: 9, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                '${cantidad.toStringAsFixed(cantidad == cantidad.truncateToDouble() ? 0 : 3)} ${um ?? ''}',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 11),
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    costoUnit != null
                        ? 'S/ ${costoUnit.toStringAsFixed(2)}'
                        : '—',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11,
                      color: costoUnit == null ? Colors.orange.shade700 : null,
                    ),
                  ),
                  // Equivalente por unidad de compra (informativo).
                  if (costoCompra != null && simboloCompra != null)
                    Text(
                      '≈ S/ ${costoCompra.toStringAsFixed(2)}/$simboloCompra',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                subtotal != null
                    ? 'S/ ${subtotal.toStringAsFixed(2)}'
                    : '—',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: subtotal == null ? Colors.orange.shade700 : null,
                ),
              ),
            ),
            SizedBox(
              width: 64,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: () => _editarCantidad(item),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.edit,
                          size: 16, color: Colors.indigo.shade600),
                    ),
                  ),
                  InkWell(
                    onTap: () => _eliminar(item),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.delete_outline,
                          size: 16, color: Colors.red.shade400),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    // Editando la receta BASE de un producto con variantes: es solo plantilla,
    // no se fabrica ni se aplica costo (eso va por variante).
    final esBasePlantilla = widget.tieneVariantes && _varianteId == null;
    final puedeFabricar = !widget.esInsumo &&
        _items.isNotEmpty &&
        _sedeId != null &&
        !esBasePlantilla;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Agregar',
                    icon: const Icon(Icons.add, size: 16, color: Colors.white),
                    backgroundColor: Colors.indigo.shade600,
                    textColor: Colors.white,
                    enableShadows: false,
                    onPressed: _agregar,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: CustomButton(
                    text: 'Aplicar a Costo',
                    icon: const Icon(Icons.check, size: 16, color: Colors.white),
                    backgroundColor: AppColors.blue1,
                    textColor: Colors.white,
                    enableShadows: false,
                    isLoading: _aplicando,
                    onPressed:
                        (_items.isNotEmpty && _costoTotal > 0 && !esBasePlantilla)
                            ? _aplicarAlProducto
                            : null,
                  ),
                ),
              ],
            ),
            if (puedeFabricar) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Fabricar',
                  icon: const Icon(Icons.precision_manufacturing_outlined,
                      size: 16, color: Colors.white),
                  backgroundColor: Colors.deepPurple.shade600,
                  textColor: Colors.white,
                  enableShadows: false,
                  onPressed: _fabricar,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Abre el dialog de Fabricar. Al confirmar, los stocks de los
  /// componentes se descuentan y se suma `cantidad` al producto final.
  /// Tras éxito refresca la lista (los costos no cambian pero los stocks
  /// de los insumos sí, importante para la próxima fabricación).
  Future<void> _fabricar() async {
    if (_sedeId == null) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _FabricarDialog(
        productoId: widget.productoId,
        productoNombre: widget.productoNombre,
        varianteId: _varianteId,
        varianteNombre: _varianteNombre,
        sedeId: _sedeId!,
        sedeNombre: _sedeNombre,
        componentes: _items,
      ),
    );
    if (result == true && mounted) _cargar();
  }
}

// ─────────────────────────────────────────────────────────────────────────
//   Helpers de UI privados
// ─────────────────────────────────────────────────────────────────────────

class _Hcell extends StatelessWidget {
  final String text;
  final bool right;
  const _Hcell(this.text, {this.right = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: right ? TextAlign.right : TextAlign.left,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Colors.indigo.shade800,
      ),
    );
  }
}

// =========================================================================
// Dialog para agregar componente: search de productos + cantidad.
// =========================================================================

class _AgregarComponenteDialog extends StatefulWidget {
  final String productoId;
  final String? varianteId;
  final String? sedeId;
  final Set<String> idsYaUsados;

  const _AgregarComponenteDialog({
    required this.productoId,
    required this.varianteId,
    required this.sedeId,
    required this.idsYaUsados,
  });

  @override
  State<_AgregarComponenteDialog> createState() =>
      _AgregarComponenteDialogState();
}

class _AgregarComponenteDialogState extends State<_AgregarComponenteDialog> {
  final DioClient _dio = locator<DioClient>();
  final _searchCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController();

  bool _searching = false;
  List<Map<String, dynamic>> _results = const [];
  Map<String, dynamic>? _selected;
  bool _saving = false;

  // Datos del componente seleccionado en la sede actual (costo + stockId)
  String? _selectedStockId;
  double? _selectedCosto;
  int? _selectedStockActual;
  bool _loadingStockInfo = false;

  // Conversión de unidad: la receta se guarda en la unidad ATÓMICA del insumo,
  // pero el usuario puede ingresar en la unidad de compra (ej. metros) y el
  // factor convierte a la atómica (ej. cm). Materiales continuos (cuero,
  // pegamento) se modelan así para que el consumo sea entero.
  double? _factorCompra; // cuántas unidades atómicas trae 1 de compra
  String? _simboloCompra; // unidad de compra (ej. "m")
  String? _simboloAtomico; // unidad base/atómica (ej. "cm")

  // Variantes del INSUMO (si las tiene). La receta apunta a una variante
  // concreta (ej. "Planta T20 Niño") y su stock/costo vive en esa variante.
  List<Map<String, dynamic>> _variantesInsumo = const [];
  String? _componenteVarianteId;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _cantidadCtrl.dispose();
    super.dispose();
  }

  Future<void> _buscar(String q) async {
    if (q.trim().length < 2) {
      setState(() => _results = const []);
      return;
    }
    setState(() => _searching = true);
    try {
      final resp = await _dio.get(
        '/productos',
        queryParameters: {
          'search': q.trim(),
          'limit': 12,
          'isActive': 'true',
        },
      );
      final data = resp.data;
      final list = data is List
          ? data
          : (data is Map ? (data['data'] ?? data['items'] ?? []) : []);
      if (!mounted) return;
      setState(() {
        _results = (list as List)
            .cast<Map<String, dynamic>>()
            .where((p) =>
                p['id'] != widget.productoId &&
                // Un insumo con variantes se puede re-elegir para agregar otra
                // de sus variantes (el backend rechaza la combinación exacta
                // duplicada). Uno sin variantes ya usado se oculta.
                !(widget.idsYaUsados.contains(p['id']) &&
                    p['tieneVariantes'] != true))
            .toList();
        _searching = false;
      });
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  /// Tras seleccionar un componente, cargar su stock+costo en la sede para
  /// que el usuario vea de cuánto es el costo unitario y pueda corregirlo
  /// si está mal (caso típico: usuario tipeó total de compra en lugar de
  /// unitario). Si no hay sede o no hay stock, devuelve nulls.
  Future<void> _cargarInfoSeleccionado() async {
    if (_selected == null) return;
    setState(() {
      _loadingStockInfo = true;
      _selectedStockId = null;
      _selectedCosto = null;
      _selectedStockActual = null;
      _factorCompra = null;
      _simboloCompra = null;
      _simboloAtomico = null;
      _variantesInsumo = const [];
      _componenteVarianteId = null;
    });
    try {
      // Detalle del insumo: factor/símbolos (no dependen de sede) + variantes.
      final detResp = await _dio.get('/productos/${_selected!['id']}');
      final det = detResp.data as Map<String, dynamic>?;
      final tieneVariantes = det?['tieneVariantes'] == true;
      final variantes =
          (det?['variantes'] as List?)?.cast<Map<String, dynamic>>() ??
              const [];
      if (!mounted) return;
      setState(() {
        final fc = det?['factorCompra'];
        _factorCompra = fc is num
            ? fc.toDouble()
            : (fc is String ? double.tryParse(fc) : null);
        _simboloCompra = _simboloDeUnidad(det?['unidadCompra']);
        _simboloAtomico = _simboloDeUnidad(det?['unidadMedida']);
        _variantesInsumo = tieneVariantes ? variantes : const [];
      });
      // Si el insumo tiene variantes, su stock vive en la variante: esperamos
      // a que el usuario elija una. Si no, cargamos el del producto base.
      if (_variantesInsumo.isEmpty) {
        await _fetchCostoStock(varianteId: null);
      } else {
        if (mounted) setState(() => _loadingStockInfo = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingStockInfo = false);
    }
  }

  /// Carga costo+stock del insumo en la sede actual, por variante si se pasa
  /// (su stock vive en la variante) o por producto base si no.
  Future<void> _fetchCostoStock({required String? varianteId}) async {
    if (widget.sedeId == null) {
      if (mounted) setState(() => _loadingStockInfo = false);
      return;
    }
    setState(() {
      _loadingStockInfo = true;
      _selectedStockId = null;
      _selectedCosto = null;
      _selectedStockActual = null;
    });
    try {
      final url = varianteId != null
          ? '/producto-stock/variante/$varianteId/sede/${widget.sedeId}'
          : '/producto-stock/producto/${_selected!['id']}/sede/${widget.sedeId}';
      final resp = await _dio.get(url);
      final data = resp.data as Map<String, dynamic>?;
      if (!mounted) return;
      setState(() {
        _selectedStockId = data?['id'] as String?;
        final costoRaw = data?['precioCosto'];
        _selectedCosto = costoRaw is num
            ? costoRaw.toDouble()
            : (costoRaw is String ? double.tryParse(costoRaw) : null);
        _selectedStockActual = (data?['stockActual'] as num?)?.toInt();
        _loadingStockInfo = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingStockInfo = false);
    }
  }

  void _onVarianteComponenteChanged(String? varianteId) {
    setState(() => _componenteVarianteId = varianteId);
    if (varianteId != null) _fetchCostoStock(varianteId: varianteId);
  }

  /// Resuelve el símbolo de una unidad (local > personalizado > maestra).
  String? _simboloDeUnidad(dynamic um) {
    if (um is! Map) return null;
    final maestra = um['unidadMaestra'];
    return (um['simboloLocal'] ??
            um['simboloPersonalizado'] ??
            (maestra is Map ? maestra['simbolo'] : null)) as String?;
  }

  /// Abre el conversor: ingresar en unidad de compra (ej. metros) → guarda
  /// la cantidad en unidad atómica (ej. cm) en el campo de cantidad.
  Future<void> _abrirConversorUnidad() async {
    final factor = _factorCompra;
    if (factor == null || factor <= 0) return;
    final atomico = await showDialog<double>(
      context: context,
      builder: (_) => _ConversorUnidadDialog(
        factor: factor,
        simboloCompra: _simboloCompra ?? '',
        simboloAtomico: _simboloAtomico ?? '',
      ),
    );
    if (atomico == null) return;
    _cantidadCtrl.text =
        atomico % 1 == 0 ? atomico.toStringAsFixed(0) : atomico.toStringAsFixed(4);
    setState(() {});
  }

  /// Abre la calculadora "total ÷ cantidad" y, si el usuario aplica,
  /// actualiza el precioCosto del INSUMO (no del componente row) en la
  /// sede actual via PATCH /producto-stock/:id/precios.
  Future<void> _recalcularCostoInsumo() async {
    if (_selectedStockId == null) return;
    final nuevo = await showDialog<double>(
      context: context,
      builder: (_) => const _CalculadoraLoteDialogInline(),
    );
    if (nuevo == null) return;
    try {
      await _dio.patch(
        '/producto-stock/$_selectedStockId/precios',
        data: {
          'precioCosto': double.parse(nuevo.toStringAsFixed(2)),
          'tipoCambio': 'CORRECCION',
          'razon': 'Corrección de costo unitario desde page de componentes',
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Costo actualizado: S/ ${nuevo.toStringAsFixed(2)}/u'),
          backgroundColor: Colors.green,
        ),
      );
      // Refresca solo costo/stock (preservando la variante elegida).
      _fetchCostoStock(varianteId: _componenteVarianteId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildInfoCostoInsumo() {
    if (_loadingStockInfo) {
      return const SizedBox(
        height: 14,
        child: Center(
          child: SizedBox(
            width: 12, height: 12,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
        ),
      );
    }
    if (_selectedCosto == null && _selectedStockId == null) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_outlined,
                size: 14, color: Colors.amber.shade800),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Este componente no tiene stock en la sede actual. Compralo o créalo manualmente para poder usarlo.',
                style: TextStyle(
                    fontSize: 10, color: Colors.amber.shade900),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.attach_money,
              size: 14, color: Colors.blue.shade700),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedCosto != null
                      ? 'Costo unitario actual: S/ ${_selectedCosto!.toStringAsFixed(2)}'
                          '${_simboloAtomico != null ? ' / $_simboloAtomico' : ''}'
                      : 'Sin costo unitario',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade900,
                  ),
                ),
                // Costo equivalente en la unidad de compra (derivado:
                // costoBase × factorCompra). Solo informativo.
                if (_selectedCosto != null &&
                    _factorCompra != null &&
                    _factorCompra! > 0 &&
                    _simboloCompra != null)
                  Text(
                    '≈ S/ ${(_selectedCosto! * _factorCompra!).toStringAsFixed(2)} / $_simboloCompra',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700),
                  ),
                if (_selectedStockActual != null)
                  Text(
                    'Stock: $_selectedStockActual unidades',
                    style: TextStyle(
                        fontSize: 9, color: Colors.blue.shade700),
                  ),
              ],
            ),
          ),
          InkWell(
            onTap: _recalcularCostoInsumo,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Icon(Icons.calculate_outlined,
                      size: 12, color: Colors.blue.shade700),
                  const SizedBox(width: 2),
                  Text(
                    'Recalcular',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.blue.shade700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _guardar() async {
    if (_selected == null) return;
    if (_variantesInsumo.isNotEmpty && _componenteVarianteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elegí la variante del insumo')),
      );
      return;
    }
    final cantidad =
        double.tryParse(_cantidadCtrl.text.replaceAll(',', '.')) ?? 0;
    if (cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresá una cantidad > 0')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _dio.post(
        '/productos/${widget.productoId}/componentes',
        data: {
          'componenteId': _selected!['id'],
          'cantidad': cantidad,
          if (widget.varianteId != null) 'varianteId': widget.varianteId,
          if (_componenteVarianteId != null)
            'componenteVarianteId': _componenteVarianteId,
        },
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is DioException
                ? (e.response?.data?['message']?.toString() ?? 'Error')
                : e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StyledDialog(
      accentColor: Colors.indigo,
      icon: Icons.add_box_outlined,
      titulo: 'Agregar componente',
      actions: [
        Expanded(
          child: CustomButton(
            text: 'Cancelar',
            isOutlined: true,
            textColor: Colors.indigo,
            borderColor: Colors.indigo.withValues(alpha: 0.4),
            enableShadows: false,
            height: 36,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        if (_selected != null)
          Expanded(
            child: CustomButton(
              text: 'Agregar',
              backgroundColor: Colors.indigo,
              textColor: Colors.white,
              enableShadows: false,
              isLoading: _saving,
              height: 36,
              icon: const Icon(Icons.check, size: 14, color: Colors.white),
              onPressed: _guardar,
            ),
          ),
      ],
      content: [
        if (_selected == null) ...[
          CustomSearchField(
            controller: _searchCtrl,
            hintText: 'Buscar producto (insumo)…',
            borderColor: Colors.indigo,
            debounceDelay: const Duration(milliseconds: 350),
            onChanged: _buscar,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 240,
            child: _searching
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2))
                : _results.isEmpty
                    ? Center(
                        child: Text(
                          _searchCtrl.text.trim().length < 2
                              ? 'Escribí al menos 2 caracteres'
                              : 'Sin resultados',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (_, i) {
                          final p = _results[i];
                          return ListTile(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            title: Text(
                              p['nombre']?.toString() ?? '',
                              style: const TextStyle(fontSize: 12),
                            ),
                            subtitle: Text(
                              p['codigoEmpresa']?.toString() ?? '',
                              style: const TextStyle(fontSize: 10),
                            ),
                            onTap: () {
                              setState(() => _selected = p);
                              _cargarInfoSeleccionado();
                            },
                          );
                        },
                      ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selected!['nombre']?.toString() ?? '',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _selected!['codigoEmpresa']?.toString() ?? '',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  tooltip: 'Cambiar',
                  onPressed: () => setState(() {
                    _selected = null;
                    _selectedStockId = null;
                    _selectedCosto = null;
                    _selectedStockActual = null;
                    _factorCompra = null;
                    _simboloCompra = null;
                    _simboloAtomico = null;
                    _variantesInsumo = const [];
                    _componenteVarianteId = null;
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Si el insumo tiene variantes, hay que elegir CUÁL se usa en la
          // receta (su stock/costo vive en la variante).
          if (_variantesInsumo.isNotEmpty) ...[
            CustomDropdown<String>(
              label: 'Variante del insumo *',
              hintText: 'Elegí la variante',
              borderColor: Colors.indigo,
              value: _componenteVarianteId,
              items: _variantesInsumo
                  .map((v) => DropdownItem<String>(
                        value: v['id'] as String,
                        label: (v['nombre'] ?? v['sku'] ?? v['id']).toString(),
                      ))
                  .toList(),
              onChanged: _onVarianteComponenteChanged,
            ),
            const SizedBox(height: 8),
          ],
          // Info de costo del insumo en la sede actual. Permite detectar
          // de un vistazo si el costo unitario está mal cargado (caso
          // típico: total de compra en lugar de unitario) y corregirlo.
          _buildInfoCostoInsumo(),
          const SizedBox(height: 12),
          CurrencyTextField(
            label: _simboloAtomico != null
                ? 'Cantidad por unidad fabricada ($_simboloAtomico)'
                : 'Cantidad por unidad fabricada',
            controller: _cantidadCtrl,
            borderColor: AppColors.blue1,
            allowZero: false,
          ),
          // Conversor: solo si el insumo tiene factor de compra (ej. se compra
          // por metros y el stock vive en cm).
          if (_factorCompra != null &&
              _factorCompra! > 1 &&
              _simboloCompra != null) ...[
            const SizedBox(height: 4),
            InkWell(
              onTap: _abrirConversorUnidad,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.swap_vert, size: 13, color: AppColors.blue1),
                    const SizedBox(width: 2),
                    Text(
                      'Convertir desde $_simboloCompra',
                      style: TextStyle(
                        fontSize: 9,
                        color: AppColors.blue1,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              'En unidad del componente. Ej: 0.05 si compraste por KG y usás 50g.',
              style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ],
    );
  }
}

// =========================================================================
// Dialog "Fabricar N": preview de consumo + validación cliente + POST.
// =========================================================================

class _FabricarDialog extends StatefulWidget {
  final String productoId;
  final String productoNombre;
  final String? varianteId;
  final String? varianteNombre;
  final String sedeId;
  final String? sedeNombre;

  /// Filas tal como las devuelve GET /productos/:id/componentes (con
  /// `cantidad`, `componente.nombre`, `componente.unidadMedida`).
  final List<Map<String, dynamic>> componentes;

  const _FabricarDialog({
    required this.productoId,
    required this.productoNombre,
    required this.varianteId,
    required this.varianteNombre,
    required this.sedeId,
    required this.sedeNombre,
    required this.componentes,
  });

  @override
  State<_FabricarDialog> createState() => _FabricarDialogState();
}

class _FabricarDialogState extends State<_FabricarDialog> {
  final DioClient _dio = locator<DioClient>();
  final _cantidadCtrl = TextEditingController(text: '1');
  final _observacionesCtrl = TextEditingController();
  final _manoObraCtrl = TextEditingController();
  bool _fabricando = false;
  // Modo "registrar producción previa": el stock terminado YA existe, solo
  // se descuentan los insumos que esas unidades consumieron.
  bool _soloConsumir = false;
  String? _error;

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    _observacionesCtrl.dispose();
    _manoObraCtrl.dispose();
    super.dispose();
  }

  int get _cantidad {
    return int.tryParse(_cantidadCtrl.text.trim()) ?? 0;
  }

  double get _manoObra =>
      double.tryParse(_manoObraCtrl.text.replaceAll(',', '.')) ?? 0;

  /// Costo estimado de insumos del lote = Σ(subtotal por unidad) × cantidad.
  /// `subtotal` viene del GET /componentes (cantidad × precioCosto por unidad).
  double get _costoInsumosLote {
    double total = 0;
    for (final item in widget.componentes) {
      final sub = (item['subtotal'] as num?)?.toDouble();
      if (sub != null) total += sub;
    }
    return total * _cantidad;
  }

  /// Para cada componente: cuánto consume × N + si la cantidad consumida
  /// es entera (stock se maneja en Int, sino el backend rechaza) + cuánto
  /// hay disponible (de stockDisponible que devuelve el GET /componentes).
  List<_PreviewLinea> get _preview {
    return widget.componentes.map((item) {
      final cantidadPorUnidad = (item['cantidad'] as num).toDouble();
      final consumido = cantidadPorUnidad * _cantidad;
      final redondeado = consumido.round();
      final esEntero = (consumido - redondeado).abs() < 1e-6;
      final stock = (item['stockDisponible'] as num?)?.toInt();
      final excede = stock != null && esEntero && redondeado > stock;
      final comp = item['componente'] as Map?;
      final fcRaw = comp?['factorCompra'];
      final factorCompra = fcRaw is num
          ? fcRaw.toDouble()
          : (fcRaw is String ? double.tryParse(fcRaw) : null);
      return _PreviewLinea(
        nombre: (comp?['nombre'] as String?) ?? '',
        unidadMedida: (comp?['unidadMedida'] as String?) ?? '',
        factorCompra: factorCompra,
        simboloCompra: comp?['unidadCompraSimbolo'] as String?,
        cantidadPorUnidad: cantidadPorUnidad,
        cantidadConsumida: consumido,
        esEntero: esEntero,
        stockDisponible: stock,
        excedeStock: excede,
      );
    }).toList();
  }

  bool get _hayFraccionarios => _preview.any((p) => !p.esEntero);
  bool get _hayInsuficiencia => _preview.any((p) => p.excedeStock);

  Future<void> _confirmar() async {
    if (_cantidad < 1) {
      setState(() => _error = 'Ingresá una cantidad ≥ 1');
      return;
    }
    if (_hayFraccionarios) {
      setState(() => _error =
          'Algún componente requiere cantidad fraccionaria. Cambia la unidad de medida (ej: KG→GR) o ajusta el lote.');
      return;
    }
    if (_hayInsuficiencia) {
      setState(() => _error =
          'Stock insuficiente en algún componente. Reducí la cantidad a fabricar o reabastecé el insumo.');
      return;
    }
    setState(() {
      _fabricando = true;
      _error = null;
    });
    try {
      final resp = await _dio.post(
        '/productos/${widget.productoId}/componentes/fabricar',
        data: {
          'sedeId': widget.sedeId,
          'cantidad': _cantidad,
          if (widget.varianteId != null) 'varianteId': widget.varianteId,
          if (_soloConsumir) 'soloConsumirInsumos': true,
          if (!_soloConsumir && _manoObra > 0) 'costoManoObra': _manoObra,
          if (_observacionesCtrl.text.trim().isNotEmpty)
            'observaciones': _observacionesCtrl.text.trim(),
        },
      );
      final data = resp.data as Map<String, dynamic>?;
      if (!mounted) return;
      Navigator.pop(context, true);
      final costoAnt = (data?['precioCostoAnterior'] as num?)?.toDouble();
      final costoNuevo = (data?['precioCostoNuevo'] as num?)?.toDouble();
      final mostrarCosto = data?['costoActualizado'] == true &&
          costoNuevo != null &&
          costoNuevo != costoAnt;
      final String base;
      final String extraCosto;
      if (_soloConsumir) {
        // Solo se descontaron insumos; no hay stock nuevo ni cambio de costo.
        base =
            'Insumos descontados por $_cantidad unidad(es) ya fabricada(s) '
            '· lote ${data?['numeroDocumento'] ?? '—'}';
        extraCosto = '';
      } else {
        base =
            'Fabricación OK · ${data?['cantidadProducida'] ?? _cantidad} '
            'unidad(es) · stock nuevo: ${data?['stockFinalNuevo'] ?? '—'} '
            '· lote ${data?['numeroDocumento'] ?? '—'}';
        extraCosto = mostrarCosto
            ? '\nCosto: S/ ${costoAnt?.toStringAsFixed(2) ?? '—'} → S/ ${costoNuevo.toStringAsFixed(2)} (promedio ponderado)'
            : (data?['razonCostoNoActualizado'] != null
                ? '\n⚠️ Costo NO actualizado: ${data!['razonCostoNoActualizado']}'
                : '');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$base$extraCosto'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      String msg;
      if (e is DioException) {
        final body = e.response?.data;
        if (body is Map<String, dynamic>) {
          msg = (body['message']?.toString()) ?? 'Error al fabricar';
          // Si el backend devuelve faltantes/conflictivos, los anexamos
          final faltantes = body['faltantes'];
          if (faltantes is List && faltantes.isNotEmpty) {
            msg += '\n\nFaltantes:\n${faltantes.map((f) => '- ${f['nombre']}: necesita ${f['requerido']}, hay ${f['disponible']}').join('\n')}';
          }
        } else {
          msg = e.message ?? 'Error al fabricar';
        }
      } else {
        msg = e.toString();
      }
      setState(() {
        _fabricando = false;
        _error = msg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final puedeConfirmar = _cantidad >= 1 &&
        !_hayFraccionarios &&
        !_hayInsuficiencia &&
        !_fabricando;
    return StyledDialog(
      accentColor: Colors.deepPurple,
      icon: Icons.precision_manufacturing_outlined,
      titulo: 'Fabricar',
      barrierDismissible: !_fabricando,
      actions: [
        Expanded(
          child: CustomButton(
            text: 'Cancelar',
            isOutlined: true,
            textColor: Colors.deepPurple,
            borderColor: Colors.deepPurple.withValues(alpha: 0.4),
            enableShadows: false,
            height: 36,
            onPressed: _fabricando ? null : () => Navigator.pop(context),
          ),
        ),
        Expanded(
          flex: 2,
          child: CustomButton(
            text: _soloConsumir ? 'Registrar consumo' : 'Fabricar',
            backgroundColor: Colors.deepPurple.shade600,
            textColor: Colors.white,
            enableShadows: false,
            isLoading: _fabricando,
            height: 36,
            icon: Icon(
                _soloConsumir
                    ? Icons.remove_circle_outline
                    : Icons.precision_manufacturing_outlined,
                size: 14,
                color: Colors.white),
            onPressed: puedeConfirmar ? _confirmar : null,
          ),
        ),
      ],
      content: [
        // Subtítulo: producto (+ variante) + sede de la que se descuentan
        // los insumos.
        Text(
          widget.varianteNombre != null
              ? '${widget.productoNombre} · ${widget.varianteNombre}'
              : widget.productoNombre,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (widget.sedeNombre != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              children: [
                Icon(Icons.store, size: 11, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  widget.sedeNombre!,
                  style:
                      TextStyle(fontSize: 10, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        const SizedBox(height: 14),
        CustomText(
          controller: _cantidadCtrl,
          label: _soloConsumir
              ? 'Unidades ya fabricadas (a registrar)'
              : 'Cantidad a fabricar (unidades)',
          hintText: 'Ej. 10',
          fieldType: FieldType.number,
          borderColor: Colors.deepPurple,
          onChanged: (_) => setState(() => _error = null),
        ),
        const SizedBox(height: 10),
        // Toggle: registrar producción previa (solo descontar insumos).
        InkWell(
          onTap: () => setState(() {
            _soloConsumir = !_soloConsumir;
            _error = null;
          }),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color:
                  _soloConsumir ? Colors.indigo.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _soloConsumir
                    ? Colors.indigo.shade200
                    : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: _soloConsumir,
                    onChanged: (v) => setState(() {
                      _soloConsumir = v ?? false;
                      _error = null;
                    }),
                    activeColor: Colors.indigo,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Solo descontar insumos',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'El producto ya tiene este stock (producción previa). '
                        'No suma stock ni cambia el costo.',
                        style: TextStyle(
                            fontSize: 9, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (preview.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(
                        'Insumo',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.deepPurple.shade800,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        'Consumirá',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.deepPurple.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 70,
                      child: Text(
                        'Stock',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.deepPurple.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border:
                          Border.all(color: Colors.deepPurple.shade100),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      itemCount: preview.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 6,
                        color: Colors.deepPurple.shade100,
                      ),
                      itemBuilder: (_, i) {
                        final p = preview[i];
                        final mostrarRojo = !p.esEntero || p.excedeStock;
                        return Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: Text(
                                p.nombre,
                                style: const TextStyle(fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${_fmt(p.cantidadConsumida)} ${p.unidadMedida}',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: mostrarRojo
                                          ? Colors.red.shade700
                                          : Colors.deepPurple.shade900,
                                    ),
                                  ),
                                  if (p.tieneConversion)
                                    Text(
                                      '≈ ${p.conversion(p.cantidadConsumida)}',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 86,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    p.stockDisponible != null
                                        ? '/ ${p.stockDisponible} ${p.unidadMedida}'
                                        : '/ —',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: p.excedeStock
                                          ? Colors.red.shade700
                                          : Colors.grey.shade600,
                                      fontWeight: p.excedeStock
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  if (p.tieneConversion &&
                                      p.stockDisponible != null)
                                    Text(
                                      '(${p.conversion(p.stockDisponible!.toDouble())})',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                if (_hayFraccionarios) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber,
                            size: 14, color: Colors.red.shade700),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Algún componente requiere cantidad fraccionaria. '
                            'Cambia la unidad de medida del componente '
                            '(ej: KG→GR) o ajusta el lote para que sea entero.',
                            style: TextStyle(
                                fontSize: 10, color: Colors.red.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_hayInsuficiencia && !_hayFraccionarios) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 14, color: Colors.orange.shade800),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Stock insuficiente en al menos un insumo. '
                            'Reducí el lote o reabastecé los marcados en rojo.',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
        // Mano de obra del lote (no aplica en modo solo-consumir insumos).
        if (!_soloConsumir) ...[
          const SizedBox(height: 12),
          CustomText(
            controller: _manoObraCtrl,
            label: 'Mano de obra (total del lote, opcional)',
            hintText: 'Ej. 150',
            fieldType: FieldType.number,
            borderColor: Colors.deepPurple,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 6),
          // Costo estimado del lote: insumos + mano de obra.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.deepPurple.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.payments_outlined,
                    size: 14, color: Colors.deepPurple.shade400),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Costo del lote ≈ insumos S/ ${_costoInsumosLote.toStringAsFixed(2)}'
                    '${_manoObra > 0 ? ' + M.O. S/ ${_manoObra.toStringAsFixed(2)}' : ''}'
                    ' = S/ ${(_costoInsumosLote + _manoObra).toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 10, color: Colors.deepPurple.shade900),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        CustomText(
          controller: _observacionesCtrl,
          label: 'Observaciones (opcional)',
          hintText: 'Ej: lote del día, encargo cliente X…',
          maxLines: 2,
          borderColor: Colors.deepPurple,
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text(
              _error!,
              style: TextStyle(fontSize: 10, color: Colors.red.shade900),
            ),
          ),
        ],
      ],
    );
  }

  String _fmt(double n) {
    if ((n - n.truncateToDouble()).abs() < 1e-6) {
      return n.toStringAsFixed(0);
    }
    return n.toStringAsFixed(3);
  }
}

class _PreviewLinea {
  final String nombre;
  final String unidadMedida;
  final double? factorCompra; // unidades atómicas por 1 de compra
  final String? simboloCompra; // unidad de compra (ej. "m")
  final double cantidadPorUnidad;
  final double cantidadConsumida;
  final bool esEntero;
  final int? stockDisponible;
  final bool excedeStock;

  _PreviewLinea({
    required this.nombre,
    required this.unidadMedida,
    this.factorCompra,
    this.simboloCompra,
    required this.cantidadPorUnidad,
    required this.cantidadConsumida,
    required this.esEntero,
    required this.stockDisponible,
    required this.excedeStock,
  });

  bool get tieneConversion =>
      factorCompra != null && factorCompra! > 1 && simboloCompra != null;

  /// Convierte una cantidad atómica a la unidad de compra (ej. 200 cm → 2 m).
  String conversion(double cantidadAtomica) {
    final v = cantidadAtomica / factorCompra!;
    final s = v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
    return '$s $simboloCompra';
  }
}

/// Conversor de unidad: el usuario ingresa la cantidad en la unidad de compra
/// (ej. metros) y devuelve la cantidad equivalente en la unidad atómica del
/// insumo (ej. cm) = valor × factor. Sirve para modelar materiales continuos
/// (cuero, pegamento) cuyo stock se maneja en unidades enteras pequeñas.
class _ConversorUnidadDialog extends StatefulWidget {
  final double factor;
  final String simboloCompra;
  final String simboloAtomico;

  const _ConversorUnidadDialog({
    required this.factor,
    required this.simboloCompra,
    required this.simboloAtomico,
  });

  @override
  State<_ConversorUnidadDialog> createState() => _ConversorUnidadDialogState();
}

class _ConversorUnidadDialogState extends State<_ConversorUnidadDialog> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  double? _atomico;

  @override
  void initState() {
    super.initState();
    // Reemplaza autofocus: true del TextField original.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _recalcular() {
    final v = double.tryParse(_ctrl.text.replaceAll(',', '.'));
    setState(() {
      _atomico = (v != null && v > 0) ? v * widget.factor : null;
    });
  }

  String _fmt(double n) =>
      n % 1 == 0 ? n.toStringAsFixed(0) : n.toStringAsFixed(4);

  @override
  Widget build(BuildContext context) {
    return StyledDialog(
      accentColor: AppColors.blue1,
      icon: Icons.swap_vert,
      titulo: 'Convertir a ${widget.simboloAtomico}',
      actions: [
        Expanded(
          child: CustomButton(
            text: 'Cancelar',
            isOutlined: true,
            textColor: AppColors.blue1,
            borderColor: AppColors.blue1.withValues(alpha: 0.4),
            enableShadows: false,
            height: 36,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        Expanded(
          child: CustomButton(
            text: 'Aplicar',
            backgroundColor: AppColors.blue1,
            textColor: Colors.white,
            enableShadows: false,
            height: 36,
            onPressed: _atomico != null
                ? () => Navigator.pop(context, _atomico)
                : null,
          ),
        ),
      ],
      content: [
        Text(
          '1 ${widget.simboloCompra} = ${_fmt(widget.factor)} ${widget.simboloAtomico}. '
          'Ingresá cuánto usa por unidad fabricada en ${widget.simboloCompra} y lo '
          'convierto a ${widget.simboloAtomico} (la unidad del stock).',
          style: const TextStyle(fontSize: 11),
        ),
        const SizedBox(height: 12),
        CustomText(
          controller: _ctrl,
          focusNode: _focusNode,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          label: 'Cantidad en ${widget.simboloCompra}',
          hintText: 'Ej. 0.30',
          onChanged: (_) => _recalcular(),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _atomico != null
                ? Colors.green.shade50
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _atomico != null
                  ? Colors.green.shade300
                  : Colors.grey.shade300,
            ),
          ),
          child: Column(
            children: [
              Text('Equivale a:',
                  style:
                      TextStyle(fontSize: 10, color: Colors.grey.shade700)),
              Text(
                _atomico != null
                    ? '${_fmt(_atomico!)} ${widget.simboloAtomico}'
                    : '—',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _atomico != null
                      ? Colors.green.shade800
                      : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Mini-dialog interno (mismo patrón que la calculadora del Configurar
/// Precios). StatefulWidget aparte para que los controllers no se
/// disposen antes de la última build.
class _CalculadoraLoteDialogInline extends StatefulWidget {
  const _CalculadoraLoteDialogInline();

  @override
  State<_CalculadoraLoteDialogInline> createState() =>
      _CalculadoraLoteDialogInlineState();
}

class _CalculadoraLoteDialogInlineState
    extends State<_CalculadoraLoteDialogInline> {
  final _cantidadCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  final _cantidadFocusNode = FocusNode();
  double? _unitario;

  @override
  void initState() {
    super.initState();
    // Reemplaza autofocus: true del TextField original.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _cantidadFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    _totalCtrl.dispose();
    _cantidadFocusNode.dispose();
    super.dispose();
  }

  void _recalcular() {
    final cant = double.tryParse(_cantidadCtrl.text.replaceAll(',', '.'));
    final tot = double.tryParse(_totalCtrl.text.replaceAll(',', '.'));
    setState(() {
      _unitario = (cant != null && cant > 0 && tot != null && tot > 0)
          ? tot / cant
          : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StyledDialog(
      accentColor: Colors.green.shade700,
      icon: Icons.calculate_outlined,
      titulo: 'Recalcular costo unitario',
      actions: [
        Expanded(
          child: CustomButton(
            text: 'Cancelar',
            isOutlined: true,
            textColor: Colors.green.shade700,
            borderColor: Colors.green.withValues(alpha: 0.4),
            enableShadows: false,
            height: 36,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        Expanded(
          child: CustomButton(
            text: 'Aplicar',
            backgroundColor: Colors.green.shade600,
            textColor: Colors.white,
            enableShadows: false,
            height: 36,
            onPressed: _unitario != null
                ? () => Navigator.pop(context, _unitario)
                : null,
          ),
        ),
      ],
      content: [
        const Text(
          'Si cargaste mal el costo del insumo (tipeaste el TOTAL en vez del unitario), corregilo acá. Ingresá la cantidad comprada y el total pagado.',
          style: TextStyle(fontSize: 11),
        ),
        const SizedBox(height: 12),
        CustomText(
          controller: _cantidadCtrl,
          focusNode: _cantidadFocusNode,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          label: 'Cantidad comprada',
          hintText: 'Ej. 20',
          onChanged: (_) => _recalcular(),
        ),
        const SizedBox(height: 8),
        CustomText(
          controller: _totalCtrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          label: 'Total pagado (S/)',
          hintText: 'Ej. 200',
          onChanged: (_) => _recalcular(),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _unitario != null
                ? Colors.green.shade50
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _unitario != null
                  ? Colors.green.shade300
                  : Colors.grey.shade300,
            ),
          ),
          child: Column(
            children: [
              Text(
                'Costo por unidad:',
                style:
                    TextStyle(fontSize: 10, color: Colors.grey.shade700),
              ),
              Text(
                _unitario != null
                    ? 'S/ ${_unitario!.toStringAsFixed(2)}'
                    : '—',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _unitario != null
                      ? Colors.green.shade800
                      : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =========================================================================
// BottomSheet "Historial de fabricaciones": lista de lotes PROD-* + tap
// para ver el detalle (insumos consumidos) on-demand.
// =========================================================================

class _HistorialFabricacionesSheet extends StatefulWidget {
  final String productoId;
  final String productoNombre;
  final String? varianteId;
  final String? varianteNombre;
  final String? sedeId;
  final String? sedeNombre;

  const _HistorialFabricacionesSheet({
    required this.productoId,
    required this.productoNombre,
    required this.varianteId,
    required this.varianteNombre,
    required this.sedeId,
    required this.sedeNombre,
  });

  @override
  State<_HistorialFabricacionesSheet> createState() =>
      _HistorialFabricacionesSheetState();
}

class _HistorialFabricacionesSheetState
    extends State<_HistorialFabricacionesSheet> {
  final DioClient _dio = locator<DioClient>();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _lotes = const [];
  final Set<String> _expandidos = {};
  final Map<String, Map<String, dynamic>> _detalles = {};
  final Set<String> _cargandoDetalle = {};
  final Set<String> _detalleError = {};

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await _dio.get(
        '/productos/${widget.productoId}/componentes/fabricaciones',
        queryParameters: {
          if (widget.sedeId != null) 'sedeId': widget.sedeId,
          if (widget.varianteId != null) 'varianteId': widget.varianteId,
          'limit': 50,
        },
      );
      if (!mounted) return;
      setState(() {
        _lotes = (resp.data as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is DioException
            ? (e.response?.data?['message']?.toString() ?? e.message ?? 'Error')
            : e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _toggleExpand(String numeroDocumento) async {
    if (_expandidos.contains(numeroDocumento)) {
      setState(() => _expandidos.remove(numeroDocumento));
      return;
    }
    setState(() => _expandidos.add(numeroDocumento));
    if (_detalles.containsKey(numeroDocumento)) return;
    await _cargarDetalle(numeroDocumento);
  }

  Future<void> _cargarDetalle(String numeroDocumento) async {
    setState(() {
      _cargandoDetalle.add(numeroDocumento);
      _detalleError.remove(numeroDocumento);
    });
    try {
      final resp = await _dio.get(
        '/productos/${widget.productoId}/componentes/fabricaciones/$numeroDocumento',
      );
      if (!mounted) return;
      setState(() {
        _detalles[numeroDocumento] = resp.data as Map<String, dynamic>;
        _cargandoDetalle.remove(numeroDocumento);
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _cargandoDetalle.remove(numeroDocumento);
          _detalleError.add(numeroDocumento);
        });
      }
    }
  }

  String _fechaCorta(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      final dd = d.day.toString().padLeft(2, '0');
      final mm = d.month.toString().padLeft(2, '0');
      final hh = d.hour.toString().padLeft(2, '0');
      final mi = d.minute.toString().padLeft(2, '0');
      return '$dd/$mm/${d.year} $hh:$mi';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      height: size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(Icons.history,
                    color: Colors.deepPurple.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Historial de fabricaciones',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.productoNombre +
                            (widget.sedeNombre != null
                                ? ' · ${widget.sedeNombre}'
                                : ''),
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.shade700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 40, color: Colors.red.shade400),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                  onPressed: _cargar, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }
    if (_lotes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_outlined,
                  size: 50, color: Colors.deepPurple.shade300),
              const SizedBox(height: 8),
              const Text('Sin fabricaciones registradas',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                widget.sedeId != null
                    ? 'No hay lotes producidos en esta sede.'
                    : 'Aún no se fabricó este producto.',
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _lotes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _buildLote(_lotes[i]),
    );
  }

  Widget _buildLote(Map<String, dynamic> lote) {
    final numero = lote['numeroDocumento'] as String? ?? '';
    final cantidad = lote['cantidadProducida'] as num?;
    final stockNuevo = lote['stockNuevo'] as num?;
    final costoLote = (lote['costoLote'] as num?)?.toDouble();
    final costoUnitario = (lote['costoUnitario'] as num?)?.toDouble();
    final fecha = lote['creadoEn'] as String?;
    final usuarioNombre =
        (lote['usuario'] as Map?)?['nombre'] as String? ?? '—';
    final sedeNombre = (lote['sede'] as Map?)?['nombre'] as String? ?? '—';
    final observaciones = lote['observaciones'] as String?;
    final expandido = _expandidos.contains(numero);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _toggleExpand(numero),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.deepPurple.shade100, width: 0.8),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade100,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      numero,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.deepPurple.shade900,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    fecha != null ? _fechaCorta(fecha) : '—',
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    expandido
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: Colors.deepPurple.shade700,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.add_circle_outline,
                      size: 14, color: Colors.green.shade700),
                  const SizedBox(width: 4),
                  Text(
                    '+$cantidad unidad(es)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Stock: $stockNuevo',
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade700),
                  ),
                ],
              ),
              if (costoLote != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.payments_outlined,
                        size: 12, color: Colors.deepPurple.shade400),
                    const SizedBox(width: 4),
                    Text(
                      'Costo lote: S/ ${costoLote.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.deepPurple.shade900,
                      ),
                    ),
                    if (costoUnitario != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '· S/ ${costoUnitario.toStringAsFixed(2)} c/u',
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.shade600),
                      ),
                    ],
                  ],
                ),
              ],
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.person_outline,
                      size: 11, color: Colors.grey.shade600),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      usuarioNombre,
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.store,
                      size: 11, color: Colors.grey.shade600),
                  const SizedBox(width: 3),
                  Text(
                    sedeNombre,
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade700),
                  ),
                ],
              ),
              if (observaciones != null && observaciones.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    observaciones,
                    style: TextStyle(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              if (expandido) _buildDetalle(numero),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetalle(String numero) {
    if (_cargandoDetalle.contains(numero)) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_detalleError.contains(numero)) {
      return detalleErrorWidget(() => _cargarDetalle(numero));
    }
    final detalle = _detalles[numero];
    if (detalle == null) return const SizedBox.shrink();
    final insumos =
        (detalle['insumosConsumidos'] as List?)?.cast<Map<String, dynamic>>() ??
            [];
    if (insumos.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Insumos consumidos',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.deepPurple.shade800,
            ),
          ),
          const SizedBox(height: 6),
          ...insumos.map((ins) => _buildInsumoTrazable(ins)),
          // Desglose de costo del lote (insumos + mano de obra = total).
          if (detalle['costoLoteTotal'] != null) ...[
            const SizedBox(height: 6),
            Divider(height: 1, color: Colors.deepPurple.shade200),
            const SizedBox(height: 6),
            _detalleCostoRow(
                'Insumos', (detalle['costoInsumos'] as num?)?.toDouble()),
            if (((detalle['costoManoObra'] as num?) ?? 0) > 0)
              _detalleCostoRow('Mano de obra',
                  (detalle['costoManoObra'] as num?)?.toDouble()),
            _detalleCostoRow('Total lote',
                (detalle['costoLoteTotal'] as num?)?.toDouble(),
                destacar: true),
          ],
        ],
      ),
    );
  }

  Widget _detalleCostoRow(String label, double? valor, {bool destacar = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: destacar ? 10.5 : 10,
              fontWeight: destacar ? FontWeight.bold : FontWeight.normal,
              color: destacar
                  ? Colors.deepPurple.shade900
                  : Colors.grey.shade700,
            ),
          ),
          Text(
            valor != null ? 'S/ ${valor.toStringAsFixed(2)}' : '—',
            style: TextStyle(
              fontSize: destacar ? 10.5 : 10,
              fontWeight: destacar ? FontWeight.bold : FontWeight.w600,
              color: destacar ? Colors.deepPurple.shade900 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsumoTrazable(Map<String, dynamic> ins) =>
      insumoTrazableTile(ins, fechaFmt: _fechaCorta);
}

/// Widget de error para el detalle de un lote que no se pudo cargar, con
/// reintento al tocar. Compartido entre el historial y la página de producción.
Widget detalleErrorWidget(VoidCallback onRetry) {
  return InkWell(
    onTap: onRetry,
    borderRadius: BorderRadius.circular(6),
    child: Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 14, color: Colors.red.shade700),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'No se pudo cargar el detalle. Tocá para reintentar.',
              style: TextStyle(fontSize: 10, color: Colors.red.shade900),
            ),
          ),
          Icon(Icons.refresh, size: 14, color: Colors.red.shade700),
        ],
      ),
    ),
  );
}

/// Fila de insumo consumido con trazabilidad: cantidad, stock resultante y
/// costos (al momento de fabricar, actual y última compra con proveedor).
Widget insumoTrazableTile(
  Map<String, dynamic> ins, {
  required String Function(String) fechaFmt,
}) {
  final um = ins['unidadMedida']?.toString() ?? '';
  final costoMom = (ins['costoUnitarioMomento'] as num?)?.toDouble();
  final costoAct = (ins['costoUnitarioActual'] as num?)?.toDouble();
  final compra = ins['ultimaCompra'] as Map?;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                ins['nombre']?.toString() ?? '—',
                style:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '-${ins['cantidadConsumida']} $um',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 92,
              child: Text(
                '→ ${ins['stockNuevo']} $um',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
        if (costoMom != null)
          Padding(
            padding: const EdgeInsets.only(top: 1, left: 2),
            child: Text(
              'Costo: S/ ${costoMom.toStringAsFixed(4)}/$um al fabricar'
              '${costoAct != null ? '  ·  actual S/ ${costoAct.toStringAsFixed(4)}' : ''}',
              style: TextStyle(fontSize: 9, color: Colors.grey.shade700),
            ),
          ),
        if (compra != null)
          Builder(builder: (_) {
            final cant = (compra['cantidad'] as num?);
            final cantStr = cant == null
                ? '—'
                : (cant % 1 == 0
                    ? cant.toStringAsFixed(0)
                    : cant.toStringAsFixed(2));
            final pu =
                (compra['precioUnitario'] as num?)?.toStringAsFixed(4) ?? '—';
            final total =
                (compra['total'] as num?)?.toStringAsFixed(2) ?? '—';
            final fechaStr = compra['fecha'] != null
                ? fechaFmt(compra['fecha'].toString())
                : '—';
            return Padding(
              padding: const EdgeInsets.only(top: 1, left: 2),
              child: Text(
                'Últ. compra: ${compra['proveedor'] ?? '—'}'
                '  ·  $cantStr $um × S/ $pu = S/ $total'
                '  ·  $fechaStr',
                style: TextStyle(
                    fontSize: 9,
                    color: Colors.blue.shade700,
                    fontStyle: FontStyle.italic),
              ),
            );
          }),
      ],
    ),
  );
}
