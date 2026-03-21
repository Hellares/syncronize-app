import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/utils/date_formatter.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import '../../domain/entities/rendicion_caja_chica.dart';
import '../bloc/rendiciones_list_cubit.dart';
import '../bloc/rendiciones_list_state.dart';
import 'rendicion_page.dart';

class HistorialRendicionesPage extends StatefulWidget {
  final String? cajaChicaId;

  const HistorialRendicionesPage({super.key, this.cajaChicaId});

  @override
  State<HistorialRendicionesPage> createState() =>
      _HistorialRendicionesPageState();
}

class _HistorialRendicionesPageState extends State<HistorialRendicionesPage> {
  late final RendicionesListCubit _rendicionesCubit;
  String? _filtroEstado;

  @override
  void initState() {
    super.initState();
    _rendicionesCubit = locator<RendicionesListCubit>();
    _rendicionesCubit.loadRendiciones(cajaChicaId: widget.cajaChicaId);
  }

  @override
  void dispose() {
    _rendicionesCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _rendicionesCubit,
      child: Scaffold(
        appBar: SmartAppBar(
          title: 'Rendiciones',
          backgroundColor: AppColors.blue1,
          foregroundColor: AppColors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list_rounded),
              onPressed: () => _showFilterSheet(context),
            ),
          ],
        ),
        body: GradientContainer(
          child: BlocBuilder<RendicionesListCubit, RendicionesListState>(
            builder: (context, state) {
              if (state is RendicionesListLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is RendicionesListError) {
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

              if (state is RendicionesListLoaded) {
                if (state.rendiciones.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 56,
                          color:
                              AppColors.textSecondary.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Sin rendiciones',
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
                    await _rendicionesCubit.reload();
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.rendiciones.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildRendicionCard(
                          context, state.rendiciones[index]);
                    },
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRendicionCard(
      BuildContext context, RendicionCajaChica rendicion) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_PE',
      symbol: 'S/ ',
      decimalDigits: 2,
    );

    Color estadoColor;
    switch (rendicion.estado) {
      case EstadoRendicion.pendiente:
        estadoColor = const Color(0xFFFFA726);
        break;
      case EstadoRendicion.aprobada:
        estadoColor = const Color(0xFF4CAF50);
        break;
      case EstadoRendicion.rechazada:
        estadoColor = const Color(0xFFF54D85);
        break;
    }

    return InkWell(
      onTap: () {
        Navigator.of(context)
            .push(
          MaterialPageRoute(
            builder: (_) =>
                RendicionPage(rendicionId: rendicion.id),
          ),
        )
            .then((_) {
          _rendicionesCubit.reload();
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: GradientContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSubtitle(
                        rendicion.codigo,
                        fontSize: 15,
                        color: AppColors.blue3,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rendicion.cajaChicaNombre,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: estadoColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    rendicion.estado.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: estadoColor,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow(
                    Icons.attach_money_rounded,
                    'Total',
                    currencyFormat.format(rendicion.totalGastado),
                  ),
                ),
                Expanded(
                  child: _buildInfoRow(
                    Icons.calendar_today_rounded,
                    'Fecha',
                    DateFormatter.formatDateTime(rendicion.creadoEn),
                  ),
                ),
              ],
            ),
            if (rendicion.aprobadoPorNombre != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.check_circle_rounded,
                'Aprobado por',
                rendicion.aprobadoPorNombre!,
              ),
            ],
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

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppSubtitle(
                    'Filtrar por Estado',
                    fontSize: 18,
                    color: AppColors.blue3,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip(
                        'Todos',
                        null,
                        setSheetState,
                      ),
                      ...EstadoRendicion.values.map(
                        (estado) => _buildFilterChip(
                          estado.label,
                          estado.apiValue,
                          setSheetState,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setSheetState(() => _filtroEstado = null);
                            setState(() {});
                            _rendicionesCubit.loadRendiciones(
                              cajaChicaId: widget.cajaChicaId,
                            );
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'Limpiar',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.blue1,
                            foregroundColor: AppColors.white,
                          ),
                          onPressed: () {
                            setState(() {});
                            _rendicionesCubit.loadRendiciones(
                              cajaChicaId: widget.cajaChicaId,
                              estado: _filtroEstado,
                            );
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'Aplicar',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip(
    String label,
    String? estadoValue,
    StateSetter setSheetState,
  ) {
    final isSelected = _filtroEstado == estadoValue;
    return ChoiceChip(
      selected: isSelected,
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isSelected ? AppColors.white : AppColors.blue3,
        ),
      ),
      selectedColor: AppColors.blue1,
      backgroundColor: AppColors.white,
      side: BorderSide(
        color: isSelected ? AppColors.blue1 : AppColors.greyLight,
      ),
      onSelected: (_) {
        setSheetState(() => _filtroEstado = estadoValue);
      },
    );
  }
}
