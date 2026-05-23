import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth/auth_bloc.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../producto/domain/entities/producto_filtros.dart';
import '../../../producto/presentation/bloc/producto_list/producto_list_cubit.dart';
import '../../../producto/presentation/widgets/producto_selector/producto_selector_view.dart';
import '../bloc/cotizacion_rapida_cubit.dart';
import '../widgets/item_manual_dialog.dart';

/// Pantalla de selección de productos para cotización rápida. Toda la UI
/// vive en `ProductoSelectorView<CotizacionRapidaCubit, CotizacionRapidaState>`.
/// Diferencias específicas de cotización inyectadas vía slots:
/// - `topExtraBuilder`: toggle "Simple / Para Venta" + botón "+ Manual".
/// - Atajo en search hacia `/empresa/venta-rapida`.
/// - Título reactivo "Cotización" / "Editar items" según `state.modoEdicion`.
///
/// Soporta modo embebida para edición: el wrapper externo provee los cubits
/// con `cargarParaEdicion()` y modoEdicion=true.
class CotizacionRapidaProductosPage extends StatelessWidget {
  /// Cuando es true, asume que el `CotizacionRapidaCubit` y el
  /// `ProductoListCubit` ya están provistos arriba en el árbol (caso
  /// editar); el widget no los reinicializa.
  final bool embebida;

  const CotizacionRapidaProductosPage({super.key}) : embebida = false;
  const CotizacionRapidaProductosPage.embebida({super.key}) : embebida = true;

  @override
  Widget build(BuildContext context) {
    final empresaState = context.read<EmpresaContextCubit>().state;
    final authState = context.read<AuthBloc>().state;

    String? empresaId;
    String? sedeId;
    String? vendedorId;
    if (empresaState is EmpresaContextLoaded) {
      empresaId = empresaState.context.empresa.id;
      sedeId = empresaState.context.sedePrincipal?.id ??
          (empresaState.context.sedes.isNotEmpty
              ? empresaState.context.sedes.first.id
              : null);
    }
    if (authState is Authenticated) {
      vendedorId = authState.user.id;
    }

    if (empresaId == null || sedeId == null || vendedorId == null) {
      return const Scaffold(
        body: Center(child: Text('Falta contexto de empresa/sede')),
      );
    }

    // Modo embebida: el wrapper (editar page) ya inyectó los cubits y llamó
    // `cargarParaEdicion`. Solo renderizamos la vista.
    if (embebida) {
      return _CotizacionProductosView(sedeId: sedeId);
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(
          value: () {
            final cubit = locator<CotizacionRapidaCubit>();
            cubit.setContexto(
              empresaId: empresaId!,
              sedeId: sedeId!,
              vendedorId: vendedorId!,
            );
            return cubit;
          }(),
        ),
        BlocProvider(
          create: (_) => locator<ProductoListCubit>()
            ..loadProductos(
              empresaId: empresaId!,
              sedeId: sedeId,
              filtros: const ProductoFiltros(isActive: true, esInsumo: false),
            ),
        ),
      ],
      child: _CotizacionProductosView(sedeId: sedeId),
    );
  }
}

class _CotizacionProductosView extends StatelessWidget {
  final String sedeId;
  const _CotizacionProductosView({required this.sedeId});

  /// Abre el dialog de items manuales y los agrega en lote al cubit.
  Future<void> _agregarItemManual(BuildContext context) async {
    final results = await showItemManualDialog(context);
    if (results == null || results.isEmpty || !context.mounted) return;
    context.read<CotizacionRapidaCubit>().agregarItemsManuales(
          results
              .map((r) => (
                    descripcion: r.descripcion,
                    cantidad: r.cantidad,
                    precioUnitario: r.precioUnitario,
                  ))
              .toList(),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          results.length == 1
              ? '✓ Item manual agregado'
              : '✓ ${results.length} items manuales agregados',
        ),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CotizacionRapidaCubit>();
    return ProductoSelectorView<CotizacionRapidaCubit, CotizacionRapidaState>(
      sedeId: sedeId,
      snapshotBuilder: (s) => (
        items: s.items,
        comboPendienteOferta: s.comboPendienteOferta,
      ),
      tituloBuilder: (s) => s.modoEdicion ? 'Editar items' : 'Cotización',
      onIrAlCarrito: () =>
          context.push('/empresa/cotizaciones/nueva/carrito'),
      onAgregarProducto: cubit.agregarProducto,
      onDecrementarProducto: cubit.decrementarProducto,
      onCargarNiveles: cubit.getNivelesProducto,
      onAceptarComboOferta: (aceptar) {
        if (aceptar) {
          cubit.confirmarComboPendiente();
        } else {
          cubit.cancelarComboPendiente();
        }
      },
      // Atajo simétrico: desde Cotización, navegar a Venta Rápida.
      // `pushReplacement` (no push) evita que el stack acumule
      // Coti/VR/Coti/VR al ir y volver — son páginas hermanas, no
      // anidadas. Al hacer back vas a lo que tenías ANTES del selector.
      atajoIcono: Icons.shopping_cart_outlined,
      atajoTooltip: 'Ir a Venta Rápida',
      onAtajo: () => context.pushReplacement('/empresa/venta-rapida'),
      // Slot superior: toggle Simple/Para Venta + botón "Manual".
      topExtraBuilder: (ctx, state) {
        final esSimple = state.tipoCotizacion == TipoCotizacionRapida.simple;
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.blue1.withValues(alpha: 0.18),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: TipoCotizacionRapida.simple,
                        label:
                            Text('Simple', style: TextStyle(fontSize: 11)),
                        icon: Icon(Icons.description_outlined, size: 14),
                      ),
                      ButtonSegment(
                        value: TipoCotizacionRapida.paraVenta,
                        label: Text('Para Venta',
                            style: TextStyle(fontSize: 11)),
                        icon: Icon(Icons.shopping_cart_outlined, size: 14),
                      ),
                    ],
                    selected: {state.tipoCotizacion},
                    showSelectedIcon: false,
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      // Override del teal/purple por defecto de Material3
                      // para alinear con el blue1 del sistema.
                      backgroundColor:
                          WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return AppColors.blue1;
                        }
                        return Colors.white;
                      }),
                      foregroundColor:
                          WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.white;
                        }
                        return AppColors.blue1;
                      }),
                      side: WidgetStateProperty.all(
                        BorderSide(
                          color: AppColors.blue1.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      overlayColor: WidgetStateProperty.all(
                        AppColors.blue1.withValues(alpha: 0.08),
                      ),
                    ),
                    onSelectionChanged: (s) {
                      ctx
                          .read<CotizacionRapidaCubit>()
                          .setTipoCotizacion(s.first);
                    },
                  ),
                ),
              ),
              if (esSimple) ...[
                const SizedBox(width: 8),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.blue1,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  onPressed: () => _agregarItemManual(ctx),
                  icon: const Icon(Icons.edit_note, size: 16),
                  label: const Text('Manual',
                      style: TextStyle(fontSize: 11)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
