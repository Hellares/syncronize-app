import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/styled_dialog.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../../empresa/presentation/bloc/sede_activa/sede_activa_cubit.dart';
import '../../domain/entities/sorteo.dart';
import '../bloc/sorteos_cubit.dart';

/// Listado de sorteos de la empresa + creación rápida.
class SorteosPage extends StatelessWidget {
  const SorteosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<SorteosCubit>()..loadSorteos(),
      child: const _SorteosView(),
    );
  }
}

class _SorteosView extends StatelessWidget {
  const _SorteosView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        customHeight: 40,
        title: 'Sorteos y dinámicas',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        actions: [
          // Cola global de jugadores del bot con pago por validar.
          IconButton(
            tooltip: 'Jugadores por validar',
            icon: const Icon(Icons.how_to_reg, size: 21, color: Colors.white),
            onPressed: () =>
                context.push('/empresa/sorteos/jugadores-pendientes'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'nuevo-sorteo',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.card_giftcard, size: 18),
        label: const Text('Nuevo sorteo', style: TextStyle(fontSize: 12.5)),
        onPressed: () => _crearSorteo(context),
      ),
      // Sorteos (rifas), bingos y dinámicas NO se mezclan: cada tipo en
      // su tab.
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            Container(
              color: AppColors.blue1,
              child: const TabBar(
                indicatorColor: Colors.white,
                indicatorWeight: 2.5,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle:
                    TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                tabs: [
                  Tab(height: 38, text: '🎟️ Sorteos'),
                  Tab(height: 38, text: '🎱 Bingos'),
                  Tab(height: 38, text: '🎯 Dinámicas'),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<SorteosCubit, SorteosState>(
                builder: (context, state) {
                  if (state is SorteosLoading || state is SorteosInitial) {
                    return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2));
                  }
                  if (state is SorteosError) {
                    return _mensaje(
                      context,
                      icono: Icons.wifi_off,
                      texto: state.message,
                      reintentar: () => context.read<SorteosCubit>().reload(),
                    );
                  }
                  final todos = (state as SorteosLoaded).sorteos;
                  final rifas = todos
                      .where((s) => s.tipo == TipoSorteo.sorteo)
                      .toList();
                  final bingos = todos
                      .where((s) => s.tipo == TipoSorteo.bingo)
                      .toList();
                  final dinamicas = todos
                      .where((s) => s.tipo == TipoSorteo.dinamica)
                      .toList();
                  return TabBarView(
                    children: [
                      _lista(context, rifas,
                          'Aún no hay sorteos.\nRegistra el primero y vende tickets para el ánfora.'),
                      _lista(context, bingos,
                          'Aún no hay bingos.\nCrea uno: el bot vende las cartillas y tú cantas las bolillas.'),
                      _lista(context, dinamicas,
                          'Aún no hay dinámicas.\nCrea una y el bot registra a los jugadores.'),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lista(
      BuildContext context, List<Sorteo> sorteos, String textoVacio) {
    if (sorteos.isEmpty) {
      return _mensaje(context,
          icono: Icons.card_giftcard, texto: textoVacio);
    }
    return RefreshIndicator(
      onRefresh: () => context.read<SorteosCubit>().reload(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 80),
        itemCount: sorteos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _SorteoCard(sorteo: sorteos[i]),
      ),
    );
  }

  /// Botón compacto de fecha para el dialog de creación.
  Widget _fechaBtn(String label, String valor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Text(label,
                style:
                    TextStyle(fontSize: 8.5, color: Colors.grey.shade600)),
            const SizedBox(height: 2),
            Text(valor,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blue1)),
          ],
        ),
      ),
    );
  }

