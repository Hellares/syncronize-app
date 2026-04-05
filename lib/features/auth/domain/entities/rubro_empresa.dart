enum RubroEmpresa {
  tecnologia('TECNOLOGIA', 'Tecnología', '💻'),
  moda('MODA', 'Moda', '👗'),
  gastronomia('GASTRONOMIA', 'Gastronomía', '🍽️'),
  salud('SALUD', 'Salud', '🏥'),
  educacion('EDUCACION', 'Educación', '📚'),
  construccion('CONSTRUCCION', 'Construcción', '🏗️'),
  automotriz('AUTOMOTRIZ', 'Automotriz', '🚗'),
  deporte('DEPORTE', 'Deporte', '⚽'),
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
