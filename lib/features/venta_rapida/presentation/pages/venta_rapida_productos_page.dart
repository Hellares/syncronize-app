import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/resource.dart';
import '../../../auth/presentation/bloc/auth/auth_bloc.dart';
import '../../../caja/domain/entities/caja.dart';
import '../../../caja/domain/usecases/get_caja_activa_usecase.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../empresa/presentation/bloc/sede_activa/sede_activa_cubit.dart';
import '../../../empresa/presentation/bloc/sede_activa/sede_activa_state.dart';
import '../../../empresa/presentation/widgets/sede_switcher.dart';
import '../../../producto/domain/entities/producto_filtros.dart';
import '../../../producto/presentation/bloc/producto_list/producto_list_cubit.dart';
import '../../../producto/presentation/widgets/producto_selector/producto_selector_view.dart';
import '../bloc/venta_rapida_cubit.dart';
import '../widgets/alta_rapida_producto_dialog.dart';

/// Pantalla de selección de productos para Venta Rápida. Toda la UI vive en
/// `ProductoSelectorView<VentaRapidaCubit, VentaRapidaState>` — esta page
/// solo provee los cubits y mapea los callbacks al `VentaRapidaCubit`.
class VentaRapidaProductosPage extends StatefulWidget {
  const VentaRapidaProductosPage({super.key});

  @override
  State<VentaRapidaProductosPage> createState() =>
      _VentaRapidaProductosPageState();
}

