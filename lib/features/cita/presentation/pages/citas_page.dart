import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_loading.dart';
import '../../../../core/widgets/floating_button_icon.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../empresa/presentation/widgets/empresa_drawer.dart';
import '../bloc/cita_list/cita_list_cubit.dart';
import '../bloc/cita_list/cita_list_state.dart';
import '../../domain/entities/cita.dart';
import '../widgets/cita_estado_badge.dart';

class CitasPage extends StatefulWidget {
  final bool asCliente;

  const CitasPage({super.key, this.asCliente = false});

  @override
  State<CitasPage> createState() => _CitasPageState();
}

class _CitasPageState extends State<CitasPage> {
  DateTime _selectedDate = DateTime.now();
  String? _filtroEstado;

  static const _estadoTabs = [
    null,
    'PENDIENTE',
    'CONFIRMADA',
    'EN_PROCESO',
    'COMPLETADA',
    'CANCELADA',
    'NO_ASISTIO',
  ];

  static const _estadoTabLabels = [
    'TODAS',
    'PENDIENTE',
    'CONFIRMADA',
    'EN PROCESO',
    'COMPLETADA',
    'CANCELADA',
    'NO ASISTIÓ',
  ];

  @override
  void initState() {
    super.initState();
    _loadCitas();
  }

