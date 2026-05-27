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
import '../../../producto/domain/entities/producto_filtros.dart';
import '../../../producto/presentation/bloc/producto_list/producto_list_cubit.dart';
import '../../../producto/presentation/widgets/producto_selector/producto_selector_view.dart';
import '../bloc/venta_rapida_cubit.dart';

/// Pantalla de selección de productos para Venta Rápida. Toda la UI vive en
/// `ProductoSelectorView<VentaRapidaCubit, VentaRapidaState>` — esta page
/// solo provee los cubits y mapea los callbacks al `VentaRapidaCubit`.
class VentaRapidaProductosPage extends StatelessWidget {
  const VentaRapidaProductosPage({super.key});

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

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(
          value: () {
            final cubit = locator<VentaRapidaCubit>();
            cubit.setContexto(
              empresaId: empresaId!,
              sedeId: sedeId!,
              vendedorId: vendedorId!,
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
              empresaId: empresaId!,
              sedeId: sedeId,
              filtros: const ProductoFiltros(isActive: true, esInsumo: false),
            ),
        ),
      ],
      child: _VentaRapidaProductosView(sedeId: sedeId),
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
    );
  }
}
