import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/utils/date_formatter.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/features/impresoras/domain/services/impresoras_manager.dart';

import '../../domain/entities/arqueo_caja.dart';
import '../../domain/entities/caja.dart';
import '../bloc/arqueos_caja_cubit.dart';
import '../bloc/arqueos_caja_state.dart';
import '../services/arqueo_caja_esc_pos_generator.dart';
import '../services/caja_ticket_data.dart';

class ArqueosListaPage extends StatefulWidget {
  final Caja caja;

  const ArqueosListaPage({super.key, required this.caja});

  @override
  State<ArqueosListaPage> createState() => _ArqueosListaPageState();
}

class _ArqueosListaPageState extends State<ArqueosListaPage> {
  @override
  void initState() {
    super.initState();
    context.read<ArqueosCajaCubit>().loadArqueos(widget.caja.id);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_PE',
      symbol: 'S/ ',
      decimalDigits: 2,
    );

    return Scaffold(
      appBar: SmartAppBar(
        title: 'Arqueos ${widget.caja.codigo}',
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
      ),
      body: GradientContainer(
        child: BlocBuilder<ArqueosCajaCubit, ArqueosCajaState>(
          builder: (context, state) {
            if (state is ArqueosCajaLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ArqueosCajaError) {
              return Center(
                child: Text(
                  state.message,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              );
            }
            if (state is ArqueosCajaLoaded) {
              if (state.arqueos.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.fact_check_outlined,
                        size: 48,
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Sin arqueos en esta caja',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () =>
                    context.read<ArqueosCajaCubit>().loadArqueos(widget.caja.id),
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: state.arqueos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, idx) =>
                      _buildArqueoCard(state.arqueos[idx], currencyFormat),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildArqueoCard(ArqueoCaja a, NumberFormat currency) {
    final hasDif = a.diferencia.abs() >= 0.01;
    final difColor = hasDif
        ? (a.diferencia > 0 ? AppColors.green : AppColors.red)
        : AppColors.textSecondary;

    return GradientContainer(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: a.tipo.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(a.tipo.icon, color: a.tipo.color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSubtitle(
                      a.tipo.label,
                      fontSize: 13,
                      color: a.tipo.color,
                    ),
                    Text(
                      DateFormatter.formatDateTime(a.fechaArqueo),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasDif)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: difColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${a.diferencia > 0 ? '+' : ''}${currency.format(a.diferencia)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: difColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _miniRow(
                    'Esperado', currency.format(a.totalEsperado)),
              ),
              Expanded(
                child: _miniRow(
                    'Conteo', currency.format(a.totalConteoFisico)),
              ),
            ],
          ),
          if (a.realizadoPorNombre != null) ...[
            const SizedBox(height: 6),
            Text(
              'Realiza: ${a.realizadoPorNombre}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (a.turnoEntregadoANombre != null)
            Text(
              'Recibe: ${a.turnoEntregadoANombre}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          if (a.observaciones != null && a.observaciones!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              a.observaciones!,
              style: const TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _reimprimir(a),
              icon: const Icon(Icons.print_rounded, size: 14),
              label: const Text(
                'Imprimir',
                style: TextStyle(fontSize: 12),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.blue1,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                minimumSize: const Size(0, 28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
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
        ),
      ],
    );
  }

  Future<void> _reimprimir(ArqueoCaja a) async {
    try {
      final ticketData = await resolverCajaTicketData(context, widget.caja);
      final manager = locator<ImpresorasManager>();
      final principal = await manager.getPrincipal();
      if (!mounted) return;
      if (principal == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay impresora principal configurada'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final bytes = await ArqueoCajaEscPosGenerator.generate(
        caja: widget.caja,
        arqueo: a,
        empresaNombre: ticketData.empresaNombre,
        empresaRazonSocial: ticketData.razonSocial,
        empresaRuc: ticketData.ruc,
        empresaDireccion: ticketData.direccion,
        empresaTelefono: ticketData.telefono,
        sedeNombre: widget.caja.sedeNombre,
        logoEmpresa: ticketData.logoBytes,
        paperWidth: principal.anchoPapel.mm,
      );

      final ok = await manager.imprimirEnPrincipal(bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Arqueo impreso' : 'No se pudo imprimir'),
          backgroundColor: ok ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
