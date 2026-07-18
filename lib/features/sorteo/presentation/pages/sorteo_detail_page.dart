import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:syncronize/features/venta/data/datasources/venta_remote_datasource.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/realtime_sync_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/cliente_unificado_selector.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/styled_dialog.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../data/datasources/sorteo_remote_datasource.dart';
import '../../domain/entities/sorteo.dart';
import '../bloc/sorteo_detail_cubit.dart';
import '../services/rotulo_envio_pdf_generator.dart';
import '../services/tickets_anfora_pdf_generator.dart';
import '../widgets/editar_entrega_sheet.dart';
import '../widgets/enviar_whatsapp_premio_sheet.dart';
import '../widgets/live_links_sheet.dart';
import '../widgets/registrar_premio_sheet.dart';

/// Detalle del sorteo: ganadores registrados, estados de envío, foto del
/// ticket de agencia y registro de nuevos ganadores.
class SorteoDetailPage extends StatelessWidget {
  final String sorteoId;
  const SorteoDetailPage({super.key, required this.sorteoId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<SorteoDetailCubit>()..load(sorteoId),
      child: const _RealtimeReload(child: _SorteoDetailView()),
    );
  }
}

/// Recarga el detalle al instante cuando OTRO device cambia el sorteo
/// (FCM SORTEO_CAMBIADO): el cajero valida un participante en su celular
/// y la card aparece sola aquí — mismo patrón realtime que productos.
class _RealtimeReload extends StatefulWidget {
  final Widget child;
  const _RealtimeReload({required this.child});

  @override
  State<_RealtimeReload> createState() => _RealtimeReloadState();
}

