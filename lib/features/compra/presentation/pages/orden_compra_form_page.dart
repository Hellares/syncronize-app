import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/custom_dropdown.dart';
import '../../../../core/di/injection_container.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../empresa/domain/entities/sede.dart';
import '../../domain/entities/orden_compra.dart';
import '../bloc/orden_compra_form/orden_compra_form_cubit.dart';
import '../bloc/orden_compra_form/orden_compra_form_state.dart';
import '../../../../core/widgets/custom_proveedor_selector.dart';
import '../widgets/orden_compra_item_selector.dart';

class OrdenCompraFormPage extends StatelessWidget {
  final String empresaId;
  final OrdenCompra? orden;

  const OrdenCompraFormPage({
    super.key,
    required this.empresaId,
    this.orden,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<OrdenCompraFormCubit>(),
      child: _OrdenCompraFormView(empresaId: empresaId, orden: orden),
    );
  }
}

class _OrdenCompraFormView extends StatefulWidget {
  final String empresaId;
  final OrdenCompra? orden;

  const _OrdenCompraFormView({required this.empresaId, this.orden});

  @override
  State<_OrdenCompraFormView> createState() => _OrdenCompraFormViewState();
}

class _OrdenCompraFormViewState extends State<_OrdenCompraFormView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _observacionesController;
  late final TextEditingController _condicionesController;

  // Proveedor seleccionado
  String? _proveedorId;
  String? _proveedorNombre;

  // Sede seleccionada
  String? _sedeId;

  String _moneda = 'PEN';
  String? _terminosPago;
  DateTime? _fechaEntrega;

  // Detalles de la orden
  final List<Map<String, dynamic>> _detalles = [];

  bool get _isEditing => widget.orden != null;

  @override
  void initState() {
    super.initState();
    final o = widget.orden;

    _observacionesController =
        TextEditingController(text: o?.observaciones ?? '');
    _condicionesController =
        TextEditingController(text: o?.condiciones ?? '');

    if (o != null) {
      _proveedorId = o.proveedorId;
      _proveedorNombre = o.nombreProveedor;
      _sedeId = o.sedeId;
      _moneda = o.moneda;
      _terminosPago = o.terminosPago;
      _fechaEntrega = o.fechaEntregaEsperada;

      if (o.detalles != null) {
        for (final d in o.detalles!) {
          _detalles.add({
            'productoId': d.productoId,
            'varianteId': d.varianteId,
            'descripcion': d.descripcion,
            'cantidad': d.cantidad,
            'precioUnitario': d.precioUnitario,
            'descuento': d.descuento,
          });
        }
      }
    } else {
      // Para nueva orden, pre-seleccionar la sede principal
      final empresaState = context.read<EmpresaContextCubit>().state;
      if (empresaState is EmpresaContextLoaded) {
        final sedePrincipal = empresaState.context.sedePrincipal;
        if (sedePrincipal != null) {
          _sedeId = sedePrincipal.id;
        }
      }
    }
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    _condicionesController.dispose();
    super.dispose();
  }

  void _removeDetalle(int index) {
    setState(() {
      _detalles.removeAt(index);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_proveedorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un proveedor'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_sedeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una sede'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_detalles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos un producto'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final data = {
      'proveedorId': _proveedorId,
      'sedeId': _sedeId,
      'moneda': _moneda,
      if (_fechaEntrega != null)
        'fechaEntregaEsperada': _fechaEntrega!.toIso8601String(),
      if (_terminosPago != null) 'terminosPago': _terminosPago,
      if (_observacionesController.text.trim().isNotEmpty)
        'observaciones': _observacionesController.text.trim(),
      if (_condicionesController.text.trim().isNotEmpty)
        'condiciones': _condicionesController.text.trim(),
      'detalles': _detalles
          .map((d) => {
                if (d['productoId'] != null) 'productoId': d['productoId'],
                if (d['varianteId'] != null) 'varianteId': d['varianteId'],
                'descripcion': d['descripcion'],
                'cantidad': d['cantidad'],
                'precioUnitario': d['precioUnitario'],
                'descuento': d['descuento'] ?? 0,
              })
          .toList(),
    };

    if (_isEditing) {
      context.read<OrdenCompraFormCubit>().actualizarOrdenCompra(
            empresaId: widget.empresaId,
            id: widget.orden!.id,
            data: data,
          );
    } else {
      context.read<OrdenCompraFormCubit>().crearOrdenCompra(
            empresaId: widget.empresaId,
            data: data,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        title: '${_isEditing ? 'Editar' : 'Nueva'} Orden de Compra',
      ),
      body: BlocConsumer<OrdenCompraFormCubit, OrdenCompraFormState>(
        listener: (context, state) {
          if (state is OrdenCompraFormSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.isUpdate
                      ? 'Orden actualizada: ${state.ordenCompra.codigo}'
                      : 'Orden creada: ${state.ordenCompra.codigo}',
                ),
                backgroundColor: Colors.green,
              ),
            );
            Future.delayed(const Duration(milliseconds: 500), () {
              if (context.mounted) context.pop(true);
            });
          } else if (state is OrdenCompraFormError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is OrdenCompraFormLoading;

          // Obtener sedes del contexto de empresa
          final empresaState = context.watch<EmpresaContextCubit>().state;
          final sedes = empresaState is EmpresaContextLoaded
              ? empresaState.context.sedes
                  .where((s) => s.isActive)
                  .toList()
              : <Sede>[];

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Proveedor selector
                      CustomProveedorSelector(
                        empresaId: widget.empresaId,
                        proveedorId: _proveedorId,
                        proveedorNombre: _proveedorNombre,
                        onSelected: (result) {
                          setState(() {
                            _proveedorId = result.proveedorId;
                            _proveedorNombre = result.nombre;
                          });
                        },
                        onCleared: () {
                          setState(() {
                            _proveedorId = null;
                            _proveedorNombre = null;
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // Sede selector
                      _buildSedeDropdown(sedes),
                      const SizedBox(height: 12),

                      // Moneda
                      CustomDropdown<String>(
                        label: 'Moneda',
                        value: _moneda,
                        items: const [
                          DropdownItem(value: 'PEN', label: 'PEN - Soles'),
                          DropdownItem(value: 'USD', label: 'USD - Dólares'),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _moneda = value);
                        },
                      ),
                      const SizedBox(height: 12),

                      // Fecha entrega esperada
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Fecha Entrega Esperada (opcional)'),
                        subtitle: Text(_fechaEntrega != null
                            ? DateFormat('dd/MM/yyyy').format(_fechaEntrega!)
                            : 'No especificada'),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _fechaEntrega ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) {
                            setState(() => _fechaEntrega = date);
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Observaciones
                      CustomText(
                        controller: _observacionesController,
                        label: 'Observaciones (opcional)',
                        hintText: 'Notas adicionales',
                        prefixIcon: const Icon(Icons.notes),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),

                      // Condiciones
                      CustomText(
                        controller: _condicionesController,
                        label: 'Condiciones (opcional)',
                        hintText: 'Condiciones de la orden',
                        prefixIcon: const Icon(Icons.policy),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Selector de items
                      OrdenCompraItemSelector(
                        empresaId: widget.empresaId,
                        sedeId: _sedeId,
                        onItemAdded: (item) {
                          setState(() {
                            _detalles.add(item);
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // Lista de items agregados
                      if (_detalles.isNotEmpty) ...[
                        Row(
                          children: [
                            AppSubtitle(
                              'Items agregados (${_detalles.length})',
                              fontSize: 13,
                            ),
                            const Spacer(),
                            AppSubtitle(
                              _moneda,
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ..._detalles.asMap().entries.map((entry) {
                          return _buildDetalleCard(entry.key, entry.value);
                        }),
                        // Total
                        _buildTotalRow(),
                        const SizedBox(height: 8),
                      ],

                      const SizedBox(height: 16),
                      CustomButton(
                        backgroundColor: AppColors.blue1,
                        text: _isEditing
                            ? 'Actualizar Orden'
                            : 'Crear Orden de Compra',
                        onPressed: isLoading ? null : _submit,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              if (isLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: const Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Guardando orden...'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSedeDropdown(List<Sede> sedes) {
    if (sedes.isEmpty) {
      return const SizedBox.shrink();
    }

    return CustomDropdown<String>(
      label: 'Sede',
      value: _sedeId,
      items: sedes.map((sede) {
        final label = sede.esPrincipal
            ? '${sede.nombre} (Principal)'
            : sede.nombre;
        return DropdownItem(value: sede.id, label: label);
      }).toList(),
      onChanged: (value) {
        if (value != null) setState(() => _sedeId = value);
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'La sede es requerida';
        }
        return null;
      },
    );
  }

  Widget _buildDetalleCard(int index, Map<String, dynamic> detalle) {
    final hasProduct = detalle['productoId'] != null;
    final descripcion = detalle['descripcion'] as String? ?? '';
    final cantidad = detalle['cantidad'];
    final precio = detalle['precioUnitario'];
    final descuento = (detalle['descuento'] as num?)?.toDouble() ?? 0.0;

    final cantidadNum =
        cantidad is int ? cantidad.toDouble() : (cantidad as num).toDouble();
    final precioNum =
        precio is int ? precio.toDouble() : (precio as num).toDouble();
    final subtotal = cantidadNum * precioNum - descuento;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            // Icono tipo
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: hasProduct
                    ? AppColors.blue1.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                hasProduct ? Icons.inventory_2 : Icons.edit_note,
                size: 16,
                color: hasProduct ? AppColors.blue1 : Colors.orange.shade700,
              ),
            ),
            const SizedBox(width: 10),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    descripcion,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '$cantidad × ${precioNum.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (descuento > 0) ...[
                        Text(
                          ' - ${descuento.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.red.shade400,
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        subtotal.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blue1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            // Eliminar
            InkWell(
              onTap: () => _removeDetalle(index),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  color: Colors.red.shade300,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow() {
    double total = 0;
    for (final d in _detalles) {
      final cantidad = d['cantidad'];
      final precio = d['precioUnitario'];
      final descuento = (d['descuento'] as num?)?.toDouble() ?? 0.0;
      final cantidadNum =
          cantidad is int ? cantidad.toDouble() : (cantidad as num).toDouble();
      final precioNum =
          precio is int ? precio.toDouble() : (precio as num).toDouble();
      total += cantidadNum * precioNum - descuento;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppSubtitle('Subtotal:', fontSize: 12, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            '$_moneda ${total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.blue1,
            ),
          ),
        ],
      ),
    );
  }
}
