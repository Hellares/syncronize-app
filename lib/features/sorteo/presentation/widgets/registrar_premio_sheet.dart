import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_search_field.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../../producto/domain/entities/producto_filtros.dart';
import '../../../producto/domain/entities/producto_list_item.dart';
import '../../../producto/presentation/bloc/producto_list/producto_list_cubit.dart';
import '../../../producto/presentation/bloc/producto_list/producto_list_state.dart';
import '../../../venta_rapida/presentation/widgets/variante_selector_sheet.dart';
import '../../domain/entities/sorteo.dart';

/// Datos del premio recolectados por el sheet (el caller llama al cubit).
class RegistrarPremioData {
  final String descripcion;
  final String? productoId;
  final String? varianteId;
  final int cantidad;
  final double? montoParticipacion;
  final ModalidadEntregaPremio modalidad;
  final String? agenciaNombre;
  final String? destinoDepartamento;
  final String? destinoProvincia;
  final String? agenciaDireccion;
  final String? observaciones;

  const RegistrarPremioData({
    required this.descripcion,
    this.productoId,
    this.varianteId,
    this.cantidad = 1,
    this.montoParticipacion,
    required this.modalidad,
    this.agenciaNombre,
    this.destinoDepartamento,
    this.destinoProvincia,
    this.agenciaDireccion,
    this.observaciones,
  });
}

class _ProductoElegido {
  final String productoId;
  final String? varianteId;
  final String nombre;
  final int cantidad;
  const _ProductoElegido({
    required this.productoId,
    this.varianteId,
    required this.nombre,
    this.cantidad = 1,
  });
}

/// Sheet para registrar el PREMIO de un ganador ya elegido (el ganador
/// se selecciona antes con ClienteUnificadoSelector). Devuelve null si
/// se cancela.
Future<RegistrarPremioData?> showRegistrarPremioSheet({
  required BuildContext context,
  required String empresaId,
  required String? sedeId,
  required String ganadorNombre,
  double? precioParticipacionDefault,
  String? descripcionDefault,
}) {
  return showModalBottomSheet<RegistrarPremioData>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RegistrarPremioSheet(
      empresaId: empresaId,
      sedeId: sedeId,
      ganadorNombre: ganadorNombre,
      precioParticipacionDefault: precioParticipacionDefault,
      descripcionDefault: descripcionDefault,
    ),
  );
}

class _RegistrarPremioSheet extends StatefulWidget {
  final String empresaId;
  final String? sedeId;
  final String ganadorNombre;
  final double? precioParticipacionDefault;
  final String? descripcionDefault;

  const _RegistrarPremioSheet({
    required this.empresaId,
    required this.sedeId,
    required this.ganadorNombre,
    this.precioParticipacionDefault,
    this.descripcionDefault,
  });

  @override
  State<_RegistrarPremioSheet> createState() => _RegistrarPremioSheetState();
}

class _RegistrarPremioSheetState extends State<_RegistrarPremioSheet> {
  /// Prellenada con la descripción del SORTEO (editable) — en la mayoría
  /// de sorteos la descripción del sorteo ES el premio.
  late final _descripcionCtrl =
      TextEditingController(text: widget.descripcionDefault ?? '');
  final _agenciaCtrl = TextEditingController();
  final _destinoDepCtrl = TextEditingController();
  final _destinoProvCtrl = TextEditingController();
  final _agenciaDirCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();

  /// Prellenado con el precio de participación del sorteo — editable
  /// (el último jugador puede pagar menos).
  late final _participacionCtrl = TextEditingController(
    text: widget.precioParticipacionDefault != null
        ? _fmtMonto(widget.precioParticipacionDefault!)
        : '',
  );

  static String _fmtMonto(double v) => v % 1 == 0
      ? v.toStringAsFixed(0)
      : v.toStringAsFixed(2);

  bool _descontarStock = false;
  _ProductoElegido? _producto;
  int _cantidad = 1;
  var _modalidad = ModalidadEntregaPremio.retiroTienda;

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    _agenciaCtrl.dispose();
    _destinoDepCtrl.dispose();
    _destinoProvCtrl.dispose();
    _agenciaDirCtrl.dispose();
    _obsCtrl.dispose();
    _participacionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.emoji_events, color: AppColors.blue1, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Premio para ${widget.ganadorNombre}',
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CustomText(
                controller: _descripcionCtrl,
                label: 'Descripción del premio',
                hintText: 'ej. Laptop Lenovo IdeaPad 3 / pack de polos',
                borderColor: AppColors.blue1,
                textCase: TextCase.upper,
              ),
              const SizedBox(height: 10),