class _RealtimeReloadState extends State<_RealtimeReload> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _sub = locator<RealtimeSyncService>().events.listen((e) {
      if (!mounted || e is! RealtimeSorteoCambiado) return;
      context.read<SorteoDetailCubit>().onSorteoCambiado(e.sorteoId);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _SorteoDetailView extends StatelessWidget {
  const _SorteoDetailView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SorteoDetailCubit, SorteoDetailState>(
      builder: (context, state) {
        final sorteo = state is SorteoDetailLoaded ? state.sorteo : null;
        return Scaffold(
          appBar: SmartAppBar(
            customHeight: 40,
            title: sorteo?.titulo ?? 'Sorteo',
            backgroundColor: AppColors.blue1,
            foregroundColor: Colors.white,
            actions: [
              // Links del LIVE (Facebook/TikTok): el bot los comparte.
              // Rojo = ya hay links puestos. Visible mientras el juego
              // esté vivo (abierto o jugando).
              if (sorteo != null && sorteo.estado != EstadoSorteo.finalizado)
                IconButton(
                  tooltip: 'Links del LIVE',
                  icon: Icon(
                    Icons.sensors,
                    size: 20,
                    color: sorteo.liveLinks.isNotEmpty
                        ? Colors.redAccent.shade100
                        : Colors.white,
                  ),
                  onPressed: () => _editarLiveLinks(context, sorteo),
                ),
              // Tickets físicos para el ánfora (solo sorteos clásicos).
              if (sorteo != null &&
                  sorteo.tipo == TipoSorteo.sorteo &&
                  sorteo.participantes.any((p) =>
                      p.estado == EstadoParticipanteSorteo.activo &&
                      p.numeroTicket != null))
                IconButton(
                  tooltip: 'Imprimir tickets del ánfora',
                  icon: const Icon(Icons.print_outlined,
                      size: 20, color: Colors.white),
                  onPressed: () => _imprimirTickets(context, sorteo),
                ),
              if (sorteo != null && sorteo.estado == EstadoSorteo.abierto)
                IconButton(
                  tooltip: 'Cerrar sorteo',
                  icon: const Icon(Icons.lock_outline,
                      size: 20, color: Colors.white),
                  onPressed: () => _cerrarSorteo(context),
                ),
              // La rifa cerrada sigue en juego: FINALIZAR = ya se sorteó
              // todo, cierre definitivo.
              if (sorteo != null &&
                  sorteo.estado == EstadoSorteo.cerrado &&
                  sorteo.tipo == TipoSorteo.sorteo)
                IconButton(
                  tooltip: 'Finalizar sorteo (ya se jugó todo)',
                  icon: const Icon(Icons.sports_score,
                      size: 20, color: Colors.white),
                  onPressed: () => _finalizarSorteo(context),
                ),
              if (sorteo != null && sorteo.estado != EstadoSorteo.abierto)
                IconButton(
                  tooltip: 'Reabrir para regularizar',
                  icon: const Icon(Icons.lock_open,
                      size: 20, color: Colors.white),
                  onPressed: () => _reabrirSorteo(context),
                ),
            ],
          ),
          floatingActionButton:
              sorteo != null && sorteo.estado == EstadoSorteo.abierto
                  ? FloatingActionButton.extended(
                      heroTag: 'registrar-ganador',
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      icon: const Icon(Icons.emoji_events, size: 18),
                      label: const Text('Registrar ganador',
                          style: TextStyle(fontSize: 12.5)),
                      onPressed: () => _registrarGanador(context, sorteo),
                    )
                  : null,
          body: switch (state) {
            SorteoDetailLoading() => const Center(
                child: CircularProgressIndicator(strokeWidth: 2)),
            SorteoDetailError(:final message) => Center(
                child: Text(message,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ),
            SorteoDetailLoaded(:final sorteo) => _cuerpo(context, sorteo),
            _ => const SizedBox.shrink(),
          },
        );
      },
    );
  }

  Widget _cuerpo(BuildContext context, Sorteo sorteo) {
    // RIFA/BINGO: dos tabs — la operación (catálogo + tickets/cartillas)
    // y los GANADORES aparte. En dinámicas el premio ES el flujo
    // principal, así que siguen en una sola vista.
    if (sorteo.tipo != TipoSorteo.dinamica) {
      final ganadores = sorteo.premios
          .where((p) => p.estado != EstadoPremioSorteo.anulado)
          .length;
      return DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              color: AppColors.blue1,
              child: TabBar(
                indicatorColor: Colors.white,
                indicatorWeight: 2.5,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700),
                tabs: [
                  const Tab(height: 38, text: '🎟️ Participantes'),
                  Tab(
                      height: 38,
                      text:
                          '🏆 Ganadores${ganadores > 0 ? ' ($ganadores)' : ''}'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _tabPrincipal(context, sorteo, conPremios: false),
                  _tabGanadores(context, sorteo),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return _tabPrincipal(context, sorteo, conPremios: true);
  }

  /// Pestaña GANADORES de la rifa: solo las cards de premios.
  Widget _tabGanadores(BuildContext context, Sorteo sorteo) {
    return RefreshIndicator(
      onRefresh: () => context.read<SorteoDetailCubit>().reload(),
      child: sorteo.premios.isEmpty
          ? ListView(
              padding: const EdgeInsets.only(top: 70),
              children: [
                Icon(Icons.emoji_events,
                    size: 52, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'Aún no hay ganadores — cierra las ventas\ny usa 🎲 JUGAR con los tickets del ánfora',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12.5, color: Colors.grey.shade500),
                  ),
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 90),
              children: [
                for (final premio in sorteo.premios) ...[
                  _PremioCard(
                    premio: premio,
                    direccionConfirmada:
                        _direccionConfirmadaDe(sorteo, premio),
                    onImprimirRotulo: () =>
                        _imprimirRotulo(context, sorteo, premio),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
    );
  }

  Widget _tabPrincipal(BuildContext context, Sorteo sorteo,
      {required bool conPremios}) {
    String dm(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    final f = sorteo.fechaSorteo;
    final fecha = '${dm(f)}/${f.year}';
    // Ventana de venta de tickets (si la empresa la definió).
    final venta = sorteo.ventaHasta != null
        ? ' · Venta${sorteo.ventaDesde != null ? ' ${dm(sorteo.ventaDesde!)}' : ''}'
            '–${dm(sorteo.ventaHasta!)}'
        : '';
    final resumen = sorteo.resumen;
    return RefreshIndicator(
      onRefresh: () => context.read<SorteoDetailCubit>().reload(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 90),
        children: [
          // Imagen promocional del sorteo (la que se publica en redes).
          _ImagenPromocional(sorteo: sorteo),
          const SizedBox(height: 8),
          // Cabecera del sorteo
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.blue1.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${sorteo.tipo == TipoSorteo.dinamica ? 'DINÁMICA · ' : ''}${sorteo.canal.label} · $fecha$venta · ${sorteo.estadoTexto}'
                  '${sorteo.reabierto && sorteo.estado == EstadoSorteo.abierto ? ' (REABIERTO — bot inactivo)' : ''}'
                  '${sorteo.precioParticipacion != null ? ' · Jugada S/ ${sorteo.precioParticipacion!.toStringAsFixed(2)}' : ''}',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700),
                ),
                if (sorteo.descripcion != null &&
                    sorteo.descripcion!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(sorteo.descripcion!,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600)),
                ],
                const SizedBox(height: 4),
                Text(
                  '${sorteo.premios.length} ganador${sorteo.premios.length == 1 ? '' : 'es'} registrado${sorteo.premios.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          // ── Economía del sorteo ──
          if (resumen != null &&
              (resumen.totalRecaudado > 0 || resumen.costoPremios > 0)) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _statBox('Recaudado',
                    'S/ ${resumen.totalRecaudado.toStringAsFixed(2)}',
                    Colors.green.shade700),
                const SizedBox(width: 8),
                _statBox('Costo premios',
                    'S/ ${resumen.costoPremios.toStringAsFixed(2)}',
                    Colors.orange.shade800),
                const SizedBox(width: 8),
                _statBox(
                  'Ganancia',
                  'S/ ${resumen.ganancia.toStringAsFixed(2)}',
                  resumen.ganancia >= 0
                      ? AppColors.blue1
                      : Colors.red.shade700,
                ),
              ],
            ),
          ],
          // ── Catálogo de premios (rifa y bingo) ──
          if (sorteo.tipo != TipoSorteo.dinamica) ...[
            const SizedBox(height: 10),
            _PremiosCatalogoSection(sorteo: sorteo),
          ],
          // ── BINGO jugando: cantar bolillas ──
          if (sorteo.tipo == TipoSorteo.bingo &&
              sorteo.estado == EstadoSorteo.cerrado) ...[
            const SizedBox(height: 10),
            _BolillasSection(sorteo: sorteo),
          ],
          // ── Participantes captados por el bot de WhatsApp ──
          if (sorteo.participantes.isNotEmpty) ...[
            const SizedBox(height: 10),
            _ParticipantesSection(sorteo: sorteo),
          ],
          const SizedBox(height: 10),
          // Premios inline SOLO en dinámicas (en la rifa van en su tab).
          if (conPremios)
            if (sorteo.premios.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Column(
                  children: [
                    Icon(Icons.emoji_events,
                        size: 52, color: Colors.grey.shade300),
                    const SizedBox(height: 10),
                    Text('Registra al primer ganador del sorteo',
                        style: TextStyle(
                            fontSize: 12.5, color: Colors.grey.shade500)),
                  ],
                ),
              )
            else
              for (final premio in sorteo.premios) ...[
                _PremioCard(
                  premio: premio,
                  direccionConfirmada:
                      _direccionConfirmadaDe(sorteo, premio),
                  onImprimirRotulo: () =>
                      _imprimirRotulo(context, sorteo, premio),
                ),
                const SizedBox(height: 8),
              ],
        ],
      ),
    );
  }

  /// Imprime el rótulo de envío en impresora normal (A4, media hoja por
  /// rótulo). Si hay OTROS premios en preparación con agencia, ofrece
  /// incluirlos para aprovechar las 2 mitades de la hoja.
  Future<void> _imprimirRotulo(
      BuildContext context, Sorteo sorteo, SorteoPremio premio) async {
    final ctxState = context.read<EmpresaContextCubit>().state;
    final empresa =
        ctxState is EmpresaContextLoaded ? ctxState.context.empresa : null;

    final otros = sorteo.premios
        .where((p) =>
            p.id != premio.id &&
            p.modalidad == ModalidadEntregaPremio.envioAgencia &&
            (p.estado == EstadoPremioSorteo.preparando ||
                p.estado == EstadoPremioSorteo.enviado))
        .toList();

    final seleccion = <SorteoPremio>[premio];
    if (otros.isNotEmpty && context.mounted) {
      final extra = await showModalBottomSheet<List<SorteoPremio>>(
        context: context,
        builder: (ctx) {
          final marcados = <String>{};
          return StatefulBuilder(
            builder: (ctx, setLocal) => SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      '¿Incluir más rótulos? (2 por hoja)',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                  // Con varios premios el Column desborda el alto máximo del
                  // sheet y el botón queda fuera de los límites (visible pero
                  // sin hit-test): la lista scrollea y el botón queda anclado.
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final p in otros.take(6))
                            CheckboxListTile(
                              dense: true,
                              value: marcados.contains(p.id),
                              activeColor: AppColors.blue1,
                              controlAffinity:
                                  ListTileControlAffinity.leading,
                              title: Text(p.ganadorNombre,
                                  style: const TextStyle(fontSize: 12)),
                              subtitle: Text(p.descripcion,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600)),
                              onChanged: (v) => setLocal(() => v == true
                                  ? marcados.add(p.id)
                                  : marcados.remove(p.id)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(
                          ctx,
                          otros
                              .where((p) => marcados.contains(p.id))
                              .toList(),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue1,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Imprimir rótulos',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
      if (extra == null || !context.mounted) return;
      seleccion.addAll(extra);
    }

    // Logo de la empresa como marca de agua (best-effort: sin logo o
    // sin red, el rótulo sale igual).
    Uint8List? logoBytes;
    final logoUrl = empresa?.logo;
    if (logoUrl != null && logoUrl.isNotEmpty) {
      try {
        final r = await http
            .get(Uri.parse(logoUrl))
            .timeout(const Duration(seconds: 5));
        if (r.statusCode == 200) logoBytes = r.bodyBytes;
      } catch (_) {}
    }

    // Remitente = NOMBRE COMERCIAL (la marca que ve el cliente), no la
    // razón social. Best-effort con fallback al nombre legal.
    String? nombreComercial;
    try {
      final config =
          await locator<VentaRemoteDataSource>().getConfiguracionSunat();
      nombreComercial = config['nombreComercial'] as String?;
    } catch (_) {}

    final bytes = await RotuloEnvioPdfGenerator.generate(
      rotulos: seleccion
          .map((p) => DatosRotulo(
                // REGALO: el destinatario del rótulo es quien RECIBE
                // (la agencia valida nombre y DNI al entregar).
                nombre: p.esRegalo ? p.recibeNombre! : p.ganadorNombre,
                dni: p.esRegalo ? p.recibeDni : p.ganadorDni,
                celular: p.ganadorCelular,
                agenciaNombre: p.agenciaNombre,
                destinoDepartamento: p.destinoDepartamento,
                destinoProvincia: p.destinoProvincia,
                agenciaDireccion: p.agenciaDireccion,
              ))
          .toList(),
      remitenteNombre: nombreComercial ?? empresa?.nombre ?? '',
      remitenteTelefono: empresa?.telefono,
      logoBytes: logoBytes,
    );
    final cubit = context.mounted ? context.read<SorteoDetailCubit>() : null;
    final impreso = await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'rotulos_envio_sorteo.pdf',
    );
    // layoutPdf devuelve true solo si el usuario COMPLETÓ la impresión
    // (canceló → false): recién ahí se marca el chip IMPRESO.
    if (impreso && cubit != null && !cubit.isClosed) {
      await cubit.marcarRotulosImpresos(
        seleccion.map((p) => p.id).toList(),
      );
    }
  }

  /// El participante vinculado al premio (por jugada o por DNI) confirmó
  /// su dirección con el bot — alimenta el chip verde de la card.
  bool _direccionConfirmadaDe(Sorteo sorteo, SorteoPremio premio) {
    return sorteo.participantes.any((x) =>
        x.direccionConfirmada &&
        ((premio.participanteId != null && x.id == premio.participanteId) ||
            (premio.ganadorDni != null && x.dni == premio.ganadorDni)));
  }

  Widget _statBox(String label, String valor, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 0.6),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w600, color: color)),
            const SizedBox(height: 2),
            FittedBox(
              child: Text(valor,
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800, color: color)),
            ),
          ],
        ),
      ),
    );
  }

  /// El creador pega los links de su transmisión (Facebook/TikTok/etc.)
  /// y el bot de WhatsApp los comparte para que el cliente entre directo.
  Future<void> _editarLiveLinks(BuildContext context, Sorteo sorteo) async {
    final cubit = context.read<SorteoDetailCubit>();
    final links = await showLiveLinksSheet(
      context: context,
      actuales: sorteo.liveLinks,
    );
    if (links == null || !context.mounted) return;
    final error = await cubit.guardarLiveLinks(links);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        error ??
            (links.isEmpty
                ? 'Links del live quitados'
                : '🔴 ¡Listo! El bot ya comparte tu live'),
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor:
          error != null ? Colors.orange.shade800 : Colors.green.shade700,
    ));
  }

  Future<void> _cerrarSorteo(BuildContext context) async {
    final cubit = context.read<SorteoDetailCubit>();
    final ok = await ConfirmDialog.show(
      context: context,
      type: ConfirmDialogType.destructive,
      title: 'Cerrar sorteo',
      message:
          'Un sorteo cerrado ya no admite registrar más ganadores. ¿Cerrar?',
      confirmText: 'Cerrar',
      icon: Icons.lock_outline,
    );
    if (ok != true) return;
    final error = await cubit.cerrarSorteo();
    if (error != null && context.mounted) _snack(context, error, error: true);
  }

  /// Tickets del ánfora: el nombre de cada participante impreso una vez
  /// POR TICKET validado (quien compró 20, sale 20 veces) — para
  /// recortar y meter al ánfora física.
  Future<void> _imprimirTickets(BuildContext context, Sorteo sorteo) async {
    final tickets = sorteo.participantes
        .where((p) =>
            p.estado == EstadoParticipanteSorteo.activo &&
            p.numeroTicket != null)
        .map((p) => DatosTicketAnfora(
            numero: p.numeroTicket!, nombre: p.nombre, dni: p.dni))
        .toList()
      ..sort((a, b) => a.numero.compareTo(b.numero));
    if (tickets.isEmpty) {
      _snack(context, 'Aún no hay tickets validados para imprimir',
          error: true);
      return;
    }
    final ctxState = context.read<EmpresaContextCubit>().state;
    final empresaNombre = ctxState is EmpresaContextLoaded
        ? ctxState.context.empresa.nombre
        : '';
    final bytes = await TicketsAnforaPdfGenerator.generate(
      sorteoTitulo: sorteo.titulo,
      empresaNombre: empresaNombre,
      tickets: tickets,
    );
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'tickets_anfora.pdf',
    );
  }

  Future<void> _finalizarSorteo(BuildContext context) async {
    final cubit = context.read<SorteoDetailCubit>();
    final ok = await ConfirmDialog.show(
      context: context,
      type: ConfirmDialogType.warning,
      title: 'Finalizar sorteo',
      message: 'Confirma que YA SE JUGARON los premios. El sorteo quedará '
          'FINALIZADO (cierre definitivo) y ya no se podrá seguir jugando. '
          '¿Finalizar?',
      confirmText: 'Finalizar',
      icon: Icons.sports_score,
    );
    if (ok != true) return;
    final error = await cubit.finalizarSorteo();
    if (!context.mounted) return;
    if (error != null) {
      _snack(context, error, error: true);
    } else {
      _snack(context, '🏁 Sorteo finalizado — ¡buen juego!');
    }
  }

  Future<void> _reabrirSorteo(BuildContext context) async {
    final cubit = context.read<SorteoDetailCubit>();
    final ok = await ConfirmDialog.show(
      context: context,
      type: ConfirmDialogType.info,
      title: 'Reabrir para regularizar',
      message: 'Podrás registrar ganadores y validar participantes que '
          'quedaron pendientes. El bot de WhatsApp NO lo ofrecerá ni '
          'enviará mensajes por este sorteo. ¿Reabrir?',
      confirmText: 'Reabrir',
      icon: Icons.lock_open,
    );
    if (ok != true) return;
    final error = await cubit.reabrirSorteo();
    if (!context.mounted) return;
    if (error != null) {
      _snack(context, error, error: true);
    } else {
      _snack(context, 'Sorteo reabierto — el bot lo ignorará 🤖🚫');
    }
  }

  /// Flujo completo: elegir/registrar ganador por DNI (Factiliza crea la
  /// cuenta automáticamente) → datos del premio → registrar.
  Future<void> _registrarGanador(BuildContext context, Sorteo sorteo) async {
    final cubit = context.read<SorteoDetailCubit>();
    final ctxState = context.read<EmpresaContextCubit>().state;
    if (ctxState is! EmpresaContextLoaded) return;
    final empresaId = ctxState.context.empresa.id;

    final ganador = await ClienteUnificadoSelector.show(
      context: context,
      empresaId: empresaId,
      tipoPermitido: TipoClienteSeleccion.persona,
    );
    if (ganador == null || ganador.dni == null || !context.mounted) return;

    // Best-effort: si el DNI ya ganó antes con envío por agencia, prellenar
    // sus datos de entrega (casi nunca cambian entre sorteos).
    final entregaPrevia = await cubit.getEntregaPrevia(ganador.dni!);
    if (!context.mounted) return;

    final datos = await showRegistrarPremioSheet(
      context: context,
      empresaId: empresaId,
      sedeId: sorteo.sedeId,
      ganadorNombre: ganador.nombreCompleto ?? '',
      precioParticipacionDefault: sorteo.precioParticipacion,
      descripcionDefault: sorteo.descripcion,
      entregaPrevia: entregaPrevia,
    );
    if (datos == null || !context.mounted) return;

    final error = await cubit.registrarPremio(
      ganadorDni: ganador.dni!,
      ganadorNombre: ganador.nombreCompleto ?? '',
      ganadorCelular: ganador.telefono,
      descripcion: datos.descripcion,
      productoId: datos.productoId,
      varianteId: datos.varianteId,
      cantidad: datos.cantidad,
      montoParticipacion: datos.montoParticipacion,
      esEfectivo: datos.esEfectivo,
      modalidad: datos.modalidad,
      agenciaNombre: datos.agenciaNombre,
      destinoDepartamento: datos.destinoDepartamento,
      destinoProvincia: datos.destinoProvincia,
      agenciaDireccion: datos.agenciaDireccion,
      observaciones: datos.observaciones,
    );
    if (!context.mounted) return;
    _snack(
      context,
      error ??
          'Premio registrado — se notificó a ${ganador.nombreCompleto} 🎉',
      error: error != null,
    );
  }
}

