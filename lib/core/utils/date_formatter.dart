import 'package:intl/intl.dart';

/// Utilidades para formatear fechas y convertir de UTC a hora local
///
/// IMPORTANTE: El backend guarda todas las fechas en UTC.
/// Este helper se encarga de convertirlas a la hora local del dispositivo.
class DateFormatter {
  /// Convierte una fecha UTC a hora local
  ///
  /// Ejemplo:
  /// ```dart
  /// DateTime utcDate = DateTime.parse('2026-02-01T02:33:18.982Z'); // UTC
  /// DateTime localDate = DateFormatter.toLocal(utcDate);
  /// // localDate = 2026-01-31 21:33:18.982 (si estás en Perú UTC-5)
  /// ```
  static DateTime toLocal(DateTime dateTime) {
    // Si ya es local, retornar tal cual
    if (!dateTime.isUtc) {
      return dateTime;
    }
    // Convertir a hora local
    return dateTime.toLocal();
  }

  /// Formatea una fecha en formato: dd/MM/yyyy HH:mm
  ///
  /// Ejemplo: 31/01/2026 21:33
  static String formatDateTime(DateTime dateTime) {
    final localDate = toLocal(dateTime);
    return DateFormat('dd/MM/yyyy HH:mm').format(localDate);
  }

  /// Formatea una fecha en formato: dd/MM/yyyy HH:mm:ss
  ///
  /// Ejemplo: 31/01/2026 21:33:18
  static String formatDateTimeWithSeconds(DateTime dateTime) {
    final localDate = toLocal(dateTime);
    return DateFormat('dd/MM/yyyy HH:mm:ss').format(localDate);
  }

  /// Formatea solo la fecha: dd/MM/yyyy
  ///
  /// Ejemplo: 31/01/2026
  static String formatDate(DateTime dateTime) {
    final localDate = toLocal(dateTime);
    return DateFormat('dd/MM/yyyy').format(localDate);
  }

  /// Formatea solo la fecha en formato corto: dd/MM/yy
  ///
  /// Ejemplo: 31/01/26
  static String formatDateShort(DateTime dateTime) {
    final localDate = toLocal(dateTime);
    return DateFormat('dd/MM/yy').format(localDate);
  }

  /// Formatea solo la hora: HH:mm
  ///
  /// Ejemplo: 21:33
  static String formatTime(DateTime dateTime) {
    final localDate = toLocal(dateTime);
    return DateFormat('HH:mm').format(localDate);
  }

  /// Formatea solo la hora con segundos: HH:mm:ss
  ///
  /// Ejemplo: 21:33:18
  static String formatTimeWithSeconds(DateTime dateTime) {
    final localDate = toLocal(dateTime);
    return DateFormat('HH:mm:ss').format(localDate);
  }

  /// Formatea en formato largo: dd 'de' MMMM 'de' yyyy 'a las' HH:mm
  ///
  /// Ejemplo: 31 de enero de 2026 a las 21:33
  static String formatDateTimeLong(DateTime dateTime) {
    final localDate = toLocal(dateTime);
    return DateFormat("dd 'de' MMMM 'de' yyyy 'a las' HH:mm", 'es').format(localDate);
  }

  /// Formatea en formato corto americano: MM/dd/yyyy HH:mm
  ///
  /// Ejemplo: 01/31/2026 21:33
  static String formatDateTimeUS(DateTime dateTime) {
    final localDate = toLocal(dateTime);
    return DateFormat('MM/dd/yyyy HH:mm').format(localDate);
  }

  /// Formatea una fecha de forma relativa (hace 5 minutos, hace 2 horas, etc.)
  ///
  /// Ejemplo: "Hace 5 minutos", "Hace 2 horas", "Hace 3 días"
  static String formatRelative(DateTime dateTime) {
    final localDate = toLocal(dateTime);
    final now = DateTime.now();
    final difference = now.difference(localDate);

    if (difference.inSeconds < 60) {
      return 'Hace ${difference.inSeconds} segundo${difference.inSeconds != 1 ? 's' : ''}';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} minuto${difference.inMinutes != 1 ? 's' : ''}';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} hora${difference.inHours != 1 ? 's' : ''}';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} día${difference.inDays != 1 ? 's' : ''}';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Hace $weeks semana${weeks != 1 ? 's' : ''}';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'Hace $months mes${months != 1 ? 'es' : ''}';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'Hace $years año${years != 1 ? 's' : ''}';
    }
  }

  /// Formatea un rango de fechas
  ///
  /// Ejemplo: "Del 31/01/2026 al 05/02/2026"
  static String formatDateRange(DateTime start, DateTime end) {
    final localStart = toLocal(start);
    final localEnd = toLocal(end);
    return 'Del ${formatDate(localStart)} al ${formatDate(localEnd)}';
  }

  /// Verifica si una fecha es hoy
  static bool isToday(DateTime dateTime) {
    final localDate = toLocal(dateTime);
    final now = DateTime.now();
    return localDate.year == now.year &&
        localDate.month == now.month &&
        localDate.day == now.day;
  }

  /// Verifica si una fecha es ayer
  static bool isYesterday(DateTime dateTime) {
    final localDate = toLocal(dateTime);
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return localDate.year == yesterday.year &&
        localDate.month == yesterday.month &&
        localDate.day == yesterday.day;
  }

  /// Formatea de forma inteligente: "Hoy a las 21:33", "Ayer a las 15:20", o fecha completa
  static String formatSmart(DateTime dateTime) {
    final localDate = toLocal(dateTime);

    if (isToday(localDate)) {
      return 'Hoy a las ${formatTime(localDate)}';
    } else if (isYesterday(localDate)) {
      return 'Ayer a las ${formatTime(localDate)}';
    } else {
      return formatDateTime(localDate);
    }
  }

  /// Helper manual para casos donde no se puede usar intl
  /// Formato: dd/MM/yyyy HH:mm
  static String formatManual(DateTime dateTime) {
    final localDate = toLocal(dateTime);
    return '${localDate.day.toString().padLeft(2, '0')}/'
        '${localDate.month.toString().padLeft(2, '0')}/'
        '${localDate.year} '
        '${localDate.hour.toString().padLeft(2, '0')}:'
        '${localDate.minute.toString().padLeft(2, '0')}';
  }
}
