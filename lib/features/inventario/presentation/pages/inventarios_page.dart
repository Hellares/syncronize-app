import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/utils/date_formatter.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import '../../domain/entities/inventario.dart';
import '../bloc/inventario_list_cubit.dart';
import '../bloc/inventario_list_state.dart';

class InventariosPage extends StatefulWidget {
  const InventariosPage({super.key});

  @override
  State<InventariosPage> createState() => _InventariosPageState();
}

class _InventariosPageState extends State<InventariosPage> {
  late final InventarioListCubit _listCubit;
  String? _selectedEstado;

  static const _estadoFilters = <String?, String>{
    null: 'Todos',
    'PLANIFICADO': 'Planificado',
    'EN_PROCESO': 'En Proceso',
    'CONTEO_COMPLETO': 'Conteo Completo',
    'APROBADO': 'Aprobado',
    'AJUSTADO': 'Ajustado',
  };

  @override
  void initState() {
    super.initState();
    _listCubit = locator<InventarioListCubit>();
    _listCubit.loadInventarios();
  }

  @override
  void dispose() {
    _listCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _listCubit,
      child: Scaffold(
        appBar: SmartAppBar(
          title: 'Inventarios',
          backgroundColor: AppColors.blue1,
          foregroundColor: AppColors.white,
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.blue1,
          onPressed: () async {
            final result = await context.push('/empresa/inventarios/crear');
            if (result == true) {
              _listCubit.reload();
            }
          },
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: GradientContainer(
          child: Column(
            children: [
              // Filter chips
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: _estadoFilters.entries.map((entry) {
                    final isSelected = _selectedEstado == entry.key;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          entry.value,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.blue1,
                        backgroundColor: Colors.white,
                        checkmarkColor: Colors.white,
                        onSelected: (_) {
                          setState(() => _selectedEstado = entry.key);
                          _listCubit.filterByEstado(entry.key);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              // List
              Expanded(
                child: BlocBuilder<InventarioListCubit, InventarioListState>(
                  builder: (context, state) {
                    if (state is InventarioListLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is InventarioListError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: AppColors.red),
                            const SizedBox(height: 12),
                            Text(
                              state.message,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    if (state is InventarioListLoaded) {
                      if (state.inventarios.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.fact_check_outlined,
                                size: 56,
                                color: AppColors.textSecondary.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Sin inventarios registrados',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          await _listCubit.reload();
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.inventarios.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _buildInventarioCard(
                              context,
                              state.inventarios[index],
                            );
                          },
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInventarioCard(BuildContext context, Inventario inv) {
    return InkWell(
      onTap: () async {
        final result = await context.push('/empresa/inventarios/${inv.id}');
        if (result == true) {
          _listCubit.reload();
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: GradientContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSubtitle(
                        inv.codigo,
                        fontSize: 15,
                        color: AppColors.blue3,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        inv.nombre,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Tipo badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    inv.tipoInventario.label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.indigo,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Estado badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: inv.estado.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    inv.estado.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: inv.estado.color,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            // Progress bar
            if (inv.totalProductosEsperados > 0) ...[
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: inv.progreso,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          inv.progreso >= 1.0 ? Colors.green : AppColors.blue1,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${inv.totalProductosContados}/${inv.totalProductosEsperados}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            // Info rows
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow(
                    Icons.store_rounded,
                    'Sede',
                    inv.sedeNombre ?? '-',
                  ),
                ),
                Expanded(
                  child: _buildInfoRow(
                    Icons.calendar_today_rounded,
                    'Fecha',
                    inv.fechaPlanificada != null
                        ? DateFormatter.formatDateTime(inv.fechaPlanificada!)
                        : DateFormatter.formatDateTime(inv.creadoEn),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
