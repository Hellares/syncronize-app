import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/anulacion.dart';
import '../bloc/anulaciones_cubit.dart';
import '../bloc/anulaciones_state.dart';
import '../widgets/anulacion_detail_sheet.dart';

class AnulacionesPage extends StatelessWidget {
  const AnulacionesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AnulacionesCubit(
        locator(),
        locator(),
        locator(),
        locator(),
      )..cargar(),
      child: const _AnulacionesView(),
    );
  }
}

class _AnulacionesView extends StatelessWidget {
  const _AnulacionesView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anulaciones SUNAT'),
        actions: [
          IconButton(
            tooltip: 'Limpiar filtros',
            icon: const Icon(Icons.filter_alt_off_outlined),
            onPressed: () => context.read<AnulacionesCubit>().limpiarFiltros(),
          ),
          IconButton(
            tooltip: 'Refrescar',
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AnulacionesCubit>().refrescar(),
          ),
        ],
      ),
      body: Column(
        children: [
          const _FiltrosBar(),
          const Divider(height: 1),
          Expanded(
            child: BlocBuilder<AnulacionesCubit, AnulacionesState>(
              builder: (context, state) {
                if (state is AnulacionesLoading || state is AnulacionesInitial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is AnulacionesError) {
                  return _ErrorView(message: state.message);
                }
                if (state is AnulacionesLoaded) {
                  if (state.items.isEmpty) {
                    return const _EmptyView();
                  }
                  return RefreshIndicator(
                    onRefresh: () =>
                        context.read<AnulacionesCubit>().refrescar(),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                      itemCount: state.items.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        if (i == state.items.length) {
                          return _Paginador(
                            currentPage: state.currentPage,
                            totalPages: state.totalPages,
                            total: state.total,
                          );
                        }
                        return _AnulacionCard(anulacion: state.items[i]);
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
    );
  }
}

class _FiltrosBar extends StatelessWidget {
  const _FiltrosBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnulacionesCubit, AnulacionesState>(
      buildWhen: (a, b) => a is! AnulacionesLoaded || b is AnulacionesLoaded,
      builder: (context, state) {
        FiltroTipoAnulacion tipoSel = FiltroTipoAnulacion.todas;
        String? estadoSel;
        String? fechaDesde;
        String? fechaHasta;
        if (state is AnulacionesLoaded) {
          tipoSel = state.filtroTipo;
          estadoSel = state.filtroEstado;
          fechaDesde = state.fechaDesde;
          fechaHasta = state.fechaHasta;
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.grey.shade50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: FiltroTipoAnulacion.values.map((t) {
                    final selected = tipoSel == t;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(t.label,
                            style: const TextStyle(fontSize: 11)),
                        selected: selected,
                        onSelected: (_) =>
                            context.read<AnulacionesCubit>().setFiltroTipo(t),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _estadoChip(context, null, 'Todos los estados', estadoSel),
                    _estadoChip(context, 'PENDIENTE', 'Pendiente', estadoSel),
                    _estadoChip(context, 'PROCESANDO', 'Procesando', estadoSel),
                    _estadoChip(context, 'ACEPTADO', 'Aceptado', estadoSel),
                    _estadoChip(context, 'RECHAZADO', 'Rechazado', estadoSel),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _DateButton(
                      label: 'Desde',
                      value: fechaDesde,
                      onPick: (val) => context
                          .read<AnulacionesCubit>()
                          .setFechas(val, fechaHasta),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _DateButton(
                      label: 'Hasta',
                      value: fechaHasta,
                      onPick: (val) => context
                          .read<AnulacionesCubit>()
                          .setFechas(fechaDesde, val),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _estadoChip(
      BuildContext ctx, String? value, String label, String? selected) {
    final isSelected = selected == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selected: isSelected,
        onSelected: (_) =>
            ctx.read<AnulacionesCubit>().setFiltroEstado(value),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final String? value;
  final void Function(String?) onPick;
  const _DateButton(
      {required this.label, required this.value, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.calendar_today, size: 14),
      label: Text(
        value == null ? label : '$label: $value',
        style: const TextStyle(fontSize: 11),
      ),
      onPressed: () async {
        final initial =
            value != null ? DateTime.tryParse(value!) ?? DateTime.now() : DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(2024),
          lastDate: DateTime.now().add(const Duration(days: 1)),
        );
        if (picked == null) {
          onPick(null);
        } else {
          final s =
              '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
          onPick(s);
        }
      },
    );
  }
}

class _AnulacionCard extends StatelessWidget {
  final Anulacion anulacion;
  const _AnulacionCard({required this.anulacion});

  @override
  Widget build(BuildContext context) {
    final estadoColor = _colorEstado(anulacion.estadoSunat);
    final tipoColor =
        anulacion.tipo == TipoAnulacion.cdb ? Colors.blue : Colors.teal;
    final fechaEmision = anulacion.fechaEmision.toLocal();
    final fechaRef = anulacion.fechaReferencia.toLocal();
    final firstDoc = anulacion.documentos.isNotEmpty
        ? anulacion.documentos.first.comprobanteCodigo
        : '—';

    return InkWell(
      onTap: () => AnulacionDetailSheet.show(context, anulacion),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: tipoColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    anulacion.tipoLabel,
                    style: TextStyle(
                        fontSize: 10,
                        color: tipoColor,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    anulacion.numeroCompleto,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: estadoColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    anulacion.estadoSunat,
                    style: TextStyle(
                        fontSize: 10,
                        color: estadoColor,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.event,
                    size: 12, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Emitido ${_fmtDate(fechaEmision)}  •  Ref ${_fmtDate(fechaRef)}',
                  style:
                      TextStyle(fontSize: 10, color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.description,
                    size: 12, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${anulacion.cantidadDocumentos} doc${anulacion.cantidadDocumentos == 1 ? '' : 's'}: $firstDoc${anulacion.cantidadDocumentos > 1 ? '...' : ''}',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade800),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (anulacion.motivo.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                anulacion.motivo,
                style: const TextStyle(fontSize: 11, color: Colors.black87),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (anulacion.ticket != null && anulacion.ticket!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Ticket: ${anulacion.ticket}',
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      fontFamily: 'monospace')),
            ],
          ],
        ),
      ),
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static Color _colorEstado(String estado) {
    switch (estado) {
      case 'ACEPTADO':
        return Colors.green.shade700;
      case 'RECHAZADO':
        return Colors.red.shade700;
      case 'PROCESANDO':
      case 'ENVIADO':
        return Colors.orange.shade700;
      case 'PENDIENTE':
      default:
        return Colors.grey.shade700;
    }
  }
}

class _Paginador extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int total;
  const _Paginador({
    required this.currentPage,
    required this.totalPages,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text('$total resultado${total == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: currentPage > 1
                ? () =>
                    context.read<AnulacionesCubit>().irAPagina(currentPage - 1)
                : null,
          ),
          Text('Página $currentPage / $totalPages',
              style: const TextStyle(fontSize: 12)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: currentPage < totalPages
                ? () =>
                    context.read<AnulacionesCubit>().irAPagina(currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text('Sin anulaciones',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text('No hay CDBs ni RCs que coincidan con los filtros',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.read<AnulacionesCubit>().refrescar(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
