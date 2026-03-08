import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../bloc/aviso_configuracion/aviso_configuracion_cubit.dart';
import '../bloc/aviso_configuracion/aviso_configuracion_state.dart';

class ConfiguracionAvisoPage extends StatefulWidget {
  const ConfiguracionAvisoPage({super.key});

  @override
  State<ConfiguracionAvisoPage> createState() => _ConfiguracionAvisoPageState();
}

class _ConfiguracionAvisoPageState extends State<ConfiguracionAvisoPage> {
  late bool _habilitado;
  late int _diasAnticipacion;
  late Map<String, int> _intervalos;

  final _diasCtrl = TextEditingController();
  bool _initialized = false;

  static const _tiposServicio = [
    ('MANTENIMIENTO', 'Mantenimiento'),
    ('REPARACION', 'Reparación'),
    ('INSTALACION', 'Instalación'),
    ('LIMPIEZA', 'Limpieza'),
    ('ACTUALIZACION', 'Actualización'),
    ('CONFIGURACION', 'Configuración'),
    ('DIAGNOSTICO', 'Diagnóstico'),
    ('RECUPERACION_DATOS', 'Recup. datos'),
    ('SOPORTE', 'Soporte'),
    ('CONSULTORIA', 'Consultoría'),
    ('FORMACION', 'Formación'),
  ];

  @override
  void initState() {
    super.initState();
    context.read<AvisoConfiguracionCubit>().loadConfiguracion();
  }

  @override
  void dispose() {
    _diasCtrl.dispose();
    super.dispose();
  }

  void _initFromState(AvisoConfiguracionLoaded state) {
    if (_initialized) return;
    _initialized = true;
    _habilitado = state.configuracion.habilitado;
    _diasAnticipacion = state.configuracion.diasAnticipacion;
    _intervalos = Map.from(state.configuracion.intervalos);
    _diasCtrl.text = '$_diasAnticipacion';
  }

  Future<void> _guardar() async {
    final success = await context.read<AvisoConfiguracionCubit>().guardar(
      intervalos: _intervalos,
      diasAnticipacion: _diasAnticipacion,
      habilitado: _habilitado,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuración guardada'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(title: 'Configuración de Avisos'),
        body: BlocConsumer<AvisoConfiguracionCubit, AvisoConfiguracionState>(
          listener: (context, state) {
            if (state is AvisoConfiguracionError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.red),
              );
            }
          },
          builder: (context, state) {
            if (state is AvisoConfiguracionLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is AvisoConfiguracionLoaded) {
              _initFromState(state);
              return _buildForm(isSaving: false);
            }

            if (state is AvisoConfiguracionSaving) {
              return _buildForm(isSaving: true);
            }

            if (state is AvisoConfiguracionError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.message, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => context.read<AvisoConfiguracionCubit>().loadConfiguracion(),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildForm({required bool isSaving}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle habilitado
          GradientContainer(
            borderColor: AppColors.blueborder,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Avisos habilitados',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(
                          'El sistema generará avisos automáticos de mantenimiento preventivo',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _habilitado,
                    onChanged: (v) => setState(() => _habilitado = v),
                    activeColor: AppColors.blue1,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Días de anticipación
          GradientContainer(
            borderColor: AppColors.blueborder,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 16, color: AppColors.blue1),
                      const SizedBox(width: 8),
                      AppSubtitle('ANTICIPACIÓN', fontSize: 12),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Días antes de la fecha recomendada para generar el aviso',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _diasCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Días de anticipación',
                      suffixText: 'días',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.blue1),
                      ),
                    ),
                    onChanged: (v) {
                      final val = int.tryParse(v);
                      if (val != null && val > 0) _diasAnticipacion = val;
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Intervalos por tipo de servicio
          GradientContainer(
            borderColor: AppColors.blueborder,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule_outlined, size: 16, color: AppColors.blue1),
                      const SizedBox(width: 8),
                      AppSubtitle('INTERVALOS POR TIPO DE SERVICIO', fontSize: 12),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Días después del servicio para recomendar el siguiente',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  ..._tiposServicio.map((entry) {
                    final key = entry.$1;
                    final label = entry.$2;
                    final dias = _intervalos[key] ?? 0;
                    return _buildIntervaloRow(key, label, dias);
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Guardar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isSaving ? null : _guardar,
              icon: isSaving
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_outlined, size: 18),
              label: Text(isSaving ? 'Guardando...' : 'Guardar configuración'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue1,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildIntervaloRow(String key, String label, int dias) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: TextFormField(
              initialValue: dias > 0 ? '$dias' : '',
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '0 = desactivado',
                suffixText: 'días',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppColors.blue1),
                ),
              ),
              style: const TextStyle(fontSize: 12),
              onChanged: (v) {
                final val = int.tryParse(v) ?? 0;
                setState(() {
                  if (val > 0) {
                    _intervalos[key] = val;
                  } else {
                    _intervalos.remove(key);
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
