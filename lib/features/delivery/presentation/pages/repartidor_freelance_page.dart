import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../auth/presentation/bloc/auth/auth_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../data/datasources/delivery_remote_datasource.dart';
import '../../data/datasources/repartidor_remote_datasource.dart';
import '../../domain/entities/delivery_local.dart';
import '../../domain/repositories/delivery_repository.dart';
import '../services/delivery_gps_reporter.dart';
import '../widgets/pin_entrega_dialog.dart';

/// Panel del repartidor FREELANCE de Syncronize — vive FUERA del tenant
/// (no pertenece a ninguna empresa): verificación OTP, estado de su
/// solicitud y, ya APROBADO, el pool externo (pedidos de empresas con
/// opt-in en sus zonas, cross-empresa).
class RepartidorFreelancePage extends StatefulWidget {
  const RepartidorFreelancePage({super.key});

  @override
  State<RepartidorFreelancePage> createState() =>
      _RepartidorFreelancePageState();
}

class _RepartidorFreelancePageState extends State<RepartidorFreelancePage>
    with WidgetsBindingObserver {
  final _repartidorDs = locator<RepartidorRemoteDataSource>();
  final _deliveryRepo = locator<DeliveryRepository>();
  late final DeliveryGpsReporter _gps;

  bool _cargando = true;
  bool _noEsRepartidor = false;
  Map<String, dynamic>? _perfil;
  List<DeliveryLocal> _disponibles = const [];
  List<DeliveryLocal> _misEntregas = const [];
  final _otpCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _gps = DeliveryGpsReporter(locator<DeliveryRemoteDataSource>());
    _cargar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _otpCtrl.dispose();
    _gps.detener();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _cargar();
  }

  bool get _aprobado => _perfil?['estado'] == 'APROBADO';

  Future<void> _cargar() async {
    try {
      final perfil = await _repartidorDs.miPerfil();
      if (!mounted) return;
      _perfil = perfil;
      _noEsRepartidor = false;
      if (_aprobado) {
        final results = await Future.wait([
          _deliveryRepo.getExternoDisponibles(),
          _deliveryRepo.getExternoMisEntregas(),
        ]);
        if (!mounted) return;
        final disp = results[0];
        final mias = results[1];
        _disponibles =
            disp is Success<List<DeliveryLocal>> ? disp.data : const [];
        _misEntregas =
            mias is Success<List<DeliveryLocal>> ? mias.data : const [];
        _syncGps();
      }
      setState(() => _cargando = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _noEsRepartidor = true;
        _cargando = false;
      });
    }
  }

  /// GPS encendido ⟺ tengo una entrega EN_CAMINO (usa la empresa DE ESA
  /// entrega — el freelance cruza empresas).
  void _syncGps() {
    final enCamino = _misEntregas.where((d) => d.esEnCamino).toList();
    if (enCamino.isEmpty || enCamino.first.empresaId == null) {
      _gps.detener();
      return;
    }
    _gps.asegurar(
      empresaId: enCamino.first.empresaId!,
      deliveryId: enCamino.first.id,
    );
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontSize: 12)),
      backgroundColor: error ? Colors.red[700] : Colors.green[700],
      behavior: SnackBarBehavior.floating,
    ));
  }

  String _msgDe(Object e) =>
      e.toString().replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '');

  // ── Acciones ──

  Future<void> _verificarOtp() async {
    final codigo = _otpCtrl.text.trim();
    if (codigo.length != 6) return _snack('Ingresa los 6 dígitos', error: true);
    try {
      await _repartidorDs.verificarOtp(codigo);
      if (!mounted) return;
      _snack('✓ Celular verificado');
      _cargar();
    } catch (e) {
      if (!mounted) return;
      _snack(_msgDe(e), error: true);
    }
  }

  Future<void> _reenviarOtp() async {
    try {
      await _repartidorDs.enviarOtp();
      if (!mounted) return;
      _snack('Código reenviado por WhatsApp');
    } catch (e) {
      if (!mounted) return;
      _snack(_msgDe(e), error: true);
    }
  }

  Future<void> _tomar(DeliveryLocal d) async {
    final ok = await ConfirmDialog.show(
      context: context,
      type: ConfirmDialogType.info,
      title: 'Tomar pedido',
      message: '${d.ventaCodigo ?? 'Pedido'} de ${d.empresaNombre ?? 'la empresa'}\n'
          '${d.direccion}${d.distrito != null ? ' (${d.distrito})' : ''}\n\n'
          'Cobrarás S/ ${d.costoDelivery.toStringAsFixed(2)} al entregar.',
      confirmText: 'Tomar',
    );
    if (ok != true || !mounted) return;
    final r = await _deliveryRepo.tomarExterno(d.id);
    if (!mounted) return;
    _snack(
      r is Success<DeliveryLocal>
          ? '🛵 ¡Pedido tomado!'
          : (r as Error<DeliveryLocal>).message,
      error: r is! Success<DeliveryLocal>,
    );
    _cargar();
  }

  Future<void> _enCamino(DeliveryLocal d) async {
    if (d.empresaId == null) return;
    final r = await _deliveryRepo.marcarEnCamino(d.id, d.empresaId!);
    if (!mounted) return;
    _snack(
      r is Success<DeliveryLocal>
          ? '🛵 En camino — se avisó al cliente'
          : (r as Error<DeliveryLocal>).message,
      error: r is! Success<DeliveryLocal>,
    );
    _cargar();
  }

  Future<void> _entregado(DeliveryLocal d) async {
    if (d.empresaId == null) return;
    // Prueba de entrega: el PIN lo tiene SOLO el cliente.
    final pin = await showPinEntregaDialog(
      context: context,
      ventaCodigo: d.ventaCodigo ?? 'Pedido',
      costoDelivery: d.costoDelivery,
    );
    if (pin == null || !mounted) return;
    final r = await _deliveryRepo.marcarEntregado(d.id, d.empresaId!, pin: pin);
    if (!mounted) return;
    _snack(
      r is Success<DeliveryLocal>
          ? '✅ Entrega completada. ¡Buen trabajo!'
          : (r as Error<DeliveryLocal>).message,
      error: r is! Success<DeliveryLocal>,
    );
    _cargar();
  }

  // ── UI ──

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      style: GradientStyle.professional,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: SmartAppBar(
            title: 'Repartidor Syncronize',
            backgroundColor: AppColors.blue1,
            foregroundColor: AppColors.white,
            actions: [
              // Puede pasear por el marketplace como cualquier persona;
              // con push, el botón atrás lo devuelve a su panel.
              IconButton(
                tooltip: 'Ir al marketplace',
                icon: const Icon(Icons.storefront_outlined, size: 20),
                onPressed: () => context.push('/marketplace'),
              ),
              IconButton(
                tooltip: 'Cerrar sesión',
                icon: const Icon(Icons.logout, size: 20),
                onPressed: () async {
                  final ok = await ConfirmDialog.show(
                    context: context,
                    type: ConfirmDialogType.warning,
                    title: 'Cerrar sesión',
                    message: '¿Seguro que quieres salir?',
                    confirmText: 'Salir',
                  );
                  if (ok == true && context.mounted) {
                    context
                        .read<AuthBloc>()
                        .add(const LogoutRequestedEvent());
                  }
                },
              ),
            ],
          ),
          body: _cargando
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : _noEsRepartidor
                  ? _buildNoRegistrado()
                  : !_aprobado || _perfil?['celularVerificado'] != true
                      ? _buildEstado()
                      : _buildPool(),
        ),
      ),
    );
  }

  Widget _buildNoRegistrado() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delivery_dining, size: 56, color: Colors.white70),
            const SizedBox(height: 12),
            const Text(
              'No estás registrado como repartidor',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Registrarme como repartidor',
              backgroundColor: Colors.white,
              textColor: AppColors.blue1,
              onPressed: () => context.go('/register-repartidor'),
            ),
          ],
        ),
      ),
    );
  }

  /// OTP pendiente / solicitud en revisión / suspendido.
  Widget _buildEstado() {
    final p = _perfil!;
    final estado = p['estado'] as String? ?? 'PENDIENTE';
    final verificado = p['celularVerificado'] == true;
    final zonas = (p['zonas'] as List<dynamic>? ?? const []).join(', ');

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GradientContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Hola, ${p['nombreCompleto'] ?? ''}! 🛵',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Zonas: $zonas',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                const Divider(height: 20),
                if (!verificado) ...[
                  const Text(
                    '1️⃣ Verifica tu celular',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Te enviamos un código de 6 dígitos por WhatsApp.',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          controller: _otpCtrl,
                          label: 'Código',
                          borderColor: AppColors.blue1,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue1,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _verificarOtp,
                        child: const Text('Verificar'),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _reenviarOtp,
                    child: const Text('Reenviar código',
                        style: TextStyle(fontSize: 12)),
                  ),
                  const Divider(height: 20),
                ],
                if (estado == 'PENDIENTE') ...[
                  Row(
                    children: [
                      Icon(Icons.hourglass_top,
                          size: 18, color: Colors.orange[800]),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Tu solicitud está EN REVISIÓN. Te avisaremos por '
                          'WhatsApp cuando estés aprobado.',
                          style: TextStyle(fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ] else if (estado == 'SUSPENDIDO' || estado == 'BLOQUEADO') ...[
                  Row(
                    children: [
                      Icon(Icons.block, size: 18, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tu cuenta está ${estado.toLowerCase()}'
                          '${p['motivoEstado'] != null ? ': ${p['motivoEstado']}' : '.'}',
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Icon(Icons.check_circle,
                          size: 18, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          '¡Aprobado! Verifica tu celular para empezar.',
                          style: TextStyle(fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'Desliza hacia abajo para actualizar',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  /// Pool externo (APROBADO + celular verificado): Disponibles / Mis entregas.
  Widget _buildPool() {
    final activas = _misEntregas.where((d) => d.esActivo).toList();
    final historial = _misEntregas.where((d) => !d.esActivo).toList();
    return Column(
      children: [
        Container(
          color: AppColors.blue1,
          child: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.inbox_outlined), text: 'Disponibles'),
              Tab(icon: Icon(Icons.delivery_dining), text: 'Mis entregas'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            children: [
              _buildLista(
                _disponibles,
                vacio:
                    'No hay pedidos en tus zonas por ahora.\nDesliza para actualizar.',
                accionDe: (d) => _AccionTile(
                  label: 'TOMAR PEDIDO',
                  icon: Icons.back_hand_outlined,
                  color: AppColors.blue1,
                  onTap: () => _tomar(d),
                ),
              ),
              _buildLista(
                [...activas, ...historial],
                vacio: 'Aún no tienes entregas.\nToma un pedido en "Disponibles".',
                accionDe: (d) => d.esTomado
                    ? _AccionTile(
                        label: 'SALIR EN CAMINO',
                        icon: Icons.delivery_dining,
                        color: Colors.orange[800]!,
                        onTap: () => _enCamino(d),
                      )
                    : d.esEnCamino
                        ? _AccionTile(
                            label:
                                'ENTREGADO — COBRA S/ ${d.costoDelivery.toStringAsFixed(2)}',
                            icon: Icons.check_circle_outline,
                            color: Colors.green[700]!,
                            onTap: () => _entregado(d),
                          )
                        : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLista(
    List<DeliveryLocal> items, {
    required String vacio,
    required _AccionTile? Function(DeliveryLocal) accionDe,
  }) {
    return RefreshIndicator(
      onRefresh: _cargar,
      child: items.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 120),
                const Icon(Icons.inbox_outlined,
                    size: 56, color: Colors.white54),
                const SizedBox(height: 16),
                Text(
                  vacio,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final d = items[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildCard(d, accionDe(d)),
                );
              },
            ),
    );
  }

  Widget _buildCard(DeliveryLocal d, _AccionTile? accion) {
    Color estadoColor() {
      if (d.esEntregado) return Colors.green[700]!;
      if (d.esCancelado) return Colors.red[700]!;
      if (d.esEnCamino) return Colors.orange[800]!;
      return AppColors.blue1;
    }

    Widget linea(IconData icon, String texto) => Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Row(
            children: [
              Icon(icon, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  texto,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        );

    return GradientContainer(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${d.ventaCodigo ?? 'Pedido'}'
                  '${d.empresaNombre != null ? ' · ${d.empresaNombre}' : ''}',
                  style: const TextStyle(
                    color: AppColors.blue1,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: estadoColor().withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  d.estadoLabel,
                  style: TextStyle(
                    color: estadoColor(),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          linea(Icons.person_outline, d.destinatarioNombre),
          linea(
            Icons.location_on_outlined,
            '${d.direccion}${d.distrito != null ? ' — ${d.distrito}' : ''}',
          ),
          if (d.referencia != null && d.referencia!.isNotEmpty)
            linea(Icons.info_outline, 'Ref: ${d.referencia}'),
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
              if (d.esActivo)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.blue1,
                    side: const BorderSide(color: AppColors.blue1),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    textStyle: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () => launchUrl(
                    Uri.parse(d.urlNavegacion),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.navigation_outlined, size: 15),
                  label: const Text('NAVEGAR'),
                ),
            ],
          ),
          if (accion != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accion.color,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  textStyle: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700),
                ),
                onPressed: accion.onTap,
                icon: Icon(accion.icon, size: 16),
                label: Text(accion.label),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AccionTile {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _AccionTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
