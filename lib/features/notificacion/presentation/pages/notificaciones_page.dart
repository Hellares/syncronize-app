import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_loading.dart';
import '../../../../core/widgets/notification_bell.dart';

class NotificacionesPage extends StatefulWidget {
  const NotificacionesPage({super.key});

  @override
  State<NotificacionesPage> createState() => _NotificacionesPageState();
}

class _NotificacionesPageState extends State<NotificacionesPage> {
  final List<Map<String, dynamic>> _notificaciones = [];
  int _noLeidas = 0;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  int _totalPages = 1;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadNotificaciones();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _page < _totalPages) {
      _loadMore();
    }
  }

  Future<void> _loadNotificaciones() async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 1;
      _notificaciones.clear();
    });

    await _fetchPage(1);
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _page >= _totalPages) return;
    setState(() => _loadingMore = true);
    await _fetchPage(_page + 1);
    setState(() => _loadingMore = false);
  }

  Future<void> _fetchPage(int page) async {
    try {
      final dio = locator<DioClient>();
      final response = await dio.get(
        ApiConstants.notificaciones,
        queryParameters: {'page': page, 'limit': 20},
      );

      if (!mounted) return;

      final data = response.data as Map<String, dynamic>;
      final items = (data['data'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();

      setState(() {
        _loading = false;
        _page = page;
        _totalPages = data['totalPages'] as int? ?? 1;
        _noLeidas = data['noLeidas'] as int? ?? 0;
        if (page == 1) {
          _notificaciones.clear();
        }
        _notificaciones.addAll(items);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
      debugPrint('[Notificaciones] Error loading page $page: $e');
    }
  }

  // Mejora 6: Actualización optimista
  void _marcarLeidaLocal(int index) {
    setState(() {
      _notificaciones[index]['leida'] = true;
      _notificaciones[index]['leidaEn'] = DateTime.now().toIso8601String();
      if (_noLeidas > 0) _noLeidas--;
    });
    // Actualizar campana
    NotificationBellState.refreshNotifier.value++;
  }

  Future<void> _marcarLeida(String id, int index) async {
    _marcarLeidaLocal(index);
    try {
      final dio = locator<DioClient>();
      await dio.patch('${ApiConstants.notificaciones}/$id/leida');
    } catch (e) {
      debugPrint('[Notificaciones] Error marking as read: $e');
    }
  }

  Future<void> _marcarTodasLeidas() async {
    // Optimista: marcar todas localmente
    setState(() {
      for (final n in _notificaciones) {
        n['leida'] = true;
        n['leidaEn'] = DateTime.now().toIso8601String();
      }
      _noLeidas = 0;
    });
    NotificationBellState.refreshNotifier.value++;

    try {
      final dio = locator<DioClient>();
      await dio.patch('${ApiConstants.notificaciones}/marcar-todas-leidas');
    } catch (e) {
      debugPrint('[Notificaciones] Error marking all as read: $e');
      // Revertir en caso de error
      _loadNotificaciones();
    }
  }

  void _navigateByNotification(Map<String, dynamic> notif, int index) {
    if (notif['leida'] != true) {
      _marcarLeida(notif['id'] as String, index);
    }

    final data = notif['data'] as Map<String, dynamic>?;
    final tipo = notif['tipo'] as String?;

    if (data != null) {
      final citaId = data['citaId'] as String?;
      final ordenId = data['ordenId'] as String?;

      if (citaId != null) {
        context.push('/empresa/citas/$citaId');
        return;
      }
      if (ordenId != null) {
        context.push('/empresa/ordenes/$ordenId');
        return;
      }
    }

    if (tipo == 'CITA' || tipo == 'cita') {
      context.push('/empresa/citas');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(
          title: 'Notificaciones',
          backgroundColor: AppColors.blue1,
          foregroundColor: Colors.white,
          actions: [
            if (_noLeidas > 0)
              TextButton(
                onPressed: _marcarTodasLeidas,
                child: const Text(
                  'Leer todas',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: _loadNotificaciones,
              tooltip: 'Actualizar',
            ),
          ],
        ),
        body: SafeArea(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return CustomLoading.small(message: 'Cargando notificaciones...');
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
              Text(_error!, textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loadNotificaciones,
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

    if (_notificaciones.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_none, size: 64,
                  color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text('No tienes notificaciones',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotificaciones,
      color: AppColors.blue1,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        itemCount: _notificaciones.length + (_loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _notificaciones.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(
                    color: AppColors.blue1, strokeWidth: 2),
              ),
            );
          }
          return _NotificacionCard(
            notificacion: _notificaciones[index],
            onTap: () => _navigateByNotification(_notificaciones[index], index),
          );
        },
      ),
    );
  }
}

class _NotificacionCard extends StatelessWidget {
  final Map<String, dynamic> notificacion;
  final VoidCallback onTap;

  const _NotificacionCard({required this.notificacion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final leida = notificacion['leida'] as bool? ?? false;
    final tipo = notificacion['tipo'] as String?;
    final creadoEn =
        DateTime.tryParse(notificacion['creadoEn'] as String? ?? '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GradientContainer(
        gradient: AppGradients.blueWhiteBlue(),
        borderColor: leida ? AppColors.blueborder : AppColors.blue1,
        borderWidth: leida ? 0.6 : 1.2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _tipoColor(tipo).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _tipoIcon(tipo),
                    size: 18,
                    color: _tipoColor(tipo),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppSubtitle(
                              notificacion['titulo'] as String? ?? '',
                              fontSize: 11,
                              color: leida
                                  ? Colors.grey.shade600
                                  : AppColors.blue2,
                            ),
                          ),
                          if (!leida)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.blue1,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notificacion['cuerpo'] as String? ?? '',
                        style: TextStyle(
                          fontSize: 10,
                          color: leida
                              ? Colors.grey.shade500
                              : Colors.grey.shade700,
                          fontFamily:
                              AppFonts.getFontFamily(AppFont.oxygenRegular),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (creadoEn != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          DateFormatter.formatSmart(creadoEn),
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _tipoIcon(String? tipo) {
    switch (tipo) {
      case 'CITA':
      case 'cita':
        return Icons.calendar_month;
      case 'ORDEN_SERVICIO':
      case 'orden':
        return Icons.build_outlined;
      case 'PROMOCION':
      case 'promocion':
        return Icons.local_offer;
      case 'AVISO_MANTENIMIENTO':
      case 'aviso':
        return Icons.warning_amber;
      case 'SISTEMA':
      case 'sistema':
        return Icons.info_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _tipoColor(String? tipo) {
    switch (tipo) {
      case 'CITA':
      case 'cita':
        return AppColors.blue1;
      case 'ORDEN_SERVICIO':
      case 'orden':
        return Colors.indigo;
      case 'PROMOCION':
      case 'promocion':
        return Colors.deepPurple;
      case 'AVISO_MANTENIMIENTO':
      case 'aviso':
        return Colors.orange;
      case 'SISTEMA':
      case 'sistema':
        return Colors.teal;
      default:
        return AppColors.blue1;
    }
  }
}
