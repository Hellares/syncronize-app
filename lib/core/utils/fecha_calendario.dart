/// Fechas de CALENDARIO: los vencimientos.
///
/// Un vencimiento no es un instante, es el día impreso en el envase. El
/// backend lo guarda como la MEDIANOCHE UTC de ese día
/// (`2026-10-01T00:00:00.000Z`), así que el día se lee de los campos UTC del
/// `DateTime` — nunca de `.toLocal()`, que en Lima (UTC−5) da el día anterior
/// a las 19:00.
///
/// 🔴 Compararlo como instante contra `DateTime.now()` daba el producto por
/// vencido desde la tarde del día ANTERIOR, y un envase que dice "VENCE
/// 01/10" vale el 01/10 entero. Mismo criterio que `estaVencido` en el
/// backend y `diasParaVencer` en la web.
library;

/// El día del envase como `yyyy-MM-dd`, por sus campos UTC.
String diaCalendario(DateTime fecha) {
  final u = fecha.toUtc();
  return '${u.year}-${u.month.toString().padLeft(2, '0')}-${u.day.toString().padLeft(2, '0')}';
}

/// Días que faltan para el vencimiento: negativo = ya pasó, 0 = vence hoy,
/// null = no vence. Día contra día: hoy es el día del calendario LOCAL del
/// teléfono, el envase es su día UTC.
int? diasParaVencer(DateTime? fechaVencimiento) {
  if (fechaVencimiento == null) return null;
  final hoy = DateTime.now();
  final hoyDia = DateTime.utc(hoy.year, hoy.month, hoy.day);
  final u = fechaVencimiento.toUtc();
  final venceDia = DateTime.utc(u.year, u.month, u.day);
  return venceDia.difference(hoyDia).inDays;
}

/// Ya pasó el día del envase. El propio día todavía se vende.
bool estaVencido(DateTime? fechaVencimiento) {
  final d = diasParaVencer(fechaVencimiento);
  return d != null && d < 0;
}

/// Lo mismo, desde el string ISO crudo de un JSON sin parsearlo a instante:
/// los primeros 10 caracteres SON el día.
int? diasParaVencerIso(String? iso) {
  if (iso == null || iso.length < 10) return null;
  final y = int.tryParse(iso.substring(0, 4));
  final m = int.tryParse(iso.substring(5, 7));
  final d = int.tryParse(iso.substring(8, 10));
  if (y == null || m == null || d == null) return null;
  final hoy = DateTime.now();
  final hoyDia = DateTime.utc(hoy.year, hoy.month, hoy.day);
  return DateTime.utc(y, m, d).difference(hoyDia).inDays;
}

/// "01/10/26" (o "01/10/2026") del día del envase.
String formatearDiaEnvase(DateTime? fecha, {bool anioCompleto = false}) {
  if (fecha == null) return '';
  final u = fecha.toUtc();
  final anio = anioCompleto ? '${u.year}' : u.year.toString().substring(2);
  return '${u.day.toString().padLeft(2, '0')}/${u.month.toString().padLeft(2, '0')}/$anio';
}

/// Lo mismo desde el string ISO crudo de un JSON.
String formatearDiaEnvaseIso(String? iso) {
  if (iso == null || iso.length < 10) return '';
  return '${iso.substring(8, 10)}/${iso.substring(5, 7)}/${iso.substring(2, 4)}';
}

/// Lo que se manda al backend al elegir un día: `yyyy-MM-dd`, sin hora ni
/// zona. El backend lo normaliza a la medianoche UTC de ese día.
String diaParaEnviar(DateTime dia) {
  return '${dia.year}-${dia.month.toString().padLeft(2, '0')}-${dia.day.toString().padLeft(2, '0')}';
}
