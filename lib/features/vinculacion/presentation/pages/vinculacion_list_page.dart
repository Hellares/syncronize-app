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
import '../../domain/entities/vinculacion.dart';
import '../bloc/vinculacion_list/vinculacion_list_cubit.dart';
import '../bloc/vinculacion_list/vinculacion_list_state.dart';
import '../widgets/nueva_vinculacion_dialog.dart';

class VinculacionListPage extends StatelessWidget {
  const VinculacionListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmpresaContextCubit, EmpresaContextState>(
      builder: (context, empresaState) {
        final empresaId = empresaState is EmpresaContextLoaded
            ? empresaState.context.empresa.id
            : '';

        return BlocProvider(
          create: (_) => locator<VinculacionListCubit>()
            ..load(empresaId: empresaId),
          child: _VinculacionContent(empresaId: empresaId),
        );
      },
    );
  }
}

class _VinculacionContent extends StatelessWidget {
  final String empresaId;
  const _VinculacionContent({required this.empresaId});

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
          title: 'Vinculaciones B2B',
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: () =>
                  context.read<VinculacionListCubit>().refresh(),
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
              context.read<VinculacionListCubit>().filterByTipo(tipos[index]);
            },
            tabs: const [
              Tab(text: 'TODAS'),
              Tab(text: 'ENVIADAS'),
              Tab(text: 'RECIBIDAS'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await NuevaVinculacionDialog.show(context);
            if (result == true && context.mounted) {
              context.read<VinculacionListCubit>().refresh();
            }
          },
          backgroundColor: Colors.teal,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: GradientBackground(
          child: SafeArea(
            child: BlocBuilder<VinculacionListCubit, VinculacionListState>(
              builder: (context, state) {
                if (state is VinculacionListLoading) {
                  return const Center(child: CustomLoading());
                }

                if (state is VinculacionListError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(state.message, style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => context.read<VinculacionListCubit>().refresh(),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is VinculacionListLoaded) {
                  if (state.items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.link_off, size: 56, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            'No hay vinculaciones',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Las vinculaciones se crean al registrar clientes empresa',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => context.read<VinculacionListCubit>().refresh(),
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (scrollInfo) {
                        if (scrollInfo.metrics.pixels >=
                            scrollInfo.metrics.maxScrollExtent - 200) {
                          context.read<VinculacionListCubit>().loadMore();
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
                          return _VinculacionCard(
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

class _VinculacionCard extends StatelessWidget {
  final VinculacionEmpresa item;
  final String empresaId;

  const _VinculacionCard({required this.item, required this.empresaId});

  bool get isEnviada => item.empresaSolicitanteId == empresaId;

  @override
  Widget build(BuildContext context) {
    final empresaNombre = isEnviada
        ? item.empresaVinculada?.nombre ?? 'Empresa vinculada'
        : item.empresaSolicitante?.nombre ?? 'Empresa solicitante';

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
          onTap: () async {
            await context.push('/empresa/vinculacion/${item.id}');
            if (!context.mounted) return;
            context.read<VinculacionListCubit>().refresh();
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Header: Direccion + Empresa + Estado ───
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
                            isEnviada ? 'Solicitud enviada' : 'Solicitud recibida',
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

                // ─── Cliente empresa info ───
                if (item.clienteEmpresa != null) ...[
                  Row(
                    children: [
                      Icon(Icons.business_outlined, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.clienteEmpresa!.razonSocial,
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
                    if (item.clienteEmpresa != null)
                      _infoChip(
                        Icons.badge_outlined,
                        item.clienteEmpresa!.numeroDocumento,
                      ),
                    if (item.empresaVinculada?.rubro != null)
                      _infoChip(
                        Icons.category_outlined,
                        item.empresaVinculada!.rubro!,
                        bgColor: AppColors.blue1.withValues(alpha: 0.08),
                        iconColor: AppColors.blue1,
                        textColor: AppColors.blue1,
                      ),
                  ],
                ),

                // ─── Mensaje ───
                if (item.mensaje != null && item.mensaje!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.message_outlined,
                          size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.mensaje!,
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
    'ACEPTADA': {'color': Colors.green, 'label': 'ACEPTADA'},
    'RECHAZADA': {'color': Colors.red, 'label': 'RECHAZADA'},
    'CANCELADA': {'color': Colors.grey, 'label': 'CANCELADA'},
    'DESVINCULADA': {'color': Colors.blueGrey, 'label': 'DESVINCULADA'},
  };
}
