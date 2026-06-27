import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/custom_dropdown.dart';
import 'package:syncronize/core/widgets/custom_switch_tile.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_button.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import 'package:syncronize/features/empresa/presentation/widgets/unidad_medida_dropdown.dart';

import 'package:syncronize/features/catalogo/presentation/bloc/categorias_empresa/categorias_empresa_cubit.dart';
import 'package:syncronize/features/catalogo/presentation/bloc/categorias_empresa/categorias_empresa_state.dart';
import 'package:syncronize/features/catalogo/presentation/bloc/marcas_empresa/marcas_empresa_cubit.dart';
import 'package:syncronize/features/catalogo/presentation/bloc/marcas_empresa/marcas_empresa_state.dart';
import 'package:syncronize/features/catalogo/presentation/bloc/unidades_medida/unidades_medida_cubit.dart';
import 'package:syncronize/features/catalogo/presentation/bloc/unidades_medida/unidades_medida_state.dart';

import '../../../producto/data/datasources/producto_remote_datasource.dart';
import '../../../producto/domain/entities/producto_list_item.dart';

/// Diálogo de creación RÁPIDA de producto desde el flujo de compra. Solo
/// campos básicos (nombre, unidad de medida, categoría, marca, y unidad de
/// compra+factor opcional). La sede se hereda de la compra. Costo, precio de
/// venta y stock se setean al confirmar la compra (no aquí).
/// Devuelve el producto creado (listo para seleccionarlo) + un precio de venta
/// opcional (se aplicará al confirmar la compra, igual que con productos
/// existentes), o null si se canceló.
typedef QuickCreateResult = ({ProductoListItem producto, double? precioVenta});

Future<QuickCreateResult?> showQuickCreateProductoDialog(
  BuildContext context, {
  required String empresaId,
  required String sedeId,
}) {
  return showDialog<QuickCreateResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        _QuickCreateProductoDialog(empresaId: empresaId, sedeId: sedeId),
  );
}

class _QuickCreateProductoDialog extends StatefulWidget {
  final String empresaId;
  final String sedeId;

  const _QuickCreateProductoDialog({
    required this.empresaId,
    required this.sedeId,
  });

  @override
  State<_QuickCreateProductoDialog> createState() =>
      _QuickCreateProductoDialogState();
}

