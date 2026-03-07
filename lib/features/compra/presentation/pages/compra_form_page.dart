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
import '../bloc/compra_form/compra_form_cubit.dart';
import '../bloc/compra_form/compra_form_state.dart';
import '../../../../core/widgets/custom_proveedor_selector.dart';
import '../widgets/orden_compra_item_selector.dart';

class CompraFormPage extends StatelessWidget {
  final String empresaId;
  final OrdenCompra? ordenCompra;

  const CompraFormPage({
    super.key,
    required this.empresaId,
    this.ordenCompra,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<CompraFormCubit>(),
      child: _CompraFormView(
        empresaId: empresaId,
        ordenCompra: ordenCompra,
      ),
    );
  }
}

class _CompraFormView extends StatefulWidget {
  final String empresaId;
  final OrdenCompra? ordenCompra;

  const _CompraFormView({
    required this.empresaId,
    this.ordenCompra,
  });

  @override
  State<_CompraFormView> createState() => _CompraFormViewState();
}

class _CompraFormViewState extends State<_CompraFormView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _observacionesController;
  late final TextEditingController _tipoDocProveedorController;
  late final TextEditingController _serieDocProveedorController;
  late final TextEditingController _numDocProveedorController;

  // Proveedor seleccionado
  String? _proveedorId;
  String? _proveedorNombre;

  // Sede seleccionada
  String? _sedeId;

  String _moneda = 'PEN';
  DateTime _fechaRecepcion = DateTime.now();
  String? _terminosPago;

  final List<Map<String, dynamic>> _detalles = [];

  bool get _isFromOc => widget.ordenCompra != null;

  @override
  void initState() {
    super.initState();
    final oc = widget.ordenCompra;

    _observacionesController = TextEditingController();
    _tipoDocProveedorController = TextEditingController();
    _serieDocProveedorController = TextEditingController();
    _numDocProveedorController = TextEditingController();

    if (oc != null) {
      _proveedorId = oc.proveedorId;
      _proveedorNombre = oc.nombreProveedor;
      _sedeId = oc.sedeId;
      _moneda = oc.moneda;
      _terminosPago = oc.terminosPago;
      // Pre-llenar detalles desde OC
      if (oc.detalles != null) {
        for (final d in oc.detalles!) {
          if (d.cantidadPendiente > 0) {
            _detalles.add({
              'ordenCompraDetalleId': d.id,
              'productoId': d.productoId,
              'varianteId': d.varianteId,
              'descripcion': d.descripcion,
              'cantidad': d.cantidadPendiente,
              'precioUnitario': d.precioUnitario,
              'descuento': d.descuento,
            });
          }
        }
      }
    } else {
      // Para compra nueva, pre-seleccionar la sede principal
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
    _tipoDocProveedorController.dispose();
    _serieDocProveedorController.dispose();
    _numDocProveedorController.dispose();
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

    if (_isFromOc) {
      // CreateCompraDesdeOcDto: usa 'lineas' con ordenCompraDetalleId + cantidad
      final data = {
        'ordenCompraId': widget.ordenCompra!.id,
        if (_terminosPago != null) 'terminosPago': _terminosPago,
        if (_moneda != 'PEN') 'moneda': _moneda,
        if (_tipoDocProveedorController.text.trim().isNotEmpty)
          'tipoDocumentoProveedor':
              _tipoDocProveedorController.text.trim(),
        if (_serieDocProveedorController.text.trim().isNotEmpty)
          'serieDocumentoProveedor':
              _serieDocProveedorController.text.trim(),
        if (_numDocProveedorController.text.trim().isNotEmpty)
          'numeroDocumentoProveedor':
              _numDocProveedorController.text.trim(),
        if (_observacionesController.text.trim().isNotEmpty)
          'observaciones': _observacionesController.text.trim(),
        'lineas': _detalles
            .map((d) => {
                  'ordenCompraDetalleId': d['ordenCompraDetalleId'],
                  'cantidad': d['cantidad'],
                  if (d['precioUnitario'] != null)
                    'precioUnitario': d['precioUnitario'],
                })
            .toList(),
      };
      context.read<CompraFormCubit>().crearCompraDesdeOc(
            empresaId: widget.empresaId,
            data: data,
          );
    } else {
      // CreateCompraDto: usa 'detalles' con estructura completa
      final data = {
        'proveedorId': _proveedorId,
        'sedeId': _sedeId,
        'moneda': _moneda,
        'fechaRecepcion': _fechaRecepcion.toIso8601String(),
        if (_terminosPago != null) 'terminosPago': _terminosPago,
        if (_tipoDocProveedorController.text.trim().isNotEmpty)
          'tipoDocumentoProveedor':
              _tipoDocProveedorController.text.trim(),
        if (_serieDocProveedorController.text.trim().isNotEmpty)
          'serieDocumentoProveedor':
              _serieDocProveedorController.text.trim(),
        if (_numDocProveedorController.text.trim().isNotEmpty)
          'numeroDocumentoProveedor':
              _numDocProveedorController.text.trim(),
        if (_observacionesController.text.trim().isNotEmpty)
          'observaciones': _observacionesController.text.trim(),
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
      context.read<CompraFormCubit>().crearCompra(
            empresaId: widget.empresaId,
            data: data,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Obtener sedes del contexto de empresa
    final empresaState = context.watch<EmpresaContextCubit>().state;
    final sedes = empresaState is EmpresaContextLoaded
        ? empresaState.context.sedes.where((s) => s.isActive).toList()
        : <Sede>[];

    return Scaffold(
      appBar: SmartAppBar(
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        title: _isFromOc ? 'Recepción desde OC' : 'Nueva Compra',
      ),
      body: BlocConsumer<CompraFormCubit, CompraFormState>(
        listener: (context, state) {
          if (state is CompraFormSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Compra creada: ${state.compra.codigo}'),
                backgroundColor: Colors.green,
              ),
            );
            Future.delayed(const Duration(milliseconds: 500), () {
              if (context.mounted) context.pop(true);
            });
          } else if (state is CompraFormError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is CompraFormLoading;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_isFromOc)
                        Card(
                          color: Colors.blue.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline,
                                    color: Colors.blue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Recepción desde OC: ${widget.ordenCompra!.codigo}',
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (_isFromOc) const SizedBox(height: 12),

                      // Proveedor selector
                      CustomProveedorSelector(
                        empresaId: widget.empresaId,
                        proveedorId: _proveedorId,
                        proveedorNombre: _proveedorNombre,
                        enabled: !_isFromOc,
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

                      CustomDropdown<String>(
                        borderColor: AppColors.blue1,
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

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Fecha de Recepción'),
                        subtitle: Text(dateFormat.format(_fechaRecepcion)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _fechaRecepcion,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) {
                            setState(() => _fechaRecepcion = date);
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Documento proveedor
                      const Text(
                        'Documento del Proveedor (opcional)',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: CustomText(
                              controller: _tipoDocProveedorController,
                              label: 'Tipo',
                              hintText: 'Ej: FACTURA',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CustomText(
                              controller: _serieDocProveedorController,
                              label: 'Serie',
                              hintText: 'F001',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CustomText(
                              controller: _numDocProveedorController,
                              label: 'Número',
                              hintText: '00001',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      CustomText(
                        controller: _observacionesController,
                        label: 'Observaciones (opcional)',
                        hintText: 'Notas de la recepción',
                        prefixIcon: const Icon(Icons.notes),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Selector de items (solo para compra standalone)
                      if (!_isFromOc)
                        OrdenCompraItemSelector(
                          empresaId: widget.empresaId,
                          sedeId: _sedeId,
                          onItemAdded: (item) {
                            setState(() {
                              _detalles.add(item);
                            });
                          },
                        ),
                      if (!_isFromOc && _detalles.isNotEmpty)
                        const SizedBox(height: 12),

                      // Lista de items
                      if (_detalles.isNotEmpty) ...[
                        Row(
                          children: [
                            AppSubtitle(
                              _isFromOc
                                  ? 'Líneas de la OC (${_detalles.length})'
                                  : 'Items agregados (${_detalles.length})',
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
                          final index = entry.key;
                          final detalle = entry.value;
                          return _isFromOc
                              ? _buildOcDetalleCard(index, detalle)
                              : _buildDetalleCard(index, detalle);
                        }),
                        _buildTotalRow(),
                        const SizedBox(height: 8),
                      ],

                      const SizedBox(height: 16),
                      CustomButton(
                        backgroundColor: AppColors.blue1,
                        text: _isFromOc ? 'Crear Recepción' : 'Crear Compra',
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
                            Text('Guardando compra...'),
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
      enabled: !_isFromOc,
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

  /// Card para items de compra standalone (read-only con delete)
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
                      if (descuento > 0)
                        Text(
                          ' - ${descuento.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.red.shade400,
                          ),
                        ),
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

  /// Card para items pre-llenados desde OC (cantidad y precio editables)
  Widget _buildOcDetalleCard(int index, Map<String, dynamic> detalle) {
    final hasProduct = detalle['productoId'] != null;
    final descripcion = detalle['descripcion'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppColors.blue1.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: hasProduct
                        ? AppColors.blue1.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    hasProduct ? Icons.inventory_2 : Icons.edit_note,
                    size: 14,
                    color:
                        hasProduct ? AppColors.blue1 : Colors.orange.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    descripcion,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: detalle['cantidad'].toString(),
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                    style: const TextStyle(fontSize: 13),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requerido';
                      if (int.tryParse(v) == null || int.parse(v) <= 0) {
                        return 'Inválido';
                      }
                      return null;
                    },
                    onChanged: (v) =>
                        detalle['cantidad'] = int.tryParse(v) ?? 1,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: detalle['precioUnitario'].toString(),
                    decoration: const InputDecoration(
                      labelText: 'Precio Unit.',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                    style: const TextStyle(fontSize: 13),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requerido';
                      if (double.tryParse(v) == null) return 'Inválido';
                      return null;
                    },
                    onChanged: (v) =>
                        detalle['precioUnitario'] = double.tryParse(v) ?? 0,
                  ),
                ),
              ],
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
