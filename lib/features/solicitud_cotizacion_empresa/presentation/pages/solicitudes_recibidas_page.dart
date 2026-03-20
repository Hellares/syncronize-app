import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../bloc/solicitudes_recibidas_cubit.dart';

class SolicitudesRecibidasPage extends StatelessWidget {
  const SolicitudesRecibidasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<SolicitudesRecibidasCubit>()..load(),
      child: const _SolicitudesView(),
    );
  }
}

class _SolicitudesView extends StatefulWidget {
  const _SolicitudesView();

  @override
  State<_SolicitudesView> createState() => _SolicitudesViewState();
}

class _SolicitudesViewState extends State<_SolicitudesView> {
  String? _filtro;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(title: 'Solicitudes de Clientes', backgroundColor: AppColors.blue1, foregroundColor: Colors.white),
      body: GradientBackground(
        child: Column(
          children: [
            _buildFiltros(),
            Expanded(
              child: BlocBuilder<SolicitudesRecibidasCubit, SolicitudesRecibidasState>(
                builder: (context, state) {
                  if (state is SolicitudesRecibidasLoading) return const Center(child: CircularProgressIndicator());
                  if (state is SolicitudesRecibidasError) {
                    return Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(state.message, style: TextStyle(color: Colors.grey.shade600)),
                        TextButton(onPressed: () => context.read<SolicitudesRecibidasCubit>().reload(), child: const Text('Reintentar')),
                      ],
                    ));
                  }
                  if (state is SolicitudesRecibidasLoaded) {
                    if (state.solicitudes.isEmpty) {
                      return Center(child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('No hay solicitudes', style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ));
                    }
                    return RefreshIndicator(
                      onRefresh: () => context.read<SolicitudesRecibidasCubit>().reload(),
                      color: AppColors.blue1,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: state.solicitudes.length,
                        itemBuilder: (context, index) {
                          final sol = state.solicitudes[index];
                          return _SolicitudCard(solicitud: sol, onTap: () => _navigateDetail(sol['id'] as String));
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
    );
  }

  Widget _buildFiltros() {
    final filtros = [
      {'label': 'Todos', 'value': null},
      {'label': 'Pendientes', 'value': 'PENDIENTE'},
      {'label': 'En Revisión', 'value': 'EN_REVISION'},
      {'label': 'Cotizadas', 'value': 'COTIZADA'},
      {'label': 'Rechazadas', 'value': 'RECHAZADA'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: filtros.map((f) {
          final isSelected = _filtro == f['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f['label'] as String, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppColors.blue1)),
              selected: isSelected, selectedColor: AppColors.blue1, backgroundColor: Colors.white, checkmarkColor: Colors.white,
              side: BorderSide(color: isSelected ? AppColors.blue1 : Colors.grey.shade300),
              onSelected: (_) {
                setState(() => _filtro = f['value']);
                context.read<SolicitudesRecibidasCubit>().load(estado: _filtro);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _navigateDetail(String id) async {
    await context.push('/empresa/solicitudes-cotizacion/$id');
    if (mounted) context.read<SolicitudesRecibidasCubit>().reload();
  }
}

class _SolicitudCard extends StatelessWidget {
  final Map<String, dynamic> solicitud;
  final VoidCallback onTap;
  const _SolicitudCard({required this.solicitud, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final codigo = solicitud['codigo'] as String? ?? '';
    final estado = solicitud['estado'] as String? ?? '';
    final nombre = solicitud['nombreSolicitante'] as String? ?? '';
    final items = solicitud['items'] as List<dynamic>? ?? [];
    final manuales = items.where((i) => i['esManual'] == true).length;
    final creadoEn = solicitud['creadoEn'] != null ? DateTime.tryParse(solicitud['creadoEn'].toString()) : null;

    return GradientContainer(
      margin: const EdgeInsets.only(bottom: 10),
      borderColor: estado == 'PENDIENTE' ? Colors.orange.shade300 : AppColors.blueborder,
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
                  AppSubtitle(codigo, fontSize: 13, color: AppColors.blue1),
                  const Spacer(),
                  _EstadoChip(estado: estado),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(child: AppSubtitle(nombre, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.list_alt, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${items.length} item${items.length != 1 ? 's' : ''}${manuales > 0 ? ' ($manuales manual${manuales != 1 ? 'es' : ''})' : ''}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
              if (creadoEn != null) ...[
                const SizedBox(height: 4),
                Text(DateFormat('dd/MM/yyyy HH:mm').format(creadoEn), style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
              ],
              if (estado == 'PENDIENTE') ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(4)),
                  child: Text('Nueva solicitud', style: TextStyle(fontSize: 10, color: Colors.orange.shade700, fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EstadoChip extends StatelessWidget {
  final String estado;
  const _EstadoChip({required this.estado});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (estado) {
      case 'PENDIENTE': color = Colors.orange; label = 'Pendiente'; break;
      case 'EN_REVISION': color = Colors.blue; label = 'En revisión'; break;
      case 'COTIZADA': color = Colors.green; label = 'Cotizada'; break;
      case 'RECHAZADA': color = Colors.red; label = 'Rechazada'; break;
      case 'CANCELADA': color = Colors.grey; label = 'Cancelada'; break;
      case 'VENCIDA': color = Colors.grey; label = 'Vencida'; break;
      default: color = Colors.grey; label = estado;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
