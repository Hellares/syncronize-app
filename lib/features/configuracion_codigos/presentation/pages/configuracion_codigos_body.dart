import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/configuracion_codigos_cubit.dart';
import '../bloc/configuracion_codigos_state.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../widgets/config_seccion_card.dart';
import '../widgets/config_documentos_card.dart';
import '../widgets/preview_codigo_dialog.dart';

/// Widget que contiene la lógica de tabs y la gestión de estado de configuración de códigos.
/// Separado de la página principal para mejorar la mantenibilidad.
class ConfiguracionCodigosBody extends StatefulWidget {
  final TabController tabController;

  const ConfiguracionCodigosBody({
    super.key,
    required this.tabController,
  });

  @override
  State<ConfiguracionCodigosBody> createState() =>
      _ConfiguracionCodigosBodyState();
}

class _ConfiguracionCodigosBodyState extends State<ConfiguracionCodigosBody> {
  @override
  void initState() {
    super.initState();
    // Cargar configuración al iniciar el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConfiguracion();
    });
  }

  void _loadConfiguracion() {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      context.read<ConfiguracionCodigosCubit>().loadConfiguracion(
            empresaState.context.empresa.id,
          );
    } else {
      // Si la empresa aún no está cargada, reintentar después de un breve retraso
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _loadConfiguracion();
        }
      });
    }
  }

  void _showPreviewDialog(BuildContext context, String tipo) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<ConfiguracionCodigosCubit>(),
        child: PreviewCodigoDialog(tipo: tipo),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ConfiguracionCodigosCubit, ConfiguracionCodigosState>(
      listener: (context, state) {
        if (state is ConfiguracionCodigosLoaded && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
          context.read<ConfiguracionCodigosCubit>().clearError();
        }
      },
      builder: (context, state) {
        // Estados de carga y error
        if (state is ConfiguracionCodigosLoading ||
            state is ConfiguracionCodigosInitial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ConfiguracionCodigosError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar configuración',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(state.message),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadConfiguracion,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        if (state is ConfiguracionCodigosLoaded) {
          final config = state.configuracion;
          final isLoading = state.isLoading;

          return Stack(
            children: [
              TabBarView(
                controller: widget.tabController,
                children: [
                  // Tab Productos
                  ConfigSeccionCard(
                    titulo: 'Productos',
                    descripcion:
                        'Configura cómo se generan los códigos de productos',
                    seccion: config.productos,
                    restriccion: config.restricciones,
                    tipo: 'producto',
                    onUpdate: (codigo, separador, longitud, incluirSede) {
                      final empresaState =
                          context.read<EmpresaContextCubit>().state;
                      if (empresaState is EmpresaContextLoaded) {
                        context
                            .read<ConfiguracionCodigosCubit>()
                            .updateConfigProductos(
                              empresaId: empresaState.context.empresa.id,
                              productoCodigo: codigo,
                              productoSeparador: separador,
                              productoLongitud: longitud,
                              productoIncluirSede: incluirSede,
                            );
                      }
                    },
                    onPreview: () => _showPreviewDialog(context, 'PRODUCTO'),
                    isLoading: isLoading,
                  ),

                  // Tab Variantes
                  ConfigSeccionCard(
                    titulo: 'Variantes',
                    descripcion:
                        'Configura cómo se generan los códigos de variantes',
                    seccion: config.variantes,
                    restriccion: config.restricciones,
                    tipo: 'variante',
                    onUpdate: (codigo, separador, longitud, _) {
                      final empresaState =
                          context.read<EmpresaContextCubit>().state;
                      if (empresaState is EmpresaContextLoaded) {
                        context
                            .read<ConfiguracionCodigosCubit>()
                            .updateConfigVariantes(
                              empresaId: empresaState.context.empresa.id,
                              varianteCodigo: codigo,
                              varianteSeparador: separador,
                              varianteLongitud: longitud,
                            );
                      }
                    },
                    onPreview: () => _showPreviewDialog(context, 'VARIANTE'),
                    isLoading: isLoading,
                  ),

                  // Tab Servicios
                  ConfigSeccionCard(
                    titulo: 'Servicios',
                    descripcion:
                        'Configura cómo se generan los códigos de servicios',
                    seccion: config.servicios,
                    restriccion: config.restricciones,
                    tipo: 'servicio',
                    onUpdate: (codigo, separador, longitud, incluirSede) {
                      final empresaState =
                          context.read<EmpresaContextCubit>().state;
                      if (empresaState is EmpresaContextLoaded) {
                        context
                            .read<ConfiguracionCodigosCubit>()
                            .updateConfigServicios(
                              empresaId: empresaState.context.empresa.id,
                              servicioCodigo: codigo,
                              servicioSeparador: separador,
                              servicioLongitud: longitud,
                              servicioIncluirSede: incluirSede,
                            );
                      }
                    },
                    onPreview: () => _showPreviewDialog(context, 'SERVICIO'),
                    isLoading: isLoading,
                  ),

                  // Tab Ventas
                  ConfigSeccionCard(
                    titulo: 'Ventas (Notas de Venta)',
                    descripcion:
                        'Configura cómo se generan los códigos de ventas internas (Notas de Venta)',
                    seccion: config.ventas,
                    restriccion: config.restricciones,
                    tipo: 'venta',
                    onUpdate: (codigo, separador, longitud, incluirSede) {
                      final empresaState =
                          context.read<EmpresaContextCubit>().state;
                      if (empresaState is EmpresaContextLoaded) {
                        context
                            .read<ConfiguracionCodigosCubit>()
                            .updateConfigVentas(
                              empresaId: empresaState.context.empresa.id,
                              ventaCodigo: codigo,
                              ventaSeparador: separador,
                              ventaLongitud: longitud,
                              ventaIncluirSede: incluirSede,
                            );
                      }
                    },
                    onPreview: () => _showPreviewDialog(context, 'VENTA'),
                    isLoading: isLoading,
                  ),

                  // Tab Documentos
                  ConfigDocumentosCard(
                    documentos: config.documentos,
                    isLoading: isLoading,
                    onPreviewFactura: () =>
                        _showPreviewDialog(context, 'FACTURA'),
                    onPreviewBoleta: () =>
                        _showPreviewDialog(context, 'BOLETA'),
                    onPreviewNotaCredito: () =>
                        _showPreviewDialog(context, 'NOTA_CREDITO'),
                    onPreviewNotaDebito: () =>
                        _showPreviewDialog(context, 'NOTA_DEBITO'),
                  ),
                ],
              ),
              if (isLoading)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          );
        }

        // Fallback (no debería ocurrir)
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}