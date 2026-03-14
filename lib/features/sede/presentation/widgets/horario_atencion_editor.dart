import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';

/// Editor de horarios de atención por día de la semana.
/// Formato: {"lunes": {"inicio": "09:00", "fin": "18:00"}, ...}
class HorarioAtencionEditor extends StatefulWidget {
  final Map<String, dynamic>? horarioInicial;
  final ValueChanged<Map<String, dynamic>> onChanged;

  const HorarioAtencionEditor({
    super.key,
    this.horarioInicial,
    required this.onChanged,
  });

  @override
  State<HorarioAtencionEditor> createState() => _HorarioAtencionEditorState();
}

class _HorarioAtencionEditorState extends State<HorarioAtencionEditor> {
  static const _dias = [
    'lunes',
    'martes',
    'miercoles',
    'jueves',
    'viernes',
    'sabado',
    'domingo',
  ];

  static const _diasLabels = {
    'lunes': 'Lunes',
    'martes': 'Martes',
    'miercoles': 'Miércoles',
    'jueves': 'Jueves',
    'viernes': 'Viernes',
    'sabado': 'Sábado',
    'domingo': 'Domingo',
  };

  late final Map<String, bool> _activo;
  late final Map<String, String> _inicio;
  late final Map<String, String> _fin;

  @override
  void initState() {
    super.initState();
    _activo = {};
    _inicio = {};
    _fin = {};

    for (final dia in _dias) {
      final horario = widget.horarioInicial?[dia];
      if (horario != null && horario is Map) {
        _activo[dia] = true;
        _inicio[dia] = horario['inicio'] as String? ?? '09:00';
        _fin[dia] = horario['fin'] as String? ?? '18:00';
      } else {
        _activo[dia] = false;
        _inicio[dia] = '09:00';
        _fin[dia] = '18:00';
      }
    }
  }

  void _emitChange() {
    final result = <String, dynamic>{};
    for (final dia in _dias) {
      if (_activo[dia] == true) {
        result[dia] = {
          'inicio': _inicio[dia],
          'fin': _fin[dia],
        };
      }
    }
    widget.onChanged(result);
  }

  Future<String?> _pickTime(BuildContext context, String currentTime) async {
    final parts = currentTime.split(':');
    final initial = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked == null) return null;
    return '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
  }

  void _applyToAll(String dia) {
    setState(() {
      for (final d in _dias) {
        _activo[d] = _activo[dia]!;
        _inicio[d] = _inicio[dia]!;
        _fin[d] = _fin[dia]!;
      }
    });
    _emitChange();
  }

  void _applyWeekdays(String dia) {
    setState(() {
      for (final d in ['lunes', 'martes', 'miercoles', 'jueves', 'viernes']) {
        _activo[d] = _activo[dia]!;
        _inicio[d] = _inicio[dia]!;
        _fin[d] = _fin[dia]!;
      }
    });
    _emitChange();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const AppSubtitle('Horario de Atención'),
            const Spacer(),
            // Botón copiar Lun a L-V
            InkWell(
              onTap: () => _applyWeekdays('lunes'),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bluechip,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.copy, size: 12, color: AppColors.blue1),
                    SizedBox(width: 4),
                    Text('Lun→L-V',
                        style: TextStyle(
                            fontSize: 9,
                            color: AppColors.blue1,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: () => _applyToAll('lunes'),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bluechip,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.copy_all, size: 12, color: AppColors.blue1),
                    SizedBox(width: 4),
                    Text('Todos',
                        style: TextStyle(
                            fontSize: 9,
                            color: AppColors.blue1,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Configure los días y horarios en que la sede atiende',
          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 12),

        ..._dias.map((dia) => _buildDiaRow(dia)),
      ],
    );
  }

  Widget _buildDiaRow(String dia) {
    final activo = _activo[dia] ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GradientContainer(
        gradient: AppGradients.blueWhiteBlue(),
        borderColor: activo ? AppColors.blue1.withValues(alpha: 0.4) : AppColors.blueborder,
        borderWidth: 0.6,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              // Checkbox + Día
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: activo,
                  onChanged: (v) {
                    setState(() => _activo[dia] = v ?? false);
                    _emitChange();
                  },
                  activeColor: AppColors.blue1,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 72,
                child: Text(
                  _diasLabels[dia]!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: activo ? FontWeight.w600 : FontWeight.w400,
                    color: activo ? AppColors.blue2 : Colors.grey.shade400,
                    fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                  ),
                ),
              ),

              if (activo) ...[
                // Hora inicio
                _buildTimePicker(dia, true),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text('—',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade400)),
                ),
                // Hora fin
                _buildTimePicker(dia, false),
              ] else
                Text(
                  'Cerrado',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade400,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimePicker(String dia, bool esInicio) {
    final hora = esInicio ? _inicio[dia]! : _fin[dia]!;
    return InkWell(
      onTap: () async {
        final picked = await _pickTime(context, hora);
        if (picked != null) {
          setState(() {
            if (esInicio) {
              _inicio[dia] = picked;
            } else {
              _fin[dia] = picked;
            }
          });
          _emitChange();
        }
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.blue1.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: AppColors.blue1.withValues(alpha: 0.2),
            width: 0.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time, size: 12, color: AppColors.blue1),
            const SizedBox(width: 4),
            Text(
              hora,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.blue1,
                fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