  void _loadCitas() {
    context.read<CitaListCubit>().loadCitas(
          fecha: DateFormat('yyyy-MM-dd').format(_selectedDate),
          estado: _filtroEstado,
          asCliente: widget.asCliente,
        );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _estadoTabs.length,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: SmartAppBar(
          backgroundColor: AppColors.blue1,
          foregroundColor: AppColors.white,
          showLogo: false,
          title: 'Citas',
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: _loadCitas,
              tooltip: 'Actualizar',
            ),
          ],
        ),
        drawer: const EmpresaDrawer(),
        body: GradientBackground(
          style: GradientStyle.professional,
          child: SafeArea(
            child: Column(
              children: [
                // ─── Tabs de estado ───
                Container(
                  height: 40,
                  color: AppColors.blue1,
                  child: TabBar(
                    isScrollable: true,
                    labelStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                    dividerHeight: 0,
                    labelColor: AppColors.white,
                    unselectedLabelColor: Colors.grey,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 10),
                    indicatorPadding: const EdgeInsets.only(bottom: 10),
                    indicatorSize: TabBarIndicatorSize.label,
                    indicatorWeight: 2,
                    indicator: const UnderlineTabIndicator(
                      borderSide:
                          BorderSide(width: 2, color: AppColors.white),
                    ),
                    tabs: _estadoTabLabels.map((e) => Tab(text: e)).toList(),
                    onTap: (index) {
                      setState(() => _filtroEstado = _estadoTabs[index]);
                      _loadCitas();
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // ─── Selector de fecha ───
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: GradientContainer(
                    gradient: AppGradients.blueWhiteBlue(),
                    borderColor: AppColors.blueborder,
                    borderWidth: 0.6,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left, size: 20, color: AppColors.blue1),
                            onPressed: () {
                              setState(() {
                                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                              });
                              _loadCitas();
                            },
                            visualDensity: VisualDensity.compact,
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  setState(() => _selectedDate = picked);
                                  _loadCitas();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.calendar_today, size: 14, color: AppColors.blue1),
                                    const SizedBox(width: 8),
                                    AppTitle(
                                      _formatDateLabel(_selectedDate),
                                      fontSize: 13,
                                      color: AppColors.blue1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, size: 20, color: AppColors.blue1),
                            onPressed: () {
                              setState(() {
                                _selectedDate = _selectedDate.add(const Duration(days: 1));
                              });
                              _loadCitas();
                            },
                            visualDensity: VisualDensity.compact,
                          ),
                          IconButton(
                            icon: const Icon(Icons.today, size: 18, color: AppColors.blue1),
                            tooltip: 'Hoy',
                            onPressed: () {
                              setState(() => _selectedDate = DateTime.now());
                              _loadCitas();
                            },
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ─── Lista de citas ───
                Expanded(child: _buildCitaList()),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingButtonIcon(
          onPressed: () async {
            final result = await context.push('/empresa/citas/nueva');
            if (!mounted) return;
            if (result == true) _loadCitas();
          },
          icon: Icons.add,
        ),
      ),
    );
  }

  Widget _buildCitaList() {
    return BlocBuilder<CitaListCubit, CitaListState>(
      builder: (context, state) {
        if (state is CitaListLoading) {
          return CustomLoading.small(message: 'Cargando citas...');
        }

        if (state is CitaListError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 48, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _loadCitas,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is CitaListLoaded) {
          final citas = state.resultado.data;

          if (citas.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_month,
                        size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text('No hay citas para este día',
                        style: TextStyle(
                            fontSize: 15, color: Colors.grey.shade500)),
                    const SizedBox(height: 8),
                    Text(
                      'Presiona + para agendar una nueva cita',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadCitas(),
            color: AppColors.blue1,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              itemCount: citas.length,
              itemBuilder: (context, index) {
                return _CitaCard(
                  cita: citas[index],
                  onTap: () async {
                    await context.push('/empresa/citas/${citas[index].id}');
                    if (!mounted) return;
                    _loadCitas();
                  },
                );
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(date.year, date.month, date.day);
    final formatted = DateFormatter.formatDate(date);

    if (selected == today) return 'Hoy, $formatted';
    if (selected == today.add(const Duration(days: 1))) {
      return 'Mañana, $formatted';
    }
    if (selected == today.subtract(const Duration(days: 1))) {
      return 'Ayer, $formatted';
    }
    return formatted;
  }
}

// ─── Card de Cita ───

class _CitaCard extends StatelessWidget {
  final Cita cita;
  final VoidCallback onTap;

  const _CitaCard({required this.cita, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GradientContainer(
        gradient: AppGradients.blueWhiteBlue(),
        shadowStyle: ShadowStyle.glow,
        borderColor: AppColors.blueborder,
        borderWidth: 0.6,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Header: Hora + Código + Estado ───
                _buildHeader(),
                const SizedBox(height: 6),
                Container(height: 1, color: Colors.grey.shade200),
                const SizedBox(height: 6),
                // ─── Cliente ───
                _buildClienteRow(),
                // ─── Servicio ───
                if (cita.servicio != null) ...[
                  const SizedBox(height: 6),
                  _buildServicioRow(),
                ],
                const SizedBox(height: 8),
                // ─── Footer: Técnico + Sede ───
                _buildFooter(),
                // ─── Notas ───
                if (cita.notas != null && cita.notas!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildNotas(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Hora badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.blue1.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                cita.horaInicio,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.blue1,
                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                ),
              ),
              Text(
                cita.horaFin,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.blue1.withValues(alpha: 0.7),
                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cita.codigo,
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (cita.sede != null) ...[
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.store_outlined,
                        size: 10, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      cita.sede!.nombre,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade700,
                        fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        CitaEstadoBadge(estado: cita.estado),
      ],
    );
  }

  Widget _buildClienteRow() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: AppColors.blue1.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            cita.clienteEmpresa != null ? Icons.business : Icons.person_outline,
            size: 12,
            color: AppColors.blue1,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            cita.clienteNombre,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.blue2,
              fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildServicioRow() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: AppColors.blue1.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.room_service_outlined,
              size: 12, color: AppColors.blue1),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            cita.servicio!.nombre,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade700,
              fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (cita.servicio!.duracionMinutos != null) ...[
          Icon(Icons.timer_outlined, size: 10, color: Colors.grey.shade500),
          const SizedBox(width: 3),
          Text(
            '${cita.servicio!.duracionMinutos} min',
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey.shade500,
              fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        // Técnico chip
        if (cita.tecnico != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.bluechip,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.engineering, size: 10, color: AppColors.blue1),
                const SizedBox(width: 3),
                AppSubtitle(
                  cita.tecnico!.nombreCompleto,
                  fontSize: 9,
                  color: AppColors.blue1,
                ),
              ],
            ),
          ),
        const Spacer(),
        // Precio
        if (cita.servicio?.precio != null)
          Text(
            'S/ ${cita.servicio!.precio!.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.blue1,
            ),
          ),
      ],
    );
  }

  Widget _buildNotas() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.blue1.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.blue1.withValues(alpha: 0.08),
          width: 0.6,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.notes, size: 12, color: Colors.grey.shade400),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              cita.notas!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
