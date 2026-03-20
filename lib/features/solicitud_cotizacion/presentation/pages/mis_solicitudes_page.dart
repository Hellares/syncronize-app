import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../domain/entities/solicitud_cotizacion.dart';
import '../bloc/mis_solicitudes_cubit.dart';
import '../bloc/mis_solicitudes_state.dart';
import 'solicitud_detail_page.dart';

class MisSolicitudesPage extends StatefulWidget {
  const MisSolicitudesPage({super.key});

  @override
  State<MisSolicitudesPage> createState() => _MisSolicitudesPageState();
}

class _MisSolicitudesPageState extends State<MisSolicitudesPage> {
  late final MisSolicitudesCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = locator<MisSolicitudesCubit>();
    _cubit.loadSolicitudes();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: GradientBackground(
        style: GradientStyle.minimal,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: SmartAppBar(title: 'Mis Cotizaciones'),
          body: Column(
            children: [
              _buildFilterChips(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return BlocBuilder<MisSolicitudesCubit, MisSolicitudesState>(
      builder: (context, state) {
        EstadoSolicitudCotizacion? currentFilter;
        if (state is MisSolicitudesLoaded) {
          currentFilter = state.filtroEstado;
        }

        final filters = <_FilterOption>[
          _FilterOption(label: 'Todos', estado: null),
          _FilterOption(
              label: 'Pendiente',
              estado: EstadoSolicitudCotizacion.pendiente),
          _FilterOption(
              label: 'Cotizada',
              estado: EstadoSolicitudCotizacion.cotizada),
          _FilterOption(
              label: 'Rechazada',
              estado: EstadoSolicitudCotizacion.rechazada),
        ];

        return Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final filter = filters[index];
              final isSelected = currentFilter == filter.estado;

              return FilterChip(
                label: Text(
                  filter.label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected ? Colors.white : AppColors.blue3,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => _cubit.filterByEstado(filter.estado),
                backgroundColor: Colors.white,
                selectedColor: AppColors.blue2,
                checkmarkColor: Colors.white,
                side: BorderSide(
                  color: isSelected ? AppColors.blue2 : AppColors.greyLight,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    return BlocBuilder<MisSolicitudesCubit, MisSolicitudesState>(
      builder: (context, state) {
        if (state is MisSolicitudesLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is MisSolicitudesError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 40, color: AppColors.red),
                const SizedBox(height: 12),
                AppText(state.message, size: 12, color: AppColors.red),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => _cubit.loadSolicitudes(),
                  child: Text(
                    'Reintentar',
                    style: TextStyle(fontSize: 11, color: AppColors.blue2),
                  ),
                ),
              ],
            ),
          );
        }

        if (state is MisSolicitudesLoaded) {
          final solicitudes = state.solicitudesFiltradas;

          if (solicitudes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.request_quote_outlined,
                      size: 48, color: AppColors.grey),
                  const SizedBox(height: 12),
                  AppText(
                    'No tienes solicitudes de cotizacion',
                    size: 12,
                    color: AppColors.blueGrey,
                  ),
                  const SizedBox(height: 4),
                  AppText(
                    'Visita una tienda en el marketplace para solicitar',
                    size: 10,
                    color: AppColors.grey,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => _cubit.reload(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: solicitudes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _buildSolicitudCard(solicitudes[index]),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSolicitudCard(SolicitudCotizacion solicitud) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                SolicitudDetailPage(solicitudId: solicitud.id),
          ),
        );
        if (result == true) {
          _cubit.reload();
        }
      },
      child: GradientContainer(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: empresa + estado
            Row(
              children: [
                // Empresa logo
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.blue3.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: solicitud.empresa?.logo != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            solicitud.empresa!.logo!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.store,
                              color: AppColors.blue3,
                              size: 18,
                            ),
                          ),
                        )
                      : const Icon(Icons.store,
                          color: AppColors.blue3, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        solicitud.empresa?.nombre ?? 'Empresa',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        solicitud.codigo,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.blueGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildEstadoChip(solicitud.estado),
              ],
            ),
            const SizedBox(height: 10),
            // Info row
            Row(
              children: [
                Icon(Icons.list_alt, size: 14, color: AppColors.blueGrey),
                const SizedBox(width: 4),
                Text(
                  '${solicitud.items.length} item${solicitud.items.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.blueGrey,
                  ),
                ),
                if (solicitud.creadoEn != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_today,
                      size: 12, color: AppColors.blueGrey),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(solicitud.creadoEn!),
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.blueGrey,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoChip(EstadoSolicitudCotizacion estado) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: estado.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        estado.label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: estado.color,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _FilterOption {
  final String label;
  final EstadoSolicitudCotizacion? estado;

  const _FilterOption({required this.label, this.estado});
}
