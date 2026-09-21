/// El orden en que los lotes van a SALIR, tal como lo decide el backend.
///
/// 🔑 Que esto se vea es el punto: el sistema descuenta las unidades que
/// quiere, pero quien va al estante agarra una caja con la mano. Sin saber
/// cuál toca, el FEFO es una ficción contable.
///
/// Vive acá y no dentro de una pantalla porque lo dibujan DOS —la ficha del
/// producto y la trazabilidad—, y dos copias de este orden es garantizar que
/// una de las dos mienta.
///
/// Trabaja sobre los `Map` crudos de `/productos/:id/trazabilidad`, que es lo
/// que las dos reciben.
library;

/// El lote está FÍSICAMENTE en el depósito: cuenta para el stock y el consumo
/// lo puede tomar.
///
/// 🔴 Un VENCIDO sigue en el estante hasta que alguien lo dé de baja, así que
/// cuenta como presente. Espejo de `ESTADOS_LOTE_PRESENTE` del backend.
bool lotePresente(Map<String, dynamic> l) {
  final cantidad = (l['cantidadActual'] as num?)?.toInt() ?? 0;
  final estado = l['estado']?.toString();
  return cantidad > 0 &&
      (estado == null || estado == 'ACTIVO' || estado == 'VENCIDO');
}

/// Primero lo que vence antes; los SIN fecha al final, del más viejo al más
/// nuevo. Espejo de `planificarFefo` del backend.
///
/// Las fechas se comparan como texto ISO a propósito: ya vienen normalizadas
/// y parsearlas solo para ordenar es trabajo de más.
int ordenFefo(Map<String, dynamic> a, Map<String, dynamic> b) {
  final va = a['fechaVencimiento']?.toString();
  final vb = b['fechaVencimiento']?.toString();
  if (va != null && vb != null) return va.compareTo(vb);
  if (va != null) return -1;
  if (vb != null) return 1;
  return (a['fechaIngreso']?.toString() ?? '')
      .compareTo(b['fechaIngreso']?.toString() ?? '');
}

/// Los presentes en orden de salida y, detrás, los agotados.
List<Map<String, dynamic>> lotesOrdenados(List<Map<String, dynamic>> todos) {
  final presentes = todos.where(lotePresente).toList()..sort(ordenFefo);
  final resto = todos.where((l) => !lotePresente(l)).toList();
  return [...presentes, ...resto];
}