void _snack(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: const TextStyle(fontSize: 12)),
    backgroundColor: error ? Colors.orange.shade800 : Colors.green.shade700,
    behavior: SnackBarBehavior.floating,
  ));
}

/// Imagen promocional del sorteo (la del post de redes) con botón para
/// subirla/cambiarla. Sin imagen muestra un placeholder invitando.
class _ImagenPromocional extends StatelessWidget {
  final Sorteo sorteo;
  const _ImagenPromocional({required this.sorteo});

  @override
  Widget build(BuildContext context) {
    final imagen = sorteo.imagenes.isNotEmpty ? sorteo.imagenes.first : null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          if (imagen != null)
            Image.network(
              imagen.url,
              width: double.infinity,
              height: 150,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(),
            )
          else
            _placeholder(),
          Positioned(
            right: 8,
            bottom: 8,
            child: Material(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _subirImagen(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo_camera,
                          size: 14, color: Colors.white),
                      const SizedBox(width: 5),
                      Text(
                        imagen != null ? 'Cambiar' : 'Agregar imagen',
                        style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: double.infinity,
      height: 90,
      color: AppColors.blue1.withValues(alpha: 0.06),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined,
              size: 26, color: AppColors.blue1.withValues(alpha: 0.4)),
          const SizedBox(height: 4),
          Text('Imagen promocional del sorteo',
              style: TextStyle(
                  fontSize: 10.5,
                  color: AppColors.blue1.withValues(alpha: 0.6))),
        ],
      ),
    );
  }

  Future<void> _subirImagen(BuildContext context) async {
    final cubit = context.read<SorteoDetailCubit>();
    final source = await _elegirFuenteImagen(context);
    if (source == null || !context.mounted) return;
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null || !context.mounted) return;
    final error = await cubit.subirImagenSorteo(File(picked.path));
    if (!context.mounted) return;
    _snack(context, error ?? 'Imagen del sorteo actualizada',
        error: error != null);
  }
}

/// Selector cámara/galería compartido.
Future<ImageSource?> _elegirFuenteImagen(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            dense: true,
            leading: Icon(Icons.photo_camera, color: AppColors.blue1),
            title: const Text('Tomar foto', style: TextStyle(fontSize: 12.5)),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            dense: true,
            leading: Icon(Icons.photo_library, color: AppColors.blue1),
            title: const Text('Elegir de la galería',
                style: TextStyle(fontSize: 12.5)),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          const SizedBox(height: 6),
        ],
      ),
    ),
  );
}

/// Participantes captados por el BOT de WhatsApp: la empresa valida el
/// pago por fuera y ACTIVA aquí (asigna ticket y el bot confirma por
/// WhatsApp al participante). Colapsable para no tapar los ganadores.
class _ParticipantesSection extends StatefulWidget {
  final Sorteo sorteo;
  const _ParticipantesSection({required this.sorteo});

  List<SorteoParticipante> get participantes => sorteo.participantes;

  @override
  State<_ParticipantesSection> createState() => _ParticipantesSectionState();
}

class _ParticipantesSectionState extends State<_ParticipantesSection> {
  bool _expandido = true;

  /// "12/07 22:53" en hora local del device.
  String _fechaHoraRegistro(DateTime d) {
    final l = d.toLocal();
    String p2(int v) => v.toString().padLeft(2, '0');
    return '${p2(l.day)}/${p2(l.month)} ${p2(l.hour)}:${p2(l.minute)}';
  }

  /// Ya tiene su card de premio abajo (auto-premio de la dinámica).
  /// Matchea por PARTICIPACIÓN (un DNI puede jugar varias veces) — el
  /// fallback por DNI cubre premios antiguos sin participanteId.
  bool _tienePremio(SorteoParticipante p) => widget.sorteo.premios.any(
      (pr) =>
          pr.estado != EstadoPremioSorteo.anulado &&
          (pr.participanteId == p.id ||
              (pr.participanteId == null && pr.ganadorDni == p.dni)));

