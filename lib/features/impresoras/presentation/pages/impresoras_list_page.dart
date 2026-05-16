import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/snack_bar_helper.dart';
import '../../domain/entities/impresora_config.dart';
import '../bloc/impresoras_list_cubit.dart';
import '../bloc/impresoras_list_state.dart';
import 'impresora_form_page.dart';

class ImpresorasListPage extends StatelessWidget {
  const ImpresorasListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<ImpresorasListCubit>()..cargar(),
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Impresoras',
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
      ),
      floatingActionButton: Builder(
        builder: (innerCtx) => FloatingActionButton(
          backgroundColor: AppColors.blue1,
          onPressed: () async {
            final ok = await Navigator.of(innerCtx).push<bool>(
              MaterialPageRoute(builder: (_) => const ImpresoraFormPage()),
            );
            if (ok == true && innerCtx.mounted) {
              innerCtx.read<ImpresorasListCubit>().cargar();
            }
          },
          child: const Icon(Icons.add, color: AppColors.white),
        ),
      ),
      body: GradientContainer(
        child: BlocConsumer<ImpresorasListCubit, ImpresorasListState>(
          listener: (context, state) {
            if (state is ImpresorasListError) {
              SnackBarHelper.showError(context, state.message);
            }
          },
          builder: (context, state) {
            if (state is ImpresorasListLoading || state is ImpresorasListInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ImpresorasListError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.red),
                    const SizedBox(height: 12),
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Reintentar',
                      onPressed: () => context.read<ImpresorasListCubit>().cargar(),
                    ),
                  ],
                ),
              );
            }
            if (state is ImpresorasListLoaded) {
              if (state.impresoras.isEmpty) return const _EmptyState();
              return RefreshIndicator(
                onRefresh: () => context.read<ImpresorasListCubit>().cargar(),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                  itemCount: state.impresoras.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) => _ImpresoraTile(imp: state.impresoras[i]),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _ImpresoraTile extends StatelessWidget {
  final ImpresoraConfig imp;
  const _ImpresoraTile({required this.imp});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final ok = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => ImpresoraFormPage(impresoraId: imp.id),
          ),
        );
        if (ok == true && context.mounted) {
          context.read<ImpresorasListCubit>().cargar();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(
              imp.tipoConexion == TipoConexionImpresora.bluetooth
                  ? Icons.bluetooth
                  : Icons.lan,
              size: 22,
              color: AppColors.blue1,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    imp.nombre,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    imp.direccion,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  Text(
                    '${imp.anchoPapel.label} · ${imp.tamanoFuentePx}px${imp.autoImprimirVentaRapida ? ' · auto-print' : ''}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                const Text(
                  'Principal',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                Checkbox(
                  value: imp.esPrincipal,
                  activeColor: AppColors.blue1,
                  visualDensity: VisualDensity.compact,
                  onChanged: (v) async {
                    if (v == true && !imp.esPrincipal) {
                      await context.read<ImpresorasListCubit>().marcarPrincipal(imp.id);
                    }
                  },
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.cancel_outlined, size: 20),
              color: AppColors.red,
              tooltip: 'Eliminar',
              visualDensity: VisualDensity.compact,
              onPressed: () => _confirmarEliminar(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarEliminar(BuildContext context) async {
    final cubit = context.read<ImpresorasListCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Eliminar impresora'),
        content: Text('¿Eliminar "${imp.nombre}" de la lista?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) await cubit.eliminar(imp.id);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.print_outlined,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          const Text(
            'No hay ninguna impresora vinculada',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Toca el botón + para agregar una impresora térmica Bluetooth',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