class _QuickCreateProductoDialogState
    extends State<_QuickCreateProductoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _factorController = TextEditingController();
  final _precioVentaController = TextEditingController();

  String? _unidadMedidaId;
  String? _categoriaId;
  String? _marcaId;
  bool _porPaquete = false;
  String? _unidadCompraId;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    // Asegurar que las listas estén cargadas (cubits globales).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoriasEmpresaCubit>().loadCategorias(widget.empresaId);
      context.read<MarcasEmpresaCubit>().loadMarcas(widget.empresaId);
      context.read<UnidadMedidaCubit>().getUnidadesEmpresa(widget.empresaId);
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _factorController.dispose();
    _precioVentaController.dispose();
    super.dispose();
  }

  String? _simboloDe(String? unidadId) {
    if (unidadId == null) return null;
    final st = context.read<UnidadMedidaCubit>().state;
    if (st is UnidadesEmpresaLoaded) {
      for (final u in st.unidadesEmpresa) {
        if (u.id == unidadId) return u.displayCorto;
      }
    }
    return null;
  }

  Future<void> _crear() async {
    if (!_formKey.currentState!.validate()) return;
    if (_unidadMedidaId == null) {
      _snack('Selecciona la unidad de medida', Colors.red);
      return;
    }
    double? factor;
    if (_porPaquete) {
      if (_unidadCompraId == null) {
        _snack('Selecciona la unidad de compra (paquete/saco)', Colors.red);
        return;
      }
      factor = double.tryParse(_factorController.text.replaceAll(',', '.'));
      if (factor == null || factor <= 0) {
        _snack('Indica cuántas unidades trae el paquete (factor)', Colors.red);
        return;
      }
    }

    final data = <String, dynamic>{
      'empresaId': widget.empresaId,
      'nombre': _nombreController.text.trim(),
      'sedesIds': [widget.sedeId],
      // Producto creado al vuelo desde una compra: NO visible en marketplace
      // (el default del backend ya es false; lo dejamos explícito por claridad).
      'visibleMarketplace': false,
      'unidadMedidaId': _unidadMedidaId,
      if (_categoriaId != null) 'empresaCategoriaId': _categoriaId,
      if (_marcaId != null) 'empresaMarcaId': _marcaId,
      if (_porPaquete) 'unidadCompraId': _unidadCompraId,
      if (_porPaquete && factor != null) 'factorCompra': factor,
    };

    setState(() => _guardando = true);
    try {
      final model = await locator<ProductoRemoteDataSource>().crearProducto(data);
      if (!mounted) return;
      final producto = ProductoListItem(
        id: model.id,
        nombre: model.nombre,
        codigoEmpresa: model.codigoEmpresa,
        destacado: false,
        isActive: true,
        factorCompra: _porPaquete ? factor : null,
        unidadCompraSimbolo: _porPaquete ? _simboloDe(_unidadCompraId) : null,
        unidadMedidaSimbolo: _simboloDe(_unidadMedidaId),
        stocksPorSede: null,
      );
      final precioVenta =
          double.tryParse(_precioVentaController.text.replaceAll(',', '.'));
      Navigator.of(context).pop((
        producto: producto,
        precioVenta: (precioVenta != null && precioVenta > 0)
            ? precioVenta
            : null,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      _snack('No se pudo crear el producto: $e', Colors.red);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: GradientContainer(
        gradient: const LinearGradient(colors: [Colors.white, Colors.white]),
        borderColor: AppColors.blue1.withValues(alpha: 0.4),
        borderWidth: 1,
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.blue1.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_box_outlined,
                        color: AppColors.blue1, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Producto nuevo',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blue1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Costo, precio de venta y stock se setean al confirmar la compra.',
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        controller: _nombreController,
                        borderColor: AppColors.blue1,
                        label: 'Nombre *',
                        hintText: 'Nombre del producto',
                        textCase: TextCase.upper,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'El nombre es requerido'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      UnidadMedidaDropdown(
                        empresaId: widget.empresaId,
                        selectedUnidadId: _unidadMedidaId,
                        onChanged: (v) => setState(() => _unidadMedidaId = v),
                        labelText: 'Unidad de medida *',
                        hintText: 'Selecciona la unidad',
                        autoSelectDefault: true,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildCategoriaDropdown()),
                          const SizedBox(width: 8),
                          Expanded(child: _buildMarcaDropdown()),
                        ],
                      ),
                      const SizedBox(height: 10),
                      CustomText(
                        controller: _precioVentaController,
                        borderColor: AppColors.blue1,
                        label: 'Precio de venta (opcional)',
                        hintText: 'Se aplica al confirmar la compra',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        prefixIcon: const Icon(Icons.sell_outlined, size: 16),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.blue1.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppColors.blue1.withValues(alpha: 0.2),
                              width: 0.6),
                        ),
                        child: CustomSwitchTile(
                          title: 'Se compra por paquete / saco',
                          subtitle:
                              'El proveedor te lo vende por bulto (ej. 1 saco = 50 u)',
                          value: _porPaquete,
                          onChanged: (v) => setState(() => _porPaquete = v),
                        ),
                      ),
                      if (_porPaquete) ...[
                        const SizedBox(height: 10),
                        UnidadMedidaDropdown(
                          empresaId: widget.empresaId,
                          selectedUnidadId: _unidadCompraId,
                          onChanged: (v) =>
                              setState(() => _unidadCompraId = v),
                          labelText: 'Unidad de compra (paquete) *',
                          hintText: 'Saco, Caja, Paquete...',
                          autoSelectDefault: false,
                        ),
                        const SizedBox(height: 10),
                        CustomText(
                          controller: _factorController,
                          borderColor: AppColors.blue1,
                          label: 'Unidades por paquete (factor) *',
                          hintText: 'Ej. 50',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Cancelar',
                      isOutlined: true,
                      backgroundColor: Colors.grey.shade200,
                      textColor: Colors.black87,
                      onPressed: _guardando
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomButton(
                      text: 'Crear y usar',
                      isLoading: _guardando,
                      backgroundColor: AppColors.blue1,
                      onPressed: _guardando ? null : _crear,
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

  Widget _buildCategoriaDropdown() {
    return BlocBuilder<CategoriasEmpresaCubit, CategoriasEmpresaState>(
      builder: (context, state) {
        final items = state is CategoriasEmpresaLoaded
            ? state.categorias
                .map((c) => DropdownItem(value: c.id, label: c.nombreDisplay))
                .toList()
            : <DropdownItem<String>>[];
        return CustomDropdown<String>(
          label: 'Categoría',
          hintText: 'Opcional',
          borderColor: AppColors.blue1,
          value: _categoriaId,
          items: items,
          onChanged: (v) => setState(() => _categoriaId = v),
        );
      },
    );
  }

  Widget _buildMarcaDropdown() {
    return BlocBuilder<MarcasEmpresaCubit, MarcasEmpresaState>(
      builder: (context, state) {
        final items = state is MarcasEmpresaLoaded
            ? state.marcas
                .map((m) => DropdownItem(value: m.id, label: m.nombreDisplay))
                .toList()
            : <DropdownItem<String>>[];
        return CustomDropdown<String>(
          label: 'Marca',
          hintText: 'Opcional',
          borderColor: AppColors.blue1,
          value: _marcaId,
          items: items,
          onChanged: (v) => setState(() => _marcaId = v),
        );
      },
    );
  }
}