class _VentaRapidaProductosPageState extends State<VentaRapidaProductosPage> {
  @override
  void initState() {
    super.initState();
    // Sincroniza la sede activa con las sedes operables del usuario (auto-elige
    // si hay una sola; restaura la persistida si sigue operable).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final empresaState = context.read<EmpresaContextCubit>().state;
      if (empresaState is EmpresaContextLoaded) {
        context.read<SedeActivaCubit>().sincronizar(
              empresaState.context.sedesOperables,
              principal: empresaState.context.sedePrincipal,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final empresaState = context.read<EmpresaContextCubit>().state;
    final authState = context.read<AuthBloc>().state;

    if (empresaState is! EmpresaContextLoaded || authState is! Authenticated) {
      return const Scaffold(
        body: Center(child: Text('Falta contexto de empresa/sede')),
      );
    }
    final empresaId = empresaState.context.empresa.id;
    final vendedorId = authState.user.id;
    final operables = empresaState.context.sedesOperables;

    return BlocBuilder<SedeActivaCubit, SedeActivaState>(
      builder: (context, sedeState) {
        final activa = sedeState.activa;
        if (activa == null) {
          if (operables.isEmpty) {
            return const Scaffold(
              body: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No tenés una sede asignada para vender.\nPedí al administrador que te asigne a una sede.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final sedeId = activa.id;
        // key por sede → al cambiar de sede, se recrean los cubits y se recargan
        // los productos/stock de la sede activa.
        return MultiBlocProvider(
          key: ValueKey('vr-$sedeId'),
          providers: [
            BlocProvider.value(
              value: () {
                final cubit = locator<VentaRapidaCubit>();
                cubit.setContexto(
                  empresaId: empresaId,
                  sedeId: sedeId,
                  vendedorId: vendedorId,
                );
                return cubit;
              }(),
            ),
            BlocProvider(
              // Venta Rápida solo debe mostrar productos disponibles para venta
              // (isActive=true). Productos inactivos o eliminados quedan ocultos
              // en este flujo de cobro.
              create: (_) => locator<ProductoListCubit>()
                ..loadProductos(
                  empresaId: empresaId,
                  sedeId: sedeId,
                  filtros:
                      const ProductoFiltros(isActive: true, esInsumo: false),
                ),
            ),
          ],
          child: _VentaRapidaProductosView(
            sedeId: sedeId,
            empresaId: empresaId,
          ),
        );
      },
    );
  }
}

class _VentaRapidaProductosView extends StatelessWidget {
  final String sedeId;
  final String empresaId;
  const _VentaRapidaProductosView({
    required this.sedeId,
    required this.empresaId,
  });

  /// Da de alta el producto que se acaba de buscar y lo mete al carrito.
  ///
  /// 🔴 El alta devuelve el producto RELEIDO, con su `stocksPorSede` ya
  /// cargado: agregarlo sin eso lo rechaza el carrito con "no tiene precio
  /// configurado en esta sede".
  Future<void> _altaRapida(BuildContext context, String nombre) async {
    final cubit = context.read<VentaRapidaCubit>();
    final creado = await showAltaRapidaProductoDialog(
      context,
      empresaId: empresaId,
      sedeId: sedeId,
      nombreInicial: nombre,
    );
    if (creado == null || !context.mounted) return;
    cubit.agregarProducto(creado);
    // La lista sigue filtrada por lo tecleado y el producto nuevo no esta en
    // ella hasta recargar; el feedback de que entro es el carrito.
    context.read<ProductoListCubit>().reload(sedeId: sedeId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${creado.nombre} creado y agregado'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _verificarCajaYNavegar(BuildContext context) async {
    final result = await locator<GetCajaActivaUseCase>()();
    if (!context.mounted) return;
    if (result is Success<Caja?> && result.data != null) {
      await context.push('/empresa/venta-rapida/carrito');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text('Debes abrir tu caja antes de continuar')),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Abrir Caja',
            textColor: Colors.white,
            onPressed: () => context.push('/empresa/caja'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<VentaRapidaCubit>();
    // 🔴 El alta rápida solo se OFRECE con el granular
    // `producto.alta-rapida-venta`. El endpoint lo valida igual; esto evita
    // mostrar un botón que va a rebotar con 403. Los admin lo tienen por
    // definición.
    final empresaState = context.read<EmpresaContextCubit>().state;
    final puedeAltaRapida = empresaState is EmpresaContextLoaded &&
        empresaState.context.permissions.canAltaRapidaVenta;
    // Vender a costo revive `venta.editar-precio`, un granular que ya estaba
    // en el catálogo: vender a costo ES cambiar el precio al cobrar.
    // ⚠️ Dárselo a un cajero le muestra el costo de TODO el catálogo.
    final puedeVenderACosto = empresaState is EmpresaContextLoaded &&
        empresaState.context.permissions.canEditarPrecioVenta;

    return ProductoSelectorView<VentaRapidaCubit, VentaRapidaState>(
      sedeId: sedeId,
      snapshotBuilder: (s) => (
        items: s.items,
        comboPendienteOferta: s.comboPendienteOferta,
      ),
      tituloBuilder: (_) => 'Productos',
      onIrAlCarrito: () => _verificarCajaYNavegar(context),
      onAgregarProducto: cubit.agregarProducto,
      onAgregarVariante: cubit.agregarVariante,
      onDecrementarVariante: (p, v) => cubit.decrementarVariante(p.id, v.id),
      onDecrementarProducto: cubit.decrementarProducto,
      onCargarNiveles: cubit.getNivelesProducto,
      onAceptarComboOferta: (aceptar) {
        if (aceptar) {
          cubit.confirmarComboPendiente();
        } else {
          cubit.cancelarComboPendiente();
        }
      },
      // Atajo simétrico: desde VR, navegar a "Nueva Cotización".
      // Usamos `pushReplacement` (no push) para que el stack no acumule
      // VR/Coti/VR/Coti al ir y volver — VR y Cotización son páginas
      // hermanas, no anidadas. Al hacer back, vas a lo que tenías ANTES
      // de entrar a este selector.
      atajoIcono: Icons.request_quote_outlined,
      atajoTooltip: 'Nueva cotización',
      onAtajo: () => context.pushReplacement('/empresa/cotizaciones/nueva'),
      onAltaRapida:
          puedeAltaRapida ? (nombre) => _altaRapida(context, nombre) : null,
      // Selector de sede activa + el interruptor de "vender a costo".
      topExtraBuilder: (_, __) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SedeSwitcher(),
            if (puedeVenderACosto) const _InterruptorCosto(),
          ],
        ),
      ),
    );
  }
}

/// Cobrar los productos a lo que costaron.
///
/// 🔴 Solo se OFRECE con el granular `venta.editar-precio`: el endpoint de
/// costos lo valida igual, y mostrar el interruptor sin él sería ofrecer algo
/// que rebota con 403. Los admin lo tienen por definición.
class _InterruptorCosto extends StatelessWidget {
  const _InterruptorCosto();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VentaRapidaCubit, VentaRapidaState>(
      buildWhen: (a, b) =>
          a.modoCosto != b.modoCosto ||
          a.cargandoCostos != b.cargandoCostos ||
          a.lineasACosto != b.lineasACosto,
      builder: (context, state) {
        final activo = state.modoCosto != null;
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Material(
            color: activo ? const Color(0xFF043261) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: state.cargandoCostos
                  ? null
                  : () => context.read<VentaRapidaCubit>().toggleModoCosto(),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.savings_outlined,
                      size: 18,
                      color: activo ? Colors.white : Colors.grey.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.cargandoCostos
                            ? 'Buscando costos…'
                            : activo
                                ? 'Vendiendo a costo · ${state.lineasACosto} '
                                    '${state.lineasACosto == 1 ? 'línea' : 'líneas'}'
                                : 'Vender a costo',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: activo ? Colors.white : Colors.grey.shade700,
                        ),
                      ),
                    ),
                    Switch(
                      value: activo,
                      onChanged: state.cargandoCostos
                          ? null
                          : (_) => context
                              .read<VentaRapidaCubit>()
                              .toggleModoCosto(),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
