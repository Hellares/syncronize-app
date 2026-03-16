import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../venta/domain/entities/venta.dart';
import '../../../venta/domain/usecases/get_venta_usecase.dart';
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
  MotivoDevolucion motivo;
  EstadoProductoDevolucion estadoProducto;
  AccionDevolucion accion;
  String? observaciones;

  _ItemInput({
    this.productoId, this.varianteId, required this.descripcion,
    this.cantidad = 1, this.motivo = MotivoDevolucion.defectuoso,
    this.estadoProducto = EstadoProductoDevolucion.bueno,
    this.accion = AccionDevolucion.reingresarStock, this.observaciones,
  });

  Map<String, dynamic> toMap() => {
    if (productoId != null) 'productoId': productoId,
    if (varianteId != null) 'varianteId': varianteId,
    'cantidad': cantidad,
    'motivo': motivo.apiValue,
    'estadoProducto': estadoProducto.apiValue,
    'accion': accion.apiValue,
    if (observaciones != null && observaciones!.isNotEmpty) 'observaciones': observaciones,
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

  @override
  void initState() {
    super.initState();
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      _sedeId = empresaState.context.sedePrincipal?.id ?? empresaState.context.sedes.first.id;
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

  Future<void> _buscarVenta(String ventaId) async {
    setState(() => _loadingVenta = true);
    final result = await locator<GetVentaUseCase>()(ventaId: ventaId);
    if (!mounted) return;

    if (result is Success<Venta>) {
      final venta = result.data;
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
              ));
            }
          }
        }
      });
    } else {
      setState(() { _loadingVenta = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Venta no encontrada'), backgroundColor: Colors.red));
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
                      controller: _ventaIdController,
                      label: 'ID de Venta',
                    )),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _loadingVenta ? null : () {
                        if (_ventaIdController.text.isNotEmpty) {
                          _buscarVenta(_ventaIdController.text.trim());
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue1, foregroundColor: Colors.white),
                      child: _loadingVenta
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Buscar'),
                    ),
                  ]),
                ],

                const SizedBox(height: 16),
                CustomText(controller: _motivoController, label: 'Motivo general'),
                const SizedBox(height: 8),
                CustomText(controller: _observacionesController, label: 'Observaciones', maxLines: 3),

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
                          DropdownButtonFormField<MotivoDevolucion>(
                            value: item.motivo, isDense: true,
                            decoration: const InputDecoration(labelText: 'Motivo', border: OutlineInputBorder(), isDense: true),
                            items: MotivoDevolucion.values.map((m) =>
                                DropdownMenuItem(value: m, child: Text(m.label, style: const TextStyle(fontSize: 12)))).toList(),
                            onChanged: (v) { if (v != null) setState(() => item.motivo = v); },
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<EstadoProductoDevolucion>(
                            value: item.estadoProducto, isDense: true,
                            decoration: const InputDecoration(labelText: 'Estado producto', border: OutlineInputBorder(), isDense: true),
                            items: EstadoProductoDevolucion.values.map((e) =>
                                DropdownMenuItem(value: e, child: Text(e.label, style: const TextStyle(fontSize: 12)))).toList(),
                            onChanged: (v) { if (v != null) setState(() => item.estadoProducto = v); },
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<AccionDevolucion>(
                            value: item.accion, isDense: true,
                            decoration: const InputDecoration(labelText: 'Accion', border: OutlineInputBorder(), isDense: true),
                            items: AccionDevolucion.values.map((a) =>
                                DropdownMenuItem(value: a, child: Text(a.label, style: const TextStyle(fontSize: 12)))).toList(),
                            onChanged: (v) { if (v != null) setState(() => item.accion = v); },
                          ),
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
      if (_motivoController.text.isNotEmpty) 'motivo': _motivoController.text,
      if (_observacionesController.text.isNotEmpty) 'observaciones': _observacionesController.text,
      'items': _items.map((i) => i.toMap()).toList(),
    };
    context.read<DevolucionFormCubit>().crear(data);
  }
}
