import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../domain/entities/campana.dart';
import '../bloc/campana_list/campana_list_cubit.dart';
import '../bloc/campana_list/campana_list_state.dart';

class CampanasPage extends StatelessWidget {
  const CampanasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<CampanaListCubit>()..loadCampanas(),
      child: const _CampanasView(),
    );
  }
}

class _CampanasView extends StatelessWidget {
  const _CampanasView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar.withBackButton(
        title: 'Campañas de Promoción',
        onBack: () => context.pop(),
      ),
      body: GradientBackground(
        child: BlocBuilder<CampanaListCubit, CampanaListState>(
          builder: (context, state) {
            if (state is CampanaListLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is CampanaListError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(state.message),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.read<CampanaListCubit>().reload(),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }

            if (state is CampanaListLoaded) {
              final campanas = state.resultado.data;

              if (campanas.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.campaign_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No hay campañas aún',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Crea tu primera campaña para notificar\na tus clientes sobre ofertas',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => context.read<CampanaListCubit>().reload(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: campanas.length,
                  itemBuilder: (context, index) {
                    return _CampanaCard(campana: campanas[index]);
                  },
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await context.push('/empresa/promociones/nueva');
          if (result == true && context.mounted) {
            context.read<CampanaListCubit>().reload();
          }
        },
        icon: const Icon(Icons.campaign),
        label: const Text('Nueva Campaña'),
        backgroundColor: AppColors.blue1,
      ),
    );
  }
}

class _CampanaCard extends StatelessWidget {
  final Campana campana;

  const _CampanaCard({required this.campana});

  @override
  Widget build(BuildContext context) {
    final fechaFormateada = DateFormat('dd/MM/yyyy HH:mm').format(campana.creadoEn.toLocal());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: tipo + estado
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: campana.esAutomatica
                        ? Colors.orange.withValues(alpha: 0.1)
                        : Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        campana.esAutomatica ? Icons.autorenew : Icons.campaign,
                        size: 14,
                        color: campana.esAutomatica ? Colors.orange[700] : Colors.blue[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        campana.esAutomatica ? 'Automática' : 'Manual',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: campana.esAutomatica ? Colors.orange[700] : Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: campana.esEnviada
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    campana.esEnviada ? 'Enviada' : 'Fallida',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: campana.esEnviada ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  fechaFormateada,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Título y mensaje
            Text(
              campana.titulo,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              campana.mensaje,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Footer: stats
            Row(
              children: [
                Icon(Icons.people_outline, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  '${campana.totalDestinatarios} destinatarios',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
                if (campana.productosIds.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.inventory_2_outlined, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${campana.productosIds.length} producto${campana.productosIds.length > 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
                if (campana.usuarioNombre != null || campana.usuarioEmail != null) ...[
                  const Spacer(),
                  Text(
                    campana.usuarioNombre ?? campana.usuarioEmail ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
