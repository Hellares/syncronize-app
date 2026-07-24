import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/realtime_sync_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../empresa/presentation/widgets/empresa_drawer.dart';
import '../../data/datasources/delivery_remote_datasource.dart';
import '../../domain/entities/delivery_local.dart';
import '../bloc/delivery_cubit.dart';
import '../bloc/delivery_state.dart';
import '../services/delivery_gps_reporter.dart';
import '../widgets/pin_entrega_dialog.dart';

/// Pantalla del REPARTIDOR: pool de deliveries disponibles para tomar y
/// sus entregas (activas + historial). El producto ya está pagado — el
/// repartidor solo cobra la tarifa de envío al entregar.
class DeliveryRepartidorPage extends StatelessWidget {
  const DeliveryRepartidorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final empresaState = context.read<EmpresaContextCubit>().state;
    final empresaId = empresaState is EmpresaContextLoaded
        ? empresaState.context.empresa.id
        : '';
    return BlocProvider(
      create: (_) => locator<DeliveryCubit>()..loadAll(empresaId),
      child: const _DeliveryView(),
    );
  }
}

class _DeliveryView extends StatefulWidget {
  const _DeliveryView();

  @override
  State<_DeliveryView> createState() => _DeliveryViewState();
}

class _DeliveryViewState extends State<_DeliveryView>
    with WidgetsBindingObserver {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  StreamSubscription? _realtimeSub;
  late final DeliveryGpsReporter _gps;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _gps = DeliveryGpsReporter(locator<DeliveryRemoteDataSource>());
    // Un delivery nuevo publicado → la lista se refresca sola.
    _realtimeSub = locator<RealtimeSyncService>().events.listen((e) {
      if (!mounted || e is! RealtimeDeliveryDisponible) return;
      context.read<DeliveryCubit>().refresh();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _realtimeSub?.cancel();
    _gps.detener();
    super.dispose();
  }

  /// Al VOLVER del background las listas quedaban congeladas (o vacías si
  /// la 1ª carga corrió antes de tener el contexto de empresa) — recargar.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _asegurarCarga();
  }

  void _asegurarCarga() {
    if (!mounted) return;
    final empresaState = context.read<EmpresaContextCubit>().state;
    final empresaId = empresaState is EmpresaContextLoaded
        ? empresaState.context.empresa.id
        : '';
    context.read<DeliveryCubit>().asegurarCarga(empresaId);
  }

  /// GPS encendido ⟺ hay una entrega EN_CAMINO mía. La posición viaja al
  /// backend y el cliente la ve en su página de tracking (mapa).
  void _syncGps(DeliveryState state) {
    if (state is! DeliveryLoaded) return;
    final enCamino =
        state.misEntregas.where((d) => d.esEnCamino).toList();
    if (enCamino.isEmpty) {
      _gps.detener();
      return;
    }
    final empresaState = context.read<EmpresaContextCubit>().state;
    final empresaId = empresaState is EmpresaContextLoaded
        ? empresaState.context.empresa.id
        : '';
    if (empresaId.isEmpty) return;
    _gps.asegurar(empresaId: empresaId, deliveryId: enCamino.first.id);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<DeliveryCubit, DeliveryState>(
          listener: (context, state) => _syncGps(state),
        ),
        // Si la página nació ANTES de que el contexto de empresa cargara
        // (resume frío), la 1ª carga fue con empresa vacía → recargar aquí.
        BlocListener<EmpresaContextCubit, EmpresaContextState>(
          listener: (context, state) {
            if (state is EmpresaContextLoaded) _asegurarCarga();
          },
        ),
      ],
      child: _buildContenido(context),
    );
  }

  Widget _buildContenido(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: GradientBackground(
        style: GradientStyle.professional,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.transparent,
          // El repartidor VIVE en esta pantalla (es su home): el drawer le da
          // la salida (Mi Cuenta / cerrar sesión) sin abrirle módulos ajenos —
          // los tiles ya se filtran por permisos/rol. SmartAppBar no implica
          // hamburguesa sola → leftIcon + openDrawer explícitos.
          drawer: const EmpresaDrawer(),
          appBar: SmartAppBar(
            title: 'Delivery',
            backgroundColor: AppColors.blue1,
            foregroundColor: AppColors.white,
            leftIcon: Icons.menu,
            onLeftTap: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          body: Column(
            children: [
              Container(
                color: AppColors.blue1,
                child: const TabBar(
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  tabs: [
                    Tab(icon: Icon(Icons.inbox_outlined), text: 'Disponibles'),
                    Tab(
                      icon: Icon(Icons.delivery_dining),
                      text: 'Mis entregas',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: BlocBuilder<DeliveryCubit, DeliveryState>(
                  builder: (context, state) {
                    if (state is DeliveryLoading || state is DeliveryInitial) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }
                    if (state is DeliveryError) {
                      return _ErrorView(
                        message: state.message,
                        onRetry: () => context.read<DeliveryCubit>().refresh(),
                      );
                    }
                    if (state is DeliveryLoaded) {
                      return TabBarView(
                        children: [
                          _ListaDisponibles(deliveries: state.disponibles),
                          _ListaMisEntregas(
                            activas: state.activas,
                            historial: state.historial,
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Disponibles ───────────────────────────

class _ListaDisponibles extends StatelessWidget {
  final List<DeliveryLocal> deliveries;
  const _ListaDisponibles({required this.deliveries});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<DeliveryCubit>().refresh(),
      child: deliveries.isEmpty
          ? _EmptyScroll(
              icon: Icons.inbox_outlined,
              texto:
                  'No hay deliveries disponibles.\nTe llegará una notificación cuando aparezca uno.',
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
              itemCount: deliveries.length,
              itemBuilder: (context, i) {
                final d = deliveries[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _DeliveryCard(
                    delivery: d,
                    accion: _AccionCard(
                      label: 'TOMAR PEDIDO',
                      icon: Icons.back_hand_outlined,
                      color: AppColors.blue1,
                      onTap: () => _tomar(context, d),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _tomar(BuildContext context, DeliveryLocal d) async {
    final cubit = context.read<DeliveryCubit>();
    final ok = await ConfirmDialog.show(
      context: context,
      type: ConfirmDialogType.info,
      title: 'Tomar pedido',
      message:
          '${d.ventaCodigo ?? 'Pedido'} — entregar en:\n${d.direccion}'
          '${d.distrito != null ? ' (${d.distrito})' : ''}\n\n'
          'Cobrarás S/ ${d.costoDelivery.toStringAsFixed(2)} de delivery al entregar.',
      confirmText: 'Tomar',
    );
    if (ok != true) return;
    final error = await cubit.tomar(d.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: error == null ? Colors.green[700] : Colors.red[700],
      content: Text(error ?? '🛵 ¡Pedido tomado! Está en "Mis entregas".'),
    ));
  }
}

// ─────────────────────────── Mis entregas ───────────────────────────

class _ListaMisEntregas extends StatelessWidget {
  final List<DeliveryLocal> activas;
  final List<DeliveryLocal> historial;
  const _ListaMisEntregas({required this.activas, required this.historial});

  @override
  Widget build(BuildContext context) {
    final vacio = activas.isEmpty && historial.isEmpty;
    return RefreshIndicator(
      onRefresh: () => context.read<DeliveryCubit>().refresh(),
      child: vacio
          ? _EmptyScroll(
              icon: Icons.delivery_dining,
              texto: 'Aún no tienes entregas.\nToma un pedido en "Disponibles".',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
              children: [
                ...activas.map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _DeliveryCard(
                        delivery: d,
                        accion: d.esTomado
                            ? _AccionCard(
                                label: 'SALIR EN CAMINO',
                                icon: Icons.delivery_dining,
                                color: Colors.orange[800]!,
                                onTap: () => _enCamino(context, d),
                              )
                            : _AccionCard(
                                label:
                                    'ENTREGADO — COBRA S/ ${d.costoDelivery.toStringAsFixed(2)}',
                                icon: Icons.check_circle_outline,
                                color: Colors.green[700]!,
                                onTap: () => _entregado(context, d),
                              ),
                      ),
                    )),
                if (historial.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Historial',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ...historial.map((d) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _DeliveryCard(delivery: d),
                      )),
                ],
              ],
            ),
    );
  }

  Future<void> _enCamino(BuildContext context, DeliveryLocal d) async {
    final cubit = context.read<DeliveryCubit>();
    final error = await cubit.marcarEnCamino(d.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: error == null ? Colors.orange[800] : Colors.red[700],
      content: Text(error ?? '🛵 En camino — se avisó al cliente por WhatsApp.'),
    ));
  }

  Future<void> _entregado(BuildContext context, DeliveryLocal d) async {
    final cubit = context.read<DeliveryCubit>();
    // Prueba de entrega: el PIN lo tiene SOLO el cliente.
    final pin = await showPinEntregaDialog(
      context: context,
      ventaCodigo: d.ventaCodigo ?? 'Pedido',
      costoDelivery: d.costoDelivery,
    );
    if (pin == null) return;
    final error = await cubit.marcarEntregado(d.id, pin: pin);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: error == null ? Colors.green[700] : Colors.red[700],
      content: Text(error ?? '✅ Entrega completada. ¡Buen trabajo!'),
    ));
  }
}

// ─────────────────────────── Widgets compartidos ───────────────────────────

class _AccionCard {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _AccionCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _DeliveryCard extends StatelessWidget {
  final DeliveryLocal delivery;
  final _AccionCard? accion;
  const _DeliveryCard({required this.delivery, this.accion});

  Color get _estadoColor {
    if (delivery.esEntregado) return Colors.green[700]!;
    if (delivery.esCancelado) return Colors.red[700]!;
    if (delivery.esEnCamino) return Colors.orange[800]!;
    return AppColors.blue1;
  }

  @override
  Widget build(BuildContext context) {
    final d = delivery;
    return GradientContainer(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  d.ventaCodigo ?? 'Pedido',
                  style: const TextStyle(
                    color: AppColors.blue1,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _estadoColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  d.estadoLabel,
                  style: TextStyle(
                    color: _estadoColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _linea(Icons.person_outline, d.destinatarioNombre),
          _linea(
            Icons.location_on_outlined,
            '${d.direccion}${d.distrito != null ? ' — ${d.distrito}' : ''}',
          ),
          if (d.referencia != null && d.referencia!.isNotEmpty)
            _linea(Icons.info_outline, 'Ref: ${d.referencia}'),
          if (d.destinatarioCelular != null)
            _linea(Icons.phone_outlined, d.destinatarioCelular!),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Delivery: S/ ${d.costoDelivery.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.green[800],
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              // Navegación turn-by-turn en Google Maps hacia el destino
              // (deep link gratis) — solo para la entrega activa.
              if (d.esActivo)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.blue1,
                      side: const BorderSide(color: AppColors.blue1),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: () => launchUrl(
                      Uri.parse(d.urlNavegacion),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.navigation_outlined, size: 15),
                    label: const Text('NAVEGAR'),
                  ),
                ),
            ],
          ),
          // Acción principal a lo ancho (labels largos + NAVEGAR arriba no
          // caben en una sola fila sin overflow).
          if (accion != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accion!.color,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: accion!.onTap,
                icon: Icon(accion!.icon, size: 16),
                label: Text(accion!.label),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _linea(IconData icon, String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                texto,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
}

class _EmptyScroll extends StatelessWidget {
  final IconData icon;
  final String texto;
  const _EmptyScroll({required this.icon, required this.texto});

  @override
  Widget build(BuildContext context) {
    // ListView para que el pull-to-refresh funcione aun vacío.
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(icon, size: 56, color: Colors.white54),
        const SizedBox(height: 16),
        Text(
          texto,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.white70),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
