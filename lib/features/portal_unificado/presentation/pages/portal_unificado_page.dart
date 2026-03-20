import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../data/datasources/portal_unificado_remote_datasource.dart';
import '../../data/repositories/portal_unificado_repository_impl.dart';
import '../../domain/entities/actividad_unificada.dart';
import '../../domain/usecases/get_actividad_unificada_usecase.dart';
import '../bloc/portal_unificado_cubit.dart';

class PortalUnificadoPage extends StatelessWidget {
  const PortalUnificadoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dataSource = PortalUnificadoRemoteDataSource(locator<DioClient>());
    final repository = PortalUnificadoRepositoryImpl(dataSource);
    final useCase = GetActividadUnificadaUseCase(repository);

    return BlocProvider(
      create: (_) => PortalUnificadoCubit(useCase)..loadActividad(),
      child: const _PortalUnificadoView(),
    );
  }
}

class _PortalUnificadoView extends StatelessWidget {
  const _PortalUnificadoView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Mi Actividad',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
      ),
      body: GradientBackground(
        child: BlocBuilder<PortalUnificadoCubit, PortalUnificadoState>(
          builder: (context, state) {
            if (state is PortalUnificadoLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is PortalUnificadoError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(state.message, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => context.read<PortalUnificadoCubit>().loadActividad(),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is PortalUnificadoLoaded) {
              if (state.actividad.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 56, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No tienes actividad como cliente',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => context.read<PortalUnificadoCubit>().loadActividad(),
                color: AppColors.blue1,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.actividad.empresas.length,
                  itemBuilder: (context, index) {
                    return _EmpresaActividadCard(
                      empresa: state.actividad.empresas[index],
                    );
                  },
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _EmpresaActividadCard extends StatelessWidget {
  final EmpresaActividad empresa;

  const _EmpresaActividadCard({required this.empresa});

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header empresa
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.bluechip,
                  child: empresa.empresa.logo != null
                      ? ClipOval(
                          child: Image.network(
                            empresa.empresa.logo!,
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Text(
                              empresa.empresa.nombre[0].toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.blue1,
                              ),
                            ),
                          ),
                        )
                      : Text(
                          empresa.empresa.nombre[0].toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.blue1,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppSubtitle(
                    empresa.empresa.nombre,
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Secciones de actividad
            if (empresa.cotizaciones.isNotEmpty)
              _ActividadSeccion(
                icon: Icons.request_quote,
                titulo: 'Cotizaciones',
                items: empresa.cotizaciones,
                color: AppColors.blue1,
              ),
            if (empresa.ventas.isNotEmpty)
              _ActividadSeccion(
                icon: Icons.point_of_sale,
                titulo: 'Ventas',
                items: empresa.ventas,
                color: Colors.green,
              ),
            if (empresa.citas.isNotEmpty)
              _ActividadSeccion(
                icon: Icons.calendar_month,
                titulo: 'Citas',
                items: empresa.citas,
                color: Colors.orange,
              ),
            if (empresa.ordenesServicio.isNotEmpty)
              _ActividadSeccion(
                icon: Icons.build,
                titulo: 'Órdenes de Servicio',
                items: empresa.ordenesServicio,
                color: Colors.purple,
              ),
          ],
        ),
      ),
    );
  }
}

class _ActividadSeccion extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final List<ActividadItem> items;
  final Color color;

  const _ActividadSeccion({
    required this.icon,
    required this.titulo,
    required this.items,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              AppSubtitle(titulo, fontSize: 11, color: color),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${items.length}',
                  style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const SizedBox(width: 21),
                    _EstadoChip(estado: item.estado),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.descripcion ?? item.codigo,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.total != null)
                      Text(
                        '${item.moneda ?? ''} ${item.total!.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    if (item.fecha != null && item.total == null)
                      Text(
                        dateFormat.format(item.fecha!),
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _EstadoChip extends StatelessWidget {
  final String estado;

  const _EstadoChip({required this.estado});

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        estado,
        style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Color _getColor() {
    final lower = estado.toLowerCase();
    if (lower.contains('pendiente') || lower.contains('recibido')) return Colors.orange;
    if (lower.contains('aprobad') || lower.contains('confirmad') || lower.contains('completad')) return Colors.green;
    if (lower.contains('rechazad') || lower.contains('anulad') || lower.contains('cancelad')) return Colors.red;
    if (lower.contains('borrador')) return Colors.grey;
    if (lower.contains('proceso') || lower.contains('diagnostico')) return Colors.blue;
    return Colors.grey.shade700;
  }
}
