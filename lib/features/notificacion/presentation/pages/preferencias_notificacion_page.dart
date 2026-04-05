import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_loading.dart';

class PreferenciasNotificacionPage extends StatefulWidget {
  const PreferenciasNotificacionPage({super.key});

  @override
  State<PreferenciasNotificacionPage> createState() =>
      _PreferenciasNotificacionPageState();
}

class _PreferenciasNotificacionPageState
    extends State<PreferenciasNotificacionPage> {
  List<_PreferenciaTipo> _preferencias = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPreferencias();
  }

  Future<void> _loadPreferencias() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final dio = locator<DioClient>();
      final response = await dio.get(
        '${ApiConstants.notificaciones}/preferencias',
      );

      if (!mounted) return;

      final list = response.data as List;
      setState(() {
        _loading = false;
        _preferencias = list
            .map((e) => _PreferenciaTipo.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
      debugPrint('[Preferencias] Error loading: $e');
    }
  }

  Future<void> _togglePreferencia(_PreferenciaTipo pref) async {
    final nuevoValor = !pref.habilitado;

    // Optimista
    setState(() => pref.habilitado = nuevoValor);

    try {
      final dio = locator<DioClient>();
      await dio.patch(
        '${ApiConstants.notificaciones}/preferencias/${pref.tipo}',
        data: {'habilitado': nuevoValor},
      );
    } catch (e) {
      // Revertir
      if (mounted) setState(() => pref.habilitado = !nuevoValor);
      debugPrint('[Preferencias] Error toggling ${pref.tipo}: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al actualizar preferencia'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(
          title: 'Preferencias de Notificaciones',
          backgroundColor: AppColors.blue1,
          foregroundColor: Colors.white,
        ),
        body: SafeArea(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return CustomLoading.small(message: 'Cargando preferencias...');
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
                onPressed: _loadPreferencias,
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

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // Info
        GradientContainer(
          gradient: AppGradients.blueWhiteBlue(),
          borderColor: AppColors.blueborder,
          borderWidth: 0.6,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.blue1),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Elige qué tipos de notificaciones push quieres recibir en tu dispositivo. Las notificaciones desactivadas no se enviarán.',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Lista de preferencias
        ..._preferencias.map((pref) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GradientContainer(
                gradient: AppGradients.blueWhiteBlue(),
                borderColor: pref.habilitado
                    ? AppColors.blue1.withValues(alpha: 0.3)
                    : AppColors.blueborder,
                borderWidth: 0.6,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _tipoColor(pref.tipo).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _tipoIcon(pref.tipo),
                          size: 18,
                          color: _tipoColor(pref.tipo),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppSubtitle(
                              _tipoLabel(pref.tipo),
                              fontSize: 12,
                              color: AppColors.blue2,
                            ),
                            Text(
                              _tipoDescription(pref.tipo),
                              style: TextStyle(
                                  fontSize: 9, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: pref.habilitado,
                        onChanged: (_) => _togglePreferencia(pref),
                        activeColor: AppColors.blue1,
                      ),
                    ],
                  ),
                ),
              ),
            )),
      ],
    );
  }

  String _tipoLabel(String tipo) {
    switch (tipo) {
      case 'CITA':
        return 'Citas';
      case 'ORDEN_SERVICIO':
        return 'Órdenes de servicio';
      case 'PROMOCION':
        return 'Promociones';
      case 'AVISO_MANTENIMIENTO':
        return 'Avisos de mantenimiento';
      case 'SISTEMA':
        return 'Sistema';
      default:
        return tipo;
    }
  }

  String _tipoDescription(String tipo) {
    switch (tipo) {
      case 'CITA':
        return 'Nuevas citas, confirmaciones y cambios de estado';
      case 'ORDEN_SERVICIO':
        return 'Creación y actualizaciones de órdenes de servicio';
      case 'PROMOCION':
        return 'Ofertas, descuentos y novedades de productos';
      case 'AVISO_MANTENIMIENTO':
        return 'Recordatorios de mantenimiento programado';
      case 'SISTEMA':
        return 'Actualizaciones del sistema y anuncios importantes';
      default:
        return '';
    }
  }

  IconData _tipoIcon(String tipo) {
    switch (tipo) {
      case 'CITA':
        return Icons.calendar_month;
      case 'ORDEN_SERVICIO':
        return Icons.build_outlined;
      case 'PROMOCION':
        return Icons.local_offer;
      case 'AVISO_MANTENIMIENTO':
        return Icons.warning_amber;
      case 'SISTEMA':
        return Icons.info_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _tipoColor(String tipo) {
    switch (tipo) {
      case 'CITA':
        return AppColors.blue1;
      case 'ORDEN_SERVICIO':
        return Colors.indigo;
      case 'PROMOCION':
        return Colors.deepPurple;
      case 'AVISO_MANTENIMIENTO':
        return Colors.orange;
      case 'SISTEMA':
        return Colors.teal;
      default:
        return AppColors.blue1;
    }
  }
}

class _PreferenciaTipo {
  final String tipo;
  bool habilitado;

  _PreferenciaTipo({required this.tipo, required this.habilitado});

  factory _PreferenciaTipo.fromJson(Map<String, dynamic> json) {
    return _PreferenciaTipo(
      tipo: json['tipo'] as String,
      habilitado: json['habilitado'] as bool? ?? true,
    );
  }
}
