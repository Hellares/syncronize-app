import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../producto/domain/entities/producto_filtros.dart';
import '../../../producto/domain/entities/producto_list_item.dart';
import '../../../producto/domain/repositories/producto_repository.dart';
import '../../../producto/presentation/bloc/producto_list/producto_list_cubit.dart';
import '../../../producto/presentation/bloc/producto_list/producto_list_state.dart';

/// Papelera de COMBOS: lista los combos soft-deleted (`esCombo=true` +
/// `deletedAt != null`) con opción de restaurarlos. Reusa la infraestructura
/// de productos (un combo ES un Producto): filtra `soloCombos + soloEliminados`
/// y restaura con `PATCH /productos/:id/restaurar`.
///
/// Ruta: `/empresa/combos/eliminados`.
class CombosEliminadosPage extends StatelessWidget {
  const CombosEliminadosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<ProductoListCubit>(),
      child: const _CombosEliminadosView(),
    );
  }
}

class _CombosEliminadosView extends StatefulWidget {
  const _CombosEliminadosView();

  @override
  State<_CombosEliminadosView> createState() => _CombosEliminadosViewState();
}

class _CombosEliminadosViewState extends State<_CombosEliminadosView> {
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
          filtros: const ProductoFiltros(
            soloEliminados: true,
            soloCombos: true,
            limit: 100,
          ),
        );
  }

  Future<void> _restaurar(ProductoListItem combo) async {
    final confirma = await ConfirmDialog.show(
      context: context,
      type: ConfirmDialogType.success,
      icon: Icons.restore_rounded,
      title: 'Restaurar combo',
      message: '"${combo.nombre}" volverá al listado de combos activos.',
      confirmText: 'Restaurar',
    );
    if (confirma != true || !mounted) return;

    final repo = locator<ProductoRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await repo.restaurarProducto(productoId: combo.id);
    if (!mounted) return;

    if (result is Success<void>) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Combo restaurado'),
          backgroundColor: Colors.green,
        ),
      );
      _cargar();
    } else if (result is Error<void>) {
      messenger.showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
        title: 'Combos eliminados',
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
                        'No hay combos eliminados',
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
                  final c = state.productos[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.red.shade50,
                      child: Icon(Icons.local_offer_outlined,
                          color: Colors.red.shade700),
                    ),
                    title: Text(
                      c.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: c.codigoEmpresa.isNotEmpty
                        ? Text('Código: ${c.codigoEmpresa}',
                            style: const TextStyle(fontSize: 11))
                        : null,
                    trailing: ElevatedButton.icon(
                      icon: const Icon(Icons.restore, size: 16),
                      label: const Text('Restaurar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      onPressed: () => _restaurar(c),
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
