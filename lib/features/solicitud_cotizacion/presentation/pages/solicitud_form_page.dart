import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../marketplace/data/datasources/marketplace_remote_datasource.dart';
import '../../domain/entities/solicitud_cotizacion.dart';
import '../bloc/solicitud_form_cubit.dart';
import '../bloc/solicitud_form_state.dart';

class SolicitudFormPage extends StatefulWidget {
  final String empresaId;
  final String empresaNombre;
  final String subdominio;

  const SolicitudFormPage({
    super.key,
    required this.empresaId,
    required this.empresaNombre,
    required this.subdominio,
  });

  @override
  State<SolicitudFormPage> createState() => _SolicitudFormPageState();
}

class _SolicitudFormPageState extends State<SolicitudFormPage> {
  late final SolicitudFormCubit _formCubit;
  final _marketplaceDataSource = locator<MarketplaceRemoteDataSource>();
  final _searchController = TextEditingController();
  final _observacionesController = TextEditingController();

  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _formCubit = locator<SolicitudFormCubit>();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _observacionesController.dispose();
    _debounce?.cancel();
    _formCubit.close();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchProducts(query);
    });
  }

  Future<void> _searchProducts(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      final data = await _marketplaceDataSource.getProductosEmpresa(
        widget.subdominio,
        search: query,
        limit: 10,
      );
      if (mounted) {
        setState(() {
          _searchResults = (data['data'] as List<dynamic>?) ?? [];
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _addProductFromCatalog(Map<String, dynamic> producto) {
    final nombre = producto['nombre'] as String? ?? '';
    final id = producto['id'] as String? ?? '';

    // Obtener imagen
    String? imagenUrl;
    final imagenes = producto['imagenes'];
    if (imagenes is List && imagenes.isNotEmpty) {
      final primera = imagenes.first;
      if (primera is Map<String, dynamic>) {
        imagenUrl = primera['url'] as String?;
      } else if (primera is String) {
        imagenUrl = primera;
      }
    }

    _formCubit.agregarItemCatalogo(
      productoId: id,
      descripcion: nombre,
      cantidad: 1,
      imagenUrl: imagenUrl,
    );

    _searchController.clear();
    setState(() {
      _searchResults = [];
    });
  }

  void _showAgregarItemManualDialog() {
    final descripcionController = TextEditingController();
    final cantidadController = TextEditingController(text: '1');
    final notasController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const AppSubtitle('Agregar item manual', fontSize: 14),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descripcionController,
                decoration: InputDecoration(
                  labelText: 'Descripcion',
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: AppColors.blueGrey,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cantidadController,
                decoration: InputDecoration(
                  labelText: 'Cantidad',
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: AppColors.blueGrey,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notasController,
                decoration: InputDecoration(
                  labelText: 'Notas (opcional)',
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: AppColors.blueGrey,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                maxLines: 2,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancelar',
              style: TextStyle(fontSize: 11, color: AppColors.blueGrey),
            ),
          ),
          TextButton(
            onPressed: () {
              final descripcion = descripcionController.text.trim();
              final cantidadText = cantidadController.text.trim();
              final notas = notasController.text.trim();

              if (descripcion.isEmpty) return;

              final cantidad = int.tryParse(cantidadText) ?? 1;

              _formCubit.agregarItemManual(
                descripcion: descripcion,
                cantidad: cantidad,
                notasItem: notas.isEmpty ? null : notas,
              );
              Navigator.of(dialogContext).pop();
            },
            child: Text(
              'Agregar',
              style: TextStyle(fontSize: 11, color: AppColors.blue2),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _formCubit,
      child: BlocListener<SolicitudFormCubit, SolicitudFormState>(
        listener: (context, state) {
          if (state is SolicitudFormSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.green,
              ),
            );
            Navigator.of(context).pop(true);
          } else if (state is SolicitudFormError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.red,
              ),
            );
          }
        },
        child: GradientBackground(
          style: GradientStyle.minimal,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: SmartAppBar(title: 'Solicitar Cotizacion'),
            body: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEmpresaHeader(),
                const SizedBox(height: 16),
                _buildSearchSection(),
                const SizedBox(height: 16),
                _buildItemsList(),
                const SizedBox(height: 12),
                _buildAgregarManualButton(),
                const SizedBox(height: 8),
                _buildCargarItemsPreviosButton(),
                const SizedBox(height: 20),
                _buildObservacionesField(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        _buildSubmitButton(),
      ],
    );
  }

  Widget _buildEmpresaHeader() {
    return GradientContainer(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.blue3.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.store, color: AppColors.blue3, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSubtitle(widget.empresaNombre, fontSize: 12),
                const SizedBox(height: 2),
                AppText(
                  'Solicitud de cotizacion',
                  size: 10,
                  color: AppColors.blueGrey,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSubtitle('Buscar productos del catalogo', fontSize: 11),
        const SizedBox(height: 8),
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Buscar producto...',
            hintStyle: TextStyle(fontSize: 11, color: AppColors.grey),
            prefixIcon: const Icon(Icons.search, size: 18),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    ),
                  )
                : _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchResults = []);
                        },
                      )
                    : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.greyLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.greyLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.blue2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          style: const TextStyle(fontSize: 12),
        ),
        if (_searchResults.isNotEmpty) _buildSearchResults(),
      ],
    );
  }

  Widget _buildSearchResults() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.greyLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _searchResults.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: AppColors.greyLight),
        itemBuilder: (context, index) {
          final producto = _searchResults[index] as Map<String, dynamic>;
          final nombre = producto['nombre'] as String? ?? '';
          final precio = producto['precioVenta'];

          // Obtener imagen
          String? imagenUrl;
          final imagenes = producto['imagenes'];
          if (imagenes is List && imagenes.isNotEmpty) {
            final primera = imagenes.first;
            if (primera is Map<String, dynamic>) {
              imagenUrl = primera['url'] as String?;
            } else if (primera is String) {
              imagenUrl = primera;
            }
          }

          return ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: imagenUrl != null
                  ? Image.network(
                      imagenUrl,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 36,
                        height: 36,
                        color: AppColors.greyLight,
                        child: const Icon(Icons.image, size: 16),
                      ),
                    )
                  : Container(
                      width: 36,
                      height: 36,
                      color: AppColors.greyLight,
                      child: const Icon(Icons.inventory_2_outlined, size: 16),
                    ),
            ),
            title: Text(
              nombre,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: precio != null
                ? Text(
                    'S/ $precio',
                    style: TextStyle(fontSize: 10, color: AppColors.green),
                  )
                : null,
            trailing: Icon(
              Icons.add_circle_outline,
              color: AppColors.blue2,
              size: 20,
            ),
            onTap: () => _addProductFromCatalog(producto),
          );
        },
      ),
    );
  }

  Widget _buildItemsList() {
    return BlocBuilder<SolicitudFormCubit, SolicitudFormState>(
      builder: (context, state) {
        List<SolicitudItem> items = [];
        if (state is SolicitudFormEditing) {
          items = state.items;
        } else if (state is SolicitudFormError) {
          items = state.items;
        }

        if (items.isEmpty) {
          return GradientContainer(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 36, color: AppColors.grey),
                  const SizedBox(height: 8),
                  AppText(
                    'No hay items agregados',
                    size: 11,
                    color: AppColors.blueGrey,
                  ),
                  const SizedBox(height: 4),
                  AppText(
                    'Busca productos o agrega items manualmente',
                    size: 10,
                    color: AppColors.grey,
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppSubtitle('Items (${items.length})', fontSize: 11),
              ],
            ),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) =>
                  _buildItemCard(items[index], index),
            ),
          ],
        );
      },
    );
  }

  Widget _buildItemCard(SolicitudItem item, int index) {
    return GradientContainer(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          // Imagen o icono
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: item.imagenUrl != null
                ? Image.network(
                    item.imagenUrl!,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 44,
                      height: 44,
                      color: AppColors.greyLight,
                      child: const Icon(Icons.image, size: 18),
                    ),
                  )
                : Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: item.esManual
                          ? AppColors.orange.withValues(alpha: 0.1)
                          : AppColors.blue3.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      item.esManual
                          ? Icons.edit_note
                          : Icons.inventory_2_outlined,
                      size: 20,
                      color: item.esManual ? AppColors.orange : AppColors.blue3,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          // Descripcion y badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.descripcion,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.esManual)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Manual',
                          style: TextStyle(
                            fontSize: 8,
                            color: AppColors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.numbers, size: 12, color: AppColors.blueGrey),
                    const SizedBox(width: 4),
                    Text(
                      'Cantidad: ${item.cantidad}',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.blueGrey,
                      ),
                    ),
                    if (item.notasItem != null) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.note_outlined,
                          size: 12, color: AppColors.blueGrey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.notasItem!,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.blueGrey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Boton eliminar
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            color: AppColors.red,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => _formCubit.eliminarItem(index),
          ),
        ],
      ),
    );
  }

  Widget _buildAgregarManualButton() {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: '+ Agregar item manual',
        isOutlined: true,
        borderColor: AppColors.blue2,
        textColor: AppColors.blue2,
        fontSize: 10,
        height: 36,
        onPressed: _showAgregarItemManualDialog,
      ),
    );
  }

  Widget _buildCargarItemsPreviosButton() {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: 'Cargar items de solicitud anterior',
        isOutlined: true,
        borderColor: AppColors.blueGrey,
        textColor: AppColors.blueGrey,
        fontSize: 10,
        height: 36,
        onPressed: () => _formCubit.cargarItemsPrevios(widget.empresaId),
      ),
    );
  }

  Widget _buildObservacionesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSubtitle('Observaciones (opcional)', fontSize: 11),
        const SizedBox(height: 8),
        TextField(
          controller: _observacionesController,
          onChanged: (value) => _formCubit.actualizarObservaciones(value),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Escribe observaciones o instrucciones adicionales...',
            hintStyle: TextStyle(fontSize: 11, color: AppColors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.greyLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.greyLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.blue2),
            ),
            contentPadding: const EdgeInsets.all(12),
            filled: true,
            fillColor: Colors.white,
          ),
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return BlocBuilder<SolicitudFormCubit, SolicitudFormState>(
      builder: (context, state) {
        final isSubmitting = state is SolicitudFormSubmitting;
        final hasItems = state is SolicitudFormEditing && state.items.isNotEmpty;

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Enviar Solicitud',
                isLoading: isSubmitting,
                loadingText: 'Enviando...',
                enabled: hasItems && !isSubmitting,
                gradient: const LinearGradient(
                  colors: [AppColors.blue2, AppColors.blue3],
                ),
                textColor: Colors.white,
                fontSize: 11,
                height: 40,
                onPressed: hasItems
                    ? () => _formCubit.submit(empresaId: widget.empresaId)
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
}
