import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/custom_dropdown.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/producto_sede_selector/producto_sede_selector.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../producto/domain/entities/producto_list_item.dart';
import '../../../producto/domain/entities/producto_variante.dart';
import '../../../venta/domain/entities/venta.dart';
import '../../../venta/domain/usecases/buscar_venta_por_codigo_usecase.dart';
import '../../domain/entities/devolucion_venta.dart';
import '../bloc/devolucion_form/devolucion_form_cubit.dart';
import '../bloc/devolucion_form/devolucion_form_state.dart';

class DevolucionVentaFormPage extends StatefulWidget {
  final String? ventaId;
  const DevolucionVentaFormPage({super.key, this.ventaId});

  @override
  State<DevolucionVentaFormPage> createState() => _DevolucionVentaFormPageState();
}

class _ItemInput {
  String? productoId;
  String? varianteId;
  String descripcion;
  int cantidad;
  double precioOriginal;
  MotivoDevolucion motivo = MotivoDevolucion.defectuoso;
  EstadoProductoDevolucion estadoProducto = EstadoProductoDevolucion.bueno;
  AccionDevolucion accion = AccionDevolucion.reingresarStock;
  String? observaciones;
  // Replacement product fields
  String? productoReemplazoId;
  String? varianteReemplazoId;
  String? productoReemplazoNombre;
  double? precioReemplazo;

  _ItemInput({
    this.productoId, this.varianteId, required this.descripcion,
    this.cantidad = 1, this.precioOriginal = 0,
  });

  double? get diferenciaPrecio {
    if (precioReemplazo == null) return null;
    return precioReemplazo! - precioOriginal;
  }

  Map<String, dynamic> toMap(TipoReembolso tipoReembolso) => {
    if (productoId != null) 'productoId': productoId,
    if (varianteId != null) 'varianteId': varianteId,
    'cantidad': cantidad,
    'motivo': motivo.apiValue,
    'estadoProducto': estadoProducto.apiValue,
    'accion': accion.apiValue,
    if (observaciones != null && observaciones!.isNotEmpty) 'observaciones': observaciones,
    if (tipoReembolso == TipoReembolso.cambioProducto && productoReemplazoId != null)
      'productoReemplazoId': productoReemplazoId,
    if (tipoReembolso == TipoReembolso.cambioProducto && varianteReemplazoId != null)
      'varianteReemplazoId': varianteReemplazoId,
  };
}

class _DevolucionVentaFormPageState extends State<DevolucionVentaFormPage> {
  final _motivoController = TextEditingController();
  final _observacionesController = TextEditingController();
  Venta? _venta;
  bool _loadingVenta = false;
  final _ventaIdController = TextEditingController();
  final List<_ItemInput> _items = [];
  String? _sedeId;
  String? _empresaId;
  TipoReembolso _tipoReembolso = TipoReembolso.efectivo;

