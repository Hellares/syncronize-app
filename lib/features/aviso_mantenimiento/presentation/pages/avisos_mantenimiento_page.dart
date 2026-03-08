import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/aviso_mantenimiento.dart';
import '../bloc/aviso_list/aviso_list_cubit.dart';
import '../bloc/aviso_list/aviso_list_state.dart';
import '../widgets/aviso_card_widget.dart';
import '../pages/configuracion_aviso_page.dart';

class AvisosMantenimientoPage extends StatefulWidget {
  const AvisosMantenimientoPage({super.key});

  @override
  State<AvisosMantenimientoPage> createState() => _AvisosMantenimientoPageState();
}

class _AvisosMantenimientoPageState extends State<AvisosMantenimientoPage> {
  @override
  void initState() {
    super.initState();
    context.read<AvisoListCubit>().loadAvisos();
  }

  Future<void> _onUpdateEstado(AvisoMantenimiento aviso, String nuevoEstado) async {
    final success = await context.read<AvisoListCubit>().updateEstado(aviso.id, nuevoEstado);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aviso actualizado'), duration: Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(
          title: 'Avisos de Mantenimiento',
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, size: 22),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ConfiguracionAvisoPage(),
                  ),
                );
                if (mounted) {
                  context.read<AvisoListCubit>().refresh();
                }
              },
            ),
          ],
        ),
        body: BlocBuilder<AvisoListCubit, AvisoListState>(
          builder: (context, state) {
            if (state is AvisoListLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is AvisoListError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.message, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => context.read<AvisoListCubit>().refresh(),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }

            if (state is AvisoListLoaded) {
              return RefreshIndicator(
                onRefresh: () => context.read<AvisoListCubit>().refresh(),
                child: CustomScrollView(
                  slivers: [
                    if (state.resumen != null)
                      SliverToBoxAdapter(child: _buildResumen(state.resumen!)),

                    SliverToBoxAdapter(child: _buildFiltros(state.filtroEstado)),

                    if (state.avisos.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.notifications_none,
                                  size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                'No hay avisos de mantenimiento',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => AvisoCardWidget(
                              aviso: state.avisos[index],
                              onMarcarAtendido: () =>
                                  _onUpdateEstado(state.avisos[index], 'ATENDIDO'),
                              onDescartar: () =>
                                  _onUpdateEstado(state.avisos[index], 'DESCARTADO'),
                              onTap: () => _showAvisoDetail(state.avisos[index]),
                            ),
                            childCount: state.avisos.length,
                          ),
                        ),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildResumen(AvisoResumen r) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GradientContainer(
        borderColor: AppColors.blueborder,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.dashboard_outlined, size: 16, color: AppColors.blue1),
                  const SizedBox(width: 8),
                  AppSubtitle('RESUMEN', fontSize: 12),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildResumenChip('Pendientes', r.pendientes, Colors.orange),
                  const SizedBox(width: 8),
                  _buildResumenChip('Notificados', r.notificados, AppColors.blue1),
                  const SizedBox(width: 8),
                  _buildResumenChip('Esta semana', r.proximosSemana, Colors.red),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResumenChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700, color: color),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltros(String? filtroEstado) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Todos', null, filtroEstado),
            const SizedBox(width: 6),
            _buildFilterChip('Pendientes', 'PENDIENTE', filtroEstado),
            const SizedBox(width: 6),
            _buildFilterChip('Notificados', 'NOTIFICADO', filtroEstado),
            const SizedBox(width: 6),
            _buildFilterChip('Atendidos', 'ATENDIDO', filtroEstado),
            const SizedBox(width: 6),
            _buildFilterChip('Descartados', 'DESCARTADO', filtroEstado),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? estado, String? currentFiltro) {
    final isSelected = currentFiltro == estado;
    return GestureDetector(
      onTap: () => context.read<AvisoListCubit>().filterByEstado(estado),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blue1 : AppColors.bluechip,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.blue1,
          ),
        ),
      ),
    );
  }

  void _showAvisoDetail(AvisoMantenimiento aviso) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20, right: 20, top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.notifications_active_outlined,
                    color: AppColors.blue1, size: 20),
                SizedBox(width: 8),
                Text('Detalle del Aviso',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 16),

            _detailRow('Cliente', aviso.cliente?.nombreCompleto ?? 'N/A'),
            _detailRow('Equipo', aviso.equipoDescripcion ?? 'No especificado'),
            _detailRow('Tipo de servicio', _tipoServicioLabel(aviso.tipoServicio)),
            _detailRow('Orden original', aviso.ordenServicio?.codigo ?? aviso.ordenServicioId),
            _detailRow('Último servicio', DateFormatter.formatDate(aviso.fechaUltimoServicio)),
            _detailRow('Fecha recomendada', DateFormatter.formatDate(aviso.fechaRecomendada)),
            _detailRow('Estado', aviso.estado),

            if (aviso.diasRestantes < 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, size: 16, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Vencido hace ${-aviso.diasRestantes} día(s)',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade700),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            if (aviso.esActivo) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _onUpdateEstado(aviso, 'DESCARTADO');
                      },
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Descartar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _onUpdateEstado(aviso, 'ATENDIDO');
                      },
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Marcar Atendido'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue1,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String _tipoServicioLabel(String tipo) {
    const labels = {
      'REPARACION': 'Reparación',
      'MANTENIMIENTO': 'Mantenimiento',
      'INSTALACION': 'Instalación',
      'DIAGNOSTICO': 'Diagnóstico',
      'ACTUALIZACION': 'Actualización',
      'LIMPIEZA': 'Limpieza',
      'RECUPERACION_DATOS': 'Recuperación de datos',
      'CONFIGURACION': 'Configuración',
      'CONSULTORIA': 'Consultoría',
      'FORMACION': 'Formación',
      'SOPORTE': 'Soporte',
    };
    return labels[tipo] ?? tipo;
  }
}
