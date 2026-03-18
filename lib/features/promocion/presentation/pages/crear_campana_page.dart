import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/snack_bar_helper.dart';
import '../../domain/entities/campana.dart';
import '../bloc/campana_form/campana_form_cubit.dart';
import '../bloc/campana_form/campana_form_state.dart';

class CrearCampanaPage extends StatelessWidget {
  const CrearCampanaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<CampanaFormCubit>()..loadProductosEnOferta(),
      child: const _CrearCampanaView(),
    );
  }
}

class _CrearCampanaView extends StatefulWidget {
  const _CrearCampanaView();

  @override
  State<_CrearCampanaView> createState() => _CrearCampanaViewState();
}

class _CrearCampanaViewState extends State<_CrearCampanaView> {
  final _tituloController = TextEditingController();
  final _mensajeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final Set<String> _productosSeleccionados = {};

  @override
  void dispose() {
    _tituloController.dispose();
    _mensajeController.dispose();
    super.dispose();
  }

  void _toggleProducto(String productoId) {
    setState(() {
      if (_productosSeleccionados.contains(productoId)) {
        _productosSeleccionados.remove(productoId);
      } else {
        _productosSeleccionados.add(productoId);
      }
    });
  }

  void _seleccionarTodos(List<ProductoEnOferta> productos) {
    setState(() {
      if (_productosSeleccionados.length == productos.length) {
        _productosSeleccionados.clear();
      } else {
        _productosSeleccionados.clear();
        _productosSeleccionados.addAll(productos.map((p) => p.productoId));
      }
    });
  }

  void _enviarCampana() {
    if (!_formKey.currentState!.validate()) return;

    context.read<CampanaFormCubit>().enviarCampana(
          titulo: _tituloController.text.trim(),
          mensaje: _mensajeController.text.trim(),
          productosIds: _productosSeleccionados.isNotEmpty
              ? _productosSeleccionados.toList()
              : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CampanaFormCubit, CampanaFormState>(
      listener: (context, state) {
        if (state is CampanaFormSuccess) {
          SnackBarHelper.showSuccess(context, 'Campaña enviada exitosamente');
          context.pop(true);
        } else if (state is CampanaFormError) {
          SnackBarHelper.showError(context, state.message);
        }
      },
      child: Scaffold(
        appBar: SmartAppBar.withBackButton(
          title: 'Nueva Campaña',
          onBack: () => context.pop(),
        ),
        body: GradientBackground(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'La notificación se enviará a todos los clientes de tu empresa',
                          style: TextStyle(fontSize: 13, color: Colors.blue[700]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Título
                TextFormField(
                  controller: _tituloController,
                  decoration: InputDecoration(
                    labelText: 'Título de la notificación',
                    hintText: 'Ej: ¡Ofertas de temporada!',
                    prefixIcon: const Icon(Icons.title),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  maxLength: 100,
                  validator: (v) =>
                      (v == null || v.trim().length < 3) ? 'Mínimo 3 caracteres' : null,
                ),
                const SizedBox(height: 12),

                // Mensaje
                TextFormField(
                  controller: _mensajeController,
                  decoration: InputDecoration(
                    labelText: 'Mensaje',
                    hintText: 'Ej: Aprovecha hasta 50% de descuento',
                    prefixIcon: const Icon(Icons.message_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  maxLines: 3,
                  maxLength: 500,
                  validator: (v) =>
                      (v == null || v.trim().length < 5) ? 'Mínimo 5 caracteres' : null,
                ),
                const SizedBox(height: 20),

                // Productos en oferta
                BlocBuilder<CampanaFormCubit, CampanaFormState>(
                  buildWhen: (prev, curr) =>
                      curr is CampanaFormLoading ||
                      curr is CampanaFormProductosLoaded ||
                      (curr is CampanaFormError && prev is CampanaFormLoading),
                  builder: (context, state) {
                    if (state is CampanaFormLoading) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final productos = context.read<CampanaFormCubit>().productos;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Productos en oferta',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            if (productos.isNotEmpty)
                              TextButton(
                                onPressed: () => _seleccionarTodos(productos),
                                child: Text(
                                  _productosSeleccionados.length == productos.length
                                      ? 'Deseleccionar todos'
                                      : 'Seleccionar todos',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (productos.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange[200]!),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 40, color: Colors.orange[400]),
                                const SizedBox(height: 8),
                                Text(
                                  'No hay productos en oferta',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Activa ofertas en tus productos desde el inventario',
                                  style: TextStyle(fontSize: 13, color: Colors.orange[600]),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        else
                          ...productos.map((producto) => _ProductoOfertaCard(
                                producto: producto,
                                isSelected: _productosSeleccionados.contains(producto.productoId),
                                onTap: () => _toggleProducto(producto.productoId),
                              )),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Botón enviar
                BlocBuilder<CampanaFormCubit, CampanaFormState>(
                  buildWhen: (prev, curr) =>
                      curr is CampanaFormSending ||
                      curr is CampanaFormSuccess ||
                      curr is CampanaFormError ||
                      curr is CampanaFormProductosLoaded,
                  builder: (context, state) {
                    final isSending = state is CampanaFormSending;

                    return SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: isSending ? null : _enviarCampana,
                        icon: isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send),
                        label: Text(isSending ? 'Enviando...' : 'Enviar Campaña'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue1,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductoOfertaCard extends StatelessWidget {
  final ProductoEnOferta producto;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProductoOfertaCard({
    required this.producto,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? AppColors.blue1 : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (_) => onTap(),
                activeColor: AppColors.blue1,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (producto.precio != null)
                          Text(
                            'S/ ${producto.precio}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                              decoration: producto.precioOferta != null
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        if (producto.precioOferta != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            'S/ ${producto.precioOferta}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      producto.sede,
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