              // ── Vínculo a inventario (opcional) ──
              Row(
                children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: Checkbox(
                      value: _descontarStock,
                      activeColor: AppColors.blue1,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (v) => setState(() {
                        _descontarStock = v ?? false;
                        if (!_descontarStock) _producto = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'Descontar de stock (premio valioso registrado)',
                      style: TextStyle(fontSize: 11.5),
                    ),
                  ),
                ],
              ),
              if (_descontarStock) ...[
                const SizedBox(height: 6),
                InkWell(
                  onTap: _elegirProducto,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _producto != null
                            ? AppColors.blue1.withValues(alpha: 0.5)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _producto != null
                              ? Icons.inventory_2
                              : Icons.search,
                          size: 16,
                          color: _producto != null
                              ? AppColors.blue1
                              : Colors.grey.shade500,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _producto?.nombre ??
                                'Buscar producto del catálogo…',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: _producto != null
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: _producto != null
                                  ? Colors.black87
                                  : Colors.grey.shade500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_producto != null)
                          Text('x$_cantidad',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
                if (_producto != null && _producto!.varianteId == null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('Cantidad',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600)),
                      const Spacer(),
                      _stepBtn(Icons.remove, () {
                        if (_cantidad > 1) setState(() => _cantidad--);
                      }),
                      SizedBox(
                        width: 32,
                        child: Center(
                          child: Text('$_cantidad',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      _stepBtn(Icons.add, () => setState(() => _cantidad++)),
                    ],
                  ),
                ],
              ],
              const SizedBox(height: 10),
              // Lo que este ganador pagó por jugar (para el total
              // recaudado del sorteo).
              CustomText(
                controller: _participacionCtrl,
                label: 'Participación pagada S/ (editable)',
                hintText: 'ej. 20 — o 15 si fue el último',
                borderColor: AppColors.blue1,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),

              // ── Entrega ──
              Text('Entrega del premio',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              Row(
                children: [
                  for (final m in ModalidadEntregaPremio.values) ...[
                    Expanded(
                      child: ChoiceChip(
                        label: Text(m.label,
                            style: const TextStyle(fontSize: 10.5)),
                        selected: _modalidad == m,
                        selectedColor:
                            AppColors.blue1.withValues(alpha: 0.15),
                        onSelected: (_) => setState(() => _modalidad = m),
                      ),
                    ),
                    if (m != ModalidadEntregaPremio.values.last)
                      const SizedBox(width: 8),
                  ],
                ],
              ),
              if (_modalidad == ModalidadEntregaPremio.envioAgencia) ...[
                const SizedBox(height: 8),
                CustomText(
                  controller: _agenciaCtrl,
                  label: 'Agencia (opcional — el ganador puede elegirla)',
                  hintText: 'ej. Shalom / Olva / Marvisur',
                  borderColor: AppColors.blue1,
                  textCase: TextCase.upper,
                ),
                const SizedBox(height: 6),
                // Selección rápida de las agencias más usadas.
                Wrap(
                  spacing: 6,
                  children: [
                    for (final a in const ['SHALOM', 'OLVA', 'MARVISUR'])
                      ActionChip(
                        label: Text(a, style: const TextStyle(fontSize: 10)),
                        visualDensity: VisualDensity.compact,
                        backgroundColor:
                            AppColors.blue1.withValues(alpha: 0.06),
                        side: BorderSide(
                            color: AppColors.blue1.withValues(alpha: 0.3),
                            width: 0.5),
                        onPressed: () =>
                            setState(() => _agenciaCtrl.text = a),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Destino como se habla: "envío a San Martín, Tarapoto".
                Row(
                  children: [
                    Expanded(
                      child: CustomText(
                        controller: _destinoDepCtrl,
                        label: 'Departamento',
                        hintText: 'ej. San Martín',
                        borderColor: AppColors.blue1,
                        textCase: TextCase.upper,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomText(
                        controller: _destinoProvCtrl,
                        label: 'Provincia / ciudad',
                        hintText: 'ej. Tarapoto',
                        borderColor: AppColors.blue1,
                        textCase: TextCase.upper,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                CustomText(
                  controller: _agenciaDirCtrl,
                  label: 'Dirección de la agencia destino',
                  hintText: 'ej. Jr. Los Pinos 123',
                  borderColor: AppColors.blue1,
                  textCase: TextCase.upper,
                ),
              ],
              const SizedBox(height: 8),
              CustomText(
                controller: _obsCtrl,
                label: 'Observaciones (opcional)',
                borderColor: AppColors.blue1,
                textCase: TextCase.upper,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Cancelar',
                      isOutlined: true,
                      borderColor: Colors.grey.shade400,
                      textColor: Colors.grey.shade700,
                      enableShadows: false,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      text: 'Registrar premio',
                      backgroundColor: AppColors.blue1,
                      textColor: Colors.white,
                      onPressed: _confirmar,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
        ),
        child: Icon(icon, size: 15, color: Colors.grey.shade700),
      ),
    );
  }

  void _confirmar() {
    final descripcion = _descripcionCtrl.text.trim();
    if (descripcion.isEmpty) return;
    if (_descontarStock && _producto == null) return;
    // La agencia NO es obligatoria: el ganador puede elegirla él mismo
    // desde Mis Premios (feature "ganador elige agencia").
    Navigator.of(context).pop(RegistrarPremioData(
      descripcion: descripcion,
      productoId: _descontarStock ? _producto!.productoId : null,
      varianteId: _descontarStock ? _producto!.varianteId : null,
      cantidad: _descontarStock ? _producto!.cantidad * 1 : 1,
      montoParticipacion: double.tryParse(
          _participacionCtrl.text.trim().replaceAll(',', '.')),
      modalidad: _modalidad,
      agenciaNombre: _agenciaCtrl.text.trim(),
      destinoDepartamento: _destinoDepCtrl.text.trim(),
      destinoProvincia: _destinoProvCtrl.text.trim(),
      agenciaDireccion: _agenciaDirCtrl.text.trim(),
      observaciones: _obsCtrl.text.trim(),
    ));
  }

  /// Picker liviano de producto (catálogo local de la sede) — variantes
  /// abren el mismo selector de Venta Rápida.
  Future<void> _elegirProducto() async {
    final sedeId = widget.sedeId;
    if (sedeId == null) return;
    final elegido = await showModalBottomSheet<_ProductoElegido>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerProductoPremio(
        empresaId: widget.empresaId,
        sedeId: sedeId,
      ),
    );
    if (elegido == null || !mounted) return;
    setState(() {
      _producto = elegido;
      _cantidad = elegido.cantidad;
      // Autocompletar la descripción si estaba vacía.
      if (_descripcionCtrl.text.trim().isEmpty) {
        _descripcionCtrl.text = elegido.nombre;
      }
    });
  }
}

class _PickerProductoPremio extends StatefulWidget {
  final String empresaId;
  final String sedeId;

  const _PickerProductoPremio({
    required this.empresaId,
    required this.sedeId,
  });

  @override
  State<_PickerProductoPremio> createState() => _PickerProductoPremioState();
}

class _PickerProductoPremioState extends State<_PickerProductoPremio> {
  late final ProductoListCubit _cubit;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _cubit = locator<ProductoListCubit>();
    _cubit.loadProductos(
      empresaId: widget.empresaId,
      sedeId: widget.sedeId,
      filtros: const ProductoFiltros(isActive: true, esInsumo: false),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.8,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
              child: CustomSearchField(
                controller: _searchCtrl,
                borderColor: AppColors.blue1,
                hintText: 'Buscar producto del premio…',
                debounceDelay: const Duration(milliseconds: 200),
                onChanged: (v) => setState(() => _query = v.trim()),
                onClear: () => setState(() => _query = ''),
              ),
            ),
            Expanded(
              child: BlocBuilder<ProductoListCubit, ProductoListState>(
                bloc: _cubit,
                builder: (context, state) {
                  if (state is! ProductoListLoaded) {
                    return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2));
                  }
                  final q = _query.toLowerCase();
                  final matches = state.productos
                      .where((p) =>
                          !p.esCombo &&
                          (q.isEmpty ||
                              p.nombre.toLowerCase().contains(q) ||
                              p.codigoEmpresa.toLowerCase().contains(q)))
                      .take(30)
                      .toList();
                  if (matches.isEmpty) {
                    return Center(
                      child: Text('Sin resultados',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                    );
                  }
                  return ListView.separated(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    itemCount: matches.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (_, i) {
                      final p = matches[i];
                      final stock = p.tieneVariantes
                          ? p.stockConsolidadoEnSede(widget.sedeId)
                          : (p.stockEnSede(widget.sedeId) ?? 0);
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(p.nombre,
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w500)),
                        subtitle: Text(
                          '${p.codigoEmpresa} · Stock: $stock'
                          '${p.tieneVariantes ? ' · ${p.variantes?.length ?? 0} variantes' : ''}',
                          style: TextStyle(
                              fontSize: 9.5, color: Colors.grey.shade500),
                        ),
                        trailing: const Icon(Icons.chevron_right, size: 18),
                        onTap: () => _seleccionar(p),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _seleccionar(ProductoListItem p) async {
    if (p.tieneVariantes && (p.variantes ?? []).isNotEmpty) {
      await showVarianteSelectorSheet(
        context: context,
        producto: p,
        sedeId: widget.sedeId,
        cantidadesEnCarrito: const {},
        onAgregar: (v, cantidad) {
          Navigator.of(context).pop(_ProductoElegido(
            productoId: p.id,
            varianteId: v.id,
            nombre: '${p.nombre} — ${v.nombre}',
            cantidad: cantidad,
          ));
        },
      );
    } else {
      Navigator.of(context).pop(_ProductoElegido(
        productoId: p.id,
        nombre: p.nombre,
      ));
    }
  }
}
