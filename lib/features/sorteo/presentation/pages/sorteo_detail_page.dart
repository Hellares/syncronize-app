import 'dart:io';
import 'dart:typed_data';

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
                  '${sorteo.canal.label} · $fecha · ${sorteo.estado.label}'
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
      remitenteNombre: empresa?.nombre ?? '',
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

    final datos = await showRegistrarPremioSheet(
      context: context,
      empresaId: empresaId,
      sedeId: sorteo.sedeId,
      ganadorNombre: ganador.nombreCompleto ?? '',
      precioParticipacionDefault: sorteo.precioParticipacion,
      descripcionDefault: sorteo.descripcion,
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
                        fontSize: 11, fontWeight: FontWeight.w600),
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.print,
                                size: 9, color: Colors.teal.shade700),
                            const SizedBox(width: 3),
                            Text(
                              'IMPRESO',
                              style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.teal.shade700),
                            ),
                          ],
                        ),
                      ),
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
                        fontSize: 11.5, fontWeight: FontWeight.w600),
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
                  OutlinedButton.icon(
                    onPressed: () => _subirFoto(context),
                    icon: const Icon(Icons.photo_camera_outlined, size: 15),
                    label:
                        const Text('Foto', style: TextStyle(fontSize: 10)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.blue1,
                      side: BorderSide(
                          color: AppColors.blue1.withValues(alpha: 0.5),),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_siguienteEstado != null)
                    ElevatedButton(
                      onPressed: () =>
                          _avanzarEstado(context, _siguienteEstado!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue1,
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        'Marcar ${_siguienteEstado!.label.toLowerCase()}',
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
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
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null || !context.mounted) return;
    final file = File(picked.path);
    final error = esPremio
        ? await cubit.subirFotoPremio(premio.id, file)
        : await cubit.subirTicketEnvio(premio.id, file);
    if (!context.mounted) return;
    _snack(
      context,
      error ??
          (esPremio
              ? 'Foto del premio subida — el ganador ya puede verla'
              : 'Ticket de envío subido — el ganador ya puede verlo'),
      error: error != null,
    );
  }
}