  @override
  void initState() {
    super.initState();
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      _sedeId = empresaState.context.sedePrincipal?.id ?? empresaState.context.sedes.first.id;
      _empresaId = empresaState.context.empresa.id;
    }
    if (widget.ventaId != null) {
      _ventaIdController.text = widget.ventaId!;
      _buscarVenta(widget.ventaId!);
    }
  }

  @override
  void dispose() {
    _motivoController.dispose();
    _observacionesController.dispose();
    _ventaIdController.dispose();
    super.dispose();
  }

  Future<void> _buscarVenta(String codigo) async {
    setState(() => _loadingVenta = true);
    final result = await locator<BuscarVentaPorCodigoUseCase>()(codigo: codigo);
    if (!mounted) return;

    if (result is Success<Venta?>) {
      final venta = result.data;
      if (venta != null) {
        setState(() {
          _venta = venta;
          _loadingVenta = false;
          _items.clear();
          if (venta.detalles != null) {
            for (final d in venta.detalles!) {
              if (d.productoId != null || d.varianteId != null) {
                _items.add(_ItemInput(
                  productoId: d.productoId,
                  varianteId: d.varianteId,
                  descripcion: d.descripcion,
                  cantidad: d.cantidad.toInt(),
                  precioOriginal: d.precioUnitario,
                ));
              }
            }
          }
        });
      } else {
        setState(() { _loadingVenta = false; });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Venta no encontrada'), backgroundColor: Colors.red));
        }
      }
    } else {
      setState(() { _loadingVenta = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Venta no encontrada'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<DevolucionFormCubit>(),
      child: BlocListener<DevolucionFormCubit, DevolucionFormState>(
        listener: (context, state) {
          if (state is DevolucionFormSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
            Navigator.of(context).pop(true);
          }
          if (state is DevolucionFormError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        child: Builder(
          builder: (context) => Scaffold(
            appBar: SmartAppBar(
              title: 'Nueva Devolucion',
              backgroundColor: AppColors.blue1,
              foregroundColor: Colors.white,
            ),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Venta selector
                const AppSubtitle('Venta de origen', fontSize: 14),
                const SizedBox(height: 8),
                if (_venta != null)
                  GradientContainer(
                    borderColor: Colors.green.shade200,
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.receipt, color: Colors.green),
                      title: Text(_venta!.codigo, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${_venta!.nombreCliente} - ${_venta!.moneda} ${_venta!.total.toStringAsFixed(2)}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() { _venta = null; _items.clear(); }),
                      ),
                    ),
                  )
                else ...[
                  Row(children: [
                    Expanded(child: CustomText(
                      borderColor: AppColors.blue1,
                      controller: _ventaIdController,
                      label: 'Codigo de venta o comprobante',
                      hintText: 'Ej: VTA-00016 o B001-00000005',
                      textCase: TextCase.upper,
                    )),
                    const SizedBox(width: 8),
                    CustomButton(
                      text: 'Buscar',
                      icon: _loadingVenta
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.search, size: 16),
                      backgroundColor: AppColors.blue1,
                      height: 35,
                      onPressed: _loadingVenta ? null : () {
                        if (_ventaIdController.text.isNotEmpty) {
                          _buscarVenta(_ventaIdController.text.trim());
                        }
                      },
                    ),
                  ]),
                ],

                if (_venta != null) ...[
                  const SizedBox(height: 16),
                  CustomDropdown<TipoReembolso>(
                    label: 'Tipo de reembolso',
                    value: _tipoReembolso,
                    borderColor: AppColors.blue1,
                    items: TipoReembolso.values.map((t) => DropdownItem(value: t, label: t.label)).toList(),
                    onChanged: (v) { if (v != null) setState(() => _tipoReembolso = v); },
                  ),
                ],

                const SizedBox(height: 16),
                CustomText(controller: _motivoController, label: 'Motivo general', borderColor: AppColors.blue1, enableVoiceInput: true, textCase: TextCase.upper,),
                const SizedBox(height: 8),
                CustomText(controller: _observacionesController, label: 'Observaciones', maxLines: 3, borderColor: AppColors.blue1, enableVoiceInput: true, textCase: TextCase.upper,),

                // Items
                if (_items.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  AppSubtitle('Items a devolver (${_items.length})', fontSize: 14),
                  const SizedBox(height: 8),
                  ..._items.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    return GradientContainer(
                      borderColor: AppColors.blueborder,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text(item.descripcion,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              onPressed: () => setState(() => _items.removeAt(i)),
                            ),
                          ]),
                          const SizedBox(height: 8),
                          Row(children: [
                            const Text('Cant: ', style: TextStyle(fontSize: 11)),
                            SizedBox(width: 60, child: TextFormField(
                              initialValue: item.cantidad.toString(),
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 12),
                              decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                              onChanged: (v) => item.cantidad = int.tryParse(v) ?? 1,
                            )),
                          ]),
                          const SizedBox(height: 8),
                          CustomDropdown<MotivoDevolucion>(
                            label: 'Motivo',
                            value: item.motivo,
                            borderColor: AppColors.blue1,
                            items: MotivoDevolucion.values.map((m) =>
                                DropdownItem(value: m, label: m.label)).toList(),
                            onChanged: (v) { if (v != null) setState(() => item.motivo = v); },
                          ),
                          const SizedBox(height: 8),
                          CustomDropdown<EstadoProductoDevolucion>(
                            label: 'Estado producto',
                            value: item.estadoProducto,
                            borderColor: AppColors.blue1,
                            items: EstadoProductoDevolucion.values.map((e) =>
                                DropdownItem(value: e, label: e.label)).toList(),
                            onChanged: (v) { if (v != null) setState(() => item.estadoProducto = v); },
                          ),
                          const SizedBox(height: 8),
                          CustomDropdown<AccionDevolucion>(
                            label: 'Accion',
                            value: item.accion,
                            borderColor: AppColors.blue1,
                            items: AccionDevolucion.values.map((a) =>
                                DropdownItem(value: a, label: a.label)).toList(),
                            onChanged: (v) { if (v != null) setState(() => item.accion = v); },
                          ),
                          // Product exchange UI
                          if (_tipoReembolso == TipoReembolso.cambioProducto && _empresaId != null) ...[
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),
                            const AppSubtitle('Producto de reemplazo', fontSize: 11),
                            const SizedBox(height: 8),
                            ProductoSedeSelector(
                              empresaId: _empresaId!,
                              sedeIdInicial: _sedeId,
                              mostrarSelectorSede: false,
                              label: 'Seleccionar reemplazo',
                              hintText: 'Buscar producto de reemplazo...',
                              onProductoSeleccionado: ({
                                required ProductoListItem producto,
                                required String sedeId,
                                ProductoVariante? variante,
                              }) {
                                setState(() {
                                  item.productoReemplazoId = variante?.productoId ?? producto.id;
                                  item.varianteReemplazoId = variante?.id;
                                  item.productoReemplazoNombre = variante != null
                                      ? '${producto.nombre} - ${variante.nombre}'
                                      : producto.nombre;
                                  item.precioReemplazo = variante != null
                                      ? (variante.precioEnSede(sedeId) ?? 0.0)
                                      : (producto.precioEnSede(sedeId) ?? 0.0);
                                });
                              },
                            ),
                            if (item.productoReemplazoNombre != null) ...[
                              const SizedBox(height: 8),
                              GradientContainer(
                                borderColor: Colors.orange.shade200,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('Cambio por: ${item.productoReemplazoNombre}',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 8),
                                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                      Text('Precio original:', style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                                      Text('S/ ${item.precioOriginal.toStringAsFixed(2)}',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                    ]),
                                    const SizedBox(height: 4),
                                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                      Text('Precio reemplazo:', style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                                      Text('S/ ${(item.precioReemplazo ?? 0).toStringAsFixed(2)}',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                    ]),
                                    const Divider(height: 12),
                                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                      Text('Diferencia:', style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                                      Text(
                                        'S/ ${(item.diferenciaPrecio ?? 0).toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: (item.diferenciaPrecio ?? 0) > 0 ? Colors.red.shade700 : Colors.green.shade700,
                                        ),
                                      ),
                                    ]),
                                  ]),
                                ),
                              ),
                            ],
                          ],
                        ]),
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 16),
                BlocBuilder<DevolucionFormCubit, DevolucionFormState>(
                  builder: (context, state) {
                    final isLoading = state is DevolucionFormLoading;
                    return CustomButton(
                      borderColor: AppColors.blue1,
                      textColor: AppColors.blue1,
                      text: 'Registrar Devolucion',
                      isLoading: isLoading,
                      onPressed: (_venta == null || _items.isEmpty || isLoading) ? null : () => _submit(context),
                      icon: const Icon(Icons.assignment_return, size: 18),
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit(BuildContext context) {
    final data = {
      'ventaId': _venta!.id,
      'sedeId': _sedeId,
      'tipoReembolso': _tipoReembolso.apiValue,
      if (_motivoController.text.isNotEmpty) 'motivo': _motivoController.text,
      if (_observacionesController.text.isNotEmpty) 'observaciones': _observacionesController.text,
      'items': _items.map((i) => i.toMap(_tipoReembolso)).toList(),
    };
    context.read<DevolucionFormCubit>().crear(data);
  }
}
