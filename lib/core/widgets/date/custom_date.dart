import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/widgets/date/custom_time.dart';
import '../../../../../core/theme/app_colors.dart';


// Enum para tipos de fecha - ACTUALIZADO
enum DateFieldType {
  date, // Fecha simple
  dateTime, // Fecha y hora
  time, // Solo hora ESTE ES PARA SOLO HORA
  dateRange, // RANGO DE FECHAS
}

// ENUM PARA MODO DE ENTRADA
enum DateInputMode {
  picker, // Solo picker (por defecto)
  manual, // Solo entrada manual
}

// ENUM PARA INCLUIR HORA
enum TimeMode {
  none, // Solo fecha (por defecto)
  hourMinute, // Incluir hora y minutos (HH:mm:00)
}

// CLASE PARA MANEJAR RANGOS DE FECHAS
class DateRange {
  final DateTime? startDate;
  final DateTime? endDate;

  const DateRange({this.startDate, this.endDate});

  bool get isComplete => startDate != null && endDate != null;
  bool get isEmpty => startDate == null && endDate == null;

  Duration? get duration => isComplete ? endDate!.difference(startDate!) : null;

  int? get daysDifference => duration != null ? duration!.inDays + 1 : null;

  @override
  String toString() {
    if (isEmpty) return '';
    if (startDate != null && endDate != null) {
      return '${_formatDate(startDate!)} - ${_formatDate(endDate!)}';
    }
    if (startDate != null) {
      return 'Desde: ${_formatDate(startDate!)}';
    }
    return 'Hasta: ${_formatDate(endDate!)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  DateRange copyWith({DateTime? startDate, DateTime? endDate}) {
    return DateRange(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

// Formateador personalizado para fechas - MEJORADO Y SIMPLIFICADO
class DateFormatter extends TextInputFormatter {
  final String format;
  final bool includeTime;

  DateFormatter({this.format = 'dd/MM/yyyy', this.includeTime = false});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cleanText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    String formattedText;

    if (includeTime) {
      // Limita la longitud a 12 dígitos (ddMMyyyyHHmm o yyyyMMddHHmm)
      final text =
          cleanText.length > 12 ? cleanText.substring(0, 12) : cleanText;

      final dateText = text.length > 8 ? text.substring(0, 8) : text;
      final timeText = text.length > 8 ? text.substring(8) : '';

      // Formatea la parte de la fecha respetando format
      final formattedDate = (format == 'yyyy-MM-dd')
          ? _formatUsing(dateText, [4, 2, 2], ['-', '-'])
          : _formatUsing(dateText, [2, 2, 4], ['/', '/']);

      // Formatea la parte de la hora (HH:mm)
      final formattedTime = _formatUsing(timeText, [2, 2], [':']);

      formattedText = formattedDate;

      if (timeText.isNotEmpty) {
        formattedText += ' $formattedTime';
        // Agrega los segundos fijos si se ha introducido la hora (al menos HH)
        if (timeText.length >= 2) {
          formattedText += ':00';
        }
      }
    } else {
      // Limita la longitud a 8 dígitos (ddMMyyyy, MMddyyyy, yyyyMMdd)
      final text = cleanText.length > 8 ? cleanText.substring(0, 8) : cleanText;

      // Respeta el formato
      if (format == 'yyyy-MM-dd') {
        formattedText = _formatUsing(text, [4, 2, 2], ['-', '-']);
      } else {
        // dd/MM/yyyy o MM/dd/yyyy (misma máscara, cambia semántica en validador)
        formattedText = _formatUsing(text, [2, 2, 4], ['/', '/']);
      }
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }

  /// Ayudante para formatear una cadena de dígitos según un patrón.
  ///
  /// [text]: La cadena de dígitos a formatear.
  /// [segments]: Una lista de longitudes para cada parte de la fecha/hora.
  /// [separators]: Los separadores a insertar entre los segmentos.
  String _formatUsing(
    String text,
    List<int> segments,
    List<String> separators,
  ) {
    String result = '';
    int textIndex = 0;

    for (int i = 0; i < segments.length; i++) {
      if (textIndex >= text.length) break;

      final segmentLength = segments[i];
      final segmentEnd = (textIndex + segmentLength).clamp(0, text.length);
      final segment = text.substring(textIndex, segmentEnd);
      result += segment;
      textIndex += segment.length;

      // Agrega un separador si el segmento está completo y no es el último.
      if (segment.length == segmentLength && i < separators.length) {
        result += separators[i];
      }
    }
    return result;
  }
}

// Validador de fechas
class DateValidator {
  static String? validateDate(String? value, {String format = 'dd/MM/yyyy'}) {
    if (value == null || value.isEmpty) return 'Campo requerido';

    try {
      late int day;
      late int month;
      late int year;

      if (format == 'dd/MM/yyyy') {
        final r = RegExp(r'^\d{2}/\d{2}/\d{4}$');
        if (!r.hasMatch(value)) return 'Formato: dd/MM/yyyy';
        final parts = value.split('/');
        day = int.parse(parts[0]);
        month = int.parse(parts[1]);
        year = int.parse(parts[2]);
      } else if (format == 'MM/dd/yyyy') {
        final r = RegExp(r'^\d{2}/\d{2}/\d{4}$');
        if (!r.hasMatch(value)) return 'Formato: MM/dd/yyyy';
        final parts = value.split('/');
        month = int.parse(parts[0]);
        day = int.parse(parts[1]);
        year = int.parse(parts[2]);
      } else if (format == 'yyyy-MM-dd') {
        final r = RegExp(r'^\d{4}-\d{2}-\d{2}$');
        if (!r.hasMatch(value)) return 'Formato: yyyy-MM-dd';
        final parts = value.split('-');
        year = int.parse(parts[0]);
        month = int.parse(parts[1]);
        day = int.parse(parts[2]);
      } else {
        return 'Formato no soportado';
      }

      if (year < 1900 || year > 2100) return 'Año inválido';
      if (month < 1 || month > 12) return 'Mes inválido';
      if (day < 1 || day > 31) return 'Día inválido';

      final date = DateTime(year, month, day);
      if (date.day != day || date.month != month || date.year != year) {
        return 'Fecha inválida';
      }
    } catch (_) {
      return 'Fecha inválida';
    }

    return null;
  }

  // ✅ VALIDADOR PARA TIEMPO (HH:mm o HH:mm:ss)
  static String? validateTime(String? value, {bool isRequired = true}) {
    if (value == null || value.isEmpty) {
      return isRequired ? 'Hora requerida' : null;
    }

    final timeRegex = RegExp(r'^\d{2}:\d{2}(:\d{2})?$');
    if (!timeRegex.hasMatch(value)) return 'Formato: HH:mm';

    try {
      final parts = value.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final second = parts.length == 3 ? int.parse(parts[2]) : 0;

      if (hour < 0 || hour > 23) return 'Hora inválida (0-23)';
      if (minute < 0 || minute > 59) return 'Minutos inválidos (0-59)';
      if (second < 0 || second > 59) return 'Segundos inválidos (0-59)';
    } catch (_) {
      return 'Hora inválida';
    }

    return null;
  }

  // VALIDADOR PARA RANGOS
  static String? validateDateRange(DateRange? range, {bool isRequired = true}) {
    if (range == null || range.isEmpty) {
      return isRequired ? 'Selecciona un rango de fechas' : null;
    }

    if (range.startDate != null && range.endDate != null) {
      if (range.endDate!.isBefore(range.startDate!)) {
        return 'La fecha final debe ser posterior a la inicial';
      }
    }

    return null;
  }
}

class CustomDate extends StatefulWidget {
  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(DateTime?)? onDateSelected;
  final void Function(String)? onChanged;
  final bool enabled;
  final Color backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? textStyle;
  final TextStyle? labelStyle;
  final TextStyle? hintStyle;
  final bool filled;
  final FocusNode? focusNode;
  final double? height;

  // Propiedades específicas de fecha
  final DateFieldType dateType;
  final String dateFormat;
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final DateInputMode inputMode;
  final TimeMode timeMode;
  final String? suffixText;

  // Propiedades de rango
  final DateRange? initialDateRange;
  final void Function(DateRange?)? onDateRangeSelected;
  final String? Function(DateRange?)? rangeValidator;
  final int? maxRangeDays;
  final int? minRangeDays;
  final bool allowSameDay;
  final double? borderWidth;

  const CustomDate({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.validator,
    this.onDateSelected,
    this.onChanged,
    this.enabled = true,
    this.backgroundColor = AppColors.white,
    this.borderColor,
    this.borderRadius = 6.0,
    this.contentPadding,
    this.textStyle,
    this.labelStyle,
    this.hintStyle,
    this.filled = true,
    this.focusNode,
    this.height = 33,
    // Propiedades de fecha
    this.dateType = DateFieldType.date,
    this.dateFormat = 'dd/MM/yyyy',
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.inputMode = DateInputMode.picker,
    this.timeMode = TimeMode.none,
    this.suffixText,
    // Propiedades de rango
    this.initialDateRange,
    this.onDateRangeSelected,
    this.rangeValidator,
    this.maxRangeDays,
    this.minRangeDays,
    this.allowSameDay = true,
    this.borderWidth = 0.5,
  }) : assert(
          !(dateType == DateFieldType.time && timeMode != TimeMode.none),
          'DateFieldType.time no debe usarse con TimeMode distinto de none',
        );

  @override
  State<CustomDate> createState() => _CustomDateState();
}

class _CustomDateState extends State<CustomDate>
    with SingleTickerProviderStateMixin {
  bool _isFocused = false;
  bool _hasText = false;
  DateTime? _selectedDate;
  DateRange? _selectedRange;

  // variables para hora y minuto seleccionados
  int? _selectedHour;
  int? _selectedMinute;

  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _shadowAnimation;
  late Animation<double> _scaleAnimation;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    _controller = widget.controller ?? TextEditingController();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _shadowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);

    if (widget.dateType == DateFieldType.dateRange) {
      _selectedRange = widget.initialDateRange ?? const DateRange();
      _updateControllerFromRange();
    } else if (widget.dateType == DateFieldType.time) {
      final now = DateTime.now();
      final initialTime =
          widget.initialDate ?? now; // Usa initialDate si se proporciona

      _selectedDate = initialTime;
      _selectedHour = initialTime.hour;
      _selectedMinute = initialTime.minute;
      _controller.text = _formatTimeOnly(_selectedHour!, _selectedMinute!);

      // Solo notificar si no había initialDate (se usó hora actual automáticamente)
      if (widget.initialDate == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onDateSelected?.call(_selectedDate);
        });
      }
    } else {
      if (widget.initialDate != null) {
        _selectedDate = widget.initialDate;
        _selectedHour = widget.initialDate?.hour;
        _selectedMinute = widget.initialDate?.minute;
        _controller.text = _formatDate(_selectedDate!);
      }
    }
  }

  @override
  void didUpdateWidget(CustomDate oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Actualizar cuando cambie initialDate
    if (widget.dateType == DateFieldType.dateRange) {
      if (widget.initialDateRange != oldWidget.initialDateRange) {
        _selectedRange = widget.initialDateRange ?? const DateRange();
        // Actualizar sin disparar listeners
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _updateControllerFromRange();
          }
        });
      }
    } else if (widget.dateType == DateFieldType.time) {
      if (widget.initialDate != oldWidget.initialDate) {
        _selectedDate = widget.initialDate;
        _selectedHour = widget.initialDate?.hour;
        _selectedMinute = widget.initialDate?.minute;
        // Actualizar el controller sin disparar listeners
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            if (widget.initialDate != null) {
              _controller.text = _formatTimeOnly(_selectedHour!, _selectedMinute!);
            } else {
              _controller.clear();
            }
          }
        });
      }
    } else {
      // Para DateFieldType.date y DateFieldType.dateTime
      if (widget.initialDate != oldWidget.initialDate) {
        _selectedDate = widget.initialDate;
        _selectedHour = widget.initialDate?.hour;
        _selectedMinute = widget.initialDate?.minute;
        // Actualizar el controller sin disparar listeners
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            if (widget.initialDate != null) {
              _controller.text = _formatDate(_selectedDate!);
            } else {
              _controller.clear();
            }
          }
        });
      }
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.removeListener(_onFocusChange);
      _focusNode.dispose();
    }
    if (widget.controller == null) {
      _controller.removeListener(_onTextChanged);
      _controller.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });

    if (_isFocused) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }

    // ✅ ÚNICA fuente de onChanged (evita duplicados)
    widget.onChanged?.call(_controller.text);
  }

  // ACTUALIZAR CONTROLLER DESDE RANGO
  void _updateControllerFromRange() {
    if (_selectedRange != null) {
      _controller.text = _selectedRange.toString();
    } else {
      _controller.text = '';
    }
  }

  // Formatear solo hora
  String _formatTimeOnly(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:00';
  }

  String _formatDate(DateTime date) {
    if (widget.dateType == DateFieldType.time) {
      return _formatTimeOnly(date.hour, date.minute);
    }

    String dateStr;
    switch (widget.dateFormat) {
      case 'dd/MM/yyyy':
        dateStr =
            '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
        break;
      case 'MM/dd/yyyy':
        dateStr =
            '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
        break;
      case 'yyyy-MM-dd':
        dateStr =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        break;
      default:
        dateStr =
            '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }

    // agregar hora si el modo de tiempo está activado (para otros tipos)
    if (widget.timeMode == TimeMode.hourMinute &&
        widget.dateType != DateFieldType.time) {
      final String timeStr =
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:00';
      dateStr += ' $timeStr';
    }

    return dateStr;
  }

  // MOSTRAR PICKER SEGÚN TIPO
  Future<void> _showDatePickerDialog() async {
    if (!widget.enabled) return;

    HapticFeedback.lightImpact();

    try {
      if (widget.dateType == DateFieldType.time) {
        await _showTimeOnlyPicker();
      } else if (widget.dateType == DateFieldType.dateRange) {
        await _showDateRangePicker();
      } else {
        await _showSingleDatePicker();
      }
    } catch (e) {
      debugPrint('Error showing picker: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al abrir selector'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Picker solo para hora
  Future<void> _showTimeOnlyPicker() async {
    final now = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => TimeScrollPicker(
        initialHour: _selectedDate?.hour ?? now.hour,
        initialMinute: _selectedDate?.minute ?? now.minute,
        primaryColor: widget.borderColor ?? AppColors.blue,
        onTimeSelected: (hour, minute) {
          final selectedTime = DateTime(
            2000,
            1,
            1,
            hour,
            minute,
          );

          setState(() {
            _selectedDate = selectedTime;
            _selectedHour = hour;
            _selectedMinute = minute;
            _controller.text = _formatTimeOnly(hour, minute);
          });

          widget.onDateSelected?.call(selectedTime);
        },
      ),
    );
  }

  // PICKER DE FECHA SIMPLE (sin selector de hora)
  Future<void> _showSingleDatePicker() async {
    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => _ModernDatePickerDialog(
        initialDate: _selectedDate ?? widget.initialDate ?? DateTime.now(),
        firstDate: widget.firstDate ?? DateTime(1900),
        lastDate: widget.lastDate ?? DateTime(2100),
        primaryColor: widget.borderColor ?? AppColors.blue,
        includeTime: false,
      ),
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
        if (widget.timeMode == TimeMode.hourMinute &&
            _selectedHour != null &&
            _selectedMinute != null) {
          _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            _selectedHour!,
            _selectedMinute!,
            0,
          );
        }
        _controller.text = _formatDate(_selectedDate!);
      });

      widget.onDateSelected?.call(_selectedDate);
    }
  }

  // PICKER DE RANGO DE FECHAS
  Future<void> _showDateRangePicker() async {
    final DateRange? picked = await showDialog<DateRange>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => _ModernDateRangePickerDialog(
        initialRange: _selectedRange ?? const DateRange(),
        firstDate: widget.firstDate ?? DateTime(1900),
        lastDate: widget.lastDate ?? DateTime(2100),
        primaryColor: widget.borderColor ?? AppColors.blue,
        maxRangeDays: widget.maxRangeDays,
        minRangeDays: widget.minRangeDays,
        allowSameDay: widget.allowSameDay,
      ),
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedRange = picked;
        _updateControllerFromRange();
      });

      widget.onDateRangeSelected?.call(picked);
    }
  }

  // método para mostrar el selector de hora
  Future<void> _showHourPickerDialog() async {
    final now = DateTime.now();
    showDialog(
      context: context,
      builder: (context) => TimeScrollPicker(
        initialHour: _selectedDate?.hour ?? now.hour,
        initialMinute: _selectedDate?.minute ?? now.minute,
        primaryColor: _getBorderColor(),
        onTimeSelected: (hour, minute) {
          final selectedDateTime = DateTime(
            _selectedDate?.year ?? now.year,
            _selectedDate?.month ?? now.month,
            _selectedDate?.day ?? now.day,
            hour,
            minute,
          );

          setState(() {
            _selectedDate = selectedDateTime;
            _selectedHour = hour;
            _selectedMinute = minute;
            if (_selectedDate != null) {
              _controller.text = _formatDate(_selectedDate!);
            }
          });

          widget.onDateSelected?.call(selectedDateTime);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: widget.labelStyle ??
                TextStyle(
                  fontSize: 9,
                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                  color: AppColors.blue1,
                ),
          ),
          // const SizedBox(height: 2),
        ],
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                height: widget.height,
                decoration: BoxDecoration(
                  color:
                      widget.filled ? widget.backgroundColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  boxShadow: widget.filled ? _buildShadows() : null,
                  border: Border.all(
                    color: _getBorderColor(),
                    width: widget.borderWidth ?? 0.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  child: TextFormField(
                    controller: _controller,
                    focusNode: _focusNode,
                    keyboardType: widget.inputMode == DateInputMode.manual
                        ? TextInputType.datetime
                        : TextInputType.none,
                    enabled: widget.enabled,
                    readOnly: widget.inputMode == DateInputMode.picker ||
                        widget.dateType == DateFieldType.dateRange ||
                        widget.dateType == DateFieldType.time,
                    inputFormatters: widget.inputMode == DateInputMode.manual &&
                            widget.dateType != DateFieldType.dateRange &&
                            widget.dateType != DateFieldType.time
                        ? [
                            DateFormatter(
                              format: widget.dateFormat,
                              includeTime: widget.timeMode == TimeMode.hourMinute,
                            ),
                          ]
                        : null,
                    textAlignVertical: TextAlignVertical.center,
                    onTap: () {
                      if (widget.inputMode == DateInputMode.picker ||
                          widget.dateType == DateFieldType.dateRange ||
                          widget.dateType == DateFieldType.time) {
                        _showDatePickerDialog();
                      }
                    },

                    // ✅ QUITADO para evitar duplicados (ya se dispara desde _onTextChanged)
                    onChanged: null,

                    validator: _getValidator(),
                    style: widget.textStyle ??
                        TextStyle(
                          color: widget.enabled ? AppColors.blue2 : Colors.grey[600],
                          fontSize: 10,
                          fontFamily:
                              AppFonts.getFontFamily(AppFont.oxygenBold),
                        ),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: widget.hintText ?? _getHintByFormat(),
                      // prefixIcon: _buildPrefixIcon(),
                      // prefixIconConstraints: const BoxConstraints(
                      //   minWidth: 28,
                      //   minHeight: 35,
                      // ),
                      suffixIcon: _buildSuffixIcon(),
                      suffixText: widget.suffixText,
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      contentPadding:
                          widget.contentPadding ?? _getDefaultContentPadding(),
                      hintStyle: widget.hintStyle ??
                          TextStyle(
                            color: Colors.grey[500],
                            fontSize: 10,
                            fontFamily:
                                AppFonts.getFontFamily(AppFont.oxygenRegular),
                            height: 1.2,
                          ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.dateType == DateFieldType.dateRange &&
            _selectedRange != null &&
            _selectedRange!.isComplete) ...[
          const SizedBox(height: 4),
          Text(
            '${_selectedRange!.daysDifference!} días seleccionados',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ],
    );
  }

  String? Function(String?)? _getValidator() {
    if (widget.dateType == DateFieldType.dateRange) {
      return (value) =>
          widget.rangeValidator?.call(_selectedRange) ??
          DateValidator.validateDateRange(_selectedRange);
    } else if (widget.dateType == DateFieldType.time) {
      return widget.validator ?? (value) => DateValidator.validateTime(value);
    } else {
      return widget.validator ??
          (value) =>
              DateValidator.validateDate(value, format: widget.dateFormat);
    }
  }

  String _getHintByFormat() {
    if (widget.dateType == DateFieldType.time) {
      return 'Seleccionar hora';
    }

    if (widget.dateType == DateFieldType.dateRange) {
      return 'Seleccionar rango de fechas';
    }

    if (widget.inputMode == DateInputMode.picker) {
      return widget.timeMode == TimeMode.hourMinute
          ? 'Seleccionar fecha y hora'
          : 'Seleccionar fecha';
    }

    String dateHint;
    switch (widget.dateFormat) {
      case 'dd/MM/yyyy':
        dateHint = 'dd/mm/aaaa';
        break;
      case 'MM/dd/yyyy':
        dateHint = 'mm/dd/aaaa';
        break;
      case 'yyyy-MM-dd':
        dateHint = 'aaaa-mm-dd';
        break;
      default:
        dateHint = 'dd/mm/aaaa';
    }

    if (widget.timeMode == TimeMode.hourMinute) {
      dateHint += ' HH:mm:00';
    }

    return dateHint;
  }

  // Widget _buildPrefixIcon() {
  //   IconData icon;
  //   switch (widget.dateType) {
  //     case DateFieldType.date:
  //       icon = Icons.calendar_today_outlined;
  //       break;
  //     case DateFieldType.dateTime:
  //       icon = Icons.schedule_outlined;
  //       break;
  //     case DateFieldType.time:
  //       icon = Icons.access_time_outlined;
  //       break;
  //     case DateFieldType.dateRange:
  //       icon = Icons.date_range_outlined;
  //       break;
  //   }

  //   return Container(
  //     margin: const EdgeInsets.symmetric(horizontal: 4),
  //     child: IconTheme(
  //       data: IconThemeData(
  //         color: _isFocused ? const Color(0xFF666666) : Colors.grey[600],
  //         size: 16,
  //       ),
  //       child: Icon(icon),
  //     ),
  //   );
  // }

  Widget? _buildSuffixIcon() {
    if (widget.inputMode != DateInputMode.picker) return null;

    if (widget.dateType == DateFieldType.time) {
      return IconButton(
        icon: const Icon(Icons.access_time_outlined),
        onPressed: widget.enabled ? _showTimeOnlyPicker : null,
        color: _isFocused ? const Color(0xFF666666) : Colors.grey[600],
        iconSize: 16,
        splashRadius: 16,
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        tooltip: 'Seleccionar hora',
      );
    }

    List<Widget> icons = [
      IconButton(
        icon: Icon(
          widget.dateType == DateFieldType.dateRange
              ? Icons.calendar_month_outlined
              : Icons.calendar_month_outlined,
        ),
        onPressed: widget.enabled ? _showDatePickerDialog : null,
        color: _isFocused ? const Color(0xFF666666) : Colors.grey[600],
        iconSize: 18,
        splashRadius: 16,
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        tooltip: widget.dateType == DateFieldType.dateRange
            ? 'Seleccionar rango'
            : 'Seleccionar fecha',
      ),
    ];

    if (widget.timeMode == TimeMode.hourMinute) {
      icons.add(
        IconButton(
          icon: const Icon(Icons.access_time_outlined),
          onPressed: widget.enabled ? _showHourPickerDialog : null,
          color: _isFocused ? const Color(0xFF666666) : Colors.grey[600],
          iconSize: 20,
          splashRadius: 16,
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          tooltip: 'Seleccionar hora',
        ),
      );
    }

    if (icons.length == 1) {
      return Row(mainAxisSize: MainAxisSize.min, children: icons);
    } else {
      return SizedBox(
        width: 55,
        height: 40,
        child: Stack(
          children: [
            Positioned(right: 22, top: -5, child: icons[0]),
            Positioned(right: -6, top: -5, child: icons[1]),
          ],
        ),
      );
    }
  }

  Color _getBorderColor() {
    return widget.borderColor ??
        (_isFocused ? const Color(0xFFE0E0E0) : const Color(0xFFF0F0F0));
  }

  EdgeInsetsGeometry _getDefaultContentPadding() {
    if (widget.height != null) {
      double verticalPadding = (widget.height! - 16) / 2;
      verticalPadding = verticalPadding.clamp(8.0, 20.0);

      return EdgeInsets.symmetric(horizontal: 12, vertical: verticalPadding);
    }

    return const EdgeInsets.symmetric(horizontal: 14, vertical: 12);
  }

  List<BoxShadow> _buildShadows() {
    final double intensity = _shadowAnimation.value;
    final Color currentBorderColor = _getBorderColor();
    Color shadowColor = _getShadowColorFromBorder(currentBorderColor);

    if (_isFocused) {
      return [
        BoxShadow(
          color: currentBorderColor.withValues(alpha: 0.3 + (intensity * 0.2)),
          offset: const Offset(0, 3),
          blurRadius: 4 + (intensity * 2),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.6),
          offset: const Offset(-1, -1),
          blurRadius: 2,
          spreadRadius: -1,
        ),
      ];
    } else {
      return [
        BoxShadow(
          color: shadowColor.withValues(alpha: 0.18),
          offset: const Offset(4, 4),
          blurRadius: 8,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: currentBorderColor.withValues(alpha: 0.15),
          offset: const Offset(1, 1),
          blurRadius: 4,
          spreadRadius: -1,
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.8),
          offset: const Offset(-2, -2),
          blurRadius: 4,
          spreadRadius: -1,
        ),
      ];
    }
  }

  Color _getShadowColorFromBorder(Color borderColor) {
    if (borderColor == AppColors.blue || borderColor == const Color(0xFF1976D2)) {
      return const Color(0xFF0D47A1);
    } else if (borderColor == Colors.red || borderColor == const Color(0xFFD32F2F)) {
      return const Color(0xFF8D1E1E);
    } else if (borderColor == Colors.green || borderColor == const Color(0xFF4CAF50)) {
      return const Color(0xFF1B5E20);
    } else if (borderColor == Colors.purple || borderColor == const Color(0xFF9C27B0)) {
      return const Color(0xFF4A148C);
    } else {
      HSLColor hsl = HSLColor.fromColor(borderColor);
      return HSLColor.fromAHSL(
        1.0,
        hsl.hue,
        (hsl.saturation * 0.9).clamp(0.0, 1.0),
        (hsl.lightness * 0.25).clamp(0.0, 0.4),
      ).toColor();
    }
  }
}

// 🎨 DIALOG MODERNO PARA FECHA SIMPLE (CON HORA OPCIONAL)
class _ModernDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final Color primaryColor;
  final bool includeTime;

  const _ModernDatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.primaryColor,
    this.includeTime = false,
  });

  @override
  State<_ModernDatePickerDialog> createState() => _ModernDatePickerDialogState();
}

