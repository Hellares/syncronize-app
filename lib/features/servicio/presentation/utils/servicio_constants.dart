class ServicioConstants {
  ServicioConstants._();

  static const tipoServicioLabels = {
    'REPARACION': 'Reparacion',
    'MANTENIMIENTO': 'Mantenimiento',
    'INSTALACION': 'Instalacion',
    'DIAGNOSTICO': 'Diagnostico',
    'ACTUALIZACION': 'Actualizacion',
    'LIMPIEZA': 'Limpieza',
    'RECUPERACION_DATOS': 'Recuperacion de datos',
    'CONFIGURACION': 'Configuracion',
    'CONSULTORIA': 'Consultoria',
    'FORMACION': 'Formacion',
    'SOPORTE': 'Soporte',
  };

  static const estadoLabels = {
    'RECIBIDO': 'Recibido',
    'EN_DIAGNOSTICO': 'En Diagnostico',
    'ESPERANDO_APROBACION': 'Esperando Aprobacion',
    'EN_REPARACION': 'En Reparacion',
    'PENDIENTE_PIEZAS': 'Pendiente Piezas',
    'REPARADO': 'Reparado',
    'LISTO_ENTREGA': 'Listo para Entrega',
    'ENTREGADO': 'Entregado',
    'FINALIZADO': 'Finalizado',
    'CANCELADO': 'Cancelado',
  };

  static const prioridadLabels = {
    'BAJA': 'Baja',
    'NORMAL': 'Normal',
    'ALTA': 'Alta',
    'URGENTE': 'Urgente',
    'EMERGENCIA': 'Emergencia',
  };

  static String tipoServicioLabel(String tipo) =>
      tipoServicioLabels[tipo] ?? tipo;

  static String estadoLabel(String estado) =>
      estadoLabels[estado] ?? estado;

  static String prioridadLabel(String prioridad) =>
      prioridadLabels[prioridad] ?? prioridad;
}
