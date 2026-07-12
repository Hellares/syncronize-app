import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../sorteo/domain/entities/sorteo.dart';
import '../../domain/entities/premio_cliente.dart';
import '../bloc/mis_premios_cubit.dart';
import '../widgets/elegir_agencia_sheet.dart';

/// "Mis Premios" — el cliente ve los premios que ganó en sorteos, el
/// estado del envío y la foto del ticket de agencia.
class MisPremiosPage extends StatelessWidget {
  /// Si viene (deep-link del push), resalta/expande ese premio.
  final String? premioId;

  const MisPremiosPage({super.key, this.premioId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<MisPremiosCubit>()..load(),
      child: _MisPremiosView(premioDestacadoId: premioId),
    );
  }
}

class _MisPremiosView extends StatelessWidget {
  final String? premioDestacadoId;
  const _MisPremiosView({this.premioDestacadoId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SmartAppBar(
        customHeight: 40,
        title: 'Mis Premios 🎁',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<MisPremiosCubit, MisPremiosState>(
        builder: (context, state) {
          if (state is MisPremiosLoading) {
            return const Center(
                child: CircularProgressIndicator(strokeWidth: 2));
          }
          if (state is MisPremiosError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off, size: 44, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text(state.message,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                  TextButton(
                    onPressed: () => context.read<MisPremiosCubit>().load(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }
          final premios = (state as MisPremiosLoaded).premios;
          if (premios.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.card_giftcard,
                        size: 56, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(
                      'Aún no tienes premios.\nCuando ganes un sorteo de tus '
                      'tiendas favoritas, aparecerá aquí con el estado de tu '
                      'envío.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12.5, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => context.read<MisPremiosCubit>().load(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
              itemCount: premios.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => PremioClienteCard(
                premio: premios[i],
                inicialmenteExpandido: premios[i].id == premioDestacadoId,
              ),
            ),
          );
        },
      ),
    );
  }
}

class PremioClienteCard extends StatefulWidget {
  final PremioCliente premio;
  final bool inicialmenteExpandido;

  const PremioClienteCard({
    super.key,
    required this.premio,
    this.inicialmenteExpandido = false,
  });

  @override
  State<PremioClienteCard> createState() => _PremioClienteCardState();
}

class _PremioClienteCardState extends State<PremioClienteCard> {
  late bool _expandido = widget.inicialmenteExpandido;

  PremioCliente get premio => widget.premio;

  static const _pasos = [
    EstadoPremioSorteo.registrado,
    EstadoPremioSorteo.preparando,
    EstadoPremioSorteo.enviado,
    EstadoPremioSorteo.entregado,
  ];

  @override
  Widget build(BuildContext context) {
    final pasoActual = _pasos.indexOf(premio.estado);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _expandido = !_expandido),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Empresa + sorteo
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.blue1.withValues(alpha: 0.1),
                    backgroundImage: premio.empresaLogo != null
                        ? NetworkImage(premio.empresaLogo!)
                        : null,
                    child: premio.empresaLogo == null
                        ? Icon(Icons.storefront,
                            size: 14, color: AppColors.blue1)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(premio.empresaNombre,
                            style: const TextStyle(
                                fontSize: 11.5, fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(premio.sorteoTitulo,
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Icon(
                    _expandido ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
              // Foto del premio como imagen destacada (si la empresa la
              // subió) — el "wow" al abrir Mis Premios.
              if (premio.fotos.isNotEmpty) ...[
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _verImagen(context, premio.fotos.first.url),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      premio.fotos.first.url,
                      width: double.infinity,
                      height: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              // El premio
              Row(
                children: [
                  const Text('🎁', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${premio.descripcion}${premio.cantidad > 1 ? '  x${premio.cantidad}' : ''}',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Timeline de estado
              Row(
                children: [
                  for (var i = 0; i < _pasos.length; i++) ...[
                    _punto(i <= pasoActual, _pasos[i]),
                    if (i < _pasos.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: i < pasoActual
                              ? Colors.green.shade400
                              : Colors.grey.shade200,
                        ),
                      ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final p in _pasos)
                    Text(
                      p.label,
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: p == premio.estado
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: p == premio.estado
                            ? Colors.green.shade700
                            : Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
              if (_expandido) ...[
                const Divider(height: 20),
                _detalleEntrega(),
                // El ganador elige SU agencia de recojo — solo antes del
                // despacho. Si no lo hace, la tienda la asigna.
                if (premio.estado == EstadoPremioSorteo.registrado ||
                    premio.estado == EstadoPremioSorteo.preparando) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _elegirAgencia(context),
                      icon: const Icon(Icons.edit_location_alt_outlined,
                          size: 15),
                      label: Text(
                        premio.agenciaNombre == null ||
                                premio.agenciaNombre!.isEmpty
                            ? 'Elegir dónde recoger mi premio'
                            : 'Cambiar agencia de recojo',
                        style: const TextStyle(fontSize: 11.5),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.blue1,
                        side: BorderSide(
                            color: AppColors.blue1.withValues(alpha: 0.5)),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ],
                // La CLAVE DE RECOJO destacada: es lo que el ganador
                // muestra en la agencia para que le entreguen.
                if (premio.envioClave != null &&
                    premio.envioClave!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Column(
                      children: [
                        Text('CLAVE DE RECOJO',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                                color: Colors.amber.shade900)),
                        const SizedBox(height: 2),
                        Text(
                          premio.envioClave!,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                              color: Colors.amber.shade900),
                        ),
                      ],
                    ),
                  ),
                ],
                if (premio.tickets.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text('Ticket de envío',
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade700)),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: premio.tickets.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () =>
                            _verImagen(context, premio.tickets[i].url),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            premio.tickets[i].urlThumbnail ??
                                premio.tickets[i].url,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 120,
                              height: 120,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.receipt_long),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _punto(bool activo, EstadoPremioSorteo paso) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: activo ? Colors.green.shade500 : Colors.grey.shade200,
      ),
      child: Icon(
        activo ? Icons.check : Icons.circle,
        size: activo ? 12 : 6,
        color: activo ? Colors.white : Colors.grey.shade400,
      ),
    );
  }

  Widget _detalleEntrega() {
    final esAgencia = premio.modalidad == ModalidadEntregaPremio.envioAgencia;
    final lineas = <(IconData, String)>[
      if (esAgencia && premio.agenciaNombre != null)
        (
          Icons.local_shipping_outlined,
          'Agencia: ${premio.agenciaNombre}'
              '${premio.destinoTexto != null ? ' → ${premio.destinoTexto}' : ''}'
        ),
      if (esAgencia &&
          premio.agenciaDireccion != null &&
          premio.agenciaDireccion!.isNotEmpty)
        (Icons.location_on_outlined, 'Recoges en: ${premio.agenciaDireccion}'),
      if (esAgencia && premio.envioNumeroOrden != null)
        (Icons.confirmation_number_outlined,
            'N° de orden: ${premio.envioNumeroOrden}'),
      if (esAgencia && premio.envioCodigo != null)
        (Icons.qr_code_2, 'Código: ${premio.envioCodigo}'),
      if (!esAgencia)
        (
          Icons.storefront_outlined,
          'Retiro en tienda'
              '${premio.sedeRetiroNombre != null ? ': ${premio.sedeRetiroNombre}' : ''}'
        ),
      if (!esAgencia && premio.sedeRetiroDireccion != null)
        (Icons.location_on_outlined, premio.sedeRetiroDireccion!),
      if (premio.empresaTelefono != null)
        (Icons.phone_outlined, 'Consultas: ${premio.empresaTelefono}'),
      if (premio.enviadoEn != null)
        (
          Icons.schedule,
          'Enviado el ${_fmt(premio.enviadoEn!)}',
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (icono, texto) in lineas)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icono, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(texto,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade700)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// El ganador indica su agencia de recojo (lo único que puede editar).
  Future<void> _elegirAgencia(BuildContext context) async {
    final cubit = context.read<MisPremiosCubit>();
    final elegida = await showElegirAgenciaSheet(
      context: context,
      premio: premio,
    );
    if (elegida == null || !context.mounted) return;
    final error = await cubit.elegirAgencia(
      premioId: premio.id,
      agenciaNombre: elegida.agenciaNombre,
      destinoDepartamento: elegida.destinoDepartamento,
      destinoProvincia: elegida.destinoProvincia,
      agenciaDireccion: elegida.agenciaDireccion,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        error ??
            '¡Listo! Tu premio se enviará a ${elegida.agenciaNombre} 📦',
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor:
          error != null ? Colors.orange.shade800 : Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
    ));
  }

  String _fmt(DateTime f) =>
      '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';

  void _verImagen(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: InteractiveViewer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(url, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
