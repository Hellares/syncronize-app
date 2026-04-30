import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/producto_sede_selector/producto_sede_selector.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';

/// Punto de entrada global para ver el kardex de cualquier producto.
/// Selecciona producto + sede → resuelve el stockId → navega a la KardexPage existente.
class KardexGlobalPage extends StatelessWidget {
  const KardexGlobalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const SmartAppBar(title: 'Kardex'),
        body: BlocBuilder<EmpresaContextCubit, EmpresaContextState>(
          builder: (context, state) {
            if (state is! EmpresaContextLoaded) {
              return const Center(child: CircularProgressIndicator());
            }
            // Pre-seleccionamos la sede principal (o la primera) para que el
            // selector arranque cargando productos sin que el usuario tenga
            // que tocar el dropdown de sede.
            final sedeInicial = state.context.sedePrincipal?.id ??
                (state.context.sedes.isNotEmpty
                    ? state.context.sedes.first.id
                    : null);
            return _KardexGlobalContent(
              empresaId: state.context.empresa.id,
              sedeIdInicial: sedeInicial,
            );
          },
        ),
      ),
    );
  }
}

class _KardexGlobalContent extends StatefulWidget {
  final String empresaId;
  final String? sedeIdInicial;
  const _KardexGlobalContent({
    required this.empresaId,
    this.sedeIdInicial,
  });

  @override
  State<_KardexGlobalContent> createState() => _KardexGlobalContentState();
}

class _KardexGlobalContentState extends State<_KardexGlobalContent> {
  bool _resolviendoStock = false;
  String? _errorResolver;

  Future<void> _abrirKardex({
    required String productoId,
    required String productoNombre,
    required String sedeId,
    String? varianteId,
    String? varianteNombre,
  }) async {
    if (_resolviendoStock) return;
    setState(() {
      _resolviendoStock = true;
      _errorResolver = null;
    });

    final dio = locator<DioClient>();
    String? stockId;

    try {
      // El backend tiene endpoints separados para producto y variante.
      // Devuelven el ProductoStock (con id) si existe; sino, lanzan o devuelven null.
      final path = varianteId != null
          ? '/producto-stock/variante/$varianteId/sede/$sedeId'
          : '/producto-stock/producto/$productoId/sede/$sedeId';

      final response = await dio.get(path);
      final data = response.data;
      if (data is Map<String, dynamic>) {
        stockId = data['id'] as String?;
      }
    } catch (e) {
      // Caer al fallback de mensaje de error abajo.
    }

    if (!mounted) return;

    if (stockId == null) {
      setState(() {
        _resolviendoStock = false;
        _errorResolver =
            'Este producto aún no tiene stock registrado en la sede seleccionada. Selecciona otra sede o crea el stock primero.';
      });
      return;
    }

    setState(() => _resolviendoStock = false);

    final nombre = varianteNombre != null
        ? '$productoNombre — $varianteNombre'
        : productoNombre;
    context.push(
      '/empresa/inventario/kardex/$stockId?nombre=${Uri.encodeComponent(nombre)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado descriptivo
          GradientContainer(
            borderColor: AppColors.blueborder,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.bluechip,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.history,
                        size: 20, color: AppColors.blue1),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSubtitle('Kardex de productos', fontSize: 14),
                        SizedBox(height: 2),
                        AppText(
                          'Selecciona un producto y una sede para ver su historial de movimientos.',
                          size: 11,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Selector
          GradientContainer(
            borderColor: AppColors.blueborder,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ProductoSedeSelector(
                empresaId: widget.empresaId,
                sedeIdInicial: widget.sedeIdInicial,
                label: 'Producto',
                hintText: 'Buscar producto...',
                soloProductos: false,
                onProductoSeleccionado: ({
                  required producto,
                  required sedeId,
                  variante,
                }) {
                  _abrirKardex(
                    productoId: producto.id,
                    productoNombre: producto.nombre,
                    sedeId: sedeId,
                    varianteId: variante?.id,
                    varianteNombre: variante?.nombre,
                  );
                },
              ),
            ),
          ),

          if (_resolviendoStock) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                'Cargando kardex...',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
          ],

          if (_errorResolver != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      size: 14, color: Colors.amber.shade800),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _errorResolver!,
                      style: TextStyle(
                          fontSize: 11, color: Colors.amber.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
