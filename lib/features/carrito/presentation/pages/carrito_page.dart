import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_background.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import '../../../../core/di/injection_container.dart';
import '../../../auth/presentation/bloc/auth/auth_bloc.dart';
import '../../../auth/presentation/pages/complete_profile_page.dart';
import '../../../checkout/presentation/pages/checkout_page.dart';
import '../../domain/entities/carrito.dart';
import '../bloc/carrito_cubit.dart';

class CarritoPage extends StatelessWidget {
  const CarritoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<CarritoCubit>()..loadCarrito(),
      child: const _CarritoView(),
    );
  }
}

class _CarritoView extends StatelessWidget {
  const _CarritoView();

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      style: GradientStyle.skyBlue,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(
          title: 'Mi Carrito',
          backgroundColor: Colors.transparent,
        ),
        body: BlocBuilder<CarritoCubit, CarritoState>(
          builder: (context, state) {
            if (state is CarritoLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.blue1),
              );
            }

            if (state is CarritoError) {
              return _ErrorView(
                message: state.message,
                onRetry: () => context.read<CarritoCubit>().loadCarrito(),
              );
            }

            if (state is CarritoLoaded) {
              if (state.carrito.isEmpty) {
                return const _EmptyCartView();
              }
              return _CartContent(carrito: state.carrito);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

// ============================================================================
// Empty State
// ============================================================================

class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: AppColors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            AppSubtitle(
              'Tu carrito esta vacio',
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega productos desde el marketplace para comenzar',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Error State
// ============================================================================

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.red,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Reintentar',
              onPressed: onRetry,
              backgroundColor: AppColors.blue1,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Cart Content (list + bottom bar)
// ============================================================================

class _CartContent extends StatelessWidget {
  final Carrito carrito;

  const _CartContent({required this.carrito});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            color: AppColors.blue1,
            onRefresh: () => context.read<CarritoCubit>().loadCarrito(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: carrito.empresas.length,
              itemBuilder: (context, index) {
                return _EmpresaGrupoCard(grupo: carrito.empresas[index]);
              },
            ),
          ),
        ),
        _BottomCheckoutBar(carrito: carrito),
      ],
    );
  }
}

// ============================================================================
// Empresa Group Card
// ============================================================================

class _EmpresaGrupoCard extends StatelessWidget {
  final CarritoGrupo grupo;

