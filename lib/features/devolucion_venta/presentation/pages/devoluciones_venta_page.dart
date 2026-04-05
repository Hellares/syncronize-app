import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/widgets/custom_filter_chip.dart';
import 'package:syncronize/core/widgets/custom_search_field.dart';
import 'package:syncronize/core/widgets/floating_button_text.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../domain/entities/devolucion_venta.dart';
import '../bloc/devolucion_list/devolucion_list_cubit.dart';
import '../bloc/devolucion_list/devolucion_list_state.dart';
import '../widgets/devolucion_estado_chip.dart';

class DevolucionesVentaPage extends StatefulWidget {
  const DevolucionesVentaPage({super.key});

  @override
  State<DevolucionesVentaPage> createState() => _DevolucionesVentaPageState();
}

class _DevolucionesVentaPageState extends State<DevolucionesVentaPage> {
  EstadoDevolucion? _filtroEstado;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _load() {
    final state = context.read<EmpresaContextCubit>().state;
    if (state is EmpresaContextLoaded) {
      context.read<DevolucionListCubit>().load(empresaId: state.context.empresa.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Devoluciones',
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
      ),
      body: GradientContainer(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: CustomSearchField(
                controller: _searchController,
                borderColor: AppColors.blue1,
                hintText: 'Buscar por codigo...',
                onChanged: (q) => context.read<DevolucionListCubit>().search(q),
                onSubmitted: (q) => context.read<DevolucionListCubit>().search(q),
                onClear: () => context.read<DevolucionListCubit>().search(''),
              ),
            ),
            SizedBox(
              height: 30,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  CustomFilterChip(
                    label: 'Todos', selected: _filtroEstado == null,
                    onSelected: () => _filterByEstado(null), showCheckmark: true,
                  ),
                  const SizedBox(width: 6),
                  ...EstadoDevolucion.values.map((e) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: CustomFilterChip(
                      showCheckmark: true, label: e.label,
                      selected: _filtroEstado == e,
                      onSelected: () => _filterByEstado(e),
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BlocBuilder<DevolucionListCubit, DevolucionListState>(
                builder: (context, state) {
                  if (state is DevolucionListLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is DevolucionListError) {
                    return Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(state.message),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => context.read<DevolucionListCubit>().reload(),
                          icon: const Icon(Icons.refresh), label: const Text('Reintentar'),
                        ),
                      ],
                    ));
                  }
                  if (state is DevolucionListLoaded) {
                    if (state.devoluciones.isEmpty) {
                      return Center(child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_return, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text('No hay devoluciones', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                        ],
                      ));
                    }
                    return RefreshIndicator(
                      onRefresh: () => context.read<DevolucionListCubit>().reload(),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        itemCount: state.devoluciones.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final dev = state.devoluciones[index];
                          return _DevolucionListTile(
                            devolucion: dev,
                            onTap: () => context.push('/empresa/devoluciones/${dev.id}'),
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
      floatingActionButton: FloatingButtonText(
        label: 'Nueva Devolucion',
        icon: Icons.add,
        onPressed: () => context.push('/empresa/devoluciones/nueva'),
      ),
    );
  }

  void _filterByEstado(EstadoDevolucion? estado) {
    setState(() => _filtroEstado = estado);
    context.read<DevolucionListCubit>().filterByEstado(estado);
  }
}

class _DevolucionListTile extends StatelessWidget {
  final DevolucionVenta devolucion;
  final VoidCallback onTap;

  const _DevolucionListTile({required this.devolucion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return GradientContainer(
      shadowStyle: ShadowStyle.colorful,
      borderColor: AppColors.blueborder,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppSubtitle(devolucion.codigo),
                  const SizedBox(width: 8),
                  DevolucionEstadoChip(estado: devolucion.estado),
                  const Spacer(),
                  Text(dateFormat.format(devolucion.creadoEn),
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                ],
              ),
              if (devolucion.ventaCodigo != null) ...[
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.receipt, size: 12, color: Colors.blue.shade400),
                  const SizedBox(width: 4),
                  Text('Venta: ${devolucion.ventaCodigo}',
                      style: TextStyle(fontSize: 11, color: Colors.blue.shade600)),
                ]),
              ],
              if (devolucion.ventaNombreCliente != null) ...[
                const SizedBox(height: 2),
                Text('Cliente: ${devolucion.ventaNombreCliente}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
              if (devolucion.motivo != null) ...[
                const SizedBox(height: 4),
                Text(devolucion.motivo!, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