  Widget _mensaje(BuildContext context,
      {required IconData icono,
      required String texto,
      VoidCallback? reintentar}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 52, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              texto,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
            ),
          ),
          if (reintentar != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: reintentar,
              child: const Text('Reintentar'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _crearSorteo(BuildContext context) async {
    final cubit = context.read<SorteosCubit>();
    final tituloCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final precioCtrl = TextEditingController();
    var canal = CanalSorteo.facebook;
    var tipo = TipoSorteo.sorteo;
    DateTime? ventaDesde;
    DateTime? ventaHasta;
    DateTime? fechaSorteo;

    String fmt(DateTime? d) => d == null
        ? '—'
        : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    Future<DateTime?> pickFecha(
        BuildContext ctx, DateTime? actual) async {
      final hoy = DateTime.now();
      return showDatePicker(
        context: ctx,
        initialDate: actual ?? hoy,
        firstDate: hoy.subtract(const Duration(days: 1)),
        lastDate: hoy.add(const Duration(days: 365)),
      );
    }

    final crear = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => StyledDialog(
          accentColor: AppColors.blue1,
          icon: Icons.card_giftcard,
          titulo: 'Nuevo sorteo / dinámica',
          content: [
            // SORTEO: se sortea entre participantes. DINÁMICA: el que
            // juega YA ganó lo que saca (canasta, etc.).
            Row(
              children: [
                for (final t in TipoSorteo.values) ...[
                  Expanded(
                    child: ChoiceChip(
                      label: Text(t.label,
                          style: const TextStyle(fontSize: 10.5)),
                      selected: tipo == t,
                      selectedColor: AppColors.blue1.withValues(alpha: 0.15),
                      onSelected: (_) => setLocal(() => tipo = t),
                    ),
                  ),
                  if (t != TipoSorteo.values.last) const SizedBox(width: 8),
                ],
              ],
            ),
            if (tipo == TipoSorteo.dinamica) ...[
              const SizedBox(height: 4),
              Text(
                'Dinámica: el participante paga, juega y lo que saca YA lo '
                'ganó — cada jugador se registra como ganador con su premio.',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ],
            // Rifa/bingo: ventana de venta + fecha del juego (el bot las
            // anuncia al cliente).
            if (tipo != TipoSorteo.dinamica) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _fechaBtn(
                      'Venta desde',
                      fmt(ventaDesde),
                      () async {
                        final d = await pickFecha(ctx, ventaDesde);
                        if (d != null) setLocal(() => ventaDesde = d);
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _fechaBtn(
                      'Venta hasta',
                      fmt(ventaHasta),
                      () async {
                        final d = await pickFecha(ctx, ventaHasta);
                        if (d != null) setLocal(() => ventaHasta = d);
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _fechaBtn(
                      'Se sortea el',
                      fmt(fechaSorteo),
                      () async {
                        final d = await pickFecha(ctx, fechaSorteo);
                        if (d != null) setLocal(() => fechaSorteo = d);
                      },
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            CustomText(
              controller: tituloCtrl,
              label: 'Título',
              hintText: 'ej. Sorteo aniversario TikTok',
              borderColor: AppColors.blue1,
              textCase: TextCase.upper,
            ),
            const SizedBox(height: 8),
            CustomText(
              controller: descCtrl,
              label: 'Descripción (opcional)',
              hintText: 'ej. 5 premios entre seguidores',
              borderColor: AppColors.blue1,
              textCase: TextCase.upper,
            ),
            const SizedBox(height: 8),
            CustomText(
              controller: precioCtrl,
              label: 'Precio de participación S/ (opcional)',
              hintText: 'ej. 20 — lo que paga cada jugada',
              borderColor: AppColors.blue1,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Canal del sorteo',
                  style:
                      TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final c in CanalSorteo.values)
                  ChoiceChip(
                    label:
                        Text(c.label, style: const TextStyle(fontSize: 10.5)),
                    selected: canal == c,
                    selectedColor: AppColors.blue1.withValues(alpha: 0.15),
                    onSelected: (_) => setLocal(() => canal = c),
                  ),
              ],
            ),
          ],
          actions: [
            Expanded(
              child: CustomButton(
                text: 'Cancelar',
                isOutlined: true,
                borderColor: Colors.grey.shade400,
                textColor: Colors.grey.shade700,
                enableShadows: false,
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
            ),
            Expanded(
              child: CustomButton(
                text: 'Crear',
                backgroundColor: AppColors.blue1,
                textColor: Colors.white,
                onPressed: () {
                  if (tituloCtrl.text.trim().isEmpty) return;
                  Navigator.of(ctx).pop(true);
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (crear != true || !context.mounted) return;

    // Fechas como mediodía UTC (07:00 Lima): fecha-only sin corrimiento
    // de día por zona horaria.
    DateTime? aUtc(DateTime? d) =>
        d == null ? null : DateTime.utc(d.year, d.month, d.day, 12);

    // El stock de los premios sale de la sede activa.
    final sede = context.read<SedeActivaCubit>().state.activa;
    final sorteo = await cubit.crearSorteo(
      titulo: tituloCtrl.text.trim(),
      descripcion: descCtrl.text.trim(),
      canal: canal,
      tipo: tipo,
      fechaSorteo: aUtc(fechaSorteo),
      ventaDesde: aUtc(ventaDesde),
      ventaHasta: aUtc(ventaHasta),
      sedeId: sede?.id,
      precioParticipacion:
          double.tryParse(precioCtrl.text.trim().replaceAll(',', '.')),
    );
    if (sorteo != null && context.mounted) {
      context.push('/empresa/sorteos/${sorteo.id}');
    }
  }
}

class _SorteoCard extends StatelessWidget {
  final Sorteo sorteo;
  const _SorteoCard({required this.sorteo});

  @override
  Widget build(BuildContext context) {
    final f = sorteo.fechaSorteo;
    final fecha =
        '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';
    final cerrado = sorteo.estado != EstadoSorteo.abierto;
    // La rifa/bingo cerrado sigue EN JUEGO hasta marcarse finalizado.
    final jugando = sorteo.estado == EstadoSorteo.cerrado &&
        sorteo.tipo != TipoSorteo.dinamica;
    // GradientContainer de la casa (mismo patrón que cola POS).
    return GradientContainer(
      borderColor: cerrado ? Colors.grey.shade400 : AppColors.blueborder,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.push('/empresa/sorteos/${sorteo.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (cerrado ? Colors.grey : AppColors.blue1)
                      .withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.card_giftcard,
                    size: 18,
                    color: cerrado ? Colors.grey : AppColors.blue1),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sorteo.titulo,
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.blue1),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      '${sorteo.tipo == TipoSorteo.dinamica ? 'DINÁMICA · ' : ''}'
                      '${sorteo.canal.label} · $fecha · '
                      '${sorteo.cantidadPremios} premio${sorteo.cantidadPremios == 1 ? '' : 's'}',
                      style: TextStyle(
                          fontSize: 10.5, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (jugando
                          ? Colors.purple
                          : cerrado
                              ? Colors.grey
                              : Colors.green)
                      .withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  sorteo.estadoTexto.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: jugando
                        ? Colors.purple.shade700
                        : cerrado
                            ? Colors.grey.shade700
                            : Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
