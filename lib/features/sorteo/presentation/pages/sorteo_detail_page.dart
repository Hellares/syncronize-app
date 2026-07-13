import 'dart:io';
import 'dart:typed_data';

import 'package:syncronize/features/venta/data/datasources/venta_remote_datasource.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';

import '../../../../core/di/injection_container.dart';
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
import '../../domain/entities/sorteo.dart';
import '../bloc/sorteo_detail_cubit.dart';
import '../services/rotulo_envio_pdf_generator.dart';
import '../widgets/editar_entrega_sheet.dart';
import '../widgets/enviar_whatsapp_premio_sheet.dart';
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
      child: const _SorteoDetailView(),
    );
  }
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
              if (sorteo != null && sorteo.estado == EstadoSorteo.abierto)
                IconButton(
                  tooltip: 'Cerrar sorteo',
                  icon: const Icon(Icons.lock_outline,
                      size: 20, color: Colors.white),
                  onPressed: () => _cerrarSorteo(context),
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
    final f = sorteo.fechaSorteo;
    final fecha =
        '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';
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
                  '${sorteo.tipo == TipoSorteo.dinamica ? 'DINÁMICA · ' : ''}${sorteo.canal.label} · $fecha · ${sorteo.estado.label}'
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
          // ── Participantes captados por el bot de WhatsApp ──
          if (sorteo.participantes.isNotEmpty) ...[
            const SizedBox(height: 10),
            _ParticipantesSection(sorteo: sorteo),
          ],
          const SizedBox(height: 10),
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
                  for (final p in otros.take(6))
                    CheckboxListTile(
                      dense: true,
                      value: marcados.contains(p.id),
                      activeColor: AppColors.blue1,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(p.ganadorNombre,
                          style: const TextStyle(fontSize: 12)),
                      subtitle: Text(p.descripcion,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey.shade600)),
                      onChanged: (v) => setLocal(() => v == true
                          ? marcados.add(p.id)
                          : marcados.remove(p.id)),
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
                nombre: p.ganadorNombre,
                dni: p.ganadorDni,
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

  /// Ya tiene su card de premio abajo (auto-premio de la dinámica).
  bool _tienePremio(SorteoParticipante p) => widget.sorteo.premios.any(
      (pr) => pr.ganadorDni == p.dni && pr.estado != EstadoPremioSorteo.anulado);

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
              for (final p in visibles) _fila(context, p),
            ],
          ],
        ),
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
            // trofeo solo aparece si aún no tiene premio en el sorteo.
            if (esActivo &&
                !widget.sorteo.premios.any((pr) =>
                    pr.ganadorDni == p.dni &&
                    pr.estado != EstadoPremioSorteo.anulado))
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
      ganadorDni: p.dni,
      ganadorNombre: p.nombre,
      ganadorCelular:
          p.celular.length > 9 ? p.celular.substring(p.celular.length - 9) : p.celular,
      descripcion: datos.descripcion,
      productoId: datos.productoId,
      varianteId: datos.varianteId,
      cantidad: datos.cantidad,
      montoParticipacion: datos.montoParticipacion,
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
  const _PremioCard({required this.premio, this.onImprimirRotulo});

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
                    style:
                        TextStyle(fontSize: 10.5, color: Colors.grey.shade700),
                  ),
                ),
              ],
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
                  // Foto del premio o del ticket de envío
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
      final datos = await _dialogDatosEnvio(context);
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
      BuildContext context) async {
    final ordenCtrl =
        TextEditingController(text: premio.envioNumeroOrden ?? '');
    final codigoCtrl = TextEditingController(text: premio.envioCodigo ?? '');
    final claveCtrl = TextEditingController(text: premio.envioClave ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StyledDialog(
        accentColor: AppColors.blue1,
        icon: Icons.local_shipping_outlined,
        titulo: 'Datos del envío',
        content: [
          Text(
            'Los datos que entrega la agencia — el ganador los verá en '
            'Mis Premios (todos opcionales).',
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
            label: 'Clave de recojo',
            hintText: 'la que pide la agencia para entregar',
            borderColor: AppColors.blue1,
            textCase: TextCase.upper,
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
              text: 'Guardar',
              backgroundColor: AppColors.blue1,
              textColor: Colors.white,
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ),
        ],
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
