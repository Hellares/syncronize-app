import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_loading.dart';
import '../../domain/entities/cita.dart';
import '../../domain/repositories/cita_repository.dart';
import '../widgets/cita_estado_badge.dart';

class HistorialCitasClientePage extends StatefulWidget {
  final String clienteId;
  final String? clienteEmpresaId;
  final String clienteNombre;

  const HistorialCitasClientePage({
    super.key,
    required this.clienteId,
    this.clienteEmpresaId,
    required this.clienteNombre,
  });

  @override
  State<HistorialCitasClientePage> createState() =>
      _HistorialCitasClientePageState();
}

class _HistorialCitasClientePageState extends State<HistorialCitasClientePage> {
  List<Cita> _citas = [];
  int _total = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistorial();
  }

  Future<void> _loadHistorial() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final repo = locator<CitaRepository>();
    final result = await repo.getHistorialCliente(
      widget.clienteId,
      clienteEmpresaId: widget.clienteEmpresaId,
    );

    if (!mounted) return;

    setState(() {
      _loading = false;
      if (result is Success<({List<Cita> citas, int total})>) {
        _citas = result.data.citas;
        _total = result.data.total;
      } else if (result is Error) {
        _error = (result as Error).message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(
          title: 'Historial de Citas',
          backgroundColor: AppColors.blue1,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: _loadHistorial,
              tooltip: 'Actualizar',
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Header con info del cliente
              Padding(
                padding: const EdgeInsets.all(12),
                child: GradientContainer(
                  gradient: AppGradients.blueWhiteBlue(),
                  borderColor: AppColors.blueborder,
                  borderWidth: 0.6,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.blue1.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            widget.clienteEmpresaId != null
                                ? Icons.business
                                : Icons.person,
                            color: AppColors.blue1,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppSubtitle(
                                widget.clienteNombre,
                                fontSize: 13,
                                color: AppColors.blue2,
                              ),
                              if (!_loading)
                                Text(
                                  '$_total cita${_total != 1 ? 's' : ''} registrada${_total != 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Lista
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return CustomLoading.small(message: 'Cargando historial...');
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loadHistorial,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reintentar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.blue1,
                  side: const BorderSide(color: AppColors.blue1),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_citas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_month, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Este cliente no tiene citas registradas',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistorial,
      color: AppColors.blue1,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _citas.length,
        itemBuilder: (context, index) {
          final cita = _citas[index];
          return _HistorialCitaCard(
            cita: cita,
            onTap: () async {
              await context.push('/empresa/citas/${cita.id}');
              if (!mounted) return;
              _loadHistorial();
            },
          );
        },
      ),
    );
  }
}

class _HistorialCitaCard extends StatelessWidget {
  final Cita cita;
  final VoidCallback onTap;

  const _HistorialCitaCard({required this.cita, required this.onTap});

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
                // Header: Fecha + Código + Estado
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.blue1.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            DateFormatter.formatDate(cita.fecha),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.blue1,
                              fontFamily:
                                  AppFonts.getFontFamily(AppFont.oxygenBold),
                            ),
                          ),
                          Text(
                            '${cita.horaInicio} - ${cita.horaFin}',
                            style: TextStyle(
                              fontSize: 9,
                              color: AppColors.blue1.withValues(alpha: 0.7),
                              fontFamily:
                                  AppFonts.getFontFamily(AppFont.oxygenRegular),
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
                              fontFamily:
                                  AppFonts.getFontFamily(AppFont.oxygenRegular),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (cita.servicio != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              cita.servicio!.nombre,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                                fontFamily:
                                    AppFonts.getFontFamily(AppFont.oxygenRegular),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    CitaEstadoBadge(estado: cita.estado),
                  ],
                ),
                const SizedBox(height: 8),
                // Footer: Técnico + Sede + Precio
                Row(
                  children: [
                    if (cita.tecnico != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.bluechip,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.engineering,
                                size: 10, color: AppColors.blue1),
                            const SizedBox(width: 3),
                            AppSubtitle(
                              cita.tecnico!.nombreCompleto,
                              fontSize: 9,
                              color: AppColors.blue1,
                            ),
                          ],
                        ),
                      ),
                    if (cita.sede != null) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.store_outlined,
                          size: 10, color: Colors.grey.shade500),
                      const SizedBox(width: 3),
                      Text(
                        cita.sede!.nombre,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade600,
                          fontFamily:
                              AppFonts.getFontFamily(AppFont.oxygenRegular),
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (cita.costoTotal != null && cita.costoTotal! > 0)
                      Text(
                        'S/ ${cita.costoTotal!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blue1,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
