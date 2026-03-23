import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';

import '../../domain/entities/empleado.dart';
import '../bloc/empleado_list/empleado_list_cubit.dart';
import '../bloc/empleado_list/empleado_list_state.dart';

class EmpleadosPage extends StatefulWidget {
  const EmpleadosPage({super.key});

  @override
  State<EmpleadosPage> createState() => _EmpleadosPageState();
}

class _EmpleadosPageState extends State<EmpleadosPage> {
  late final EmpleadoListCubit _listCubit;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedEstado;

  static const _estadoFilters = <String?, String>{
    null: 'Todos',
    'ACTIVO': 'Activo',
    'VACACIONES': 'Vacaciones',
    'LICENCIA': 'Licencia',
    'SUSPENDIDO': 'Suspendido',
    'CESADO': 'Cesado',
  };

  @override
  void initState() {
    super.initState();
    _listCubit = locator<EmpleadoListCubit>();
    _listCubit.loadEmpleados();
  }

  @override
  void dispose() {
    _listCubit.close();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    _listCubit.loadEmpleados(
      search: query.isNotEmpty ? query : null,
      estado: _selectedEstado,
    );
  }

  void _onFilterEstado(String? estado) {
    setState(() => _selectedEstado = estado);
    _listCubit.loadEmpleados(
      search: _searchController.text.isNotEmpty
          ? _searchController.text
          : null,
      estado: estado,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _listCubit,
      child: Scaffold(
        appBar: SmartAppBar(
          title: 'Empleados',
          backgroundColor: AppColors.blue1,
          foregroundColor: AppColors.white,
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.blue1,
          onPressed: () async {
            final result = await context.push('/empresa/rrhh/empleados/crear');
            if (result == true) {
              _listCubit.refresh();
            }
          },
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: GradientContainer(
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearch,
                  decoration: InputDecoration(
                    hintText: 'Buscar empleado...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textHint),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _onSearch('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.blue1),
                    ),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),

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
                        onSelected: (_) => _onFilterEstado(entry.key),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // List
              Expanded(
                child: BlocBuilder<EmpleadoListCubit, EmpleadoListState>(
                  builder: (context, state) {
                    if (state is EmpleadoListLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is EmpleadoListError) {
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
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => _listCubit.refresh(),
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (state is EmpleadoListLoaded) {
                      if (state.empleados.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 56,
                                color: AppColors.textSecondary.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Sin empleados registrados',
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
                        onRefresh: () async => await _listCubit.refresh(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.empleados.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            return _buildEmpleadoCard(context, state.empleados[index]);
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

  Widget _buildEmpleadoCard(BuildContext context, Empleado empleado) {
    return InkWell(
      onTap: () async {
        final result = await context.push('/empresa/rrhh/empleados/${empleado.id}');
        if (result == true) {
          _listCubit.refresh();
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: GradientContainer(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: empleado.estado.color.withValues(alpha: 0.1),
              child: Text(
                empleado.iniciales,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: empleado.estado.color,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    empleado.nombreCompleto,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    empleado.codigo,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.blue1,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (empleado.cargo != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      empleado.cargo!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Estado badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: empleado.estado.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                empleado.estado.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: empleado.estado.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
