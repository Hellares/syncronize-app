import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_loading.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../domain/entities/tercerizacion.dart';
import '../bloc/tercerizacion_list/tercerizacion_list_cubit.dart';
import '../bloc/tercerizacion_list/tercerizacion_list_state.dart';

class TercerizacionListPage extends StatelessWidget {
  const TercerizacionListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmpresaContextCubit, EmpresaContextState>(
      builder: (context, empresaState) {
        final empresaId = empresaState is EmpresaContextLoaded
            ? empresaState.context.empresa.id
            : '';

        return BlocProvider(
          create: (_) => locator<TercerizacionListCubit>()
            ..load(empresaId: empresaId),
          child: _TercerizacionContent(empresaId: empresaId),
        );
      },
    );
  }
}

class _TercerizacionContent extends StatelessWidget {
  final String empresaId;
  const _TercerizacionContent({required this.empresaId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: SmartAppBar(
          backgroundColor: AppColors.blue1,
          foregroundColor: AppColors.white,
          title: 'Tercerización B2B',
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: () =>
                  context.read<TercerizacionListCubit>().refresh(),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            tabAlignment: TabAlignment.start,
            onTap: (index) {
              final tipos = [null, 'enviadas', 'recibidas'];
              context.read<TercerizacionListCubit>().filterByTipo(tipos[index]);
            },
            tabs: const [
              Tab(text: 'TODAS'),
              Tab(text: 'ENVIADAS'),
              Tab(text: 'RECIBIDAS'),
            ],
          ),
        ),
        body: GradientBackground(
          child: SafeArea(
            child: BlocBuilder<TercerizacionListCubit, TercerizacionListState>(
              builder: (context, state) {
                if (state is TercerizacionListLoading) {
                  return const Center(child: CustomLoading());
                }

                if (state is TercerizacionListError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(state.message, style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => context.read<TercerizacionListCubit>().refresh(),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is TercerizacionListLoaded) {
                  if (state.items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.swap_horiz, size: 56, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            'No hay tercerizaciones',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Terceriza servicios desde el detalle de una orden',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    );
                  }

                  // F6 FIX: Usar NotificationListener para loadMore en vez de llamarlo en itemBuilder
                  return RefreshIndicator(
                    onRefresh: () => context.read<TercerizacionListCubit>().refresh(),
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (scrollInfo) {
                        if (scrollInfo.metrics.pixels >=
                            scrollInfo.metrics.maxScrollExtent - 200) {
                          context.read<TercerizacionListCubit>().loadMore();
                        }
                        return false;
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: state.items.length + (state.hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == state.items.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            );
                          }
                          return _TercerizacionCard(
                            item: state.items[index],
                            empresaId: empresaId,
                          );
                        },
                      ),
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _TercerizacionCard extends StatelessWidget {
  final TercerizacionServicio item;
  final String empresaId;

  const _TercerizacionCard({required this.item, required this.empresaId});

  bool get isEnviada => item.empresaOrigenId == empresaId;

  @override
  Widget build(BuildContext context) {
    final datosEquipo = item.datosEquipo;
    final tipoEquipo = datosEquipo['tipoEquipo'] as String? ?? '';
    final marcaEquipo = datosEquipo['marcaEquipo'] as String? ?? '';
    final equipoLabel = [tipoEquipo, marcaEquipo]
        .where((e) => e.isNotEmpty)
        .join(' - ');

    final empresaNombre = isEnviada
        ? item.empresaDestino?.nombre ?? 'Empresa destino'
        : item.empresaOrigen?.nombre ?? 'Empresa origen';

    final dirColor = isEnviada ? Colors.orange : AppColors.blue1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GradientContainer(
        gradient: AppGradients.blueWhiteBlue(),
        shadowStyle: ShadowStyle.glow,
        borderColor: AppColors.blueborder,
        borderWidth: 0.6,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          // F7 FIX: Refrescar lista al volver del detalle
          onTap: () async {
            await context.push('/empresa/tercerizacion/${item.id}');
            if (!context.mounted) return;
            context.read<TercerizacionListCubit>().refresh();
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Header: Dirección + Empresa + Estado ───
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: dirColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isEnviada ? Icons.call_made : Icons.call_received,
                        size: 16,
                        color: dirColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            empresaNombre,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.blue2,
                              fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isEnviada ? 'Enviada' : 'Recibida',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                              fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _EstadoBadge(estado: item.estado),
                  ],
                ),

                const SizedBox(height: 6),
                Divider(height: 1, color: Colors.grey.shade200),
                const SizedBox(height: 6),

                // ─── Equipo ───
                if (equipoLabel.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.devices_outlined, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          equipoLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.blue2,
                            fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // ─── Chips de info ───
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _infoChip(
                      Icons.calendar_today_outlined,
                      DateFormatter.formatDate(item.fechaSolicitud),
                    ),
                    if (item.ordenOrigen != null)
                      _infoChip(
                        Icons.receipt_long,
                        item.ordenOrigen!.codigo,
                      ),
                    if (item.componentesData != null &&
                        item.componentesData is List &&
                        (item.componentesData as List).isNotEmpty)
                      _infoChip(
                        Icons.build_outlined,
                        '${(item.componentesData as List).length} comp.',
                        bgColor: Colors.indigo.withValues(alpha: 0.08),
                        iconColor: Colors.indigo,
                        textColor: Colors.indigo,
                      ),
                    if (item.precioB2B != null)
                      _infoChip(
                        Icons.payments_outlined,
                        'S/ ${item.precioB2B!.toStringAsFixed(2)}',
                        bgColor: AppColors.blue1.withValues(alpha: 0.08),
                        iconColor: AppColors.blue1,
                        textColor: AppColors.blue1,
                        bold: true,
                      ),
                  ],
                ),

                // ─── Descripción del problema ───
                if (item.datosEquipo['descripcionProblema'] is String &&
                    (item.datosEquipo['descripcionProblema'] as String).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.description_outlined,
                          size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.datosEquipo['descripcionProblema'] as String,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                            height: 1.3,
                            fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, {
    Color? bgColor,
    Color? iconColor,
    Color? textColor,
    bool bold = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor ?? Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: iconColor ?? Colors.grey.shade500),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: textColor ?? Colors.grey.shade600,
              fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  final String estado;
  const _EstadoBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    final config = _estadoConfig[estado] ??
        {'color': Colors.grey, 'label': estado};

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (config['color'] as Color).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        config['label'] as String,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: config['color'] as Color,
          fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
        ),
      ),
    );
  }

  static const _estadoConfig = {
    'PENDIENTE': {'color': Colors.orange, 'label': 'PENDIENTE'},
    'ACEPTADO': {'color': Colors.blue, 'label': 'ACEPTADO'},
    'RECHAZADO': {'color': Colors.red, 'label': 'RECHAZADO'},
    'EN_PROCESO': {'color': Colors.indigo, 'label': 'EN PROCESO'},
    'COMPLETADO': {'color': Colors.green, 'label': 'COMPLETADO'},
    'CANCELADO': {'color': Colors.grey, 'label': 'CANCELADO'},
  };
}