  const _EmpresaGrupoCard({required this.grupo});

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Empresa header
          Row(
            children: [
              if (grupo.empresa.logo != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: grupo.empresa.logo!,
                    width: 24,
                    height: 24,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.store,
                      size: 24,
                      color: AppColors.blue1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ] else ...[
                const Icon(Icons.store, size: 24, color: AppColors.blue1),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: AppSubtitle(
                  grupo.empresa.nombre,
                  fontSize: 14,
                  color: AppColors.blue1,
                ),
              ),
              AppSubtitle(
                'S/ ${grupo.subtotal.toStringAsFixed(2)}',
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ],
          ),
          const Divider(height: 16),
          // Items list
          ...grupo.items.map(
            (item) => _CarritoItemTile(item: item),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Cart Item Tile
// ============================================================================

class _CarritoItemTile extends StatelessWidget {
  final CarritoItem item;

  const _CarritoItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Opacity(
        opacity: item.disponible ? 1.0 : 0.5,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            _buildThumbnail(),
            const SizedBox(width: 10),
            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSubtitle(
                    item.productoNombre,
                    fontSize: 13,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.varianteNombre != null) ...[
                    const SizedBox(height: 2),
                    AppSubtitle(
                      item.varianteNombre!,
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ],
                  const SizedBox(height: 4),
                  _buildPrecio(),
                  if (!item.disponible) ...[
                    const SizedBox(height: 4),
                    const AppSubtitle(
                      'No disponible',
                      fontSize: 11,
                      color: Colors.red,
                    ),
                  ],
                  const SizedBox(height: 6),
                  // Quantity + delete
                  Row(
                    children: [
                      _QuantitySelector(item: item),
                      const Spacer(),
                      AppSubtitle(
                        'S/ ${item.subtotal.toStringAsFixed(2)}',
                        fontSize: 13,
                        color: AppColors.blue1,
                      ),
                      const SizedBox(width: 4),
                      _DeleteButton(itemId: item.id),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    final imageUrl = item.thumbnailUrl ?? item.imagenUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: imageUrl != null
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                width: 60,
                height: 60,
                color: AppColors.greyLight,
                child: const Icon(Icons.image, color: AppColors.grey),
              ),
              errorWidget: (_, __, ___) => Container(
                width: 60,
                height: 60,
                color: AppColors.greyLight,
                child: const Icon(Icons.image, color: AppColors.grey),
              ),
            )
          : Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.image, color: AppColors.grey),
            ),
    );
  }

  Widget _buildPrecio() {
    if (item.tieneOferta) {
      return Row(
        children: [
          AppSubtitle(
            'S/ ${item.precioOferta!.toStringAsFixed(2)}',
            fontSize: 13,
            color: Colors.green,
          ),
          const SizedBox(width: 6),
          Text(
            'S/ ${item.precioNormal.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textHint,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      );
    }
    return AppSubtitle(
      'S/ ${item.precioUnitario.toStringAsFixed(2)}',
      fontSize: 13,
    );
  }
}

// ============================================================================
// Quantity Selector (+/- buttons)
// ============================================================================

class _QuantitySelector extends StatelessWidget {
  final CarritoItem item;

  const _QuantitySelector({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.greyLight),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QuantityButton(
            icon: Icons.remove,
            onTap: item.cantidad > 1
                ? () => context.read<CarritoCubit>().actualizarCantidad(
                      itemId: item.id,
                      cantidad: item.cantidad - 1,
                    )
                : null,
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 32),
            alignment: Alignment.center,
            child: AppSubtitle(
              '${item.cantidad}',
              fontSize: 13,
            ),
          ),
          _QuantityButton(
            icon: Icons.add,
            onTap: item.cantidad < item.stockDisponible
                ? () => context.read<CarritoCubit>().actualizarCantidad(
                      itemId: item.id,
                      cantidad: item.cantidad + 1,
                    )
                : null,
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QuantityButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 16,
          color: onTap != null ? AppColors.blue1 : AppColors.greyLight,
        ),
      ),
    );
  }
}

// ============================================================================
// Delete Button
// ============================================================================

class _DeleteButton extends StatelessWidget {
  final String itemId;

  const _DeleteButton({required this.itemId});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _confirmarEliminar(context),
      borderRadius: BorderRadius.circular(6),
      child: const Padding(
        padding: EdgeInsets.all(4),
        child: Icon(
          Icons.delete_outline,
          size: 20,
          color: AppColors.red,
        ),
      ),
    );
  }

  void _confirmarEliminar(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar producto'),
        content:
            const Text('¿Estas seguro de eliminar este producto del carrito?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<CarritoCubit>().eliminarItem(itemId: itemId);
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppColors.red),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Bottom Checkout Bar
// ============================================================================

class _BottomCheckoutBar extends StatelessWidget {
  final Carrito carrito;

  const _BottomCheckoutBar({required this.carrito});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppSubtitle(
                    '${carrito.totalCantidad} producto${carrito.totalCantidad != 1 ? 's' : ''}',
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(height: 2),
                  AppSubtitle(
                    'S/ ${carrito.total.toStringAsFixed(2)}',
                    fontSize: 18,
                    color: AppColors.blue1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomButton(
                text: 'Ir a pagar',
                onPressed: () {
                  // Verificar perfil completo antes de checkout
                  final authState = context.read<AuthBloc>().state;
                  if (authState is Authenticated && !authState.user.perfilCompleto) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Completa tu perfil para poder comprar (DNI, teléfono y dirección)'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CompleteProfilePage()),
                    );
                    return;
                  }

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CheckoutPage(
                        carritoData: carrito.empresas.map((g) => <String, dynamic>{
                          'empresaId': g.empresa.id,
                          'empresaNombre': g.empresa.nombre,
                          'empresaLogo': g.empresa.logo,
                          'items': g.items.map((i) => <String, dynamic>{
                            'productoNombre': i.productoNombre,
                            'varianteNombre': i.varianteNombre,
                            'cantidad': i.cantidad,
                            'precioUnitario': i.precioUnitario,
                            'subtotal': i.subtotal,
                            'imagenUrl': i.imagenUrl,
                          }).toList(),
                          'subtotal': g.subtotal,
                        }).toList(),
                      ),
                    ),
                  );
                },
                backgroundColor: AppColors.green,
                height: 44,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
