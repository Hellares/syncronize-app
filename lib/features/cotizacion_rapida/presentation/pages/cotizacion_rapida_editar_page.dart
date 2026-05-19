import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/resource.dart';
import '../../../auth/presentation/bloc/auth/auth_bloc.dart';
import '../../../cotizacion/domain/entities/cotizacion.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../producto/domain/entities/producto_filtros.dart';
import '../../../producto/presentation/bloc/producto_list/producto_list_cubit.dart';
import '../../domain/usecases/obtener_cotizacion_rapida_usecase.dart';
import '../bloc/cotizacion_rapida_cubit.dart';
import 'cotizacion_rapida_productos_page.dart';

/// Wrapper para editar cotizaciones existentes (solo agregar/quitar items).
/// 1. Carga la cotización por id.
/// 2. La inyecta al `CotizacionRapidaCubit` (modo edición) UNA SOLA VEZ —
///    si lo hiciéramos en `build`, cada rebuild reseteaba los items que el
///    cajero acababa de agregar.
/// 3. Renderiza la grid de productos. El botón final del carrito dice
///    "GUARDAR CAMBIOS" cuando `modoEdicion=true` y dispara PUT /cotizaciones/:id.
///
/// Solo se permite editar si la cotización está en BORRADOR (validación
/// final del backend; aquí avisamos antes para no perder el viaje).
class CotizacionRapidaEditarPage extends StatefulWidget {
  final String cotizacionId;

  const CotizacionRapidaEditarPage({
    super.key,
    required this.cotizacionId,
  });

  @override
  State<CotizacionRapidaEditarPage> createState() =>
      _CotizacionRapidaEditarPageState();
}

class _CotizacionRapidaEditarPageState
    extends State<CotizacionRapidaEditarPage> {
  Cotizacion? _cotizacion;
  bool _loading = true;
  String? _error;

  /// Contexto resuelto en el load inicial. Si falta alguno, el wrapper
  /// muestra mensaje de error en lugar de la grid.
  String? _empresaId;
  String? _sedeId;
  String? _vendedorId;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await locator<ObtenerCotizacionRapidaUseCase>()(
      cotizacionId: widget.cotizacionId,
    );
    if (!mounted) return;

    if (result is Error<Cotizacion>) {
      setState(() {
        _error = result.message;
        _loading = false;
      });
      return;
    }

    if (result is! Success<Cotizacion>) {
      setState(() {
        _error = 'No se pudo cargar la cotización';
        _loading = false;
      });
      return;
    }

    final cot = result.data;

    // Solo inicializamos el cubit si la cotización es editable y tenemos
    // contexto completo. Lo hacemos UNA sola vez aquí (no en `build`) para
    // que `cargarParaEdicion` no se vuelva a disparar en rebuilds y borre
    // los items que el cajero agregó.
    if (cot.estado == EstadoCotizacion.borrador) {
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
      if (empresaId != null && sedeId != null && vendedorId != null) {
        final cubit = locator<CotizacionRapidaCubit>();
        cubit.setContexto(
          empresaId: empresaId,
          sedeId: sedeId,
          vendedorId: vendedorId,
        );
        cubit.cargarParaEdicion(cot);
        _empresaId = empresaId;
        _sedeId = sedeId;
        _vendedorId = vendedorId;
      }
    }

    setState(() {
      _cotizacion = cot;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _cotizacion == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.blue1,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    size: 48, color: Colors.red.shade400),
                const SizedBox(height: 12),
                Text(
                  _error ?? 'No se pudo cargar la cotización',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _cargar,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Volver'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final cot = _cotizacion!;

    if (cot.estado != EstadoCotizacion.borrador) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.blue1,
          foregroundColor: Colors.white,
          title: const Text('No se puede editar'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline,
                    size: 48, color: Colors.orange.shade400),
                const SizedBox(height: 12),
                Text(
                  'Esta cotización está en estado ${cot.estado.name.toUpperCase()} '
                  'y ya no se puede editar. Solo las cotizaciones en BORRADOR '
                  'permiten cambios.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context
                      .go('/empresa/cotizaciones/${widget.cotizacionId}'),
                  child: const Text('Ver detalle'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_empresaId == null || _sedeId == null || _vendedorId == null) {
      return const Scaffold(
        body: Center(child: Text('Falta contexto de empresa/sede')),
      );
    }

    return MultiBlocProvider(
      providers: [
        // El cubit ya fue inicializado en `_cargar()` con `cargarParaEdicion`.
        // En cada rebuild solo lo exponemos — no se vuelve a llamar el setter,
        // por lo que los items que el cajero agregó/quitó persisten.
        BlocProvider.value(value: locator<CotizacionRapidaCubit>()),
        BlocProvider(
          create: (_) => locator<ProductoListCubit>()
            ..loadProductos(
              empresaId: _empresaId!,
              sedeId: _sedeId,
              filtros: const ProductoFiltros(isActive: true, esInsumo: false),
            ),
        ),
      ],
      child: const CotizacionRapidaProductosPage.embebida(),
    );
  }
}
