import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/custom_search_field.dart';
import 'package:syncronize/core/widgets/floating_button_text.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import '../../../../core/di/injection_container.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../bloc/servicio_list/servicio_list_cubit.dart';
import '../bloc/servicio_list/servicio_list_state.dart';
import '../../domain/entities/servicio.dart';
import '../../domain/entities/servicio_filtros.dart';

class ServiciosPage extends StatelessWidget {
  const ServiciosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmpresaContextCubit, EmpresaContextState>(
      builder: (context, empresaState) {
        final empresaId = empresaState is EmpresaContextLoaded
            ? empresaState.context.empresa.id
            : '';

        return BlocProvider(
          create: (_) => locator<ServicioListCubit>()
            ..loadServicios(empresaId: empresaId),
          child: _ServiciosPageContent(empresaId: empresaId),
        );
      },
    );
  }
}

class _ServiciosPageContent extends StatelessWidget {
  final String empresaId;
  const _ServiciosPageContent({required this.empresaId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
        title: 'Catalogo de Servicios',
      ),
      body: GradientContainer(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CustomSearchField(
                borderColor: AppColors.blue1,
                hintText: 'Buscar por nombre o codigo',
                onChanged: (value) {
                  context.read<ServicioListCubit>().applyFiltros(
                        ServicioFiltros(search: value),
                      );
                },
              ),
            ),
            Expanded(
              child: BlocBuilder<ServicioListCubit, ServicioListState>(
                builder: (context, state) {
                  if (state is ServicioListLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is ServicioListError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(state.message,
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () =>
                                context.read<ServicioListCubit>().refresh(),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    );
                  }

                  final servicios =
                      state is ServicioListLoaded ? state.servicios : [];

                  if (servicios.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.room_service_outlined,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            state is ServicioListLoaded &&
                                    state.filtros.search != null
                                ? 'No se encontraron servicios'
                                : 'No hay servicios',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          if (state is! ServicioListLoaded ||
                              state.filtros.search == null)
                            const Text(
                              'Presiona el boton + para crear uno',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () =>
                        context.read<ServicioListCubit>().refresh(),
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (scrollInfo) {
                        if (scrollInfo.metrics.pixels >=
                            scrollInfo.metrics.maxScrollExtent - 200) {
                          context.read<ServicioListCubit>().loadMore();
                        }
                        return false;
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        itemCount: servicios.length +
                            (state is ServicioListLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= servicios.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final servicio = servicios[index];
                          return _ServicioListTile(
                            servicio: servicio,
                            onTap: () async {
                              final cubit =
                                  context.read<ServicioListCubit>();
                              final result = await context.push(
                                '/empresa/servicios/${servicio.id}/editar',
                              );
                              if (result == true) {
                                cubit.refresh();
                              }
                            },
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingButtonText(
        width: 130,
        onPressed: () async {
          final cubit = context.read<ServicioListCubit>();
          final result = await context.push('/empresa/servicios/crear');
          if (result == true) {
            cubit.refresh();
          }
        },
        icon: Icons.add,
        label: 'Nuevo Servicio',
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Card tile con el mismo estilo que OrdenCompraListTile
// ─────────────────────────────────────────────────────────────
class _ServicioListTile extends StatelessWidget {
  final Servicio servicio;
  final VoidCallback? onTap;

  const _ServicioListTile({
    required this.servicio,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GradientContainer(
        gradient: AppGradients.blueWhiteBlue(),
        shadowStyle: ShadowStyle.glow,
        borderColor: AppColors.blueborder,
        borderWidth: 0.8,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 8),
                Container(height: 1, color: Colors.grey.shade200),
                const SizedBox(height: 8),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.blue1.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.room_service,
            color: AppColors.blue1,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nombre
              Text(
                servicio.nombre,
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              // Codigo + categoria
              Row(
                children: [
                  Icon(Icons.qr_code_2,
                      size: 11, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    servicio.codigoEmpresa,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                      fontFamily:
                          AppFonts.getFontFamily(AppFont.oxygenRegular),
                    ),
                  ),
                  if (servicio.categoria != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Text(
                        '·',
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 8),
                      ),
                    ),
                    Icon(Icons.category_outlined,
                        size: 10, color: Colors.grey.shade600),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        servicio.categoria!.nombre,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade700,
                          fontFamily:
                              AppFonts.getFontFamily(AppFont.oxygenRegular),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        // Precio
        if (servicio.precio != null)
          Text(
            'S/ ${servicio.precio!.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.blue1,
            ),
          ),
        if (servicio.precio == null)
          Text(
            'Sin precio',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontStyle: FontStyle.italic,
            ),
          ),

        // Duracion
        if (servicio.duracionMinutos != null) ...[
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.bluechip,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined,
                    size: 10, color: AppColors.blue1),
                const SizedBox(width: 3),
                AppSubtitle(
                  '${servicio.duracionMinutos} min',
                  fontSize: 9,
                  color: AppColors.blue1,
                ),
              ],
            ),
          ),
        ],

        const Spacer(),

        // Oferta badge
        if (servicio.enOferta) ...[
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppColors.green.withValues(alpha: 0.4),
                width: 0.6,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_offer,
                    size: 10, color: AppColors.green),
                const SizedBox(width: 4),
                AppSubtitle(
                  servicio.precioOferta != null
                      ? 'S/ ${servicio.precioOferta!.toStringAsFixed(2)}'
                      : 'OFERTA',
                  fontSize: 9,
                  color: AppColors.green,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
        ],

        // Estado badge
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: (servicio.isActive ? AppColors.green : Colors.grey)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: (servicio.isActive ? AppColors.green : Colors.grey)
                  .withValues(alpha: 0.4),
              width: 0.6,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                servicio.isActive ? Icons.check_circle : Icons.cancel,
                size: 10,
                color:
                    servicio.isActive ? AppColors.green : Colors.grey,
              ),
              const SizedBox(width: 4),
              AppSubtitle(
                servicio.isActive ? 'ACTIVO' : 'INACTIVO',
                fontSize: 9,
                color:
                    servicio.isActive ? AppColors.green : Colors.grey,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