  @override
  Widget build(BuildContext context) {
    final esDinamica = widget.sorteo.tipo == TipoSorteo.dinamica;
    // En dinámicas el jugador validado YA tiene su card de premio abajo:
    // listarlo aquí también duplicaría cada persona (spam). Solo quedan
    // los pendientes de validar (y activos sin premio, respaldo del 🏆).
    final visibles = esDinamica
        ? widget.participantes
            .where((p) =>
                p.estado != EstadoParticipanteSorteo.rechazado &&
                !_tienePremio(p))
            .toList()
        : widget.participantes;
    if (visibles.isEmpty) return const SizedBox.shrink();

    final activos = widget.participantes
        .where((p) => p.estado == EstadoParticipanteSorteo.activo)
        .length;
    final pendientes = widget.participantes
        .where((p) => p.estado == EstadoParticipanteSorteo.pendientePago)
        .length;
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _expandido = !_expandido),
              child: Row(
                children: [
                  Icon(Icons.confirmation_number_outlined,
                      size: 16, color: AppColors.blue1),
                  const SizedBox(width: 6),
                  Text(
                    esDinamica ? 'Jugadores por validar' : 'Participantes',
                    style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.blue1),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    esDinamica
                        // Los validados ya están abajo como premios.
                        ? '$pendientes pendiente${pendientes == 1 ? '' : 's'}'
                        : '$activos activo${activos == 1 ? '' : 's'}'
                            '${pendientes > 0 ? ' · $pendientes por validar' : ''}',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight:
                            pendientes > 0 ? FontWeight.w700 : FontWeight.w400,
                        color: pendientes > 0
                            ? Colors.orange.shade800
                            : Colors.grey.shade600),
                  ),
                  const Spacer(),
                  Icon(
                    _expandido ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
            if (_expandido) ...[
              const SizedBox(height: 4),
              // SORTEO clásico: una compra de N tickets = UNA fila con
              // su rango. Dinámicas siguen fila por jugada.
              if (esDinamica)
                for (final p in visibles) _fila(context, p)
              else
                for (final g in _grupos(visibles)) _filaGrupo(context, g),
            ],
          ],
        ),
      ),
    );
  }

  /// Agrupa por COMPRA (compraId) — filas sin compra van solas.
  List<List<SorteoParticipante>> _grupos(List<SorteoParticipante> lista) {
    final mapa = <String, List<SorteoParticipante>>{};
    for (final p in lista) {
      mapa.putIfAbsent(p.compraId ?? p.id, () => []).add(p);
    }
    return mapa.values.toList();
  }

  /// COMPRA de tickets: una fila por compra con el rango ("#1–#20"),
  /// la cantidad y el monto total. Validar opera sobre TODA la compra
  /// (el backend activa todas las filas con tickets consecutivos).
  /// Sugerencia de pago Yape/Plin (api-yape, match por nombre) para un
  /// participante PENDIENTE — null si no hay o no aplica.
  PagoYapeSugerido? _sugerenciaYape(BuildContext context, SorteoParticipante p) {
    if (p.estado != EstadoParticipanteSorteo.pendientePago) return null;
    final st = context.read<SorteoDetailCubit>().state;
    if (st is! SorteoDetailLoaded) return null;
    return st.pagosYape[p.compraId ?? p.id];
  }

  /// "💸 Yape recibido: SEBASTIANA C. · S/ 20.00 ✓ · hace 2 min" —
  /// verde si el monto calza con lo esperado (tickets × precio), ámbar
  /// si no. La empresa decide; esto solo evita ir a mirar el celular.
  Widget _chipYape(PagoYapeSugerido sug) {
    final color =
        sug.montoCoincide ? Colors.green.shade700 : Colors.orange.shade800;
    final proveedor =
        (sug.provider ?? '').toLowerCase() == 'plin' ? 'Plin' : 'Yape';
    final extra = sug.montoCoincide
        ? ' ✓'
        : sug.montoEsperado != null
            ? ' (esperado S/ ${sug.montoEsperado!.toStringAsFixed(2)})'
            : '';
    final hace = _haceTexto(sug.receivedAt);
    return Row(
      children: [
        Icon(Icons.price_check, size: 11, color: color),
        const SizedBox(width: 3),
        Expanded(
          child: Text(
            '$proveedor recibido: ${sug.senderName ?? '—'} · '
            'S/ ${sug.amount.toStringAsFixed(2)}$extra'
            '${hace != null ? ' · $hace' : ''}',
            style: TextStyle(
                fontSize: 9, fontWeight: FontWeight.w700, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String? _haceTexto(DateTime? t) {
    if (t == null) return null;
    final d = DateTime.now().difference(t.toLocal());
    if (d.inMinutes < 1) return 'ahora';
    if (d.inMinutes < 60) return 'hace ${d.inMinutes} min';
    if (d.inHours < 24) return 'hace ${d.inHours} h';
    return 'hace ${d.inDays} d';
  }

  Widget _filaGrupo(BuildContext context, List<SorteoParticipante> grupo) {
    if (grupo.length == 1) return _fila(context, grupo.first);
    final p = grupo.first;
    final esPendiente = p.estado == EstadoParticipanteSorteo.pendientePago;
    final esActivo = p.estado == EstadoParticipanteSorteo.activo;
    final nums = grupo
        .map((x) => x.numeroTicket)
        .whereType<int>()
        .toList()
      ..sort();
    final rango = nums.isEmpty
        ? '×${grupo.length}'
        : nums.length == 1
            ? '#${nums.first}'
            : '#${nums.first}–${nums.last}';
    final precio = widget.sorteo.precioParticipacion;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              rango,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color:
                    esActivo ? Colors.green.shade700 : Colors.grey.shade400,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.nombre,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: p.estado == EstadoParticipanteSorteo.rechazado
                        ? Colors.grey.shade400
                        : Colors.black87,
                    decoration:
                        p.estado == EstadoParticipanteSorteo.rechazado
                            ? TextDecoration.lineThrough
                            : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'DNI ${p.dni} · ${p.celular}',
                  style:
                      TextStyle(fontSize: 9.5, color: Colors.grey.shade600),
                ),
                Text(
                  '${widget.sorteo.tipo == TipoSorteo.bingo ? '🎱' : '🎟️'} '
                  '${grupo.length} ${widget.sorteo.tipo == TipoSorteo.bingo ? 'cartillas' : 'tickets'}'
                  '${precio != null ? ' · S/ ${(grupo.length * precio).toStringAsFixed(2)}' : ''}',
                  style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blue1),
                ),
                if (p.pagadorTexto != null)
                  Text(
                    '💳 Yapea: ${p.pagadorTexto}',
                    style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.teal.shade700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (p.recibeNombre != null && p.recibeNombre!.isNotEmpty)
                  Text(
                    '🎁 Recibe: ${p.recibeNombre}'
                    '${p.recibeDni != null ? ' · DNI ${p.recibeDni}' : ''}',
                    style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.purple.shade700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (p.envioTexto != null)
                  Text(
                    '🚚 ${p.envioTexto}',
                    style: TextStyle(
                        fontSize: 9.5,
                        color: AppColors.blue1,
                        fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                // El CLIENTE confirmó su dirección con el bot (vs. la
                // copia silenciosa de una jugada anterior).
                if (p.envioTexto != null && p.direccionConfirmada)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified,
                          size: 10, color: Colors.green.shade700),
                      const SizedBox(width: 3),
                      Text(
                        'Dirección confirmada',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700),
                      ),
                    ],
                  ),
                // 💸 Posible pago detectado por api-yape (match nombre).
                if (_sugerenciaYape(context, p) != null)
                  _chipYape(_sugerenciaYape(context, p)!),
              ],
            ),
          ),
          if (esPendiente) ...[
            IconButton(
              tooltip:
                  'Validar pago (activa los ${grupo.length} tickets y confirma por WhatsApp)',
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.check_circle_outline,
                  size: 19, color: Colors.green.shade700),
              onPressed: () =>
                  _cambiarEstado(context, p, EstadoParticipanteSorteo.activo),
            ),
            IconButton(
              tooltip: 'Rechazar la compra completa',
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.cancel_outlined,
                  size: 19, color: Colors.red.shade400),
              onPressed: () => _cambiarEstado(
                  context, p, EstadoParticipanteSorteo.rechazado),
            ),
          ] else
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (esActivo ? Colors.green : Colors.red)
                    .withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                p.estado.label.toUpperCase(),
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: esActivo
                      ? Colors.green.shade700
                      : Colors.red.shade400,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _fila(BuildContext context, SorteoParticipante p) {
    final esPendiente = p.estado == EstadoParticipanteSorteo.pendientePago;
    final esActivo = p.estado == EstadoParticipanteSorteo.activo;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          // Ticket asignado (solo activos).
          SizedBox(
            width: 34,
            child: Text(
              esActivo && p.numeroTicket != null ? '#${p.numeroTicket}' : '—',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: esActivo ? Colors.green.shade700 : Colors.grey.shade400,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.nombre,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: p.estado == EstadoParticipanteSorteo.rechazado
                        ? Colors.grey.shade400
                        : Colors.black87,
                    decoration: p.estado == EstadoParticipanteSorteo.rechazado
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'DNI ${p.dni} · ${p.celular}',
                  style:
                      TextStyle(fontSize: 9.5, color: Colors.grey.shade600),
                ),
                // Fecha/hora del registro: distingue la 1ª de la 2ª
                // participación del mismo DNI.
                Row(
                  children: [
                    Icon(Icons.schedule,
                        size: 9, color: Colors.grey.shade500),
                    const SizedBox(width: 3),
                    Text(
                      _fechaHoraRegistro(p.creadoEn),
                      style: TextStyle(
                          fontSize: 9, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                // El YAPE lo hace un tercero: clave para cuadrar el pago.
                if (p.pagadorTexto != null)
                  Row(
                    children: [
                      Icon(Icons.payments_outlined,
                          size: 10, color: Colors.teal.shade700),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          'Yapea: ${p.pagadorTexto}',
                          style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.teal.shade700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                // REGALO: el premio lo recibirá otra persona.
                if (p.recibeNombre != null && p.recibeNombre!.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.card_giftcard,
                          size: 10, color: Colors.purple.shade700),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          'Recibe: ${p.recibeNombre}'
                          '${p.recibeDni != null ? ' · DNI ${p.recibeDni}' : ''}',
                          style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.purple.shade700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                // Datos de envío que dejó en el bot (si gana, la entrega
                // ya está lista).
                if (p.envioTexto != null)
                  Row(
                    children: [
                      Icon(Icons.local_shipping_outlined,
                          size: 10, color: AppColors.blue1),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          p.envioTexto!,
                          style: TextStyle(
                              fontSize: 9.5,
                              color: AppColors.blue1,
                              fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                // El CLIENTE confirmó su dirección con el bot (vs. la
                // copia silenciosa de una jugada anterior).
                if (p.envioTexto != null && p.direccionConfirmada)
                  Row(
                    children: [
                      Icon(Icons.verified,
                          size: 10, color: Colors.green.shade700),
                      const SizedBox(width: 3),
                      Text(
                        'Dirección confirmada',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700),
                      ),
                    ],
                  ),
                // 💸 Posible pago detectado por api-yape (match nombre).
                if (_sugerenciaYape(context, p) != null)
                  _chipYape(_sugerenciaYape(context, p)!),
              ],
            ),
          ),
          if (esPendiente) ...[
            IconButton(
              tooltip: 'Validar pago (activa y confirma por WhatsApp)',
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.check_circle_outline,
                  size: 19, color: Colors.green.shade700),
              onPressed: () => _cambiarEstado(
                  context, p, EstadoParticipanteSorteo.activo),
            ),
            IconButton(
              tooltip: 'Rechazar',
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.cancel_outlined,
                  size: 19, color: Colors.red.shade400),
              onPressed: () => _cambiarEstado(
                  context, p, EstadoParticipanteSorteo.rechazado),
            ),
          ] else ...[
            // Registrar su premio manualmente — respaldo: en dinámicas
            // el premio se crea SOLO al validar el pago, así que este
            // trofeo solo aparece si ESTA participación no tiene premio.
            if (esActivo && !_tienePremio(p))
              IconButton(
                tooltip: 'Ganó — registrar su premio',
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.emoji_events,
                    size: 19, color: Colors.amber.shade800),
                onPressed: () => _registrarPremio(context, p),
              ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (esActivo ? Colors.green : Colors.red)
                    .withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                p.estado.label.toUpperCase(),
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: esActivo
                      ? Colors.green.shade700
                      : Colors.red.shade400,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// El participante jugó y ganó (dinámica) o salió sorteado: registrar
  /// su premio con lo que dejó en el bot — nombre, DNI, celular y datos
  /// de agencia prellenados. Si su DNI no tiene cuenta, el backend la
  /// crea solo (RENIEC + celular del bot).
  Future<void> _registrarPremio(
      BuildContext context, SorteoParticipante p) async {
    final cubit = context.read<SorteoDetailCubit>();
    final ctxState = context.read<EmpresaContextCubit>().state;
    if (ctxState is! EmpresaContextLoaded) return;
    final sorteo = widget.sorteo;

    final datos = await showRegistrarPremioSheet(
      context: context,
      empresaId: ctxState.context.empresa.id,
      sedeId: sorteo.sedeId,
      ganadorNombre: p.nombre,
      precioParticipacionDefault: sorteo.precioParticipacion,
      descripcionDefault: sorteo.tipo == TipoSorteo.dinamica
          ? null // en la dinámica el premio es LO QUE SACÓ — se escribe
          : sorteo.descripcion,
      entregaPrevia: (p.agenciaNombre != null && p.agenciaNombre!.isNotEmpty)
          ? EntregaPreviaGanador(
              agenciaNombre: p.agenciaNombre,
              destinoDepartamento: p.destinoDepartamento,
              destinoProvincia: p.destinoProvincia,
              agenciaDireccion: p.agenciaDireccion,
            )
          : null,
    );
    if (datos == null || !context.mounted) return;

    final error = await cubit.registrarPremio(
      participanteId: p.id,
      ganadorDni: p.dni,
      ganadorNombre: p.nombre,
      ganadorCelular:
          p.celular.length > 9 ? p.celular.substring(p.celular.length - 9) : p.celular,
      descripcion: datos.descripcion,
      productoId: datos.productoId,
      varianteId: datos.varianteId,
      cantidad: datos.cantidad,
      montoParticipacion: datos.montoParticipacion,
      esEfectivo: datos.esEfectivo,
      modalidad: datos.modalidad,
      agenciaNombre: datos.agenciaNombre,
      destinoDepartamento: datos.destinoDepartamento,
      destinoProvincia: datos.destinoProvincia,
      agenciaDireccion: datos.agenciaDireccion,
      observaciones: datos.observaciones,
    );
    if (!context.mounted) return;
    _snack(
      context,
      error ?? '🏆 Premio registrado para ${p.nombre.split(' ').first} 🎉',
      error: error != null,
    );
  }

  Future<void> _cambiarEstado(
    BuildContext context,
    SorteoParticipante p,
    EstadoParticipanteSorteo estado,
  ) async {
    final cubit = context.read<SorteoDetailCubit>();
    final activar = estado == EstadoParticipanteSorteo.activo;
    final ok = await ConfirmDialog.show(
      context: context,
      type: activar ? ConfirmDialogType.info : ConfirmDialogType.destructive,
      title: activar ? 'Validar pago' : 'Rechazar participante',
      message: activar
          ? '¿Confirmar el pago de ${p.nombre}? Se le asignará su ticket '
              'y el bot le confirmará por WhatsApp.'
          : '¿Rechazar a ${p.nombre}?',
      confirmText: activar ? 'Validar' : 'Rechazar',
      icon: activar ? Icons.check_circle_outline : Icons.cancel_outlined,
    );
    if (ok != true || !context.mounted) return;
    final error = await cubit.cambiarEstadoParticipante(
      participanteId: p.id,
      estado: estado,
    );
    if (!context.mounted) return;
    _snack(
      context,
      error ??
          (activar
              ? '🎟️ ${p.nombre.split(' ').first} activado — el bot le confirmó su ticket'
              : 'Participante rechazado'),
      error: error != null,
    );
  }
}

/// Resultado del preview: [archivo] != null → subir esa imagen;
/// [volverAElegir] → reabrir el picker (descartó todas / quiere otras).
class _ResultadoPreview {
  final File? archivo;
  final bool volverAElegir;
  const _ResultadoPreview.subir(File this.archivo) : volverAElegir = false;
  const _ResultadoPreview.volver()
      : archivo = null,
        volverAElegir = true;
}

/// Vista previa a pantalla completa ANTES de subir: los tickets de
/// agencia se parecen entre sí (solo cambian los datos), así que se
/// seleccionan VARIAS candidatas y aquí se comparan con zoom deslizando
/// entre ellas y descartando hasta quedarse con la correcta.
/// Devuelve null si se canceló todo.
Future<_ResultadoPreview?> _previewImagenesAntesDeSubir(
    BuildContext context, List<File> imagenes, String titulo) {
  return Navigator.of(context).push<_ResultadoPreview>(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => _PreviewImagenesPage(imagenes: imagenes, titulo: titulo),
  ));
}

class _PreviewImagenesPage extends StatefulWidget {
  final List<File> imagenes;
  final String titulo;
  const _PreviewImagenesPage(
      {required this.imagenes, required this.titulo});

  @override
  State<_PreviewImagenesPage> createState() => _PreviewImagenesPageState();
}

class _PreviewImagenesPageState extends State<_PreviewImagenesPage> {
  late final List<File> _imagenes = List.of(widget.imagenes);
  final _pageCtrl = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _descartar() {
    // Descartó la última: de vuelta al picker a elegir otras.
    if (_imagenes.length == 1) {
      Navigator.of(context).pop(const _ResultadoPreview.volver());
      return;
    }
    setState(() {
      _imagenes.removeAt(_index);
      if (_index >= _imagenes.length) _index = _imagenes.length - 1;
    });
    if (_pageCtrl.hasClients) _pageCtrl.jumpToPage(_index);
  }

  @override
  Widget build(BuildContext context) {
    final varias = _imagenes.length > 1;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          varias
              ? '${widget.titulo}  ·  ${_index + 1}/${_imagenes.length}'
              : widget.titulo,
          style: const TextStyle(fontSize: 13.5),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            // Al hacer zoom el InteractiveViewer captura el arrastre;
            // con la imagen sin zoom el swipe pasa al PageView.
            child: PageView.builder(
              controller: _pageCtrl,
              onPageChanged: (i) => setState(() => _index = i),
              itemCount: _imagenes.length,
              itemBuilder: (_, i) => InteractiveViewer(
                maxScale: 6,
                child: Center(child: Image.file(_imagenes[i])),
              ),
            ),
          ),
          if (varias)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '◂ desliza para comparar ▸',
                style:
                    TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: varias ? 'Descartar' : 'Elegir otra',
                      isOutlined: true,
                      borderColor: Colors.red.shade300,
                      textColor: Colors.red.shade300,
                      enableShadows: false,
                      icon: Icon(
                          varias
                              ? Icons.delete_outline
                              : Icons.photo_library_outlined,
                          size: 15,
                          color: Colors.red.shade300),
                      iconColor: Colors.red.shade300,
                      onPressed: _descartar,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      text: 'Subir esta',
                      backgroundColor: Colors.green.shade700,
                      textColor: Colors.white,
                      icon: const Icon(Icons.cloud_upload_outlined,
                          size: 15, color: Colors.white),
                      iconColor: Colors.white,
                      onPressed: () => Navigator.of(context).pop(
                          _ResultadoPreview.subir(_imagenes[_index])),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremioCard extends StatelessWidget {
  final SorteoPremio premio;
  final VoidCallback? onImprimirRotulo;

  /// El CLIENTE confirmó su dirección con el bot (sello del participante
  /// vinculado) — chip verde bajo la línea del envío.
  final bool direccionConfirmada;

  const _PremioCard({
    required this.premio,
    this.onImprimirRotulo,
    this.direccionConfirmada = false,
  });

  Color get _colorEstado => switch (premio.estado) {
        EstadoPremioSorteo.registrado => Colors.blueGrey,
        EstadoPremioSorteo.preparando => Colors.orange.shade800,
        EstadoPremioSorteo.enviado => AppColors.blue1,
        EstadoPremioSorteo.entregado => Colors.green.shade700,
        EstadoPremioSorteo.anulado => Colors.red.shade700,
      };

  EstadoPremioSorteo? get _siguienteEstado => switch (premio.estado) {
        EstadoPremioSorteo.registrado => EstadoPremioSorteo.preparando,
        EstadoPremioSorteo.preparando => EstadoPremioSorteo.enviado,
        EstadoPremioSorteo.enviado => EstadoPremioSorteo.entregado,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final esFinal = premio.estado == EstadoPremioSorteo.entregado ||
        premio.estado == EstadoPremioSorteo.anulado;
    // GradientContainer de la casa (degradado default + borde azul).
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    premio.ganadorNombre,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.blue1),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _colorEstado.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        premio.estado.label.toUpperCase(),
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: _colorEstado),
                      ),
                    ),
                    // Rótulo ya impreso: el paquete tiene su ticket.
                    if (premio.rotuloImpreso) ...[
                      const SizedBox(height: 3),
                      _miniChip(Icons.print, 'IMPRESO', Colors.teal.shade700),
                    ],
                    // Ticket ya enviado por WhatsApp automático al ganador.
                    if (premio.whatsappEnviado) ...[
                      const SizedBox(height: 3),
                      _miniChip(
                          Icons.chat, 'WSP ENVIADO', Colors.green.shade700),
                    ],
                  ],
                ),
              ],
            ),
            Text(
              [
                if (premio.ganadorDni != null) 'DNI ${premio.ganadorDni}',
                if (premio.ganadorCelular != null) premio.ganadorCelular!,
              ].join(' · '),
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
            // Fecha/hora del registro del premio — distingue las cards
            // cuando el mismo DNI jugó/ganó varias veces.
            Row(
              children: [
                Icon(Icons.schedule, size: 9, color: Colors.grey.shade500),
                const SizedBox(width: 3),
                Text(
                  _fechaHoraRegistro(premio.creadoEn),
                  style:
                      TextStyle(fontSize: 9, color: Colors.grey.shade500),
                ),
              ],
            ),
            // REGALO: lo recibe otra persona — el rótulo y la agencia
            // usan estos datos como destinatario.
            if (premio.esRegalo)
              Row(
                children: [
                  Icon(Icons.card_giftcard,
                      size: 11, color: Colors.purple.shade700),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      'Recibe: ${premio.recibeNombre}'
                      '${premio.recibeDni != null ? ' · DNI ${premio.recibeDni}' : ''}',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.purple.shade700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.card_giftcard,
                    size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    '${premio.descripcion}${premio.cantidad > 1 ? '  x${premio.cantidad}' : ''}',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.blue1),
                  ),
                ),
                if (premio.descuentaStock)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('STOCK',
                        style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.teal.shade700)),
                  ),
              ],
            ),
            if (premio.montoParticipacion != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.payments_outlined,
                      size: 14, color: Colors.green.shade700),
                  const SizedBox(width: 5),
                  Text(
                    'Participación: S/ ${premio.montoParticipacion!.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            // EFECTIVO 💸: se yapea al número que el ganador confirmó con
            // el bot (fallback su celular, marcado "por confirmar").
            if (premio.esEfectivo)
              Row(
                children: [
                  Icon(Icons.currency_exchange,
                      size: 14, color: Colors.teal.shade700),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      premio.abonoNumero != null
                          ? '💸 Yapear a: ${premio.abonoNumero}'
                          : '💸 Yapear a: ${premio.ganadorCelular ?? '—'} (por confirmar con el bot)',
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.teal.shade700),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Icon(
                    premio.modalidad == ModalidadEntregaPremio.envioAgencia
                        ? Icons.local_shipping_outlined
                        : Icons.storefront_outlined,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      premio.modalidad == ModalidadEntregaPremio.envioAgencia
                          ? [
                              premio.agenciaNombre ?? 'Agencia',
                              if (premio.destinoTexto != null)
                                '→ ${premio.destinoTexto}',
                              if (premio.agenciaDireccion != null &&
                                  premio.agenciaDireccion!.isNotEmpty)
                                '· ${premio.agenciaDireccion}',
                            ].join(' ')
                          : 'Retiro en tienda',
                      style: TextStyle(
                          fontSize: 10.5, color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            if (!premio.esEfectivo &&
                premio.modalidad == ModalidadEntregaPremio.envioAgencia &&
                direccionConfirmada)
              Padding(
                padding: const EdgeInsets.only(left: 19, top: 1),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified,
                        size: 11, color: Colors.green.shade700),
                    const SizedBox(width: 3),
                    Text(
                      'Dirección confirmada por el cliente',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700),
                    ),
                  ],
                ),
              ),
            if (premio.envioNumeroOrden != null ||
                premio.envioCodigo != null ||
                premio.envioClave != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.confirmation_number_outlined,
                      size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      [
                        if (premio.envioNumeroOrden != null)
                          'Orden: ${premio.envioNumeroOrden}',
                        if (premio.envioCodigo != null)
                          'Cód: ${premio.envioCodigo}',
                        if (premio.envioClave != null)
                          'Clave: ${premio.envioClave}',
                      ].join(' · '),
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ],
            if (premio.fotos.isNotEmpty || premio.tickets.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 62,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Fotos del premio primero, luego tickets de envío.
                    for (final f in premio.fotos)
                      _miniFoto(f.urlThumbnail ?? f.url,
                          etiqueta: 'PREMIO', color: Colors.purple),
                    for (final t in premio.tickets)
                      _miniFoto(t.urlThumbnail ?? t.url,
                          etiqueta: 'TICKET', color: AppColors.blue1),
                  ],
                ),
              ),
            ],
            if (!esFinal) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  // Anular (repone stock si descontó)
                  IconButton(
                    tooltip: 'Anular premio',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.delete_outline,
                        size: 18, color: Colors.red.shade400),
                    onPressed: () => _anular(context),
                  ),
                  // Corregir la entrega (modalidad y/o agencia) — solo
                  // antes del despacho, mismo guard que el backend.
                  if (premio.estado == EstadoPremioSorteo.registrado ||
                      premio.estado == EstadoPremioSorteo.preparando)
                    IconButton(
                      tooltip: 'Editar entrega (modalidad/agencia)',
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.local_shipping_outlined,
                          size: 19, color: AppColors.blue1),
                      onPressed: () => _editarEntrega(context),
                    ),
                  // Editar datos del despacho (solo premios ya enviados
                  // por agencia).
                  if (premio.estado == EstadoPremioSorteo.enviado &&
                      premio.modalidad ==
                          ModalidadEntregaPremio.envioAgencia)
                    IconButton(
                      tooltip: 'Datos del envío',
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.edit_note,
                          size: 20, color: AppColors.blue1),
                      onPressed: () => _editarDatosEnvio(context),
                    ),
                  // Avisar al ganador por WhatsApp con el ticket de envío
                  // (2 pasos guiados: mensaje + imagen).
                  if (premio.ganadorCelular != null &&
                      premio.ganadorCelular!.isNotEmpty &&
                      premio.tickets.isNotEmpty)
                    IconButton(
                      tooltip: 'Enviar ticket por WhatsApp',
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.chat,
                          size: 18, color: Colors.green.shade700),
                      onPressed: () => _enviarWhatsApp(context),
                    ),
                  // Rótulo de envío (media hoja A4, impresora normal) —
                  // desde PREPARANDO en adelante, solo envíos por agencia.
                  if (onImprimirRotulo != null &&
                      premio.modalidad ==
                          ModalidadEntregaPremio.envioAgencia &&
                      (premio.estado == EstadoPremioSorteo.preparando ||
                          premio.estado == EstadoPremioSorteo.enviado))
                    IconButton(
                      tooltip: 'Imprimir rótulo de envío',
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.print_outlined,
                          size: 19, color: AppColors.blue1),
                      onPressed: onImprimirRotulo,
                    ),
                  const Spacer(),
                  // Foto del premio o del ticket de envío — recién desde
                  // PREPARANDO (en REGISTRADO no hay paquete ni ticket).
                  if (premio.estado == EstadoPremioSorteo.preparando ||
                      premio.estado == EstadoPremioSorteo.enviado) ...[
                    SizedBox(
                      width: 80,
                      child: CustomButton(
                        borderRadius: 4,
                        height: 28,
                        text: 'Foto',
                        textColor: AppColors.blue1,
                        icon: Icon(Icons.photo_camera_outlined, size: 15),
                        onPressed: () => _subirFoto(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (_siguienteEstado != null)
                    CustomButton(

                      
                      text: 'Marcar ${_siguienteEstado!.label.toLowerCase()}',
                      height: 28,
                      borderRadius: 4,
                      backgroundColor: AppColors.blue1,
                      textColor: Colors.white,
                      onPressed: () =>
                          _avanzarEstado(context, _siguienteEstado!),
                    )
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// "12/07 22:53" en hora local del device.
  String _fechaHoraRegistro(DateTime d) {
    final l = d.toLocal();
    String p2(int v) => v.toString().padLeft(2, '0');
    return '${p2(l.day)}/${p2(l.month)} ${p2(l.hour)}:${p2(l.minute)}';
  }

  /// Chip compacto de estado extra en la esquina de la card (IMPRESO,
  /// WSP ENVIADO): mismo formato para todos.
  Widget _miniChip(IconData icono, String texto, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 9, color: color),
          const SizedBox(width: 3),
          Text(
            texto,
            style: TextStyle(
                fontSize: 8, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  Future<void> _avanzarEstado(
      BuildContext context, EstadoPremioSorteo nuevo) async {
    final cubit = context.read<SorteoDetailCubit>();
    String? orden;
    String? codigo;
    String? clave;
    // Al despachar por agencia se registran los datos del envío (el
    // ganador ve orden/código y sobre todo la CLAVE de recojo).
    if (nuevo == EstadoPremioSorteo.enviado &&
        premio.modalidad == ModalidadEntregaPremio.envioAgencia) {
      // La clave es obligatoria al despachar: viaja en el WhatsApp del
      // ticket y la agencia la exige para entregar.
      final datos =
          await _dialogDatosEnvio(context, claveObligatoria: true);
      if (datos == null || !context.mounted) return;
      (orden, codigo, clave) = datos;
    }
    final error = await cubit.cambiarEstadoPremio(
      premioId: premio.id,
      estado: nuevo,
      envioNumeroOrden: orden,
      envioCodigo: codigo,
      envioClave: clave,
    );
    if (!context.mounted) return;
    _snack(
      context,
      error ??
          (nuevo == EstadoPremioSorteo.enviado
              ? 'Marcado como enviado — se notificó al ganador 📦'
              : 'Premio ${nuevo.label.toLowerCase()}'),
      error: error != null,
    );

    // Al pasar a PREPARANDO (envío por agencia): ofrecer imprimir el
    // rótulo de una vez — es el momento natural de alistar el paquete.
    if (error == null &&
        nuevo == EstadoPremioSorteo.preparando &&
        premio.modalidad == ModalidadEntregaPremio.envioAgencia &&
        onImprimirRotulo != null) {
      final imprimir = await ConfirmDialog.show(
        context: context,
        type: ConfirmDialogType.info,
        title: 'Imprimir rótulo',
        message: '¿Imprimir el rótulo de envío de ${premio.ganadorNombre} '
            'ahora?',
        confirmText: 'Imprimir',
        icon: Icons.print_outlined,
      );
      if (imprimir == true) onImprimirRotulo!();
    }
  }

  /// Corrige la modalidad de entrega y/o la agencia de un premio aún no
  /// despachado — p.ej. quedó en retiro en tienda por error.
  Future<void> _editarEntrega(BuildContext context) async {
    final cubit = context.read<SorteoDetailCubit>();
    final editada =
        await showEditarEntregaSheet(context: context, premio: premio);
    if (editada == null || !context.mounted) return;
    final error = await cubit.editarEntregaPremio(
      premioId: premio.id,
      modalidad: editada.modalidad,
      agenciaNombre: editada.agenciaNombre,
      destinoDepartamento: editada.destinoDepartamento,
      destinoProvincia: editada.destinoProvincia,
      agenciaDireccion: editada.agenciaDireccion,
    );
    if (!context.mounted) return;
    _snack(context, error ?? 'Entrega actualizada', error: error != null);
  }

  /// Editar los datos del envío de un premio ya ENVIADO (re-envía el
  /// mismo estado — el backend no duplica la notificación).
  Future<void> _editarDatosEnvio(BuildContext context) async {
    final cubit = context.read<SorteoDetailCubit>();
    final datos = await _dialogDatosEnvio(context);
    if (datos == null || !context.mounted) return;
    final (orden, codigo, clave) = datos;
    final error = await cubit.cambiarEstadoPremio(
      premioId: premio.id,
      estado: premio.estado,
      envioNumeroOrden: orden,
      envioCodigo: codigo,
      envioClave: clave,
    );
    if (!context.mounted) return;
    _snack(context, error ?? 'Datos de envío actualizados',
        error: error != null);
  }

  Future<(String, String, String)?> _dialogDatosEnvio(
    BuildContext context, {
    bool claveObligatoria = false,
    String? subtitulo,
  }) async {
    final ordenCtrl =
        TextEditingController(text: premio.envioNumeroOrden ?? '');
    final codigoCtrl = TextEditingController(text: premio.envioCodigo ?? '');
    final claveCtrl = TextEditingController(text: premio.envioClave ?? '');
    String? errorClave;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => StyledDialog(
          accentColor: AppColors.blue1,
          icon: Icons.local_shipping_outlined,
          titulo: 'Datos del envío',
          content: [
            Text(
              subtitulo ??
                  'Los datos que entrega la agencia — el ganador los verá '
                      'en Mis Premios${claveObligatoria ? '. La CLAVE es obligatoria: la agencia la pide para entregar' : ' (todos opcionales)'}.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 10),
            CustomText(
              controller: ordenCtrl,
              label: 'N° de orden',
              hintText: 'ej. 0012345',
              borderColor: AppColors.blue1,
              textCase: TextCase.upper,
            ),
            const SizedBox(height: 8),
            CustomText(
              controller: codigoCtrl,
              label: 'Código',
              hintText: 'ej. SHA-88421',
              borderColor: AppColors.blue1,
              textCase: TextCase.upper,
            ),
            const SizedBox(height: 8),
            CustomText(
              controller: claveCtrl,
              label:
                  'Clave de recojo${claveObligatoria ? ' (obligatoria)' : ''}',
              hintText: 'la que pide la agencia para entregar',
              borderColor:
                  errorClave != null ? AppColors.red : AppColors.blue1,
              textCase: TextCase.upper,
            ),
            if (errorClave != null) ...[
              const SizedBox(height: 4),
              Text(errorClave!,
                  style:
                      const TextStyle(fontSize: 10.5, color: AppColors.red)),
            ],
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
                text: 'Guardar',
                backgroundColor: AppColors.blue1,
                textColor: Colors.white,
                onPressed: () {
                  if (claveObligatoria && claveCtrl.text.trim().isEmpty) {
                    setLocal(() => errorClave =
                        'Ingresa la clave de recojo — viaja en el WhatsApp al ganador');
                    return;
                  }
                  Navigator.of(ctx).pop(true);
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return null;
    return (
      ordenCtrl.text.trim(),
      codigoCtrl.text.trim(),
      claveCtrl.text.trim(),
    );
  }

  Future<void> _anular(BuildContext context) async {
    final cubit = context.read<SorteoDetailCubit>();
    final ok = await ConfirmDialog.show(
      context: context,
      type: ConfirmDialogType.destructive,
      title: 'Anular premio',
      message: premio.descuentaStock
          ? 'Se anulará el premio de ${premio.ganadorNombre} y se REPONDRÁ '
              'el stock descontado. ¿Continuar?'
          : '¿Anular el premio de ${premio.ganadorNombre}?',
      confirmText: 'Anular',
      icon: Icons.delete_outline,
    );
    if (ok != true || !context.mounted) return;
    final error = await cubit.cambiarEstadoPremio(
      premioId: premio.id,
      estado: EstadoPremioSorteo.anulado,
    );
    if (!context.mounted) return;
    _snack(context, error ?? 'Premio anulado', error: error != null);
  }

  Widget _miniFoto(String url, {required String etiqueta, required Color color}) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              url,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 48,
                height: 48,
                color: Colors.grey.shade200,
                child: const Icon(Icons.image, size: 18),
              ),
            ),
          ),
          const SizedBox(height: 1),
          Text(etiqueta,
              style: TextStyle(
                  fontSize: 7.5, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  /// Abre el flujo guiado de WhatsApp (mensaje + imagen del ticket).
  /// [ticketLocal] evita re-descargar cuando el ticket se acaba de subir.
  Future<void> _enviarWhatsApp(BuildContext context,
      {File? ticketLocal}) async {
    final ctxState = context.read<EmpresaContextCubit>().state;
    final empresaNombre = ctxState is EmpresaContextLoaded
        ? ctxState.context.empresa.nombre
        : '';
    await showEnviarWhatsAppPremioSheet(
      context: context,
      premio: premio,
      empresaNombre: empresaNombre,
      ticketLocal: ticketLocal,
    );
  }

  Future<void> _subirFoto(BuildContext context) async {
    final cubit = context.read<SorteoDetailCubit>();
    // 1) ¿Qué foto es? Premio ganado o ticket de envío de agencia.
    final esPremio = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('¿Qué foto vas a subir?',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.card_giftcard, color: Colors.purple),
              title: const Text('Foto del premio ganado',
                  style: TextStyle(fontSize: 12.5)),
              subtitle: Text('El ganador la ve en Mis Premios',
                  style:
                      TextStyle(fontSize: 10.5, color: Colors.grey.shade600)),
              onTap: () => Navigator.pop(ctx, true),
            ),
            ListTile(
              dense: true,
              leading: Icon(Icons.receipt_long, color: AppColors.blue1),
              title: const Text('Ticket de envío de la agencia',
                  style: TextStyle(fontSize: 12.5)),
              subtitle: Text('Constancia de que el premio ya fue despachado',
                  style:
                      TextStyle(fontSize: 10.5, color: Colors.grey.shade600)),
              onTap: () => Navigator.pop(ctx, false),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
    if (esPremio == null || !context.mounted) return;

    // Ticket de envío por agencia: exige premio ENVIADO con CLAVE antes
    // de subir la imagen — el WhatsApp automático del ticket lleva la
    // clave de recojo, y sin este gate podía salir sin ella.
    if (!esPremio &&
        premio.modalidad == ModalidadEntregaPremio.envioAgencia &&
        (premio.estado != EstadoPremioSorteo.enviado ||
            (premio.envioClave ?? '').trim().isEmpty)) {
      final datos = await _dialogDatosEnvio(
        context,
        claveObligatoria: true,
        subtitulo: 'Antes de subir el ticket registra los datos del envío: '
            'la CLAVE de recojo viaja en el WhatsApp al ganador y la '
            'agencia la pide para entregar. Se marcará como ENVIADO.',
      );
      if (datos == null || !context.mounted) return;
      final (orden, codigo, clave) = datos;
      final errorEnvio = await cubit.cambiarEstadoPremio(
        premioId: premio.id,
        estado: EstadoPremioSorteo.enviado,
        envioNumeroOrden: orden,
        envioCodigo: codigo,
        envioClave: clave,
      );
      if (!context.mounted) return;
      if (errorEnvio != null) {
        _snack(context, errorEnvio, error: true);
        return;
      }
    }

    final source = await _elegirFuenteImagen(context);
    if (source == null || !context.mounted) return;

    // Galería: selección MÚLTIPLE (los tickets se parecen entre sí) →
    // en el preview se comparan con zoom y se descarta hasta quedarse
    // con la correcta. Cámara: de a una foto, mismo preview.
    File? file;
    while (file == null) {
      final List<File> candidatas;
      if (source == ImageSource.camera) {
        final picked = await ImagePicker().pickImage(
          source: source,
          maxWidth: 1600,
          imageQuality: 85,
        );
        if (picked == null || !context.mounted) return;
        candidatas = [File(picked.path)];
      } else {
        final picked = await ImagePicker().pickMultiImage(
          maxWidth: 1600,
          imageQuality: 85,
        );
        if (picked.isEmpty || !context.mounted) return;
        candidatas = [for (final x in picked) File(x.path)];
      }
      final resultado = await _previewImagenesAntesDeSubir(
        context,
        candidatas,
        esPremio ? 'Foto del premio' : 'Ticket de envío',
      );
      if (resultado == null || !context.mounted) return; // canceló
      file = resultado.archivo; // null → volver a elegir
    }
    String? error;
    var whatsappEnviado = false;
    if (esPremio) {
      error = await cubit.subirFotoPremio(premio.id, file);
    } else {
      (error, whatsappEnviado) =
          await cubit.subirTicketEnvio(premio.id, file);
    }
    if (!context.mounted) return;
    _snack(
      context,
      error ??
          (esPremio
              ? 'Foto del premio subida — el ganador ya puede verla'
              : whatsappEnviado
                  ? 'Ticket subido y ENVIADO por WhatsApp al ganador ✅'
                  : 'Ticket de envío subido — el ganador ya puede verlo'),
      error: error != null,
    );

    // Ticket recién subido SIN envío automático (empresa sin WhatsApp
    // vinculado): ofrecer el flujo manual de 2 pasos como fallback.
    if (error == null &&
        !esPremio &&
        !whatsappEnviado &&
        premio.ganadorCelular != null &&
        premio.ganadorCelular!.isNotEmpty) {
      final enviar = await ConfirmDialog.show(
        context: context,
        type: ConfirmDialogType.info,
        title: 'Avisar al ganador',
        message: '¿Enviar el ticket por WhatsApp a ${premio.ganadorNombre} '
            '(${premio.ganadorCelular})?',
        confirmText: 'Enviar',
        icon: Icons.chat,
      );
      if (enviar == true && context.mounted) {
        await _enviarWhatsApp(context, ticketLocal: file);
      }
    }
  }
}

/// BINGO jugando: registrar las bolillas que van saliendo — el backend
/// marca TODAS las cartillas y devuelve los logros nuevos (¡LÍNEA! /
/// ¡BINGO!) al instante. El premio se adjudica con 🎲 JUGAR (número de
/// la cartilla ganadora + premio del catálogo).
class _BolillasSection extends StatefulWidget {
  final Sorteo sorteo;
  const _BolillasSection({required this.sorteo});

  @override
  State<_BolillasSection> createState() => _BolillasSectionState();
}

class _BolillasSectionState extends State<_BolillasSection> {
  final _ds = locator<SorteoRemoteDataSource>();
  bool _ocupado = false;

  Future<void> _cantar() async {
    final numCtrl = TextEditingController();
    final ok = await StyledDialog.show<bool>(
      context,
      accentColor: Colors.purple.shade700,
      icon: Icons.casino_outlined,
      titulo: 'Cantar bolilla',
      content: [
        CustomText(
          controller: numCtrl,
          label: 'Número de la bolilla (1-75)',
          hintText: 'ej. 42',
          borderColor: AppColors.blue1,
          keyboardType: TextInputType.number,
        ),
      ],
      actions: [
        Builder(
          builder: (ctx) => TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(fontSize: 12)),
          ),
        ),
        Builder(
          builder: (ctx) => CustomButton(
            text: 'Cantar',
            backgroundColor: Colors.purple.shade700,
            textColor: Colors.white,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ),
      ],
    );
    if (ok != true || !mounted) return;
    final numero = int.tryParse(numCtrl.text.trim());
    if (numero == null || numero < 1 || numero > 75) {
      _snack(context, 'La bolilla debe ser un número del 1 al 75',
          error: true);
      return;
    }
    setState(() => _ocupado = true);
    try {
      final r = await _ds.cantarBolilla(widget.sorteo.id, numero);
      if (!mounted) return;
      await context.read<SorteoDetailCubit>().reload();
      if (!mounted) return;
      final eventos = (r['eventos'] as List?) ?? const [];
      if (eventos.isEmpty) {
        _snack(context, '🎱 Bolilla $numero cantada — sin ganadores aún');
      } else {
        // ¡Hay línea/bingo! Mostrarlo en grande.
        final lineas = eventos
            .map((e) =>
                '🎉 Cartilla #${(e as Map)['numeroCartilla']} · ${e['nombre']}'
                ' · ¡${e['logro'] == 'BINGO' ? 'BINGO' : 'LÍNEA'}!')
            .join('\n');
        await ConfirmDialog.show(
          context: context,
          type: ConfirmDialogType.success,
          title: '¡Tenemos ganador! 🎱',
          message: '$lineas\n\nUsa 🎲 JUGAR (arriba, en Premios) con el '
              'número de la cartilla para asignarle su premio.',
          confirmText: 'Entendido',
          icon: Icons.emoji_events,
        );
      }
    } catch (e) {
      if (mounted) _snack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bolillas = widget.sorteo.bolillas;
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.casino_outlined,
                    size: 16, color: Colors.purple.shade700),
                const SizedBox(width: 6),
                Text(
                  'Bolillas cantadas (${bolillas.length})',
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.purple.shade700),
                ),
                const Spacer(),
                if (_ocupado)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: Colors.purple.shade700,
                    ),
                    icon: const Icon(Icons.campaign_outlined, size: 16),
                    label: const Text('CANTAR',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700)),
                    onPressed: _cantar,
                  ),
              ],
            ),
            if (bolillas.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  'Canta cada bolilla que salga: el sistema marca TODAS '
                  'las cartillas y avisa al instante quién hace línea o bingo.',
                  style:
                      TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              )
            else
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final b in bolillas)
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$b',
                        style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.purple.shade700),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Catálogo de PREMIOS de la rifa con ánfora (tipo SORTEO): se registran
/// antes de jugar ("3× S/ 500 EN EFECTIVO", con imagen opcional). Con el
/// sorteo CERRADO aparece el modo JUGAR: sale un ticket del ánfora → se
/// busca al dueño → se le adjudica un premio pendiente.
class _PremiosCatalogoSection extends StatefulWidget {
  final Sorteo sorteo;
  const _PremiosCatalogoSection({required this.sorteo});

  @override
  State<_PremiosCatalogoSection> createState() =>
      _PremiosCatalogoSectionState();
}

class _PremiosCatalogoSectionState extends State<_PremiosCatalogoSection> {
  final _ds = locator<SorteoRemoteDataSource>();
  bool _ocupado = false;

  int get _totalUnidades =>
      widget.sorteo.premiosCatalogo.fold(0, (s, c) => s + c.cantidad);
  int get _totalSorteados =>
      widget.sorteo.premiosCatalogo.fold(0, (s, c) => s + c.sorteados);

  Future<void> _reload() => context.read<SorteoDetailCubit>().reload();

  // ── Agregar premio (descripción + cantidad + efectivo) ──────────────
  Future<void> _agregar() async {
    final descCtrl = TextEditingController();
    final cantCtrl = TextEditingController(text: '1');
    bool esEfectivo = false;
    final ok = await StyledDialog.show<bool>(
      context,
      accentColor: AppColors.blue1,
      icon: Icons.card_giftcard,
      titulo: 'Agregar premio a la rifa',
      content: [
        CustomText(
          controller: descCtrl,
          label: 'Premio',
          hintText: 'ej. S/ 500 EN EFECTIVO · CELULAR SAMSUNG',
          borderColor: AppColors.blue1,
          textCase: TextCase.upper,
        ),
        const SizedBox(height: 10),
        StatefulBuilder(
          builder: (ctx, setLocal) => Row(
            children: [
              Expanded(
                child: CustomText(
                  controller: cantCtrl,
                  label: 'Cantidad',
                  borderColor: AppColors.blue1,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              // EFECTIVO: se yapea al ganador (el bot le confirma su
              // número) — sin envío por agencia.
              Expanded(
                child: InkWell(
                  onTap: () => setLocal(() => esEfectivo = !esEfectivo),
                  child: Row(
                    children: [
                      Checkbox(
                        value: esEfectivo,
                        activeColor: AppColors.blue1,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        onChanged: (v) =>
                            setLocal(() => esEfectivo = v ?? false),
                      ),
                      const Expanded(
                        child: Text(
                          'En efectivo 💸 (se yapea)',
                          style: TextStyle(fontSize: 10.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      actions: [
        Builder(
          builder: (ctx) => TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(fontSize: 12)),
          ),
        ),
        Builder(
          builder: (ctx) => CustomButton(
            text: 'Agregar',
            backgroundColor: AppColors.blue1,
            textColor: Colors.white,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ),
      ],
    );
    final desc = descCtrl.text.trim();
    final cant = int.tryParse(cantCtrl.text.trim()) ?? 1;
    if (ok != true) return;
    if (desc.isEmpty || cant < 1) {
      if (mounted) {
        _snack(context, 'Indica el premio y una cantidad válida',
            error: true);
      }
      return;
    }
    try {
      await _ds.crearPremioCatalogo(widget.sorteo.id, desc, cant,
          esEfectivo: esEfectivo);
      await _reload();
    } catch (e) {
      if (mounted) _snack(context, 'No se pudo agregar: $e', error: true);
    }
  }

  Future<void> _eliminar(SorteoPremioCatalogo item) async {
    final ok = await ConfirmDialog.show(
      context: context,
      type: ConfirmDialogType.destructive,
      title: 'Quitar premio',
      message: '¿Quitar "${item.descripcion}" de la rifa?',
      confirmText: 'Quitar',
      icon: Icons.delete_outline,
    );
    if (ok != true) return;
    try {
      await _ds.eliminarPremioCatalogo(item.id);
      await _reload();
    } catch (e) {
      if (mounted) _snack(context, 'No se pudo quitar: $e', error: true);
    }
  }

  Future<void> _subirImagen(SorteoPremioCatalogo item) async {
    final source = await _elegirFuenteImagen(context);
    if (source == null || !mounted) return;
    final picked =
        await ImagePicker().pickImage(source: source, imageQuality: 82);
    if (picked == null || !mounted) return;
    setState(() => _ocupado = true);
    try {
      await _ds.subirImagenPremioCatalogo(item.id, File(picked.path));
      await _reload();
    } catch (e) {
      if (mounted) _snack(context, 'No se pudo subir: $e', error: true);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  // ── Modo JUGAR ──────────────────────────────────────────────────────
  Future<void> _jugar() async {
    final pendientes =
        widget.sorteo.premiosCatalogo.where((c) => !c.agotado).toList();
    if (pendientes.isEmpty) {
      _snack(context, 'Ya se sortearon todos los premios 🎉');
      return;
    }
    final numCtrl = TextEditingController();
    String? catalogoId = pendientes.first.id;
    final ok = await StyledDialog.show<bool>(
      context,
      accentColor: Colors.purple.shade700,
      icon: Icons.casino_outlined,
      titulo: 'Salió un ticket del ánfora',
      content: [
        CustomText(
          controller: numCtrl,
          label: 'Número del ticket ganador',
          hintText: 'ej. 47',
          borderColor: AppColors.blue1,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 10),
        StatefulBuilder(
          builder: (ctx, setLocal) => DropdownButtonFormField<String>(
            initialValue: catalogoId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Premio que se sortea',
              labelStyle: TextStyle(fontSize: 12),
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            items: [
              for (final c in pendientes)
                DropdownMenuItem(
                  value: c.id,
                  child: Text(
                    '${c.descripcion} (${c.cantidad - c.sorteados} disp.)',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (v) => setLocal(() => catalogoId = v),
          ),
        ),
      ],
      actions: [
        Builder(
          builder: (ctx) => TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(fontSize: 12)),
          ),
        ),
        Builder(
          builder: (ctx) => CustomButton(
            text: 'Asignar premio',
            backgroundColor: Colors.purple.shade700,
            textColor: Colors.white,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ),
      ],
    );
    if (ok != true || !mounted) return;
    final numero = int.tryParse(numCtrl.text.trim());
    if (numero == null || numero < 1 || catalogoId == null) {
      _snack(context, 'Indica el número del ticket ganador', error: true);
      return;
    }
    setState(() => _ocupado = true);
    try {
      final r = await _ds.jugarTicket(widget.sorteo.id, numero, catalogoId!);
      await _reload();
      if (!mounted) return;
      final nombre = (r['ganadorNombre'] as String?) ?? '';
      final restantes = (r['ticketsRestantes'] as num?)?.toInt();
      _snack(
        context,
        '🏆 Ticket #$numero: ¡$nombre gana ${r['premioDescripcion']}!'
        '${restantes != null ? ' (le quedan $restantes tickets jugando)' : ''}',
      );
    } catch (e) {
      if (mounted) _snack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sorteo = widget.sorteo;
    final items = sorteo.premiosCatalogo;
    final cerrado = sorteo.estado == EstadoSorteo.cerrado;
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.card_giftcard, size: 16, color: AppColors.blue1),
                const SizedBox(width: 6),
                const Text(
                  'Premios de la rifa',
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blue1),
                ),
                const SizedBox(width: 8),
                if (items.isNotEmpty)
                  Text(
                    '$_totalSorteados/$_totalUnidades sorteados',
                    style:
                        TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                const Spacer(),
                if (_ocupado)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else ...[
                  if (cerrado && items.any((c) => !c.agotado))
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: Colors.purple.shade700,
                      ),
                      icon: const Icon(Icons.casino_outlined, size: 16),
                      label: const Text('JUGAR',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700)),
                      onPressed: _jugar,
                    ),
                  IconButton(
                    tooltip: 'Agregar premio',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.add_circle_outline,
                        size: 18, color: AppColors.blue1),
                    onPressed: _agregar,
                  ),
                ],
              ],
            ),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  'Registra los premios que se jugarán (ej. 3× S/ 500, '
                  '2× celular) — con el sorteo CERRADO aparece el modo JUGAR.',
                  style:
                      TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              )
            else
              for (final c in items) _itemCatalogo(c),
          ],
        ),
      ),
    );
  }

  Widget _itemCatalogo(SorteoPremioCatalogo c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen opcional (thumb) o icono.
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: c.imagenThumbnail != null || c.imagenUrl != null
                ? Image.network(
                    c.imagenThumbnail ?? c.imagenUrl!,
                    width: 34,
                    height: 34,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _iconoPremio(),
                  )
                : _iconoPremio(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${c.cantidad > 1 ? '${c.cantidad}× ' : ''}${c.descripcion}'
                  '${c.esEfectivo ? ' 💸' : ''}',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: c.agotado ? Colors.grey.shade500 : Colors.black87,
                    decoration:
                        c.agotado ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  c.agotado
                      ? '✅ Sorteado completo'
                      : c.sorteados > 0
                          ? '${c.sorteados}/${c.cantidad} sorteados'
                          : 'Pendiente de sortear',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight:
                        c.agotado ? FontWeight.w700 : FontWeight.w400,
                    color: c.agotado
                        ? Colors.green.shade700
                        : Colors.grey.shade600,
                  ),
                ),
                for (final g in c.ganadores)
                  Text(
                    '🏆 ${g.nombre}'
                    '${g.numeroTicket != null ? ' · ticket #${g.numeroTicket}' : ''}',
                    style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade900),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Foto del premio (opcional)',
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.photo_camera_outlined,
                size: 17, color: Colors.grey.shade600),
            onPressed: _ocupado ? null : () => _subirImagen(c),
          ),
          if (c.sorteados == 0)
            IconButton(
              tooltip: 'Quitar',
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.delete_outline,
                  size: 17, color: Colors.red.shade400),
              onPressed: _ocupado ? null : () => _eliminar(c),
            ),
        ],
      ),
    );
  }

  Widget _iconoPremio() => Container(
        width: 34,
        height: 34,
        color: AppColors.blue1.withValues(alpha: 0.08),
        child: Icon(Icons.card_giftcard, size: 18, color: AppColors.blue1),
      );
}
