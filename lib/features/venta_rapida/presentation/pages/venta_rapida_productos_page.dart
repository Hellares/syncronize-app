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
          child: _VentaRapidaProductosView(sedeId: sedeId),
        );
      },
    );
  }
}

class _VentaRapidaProductosView extends StatelessWidget {
  final String sedeId;
  const _VentaRapidaProductosView({required this.sedeId});

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
      // Selector de sede activa (solo visible si hay >1 sede operable).
      topExtraBuilder: (_, __) => const Padding(
        padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: SedeSwitcher(),
      ),
    );
  }
}
