import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../domain/entities/producto_filtros.dart';
import '../../domain/entities/producto_list_item.dart';
import '../../domain/repositories/producto_repository.dart';
import '../bloc/producto_list/producto_list_cubit.dart';
import '../bloc/producto_list/producto_list_state.dart';

/// Pantalla de papelera: lista los productos soft-deleted (deletedAt != null)
/// con la opción de restaurarlos. Acceso desde drawer / configuración.
///
/// Ruta sugerida: `/empresa/productos/eliminados`.
class ProductosEliminadosPage extends StatelessWidget {
  const ProductosEliminadosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<ProductoListCubit>(),
      child: const _ProductosEliminadosView(),
    );
  }
}

class _ProductosEliminadosView extends StatefulWidget {
  const _ProductosEliminadosView();

  @override
  State<_ProductosEliminadosView> createState() =>
      _ProductosEliminadosViewState();
}

class _ProductosEliminadosViewState extends State<_ProductosEliminadosView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  void _cargar() {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is! EmpresaContextLoaded) return;
    context.read<ProductoListCubit>().loadProductos(
          empresaId: empresaState.context.empresa.id,
          filtros: const ProductoFiltros(soloEliminados: true, limit: 100),
        );
  }

  Future<void> _restaurar(ProductoListItem producto) async {
    final confirma = await ConfirmDialog.show(
      context: context,
      type: ConfirmDialogType.success,
      icon: Icons.restore_rounded,
      title: 'Restaurar producto',
      message:
          '"${producto.nombre}" volverá al listado activo. Si su SKU ya '
          'fue reasignado a otro producto, la restauración fallará.',
      confirmText: 'Restaurar',
    );
    if (confirma != true) return;
    if (!mounted) return;

    final repo = locator<ProductoRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await repo.restaurarProducto(productoId: producto.id);
    if (!mounted) return;

    if (result is Success<void>) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Producto restaurado'),
          backgroundColor: Colors.green,
        ),
      );
      _cargar(); // recargar la papelera (este producto ya no debería aparecer)
    } else if (result is Error<void>) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
        title: 'Productos eliminados',
      ),
      body: BlocBuilder<ProductoListCubit, ProductoListState>(
        builder: (context, state) {
          if (state is ProductoListLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ProductoListError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: Colors.red.shade400),
                    const SizedBox(height: 12),
                    Text(state.message, textAlign: TextAlign.center),
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
          if (state is ProductoListLoaded) {
            if (state.productos.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_sweep_outlined,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        'No hay productos eliminados',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async => _cargar(),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: state.productos.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final p = state.productos[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.red.shade50,
                      child: Icon(Icons.delete_outline,
                          color: Colors.red.shade700),
                    ),
                    title: Text(
                      p.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (p.codigoEmpresa.isNotEmpty)
                          Text('Código: ${p.codigoEmpresa}',
                              style: const TextStyle(fontSize: 11)),
                        // ProductoListItem no expone deletedAt, así que solo
                        // mostramos fecha si hay algún campo derivable; si no,
                        // omitimos. Backend lo incluye en findAll pero el
                        // model puede filtrarlo.
                      ],
                    ),
                    trailing: ElevatedButton.icon(
                      icon: const Icon(Icons.restore, size: 16),
                      label: const Text('Restaurar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      onPressed: () => _restaurar(p),
                    ),
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

/// Placeholder usado dentro de [DateFormatter] si en el futuro queremos
/// formatear la fecha de eliminación. Hoy no se usa pero deja el import
/// listo cuando se exponga `deletedAt` en `ProductoListItem`.
// ignore: unused_element
String _formatDeleted(DateTime? d) =>
    d == null ? '—' : DateFormatter.formatDate(d);
