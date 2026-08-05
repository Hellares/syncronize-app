/// ⚠️ ESPEJO EXACTO del enum `RubroEmpresa` de Prisma (backend
/// `prisma/schema/empresa.prisma`). El DTO valida con @IsEnum, así que un
/// `value` que no exista allá devuelve 400 al crear la empresa — y el
/// dropdown lo ofrece igual. Pasó con MASCOTAS, BELLEZA, OFICINA,
/// ENTRETENIMIENTO y con DEPORTE (el backend lo llama DEPORTES).
/// Agregar un rubro acá = migración de enum + entrada en RUBROS_GENERICOS o
/// en CATALOGOS_POR_RUBRO del backend, o la empresa nace sin catálogo.
enum RubroEmpresa {
  tecnologia('TECNOLOGIA', 'Tecnología', '💻'),
  moda('MODA', 'Moda', '👗'),
  gastronomia('GASTRONOMIA', 'Gastronomía', '🍽️'),
  salud('SALUD', 'Salud', '🏥'),
  educacion('EDUCACION', 'Educación', '📚'),
  construccion('CONSTRUCCION', 'Construcción', '🏗️'),
  automotriz('AUTOMOTRIZ', 'Automotriz', '🚗'),
  deportes('DEPORTES', 'Deportes', '⚽'),
  hogar('HOGAR', 'Hogar', '🏠'),
  belleza('BELLEZA', 'Belleza', '💄'),
  mascotas('MASCOTAS', 'Mascotas', '🐾'),
  oficina('OFICINA', 'Oficina', '🖊️'),
  entretenimiento('ENTRETENIMIENTO', 'Entretenimiento', '🎬'),
  otro('OTRO', 'Otro', '📦');

  final String value;
  final String displayName;
  final String emoji;

  const RubroEmpresa(this.value, this.displayName, this.emoji);

  static RubroEmpresa fromString(String value) {
    return RubroEmpresa.values.firstWhere(
      (rubro) => rubro.value == value,
      orElse: () => RubroEmpresa.otro,
    );
  }

  @override
  String toString() => value;
}