class _ModernDatePickerDialogState extends State<_ModernDatePickerDialog>
    with TickerProviderStateMixin {
  late DateTime _selectedDate;
  late DateTime _displayedMonth;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month);

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _previousMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1);
    });
  }

  void _selectDate(DateTime date) {
    // Normalizar fechas a medianoche para comparar solo día/mes/año
    final dateOnly = DateTime(date.year, date.month, date.day);
    final firstDateOnly = DateTime(widget.firstDate.year, widget.firstDate.month, widget.firstDate.day);
    final lastDateOnly = DateTime(widget.lastDate.year, widget.lastDate.month, widget.lastDate.day);

    // Validar que la fecha esté dentro del rango permitido
    if (dateOnly.isBefore(firstDateOnly) || dateOnly.isAfter(lastDateOnly)) {
      return; // No permitir seleccionar fechas fuera del rango
    }

    setState(() {
      _selectedDate = date;
    });
  }

  void _confirmSelection() {
    Navigator.of(context).pop(_selectedDate);
  }

  List<String> get _monthNames => [
        'Enero',
        'Febrero',
        'Marzo',
        'Abril',
        'Mayo',
        'Junio',
        'Julio',
        'Agosto',
        'Septiembre',
        'Octubre',
        'Noviembre',
        'Diciembre',
      ];

  List<String> get _dayNames => ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sa', 'Do'];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          width: 320,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header con gradiente
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.primaryColor,
                      widget.primaryColor.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _previousMonth,
                      icon: const Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                        size: 20,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        shape: const CircleBorder(),
                      ),
                    ),
                    Text(
                      '${_monthNames[_displayedMonth.month - 1]} ${_displayedMonth.year}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      onPressed: _nextMonth,
                      icon: const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 20,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha:0.2),
                        shape: const CircleBorder(),
                      ),
                    ),
                  ],
                ),
              ),

              // Calendario
              Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    // Nombres de días
                    Row(
                      children: _dayNames
                          .map(
                            (day) => Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  day,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: widget.primaryColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),

                    const SizedBox(height: 8),

                    // Grid del calendario
                    ..._buildCalendarWeeks(),
                  ],
                ),
              ),

              // Botones
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _confirmSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Aceptar',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCalendarWeeks() {
    final firstDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final lastDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0);
    final firstDayWeekday = firstDayOfMonth.weekday;

    List<Widget> weeks = [];
    List<Widget> week = [];

    // Días del mes anterior (vacíos)
    for (int i = 1; i < firstDayWeekday; i++) {
      week.add(const Expanded(child: SizedBox()));
    }

    // Días del mes actual
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final date = DateTime(_displayedMonth.year, _displayedMonth.month, day);
      final isSelected = date.day == _selectedDate.day &&
          date.month == _selectedDate.month &&
          date.year == _selectedDate.year;
      final isToday = date.day == DateTime.now().day &&
          date.month == DateTime.now().month &&
          date.year == DateTime.now().year;

      // Verificar si la fecha está dentro del rango permitido (comparando solo día/mes/año)
      final dateOnly = DateTime(date.year, date.month, date.day);
      final firstDateOnly = DateTime(widget.firstDate.year, widget.firstDate.month, widget.firstDate.day);
      final lastDateOnly = DateTime(widget.lastDate.year, widget.lastDate.month, widget.lastDate.day);
      final isDisabled = dateOnly.isBefore(firstDateOnly) || dateOnly.isAfter(lastDateOnly);

      week.add(
        Expanded(
          child: GestureDetector(
            onTap: isDisabled ? null : () => _selectDate(date),
            child: Container(
              height: 35,
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isDisabled
                    ? Colors.grey.shade100
                    : isSelected
                        ? widget.primaryColor
                        : isToday
                            ? widget.primaryColor.withValues(alpha:0.1)
                            : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: isToday && !isSelected && !isDisabled
                    ? Border.all(
                        color: widget.primaryColor.withValues(alpha:0.5),
                        width: 2,
                      )
                    : null,
              ),
              child: Center(
                child: Text(
                  day.toString(),
                  style: TextStyle(
                    color: isDisabled
                        ? Colors.grey.shade400
                        : isSelected
                            ? Colors.white
                            : isToday
                                ? widget.primaryColor
                                : Colors.black87,
                    fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                    decoration: isDisabled ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      if (week.length == 7) {
        weeks.add(Row(children: week));
        weeks.add(const SizedBox(height: 4));
        week = [];
      }
    }

    // Completar última semana
    while (week.length < 7) {
      week.add(const Expanded(child: SizedBox()));
    }
    if (week.isNotEmpty) {
      weeks.add(Row(children: week));
    }
    return weeks;
  }
}

// 🚀 DIALOG MODERNO PARA RANGO DE FECHAS
class _ModernDateRangePickerDialog extends StatefulWidget {
  final DateRange initialRange;
  final DateTime firstDate;
  final DateTime lastDate;
  final Color primaryColor;
  final int? maxRangeDays;
  final int? minRangeDays;
  final bool allowSameDay;

  const _ModernDateRangePickerDialog({
    required this.initialRange,
    required this.firstDate,
    required this.lastDate,
    required this.primaryColor,
    this.maxRangeDays,
    this.minRangeDays,
    this.allowSameDay = true,
  });

  @override
  State<_ModernDateRangePickerDialog> createState() =>
      _ModernDateRangePickerDialogState();
}

class _ModernDateRangePickerDialogState extends State<_ModernDateRangePickerDialog>
    with TickerProviderStateMixin {
  late DateRange _selectedRange;
  late DateTime _displayedMonth;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool _selectingStartDate = true;

  @override
  void initState() {
    super.initState();
    _selectedRange = widget.initialRange;
    _displayedMonth = DateTime(
      (_selectedRange.startDate ?? DateTime.now()).year,
      (_selectedRange.startDate ?? DateTime.now()).month,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _previousMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1);
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      if (_selectingStartDate || _selectedRange.startDate == null) {
        _selectedRange = DateRange(startDate: date, endDate: null);
        _selectingStartDate = false;
      } else {
        if (date.isBefore(_selectedRange.startDate!)) {
          _selectedRange = DateRange(
            startDate: date,
            endDate: _selectedRange.startDate,
          );
        } else {
          _selectedRange = DateRange(
            startDate: _selectedRange.startDate,
            endDate: date,
          );
        }

        if (!_isValidRange(_selectedRange)) {
          _selectedRange = DateRange(startDate: date, endDate: null);
          _selectingStartDate = false;
        }
      }
    });
  }

  bool _isValidRange(DateRange range) {
    if (!range.isComplete) return true;

    final daysDiff = range.daysDifference!;

    if (!widget.allowSameDay && daysDiff == 1) return false;
    if (widget.minRangeDays != null && daysDiff < widget.minRangeDays!) return false;
    if (widget.maxRangeDays != null && daysDiff > widget.maxRangeDays!) return false;

    return true;
  }

  void _confirmSelection() {
    if (_selectedRange.isComplete && _isValidRange(_selectedRange)) {
      Navigator.of(context).pop(_selectedRange);
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedRange = const DateRange();
      _selectingStartDate = true;
    });
  }

  List<String> get _monthNames => [
        'Enero',
        'Febrero',
        'Marzo',
        'Abril',
        'Mayo',
        'Junio',
        'Julio',
        'Agosto',
        'Septiembre',
        'Octubre',
        'Noviembre',
        'Diciembre',
      ];

  List<String> get _dayNames => ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sa', 'Do'];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          width: 360,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.25),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header con gradiente
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.primaryColor,
                      widget.primaryColor.withValues(alpha:0.8),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    // Navegación de mes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: _previousMonth,
                          icon: const Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                            size: 28,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha:0.2),
                            shape: const CircleBorder(),
                          ),
                        ),
                        Text(
                          '${_monthNames[_displayedMonth.month - 1]} ${_displayedMonth.year}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          onPressed: _nextMonth,
                          icon: const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                            size: 28,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha:0.2),
                            shape: const CircleBorder(),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Información del rango seleccionado
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _selectingStartDate
                                ? 'Selecciona fecha de inicio'
                                : _selectedRange.endDate == null
                                    ? 'Selecciona fecha de fin'
                                    : '¡Rango seleccionado!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_selectedRange.isComplete) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${_selectedRange.daysDifference!} días',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Calendario
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Nombres de días
                    Row(
                      children: _dayNames
                          .map(
                            (day) => Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  day,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: widget.primaryColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),

                    const SizedBox(height: 8),

                    // Grid del calendario para rangos
                    ..._buildRangeCalendarWeeks(),
                  ],
                ),
              ),

              // Botones
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: _clearSelection,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: const Text(
                        'Limpiar',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _selectedRange.isComplete && _isValidRange(_selectedRange)
                          ? _confirmSelection
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Aceptar',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRangeCalendarWeeks() {
    final firstDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final lastDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0);
    final firstDayWeekday = firstDayOfMonth.weekday;

    List<Widget> weeks = [];
    List<Widget> week = [];

    for (int i = 1; i < firstDayWeekday; i++) {
      week.add(const Expanded(child: SizedBox()));
    }

    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final date = DateTime(_displayedMonth.year, _displayedMonth.month, day);

      final isStartDate = _selectedRange.startDate != null &&
          date.year == _selectedRange.startDate!.year &&
          date.month == _selectedRange.startDate!.month &&
          date.day == _selectedRange.startDate!.day;

      final isEndDate = _selectedRange.endDate != null &&
          date.year == _selectedRange.endDate!.year &&
          date.month == _selectedRange.endDate!.month &&
          date.day == _selectedRange.endDate!.day;

      final isInRange = _selectedRange.isComplete &&
          date.isAfter(_selectedRange.startDate!) &&
          date.isBefore(_selectedRange.endDate!);

      final isToday = date.year == DateTime.now().year &&
          date.month == DateTime.now().month &&
          date.day == DateTime.now().day;

      Color? backgroundColor;
      Color? textColor;

      if (isStartDate || isEndDate) {
        backgroundColor = widget.primaryColor;
        textColor = Colors.white;
      } else if (isInRange) {
        backgroundColor = widget.primaryColor.withValues(alpha:0.2);
        textColor = widget.primaryColor;
      } else if (isToday) {
        backgroundColor = widget.primaryColor.withValues(alpha:0.1);
        textColor = widget.primaryColor;
      } else {
        backgroundColor = Colors.transparent;
        textColor = Colors.black87;
      }

      week.add(
        Expanded(
          child: GestureDetector(
            onTap: () => _selectDate(date),
            child: Container(
              height: 40,
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: isToday && !isStartDate && !isEndDate && !isInRange
                    ? Border.all(
                        color: widget.primaryColor.withValues(alpha:0.5),
                        width: 2,
                      )
                    : null,
              ),
              child: Center(
                child: Text(
                  day.toString(),
                  style: TextStyle(
                    color: textColor,
                    fontWeight: isStartDate || isEndDate || isToday
                        ? FontWeight.w700
                        : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      if (week.length == 7) {
        weeks.add(Row(children: week));
        weeks.add(const SizedBox(height: 4));
        week = [];
      }
    }

    while (week.length < 7) {
      week.add(const Expanded(child: SizedBox()));
    }
    if (week.isNotEmpty) {
      weeks.add(Row(children: week));
    }

    return weeks;
  }
}
