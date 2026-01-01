import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_background.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/widgets/floating_button_icon.dart';
import 'package:syncronize/core/widgets/info_chip.dart';
import '../../../../core/widgets/animated_confirm_dialog.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../bloc/configuracion_precio/configuracion_precio_cubit.dart';
import '../bloc/configuracion_precio/configuracion_precio_state.dart';
import '../widgets/configuracion_precio_form_dialog.dart';
import '../../domain/entities/configuracion_precio.dart';

/// Página para gestionar las configuraciones de precios
class ConfiguracionesPrecioPage extends StatefulWidget {
  const ConfiguracionesPrecioPage({super.key});

  @override
  State<ConfiguracionesPrecioPage> createState() =>
      _ConfiguracionesPrecioPageState();
}

class _ConfiguracionesPrecioPageState extends State<ConfiguracionesPrecioPage> {
  @override
  void initState() {
    super.initState();
    // Cargar configuraciones al iniciar la página
    Future.microtask(() {
      if (mounted) {
        context.read<ConfiguracionPrecioCubit>().loadConfiguraciones();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Hacer el scaffold transparente
      extendBodyBehindAppBar: true, // Extender el body detrás del AppBar
      appBar: SmartAppBar(
        title: 'Configuraciones de Precios',
        showLogo: true,
        logoPath: 'assets/animations/logo1.json',
      ),
      body: GradientBackground(
        style: GradientStyle.professional, // Estilo directo sin variable
        child: SafeArea(
          // SafeArea para que el contenido no se superponga con el AppBar
          child:
              BlocConsumer<ConfiguracionPrecioCubit, ConfiguracionPrecioState>(
                listener: (context, state) {
                  if (state is ConfiguracionPrecioLoaded &&
                      state.errorMessage != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.errorMessage!),
                        backgroundColor: Colors.red,
                      ),
                    );
                    context.read<ConfiguracionPrecioCubit>().clearError();
                  }
                },
                builder: (context, state) {
                  if (state is ConfiguracionPrecioLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is ConfiguracionPrecioError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(state.message),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context
                                  .read<ConfiguracionPrecioCubit>()
                                  .loadConfiguraciones();
                            },
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is ConfiguracionPrecioLoaded) {
                    return _buildContent(context, state);
                  }

                  return const SizedBox.shrink();
                },
              ),
        ), // Cierre de SafeArea
      ), // Cierre de GradientBackground
      floatingActionButton: FloatingButtonIcon(
        onPressed: () => _showFormDialog(context),
        size: 32,
        icon: Icons.add,
      ),
    );
  }

  Widget _buildContent(BuildContext context, ConfiguracionPrecioLoaded state) {
    if (state.configuraciones.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_graph_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'No hay configuraciones de precios',
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu primera configuración para empezar',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: state.configuraciones.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final config = state.configuraciones[index];
            return _buildConfiguracionCard(context, config);
          },
        ),
        if (state.isLoading)
          Container(
            color: Colors.black26,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildConfiguracionCard(
    BuildContext context,
    ConfiguracionPrecio config,
  ) {
    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(), // Gradiente sutil para las cards
      borderRadius: BorderRadius.circular(12),
      shadowStyle: ShadowStyle.glow, // Efecto neumórfico elegante
      borderColor: AppColors.blueborder,
      borderWidth: 0.8,
      child: InkWell(
        onTap: () => _showFormDialog(context, configuracion: config),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSubtitle(
                          config.nombre,
                          fontSize: 12,
                          color: AppColors.blue1,
                        ),
                        if (config.descripcion != null) ...[
                          const SizedBox(height: 4),
                          AppLabelText(
                            config.descripcion!,
                            color: AppColors.blueGrey,
                            fontSize: 10,
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outlined,
                      color: AppColors.blueGrey,
                    ),
                    onPressed: () => _confirmDelete(context, config),
                  ),
                ],
              ),
              // const SizedBox(height: 5),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // Niveles
              ...config.niveles.map(
                (nivel) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 27,
                        height: 27,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: AppSubtitle(
                            '${nivel.orden + 1}',
                            fontSize: 11,
                            color: AppColors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppSubtitle(
                              nivel.nombre,
                              fontSize: 11,
                              color: AppColors.blue1,
                            ),
                            AppLabelText(
                              '${nivel.rangoString} unid. • ${nivel.getDescripcionPrecio(null)}',
                              color: AppColors.blueGrey,
                              fontSize: 10,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (config.cantidadProductosUsando != null &&
                  config.cantidadProductosUsando! > 0) ...[
                InfoChip(
                  icon: Icons.inventory_2_outlined,
                  text:
                      'Usado en ${config.cantidadProductosUsando} producto(s)',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showFormDialog(
    BuildContext context, {
    ConfiguracionPrecio? configuracion,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<ConfiguracionPrecioCubit>(),
        child: ConfiguracionPrecioFormDialog(configuracion: configuracion),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ConfiguracionPrecio config) {
    final canDelete =
        config.cantidadProductosUsando == null ||
        config.cantidadProductosUsando! == 0;

    AnimatedConfirmDialog.show(
      context: context,
      title: 'Eliminar configuración',
      message:
          '¿Estás seguro de eliminar "${config.nombre}"?\n\n'
          '${!canDelete ? "Esta configuración está siendo usada por ${config.cantidadProductosUsando} producto(s). No podrás eliminarla." : "Esta acción no se puede deshacer."}',
      confirmText: 'Eliminar',
      showConfirmButton: canDelete,
      onConfirm: () {
        context.read<ConfiguracionPrecioCubit>().eliminar(config.id);
      },
    );
  }
}
