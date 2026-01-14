# 📱 Implementación UI de Gestión de Catálogos - Flutter

## 📋 Índice

1. [Resumen de Implementación](#1-resumen-de-implementación)
2. [Archivos Creados](#2-archivos-creados)
3. [Configuración Requerida](#3-configuración-requerida)
4. [Integración con Dependency Injection](#4-integración-con-dependency-injection)
5. [Navegación y Rutas](#5-navegación-y-rutas)
6. [Características Implementadas](#6-características-implementadas)
7. [Cómo Usar](#7-cómo-usar)
8. [Siguientes Pasos](#8-siguientes-pasos)

---

## 1. Resumen de Implementación

Se ha implementado una **UI completa de gestión de catálogos** para Flutter siguiendo la **arquitectura Clean** existente en el proyecto. La implementación incluye:

✅ **Casos de Uso (Domain Layer)**
- `ActivarCategoriaUseCase`
- `DesactivarCategoriaUseCase`
- `ActivarMarcaUseCase`
- `DesactivarMarcaUseCase`

✅ **Gestión de Estado (Presentation Layer)**
- `CategoriasEmpresaCubit` (actualizado)
- `CategoriasMaestrasCubit` (nuevo)

✅ **Páginas Completas**
- `GestionCategoriasPage` - Gestión completa con tabs

✅ **Widgets Reutilizables**
- `CategoriaCard` - Card para categorías activas
- `CategoriaMaestraCard` - Card para maestras disponibles
- `ActivarCategoriaDialog` - Diálogo de activación
- `CrearCategoriaPersonalizadaDialog` - Diálogo para crear personalizadas
- `ConfirmDialog` - Diálogo genérico de confirmación

---

## 2. Archivos Creados

### 📁 **Domain Layer** (`lib/features/catalogo/domain/`)

```
usecases/
├── activar_categoria_usecase.dart        [NUEVO]
├── desactivar_categoria_usecase.dart     [NUEVO]
├── activar_marca_usecase.dart            [NUEVO]
└── desactivar_marca_usecase.dart         [NUEVO]
```

### 📁 **Presentation Layer** (`lib/features/catalogo/presentation/`)

```
bloc/
├── categorias_empresa/
│   └── categorias_empresa_cubit.dart     [MODIFICADO]
└── categorias_maestras/
    ├── categorias_maestras_cubit.dart    [NUEVO]
    └── categorias_maestras_state.dart    [NUEVO]

pages/
└── gestion_categorias_page.dart          [NUEVO]

widgets/
├── categoria_card.dart                   [NUEVO]
├── categoria_maestra_card.dart           [NUEVO]
└── dialogs/
    ├── activar_categoria_dialog.dart     [NUEVO]
    ├── crear_categoria_personalizada_dialog.dart [NUEVO]
    └── confirm_dialog.dart               [NUEVO]
```

---

## 3. Configuración Requerida

### 3.1. Actualizar Dependency Injection (Injectable)

Necesitas registrar los nuevos casos de uso y cubits. Abre tu archivo de configuración de inyección de dependencias (probablemente `injection.dart` o similar) y asegúrate de que `injectable` esté configurado.

Los archivos ya tienen las anotaciones `@injectable` y `@lazySingleton`, por lo que solo necesitas:

```bash
# Regenerar código de injectable
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3.2. Actualizar `catalogo_repository_impl.dart`

Asegúrate de que el repositorio implementa todos los métodos del interface. Ya debería tenerlos basándonos en el código que revisamos.

---

## 4. Integración con Dependency Injection

### 4.1. Registro Manual (Si es necesario)

Si usas GetIt directamente, registra los servicios:

```dart
// En tu archivo de configuración DI
void configureDependencies() {
  // UseCases
  getIt.registerFactory(() => ActivarCategoriaUseCase(getIt()));
  getIt.registerFactory(() => DesactivarCategoriaUseCase(getIt()));
  getIt.registerFactory(() => ActivarMarcaUseCase(getIt()));
  getIt.registerFactory(() => DesactivarMarcaUseCase(getIt()));

  // Cubits
  getIt.registerFactory(() => CategoriasEmpresaCubit(
    getIt(),
    getIt(),
    getIt(),
  ));
  getIt.registerFactory(() => CategoriasMaestrasCubit(getIt()));
}
```

### 4.2. Providers en el Widget Tree

Asegúrate de proporcionar los Cubits en el árbol de widgets. Ejemplo en `main.dart` o donde inicializas tu app:

```dart
MultiBlocProvider(
  providers: [
    // ... otros providers
    BlocProvider(
      create: (context) => getIt<CategoriasEmpresaCubit>(),
    ),
    BlocProvider(
      create: (context) => CategoriasMaestrasCubit.new(
        getIt<GetCategoriasMaestrasUseCase>(),
      ),
    ),
  ],
  child: MyApp(),
)
```

---

## 5. Navegación y Rutas

### 5.1. Agregar Ruta

En tu archivo de rutas (ejemplo: `app_router.dart` o `routes.dart`):

```dart
class AppRoutes {
  static const String gestionCategorias = '/gestion-categorias';
  // ...
}

// En el método de generación de rutas
Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    // ... otras rutas
    case AppRoutes.gestionCategorias:
      return MaterialPageRoute(
        builder: (_) => const GestionCategoriasPage(),
      );
    // ...
  }
}
```

### 5.2. Navegar a la Página

Desde cualquier parte de la app:

```dart
// Opción 1: Navigator básico
Navigator.pushNamed(context, AppRoutes.gestionCategorias);

// Opción 2: Navigator 2.0 / go_router
context.go('/gestion-categorias');
```

---

## 6. Características Implementadas

### 6.1. Tab "Activas" ✅

#### **Funcionalidades:**
- ✅ Lista de categorías activas de la empresa
- ✅ Búsqueda en tiempo real
- ✅ Diferenciación visual: Maestras vs Personalizadas
- ✅ Desactivar categorías (con validación de uso)
- ✅ Pull-to-refresh
- ✅ Chips informativos (Popular, Orden, Oculta)
- ✅ Menú de acciones por categoría

#### **Estados:**
- Loading: Spinner centrado
- Error: Mensaje de error con botón "Reintentar"
- Empty: Vista vacía con sugerencia
- Loaded: Lista de categorías

---

### 6.2. Tab "Disponibles" ✅

#### **Funcionalidades:**
- ✅ Lista de categorías maestras del catálogo global
- ✅ Búsqueda en tiempo real
- ✅ Filtro "Solo populares"
- ✅ Indicador de categorías ya activadas
- ✅ Botón "Activar" por categoría
- ✅ Pull-to-refresh
- ✅ Contador de disponibles

#### **Card de Maestra:**
- Nombre, descripción, ícono
- Badge "Popular" si aplica
- Badge "Nivel X" si es subcategoría
- Estado deshabilitado si ya está activada
- Check verde si ya está activada

---

### 6.3. Diálogo "Activar Categoría Maestra" ✅

#### **Funcionalidades:**
- ✅ Muestra información de la categoría
- ✅ Opción de personalizar nombre (nombre local)
- ✅ Campo de orden de visualización
- ✅ Validaciones de formulario
- ✅ Loading state durante activación
- ✅ Mensajes de error/éxito

#### **Flujo:**
```
Usuario hace clic en "Activar"
  ↓
Se abre el diálogo
  ↓
Usuario completa datos (opcionales)
  ↓
Clic en "Activar"
  ↓
Se muestra loading
  ↓
Backend activa la categoría
  ↓
Cubit recarga lista
  ↓
Diálogo se cierra
  ↓
SnackBar de éxito
```

---

### 6.4. Diálogo "Crear Personalizada" ✅

#### **Funcionalidades:**
- ✅ Formulario con nombre (requerido)
- ✅ Descripción (opcional, max 200 chars)
- ✅ Orden (opcional)
- ✅ Info visual que es exclusiva de la empresa
- ✅ Validaciones completas
- ✅ Loading state
- ✅ Mensajes de error/éxito

#### **Validaciones:**
- Nombre: requerido, min 3 caracteres
- Descripción: max 200 caracteres
- Orden: número entero > 0

---

### 6.5. Desactivar Categoría ✅

#### **Funcionalidades:**
- ✅ Diálogo de confirmación
- ✅ Warning sobre productos asociados
- ✅ Loading indicator durante proceso
- ✅ Validación en backend (no permite si hay productos)
- ✅ Mensajes de error claros
- ✅ Recarga automática de lista

#### **Flujo:**
```
Usuario hace clic en "Desactivar" (menú)
  ↓
Se muestra diálogo de confirmación
  ↓
Usuario confirma
  ↓
Loading indicator
  ↓
Backend valida (si hay productos → Error 400)
  ↓
Si OK: Soft delete (deletedAt, isActive=false)
  ↓
Cubit recarga lista
  ↓
SnackBar de éxito/error
```

---

## 7. Cómo Usar

### 7.1. Uso Básico

#### **Para el Usuario Final:**

1. **Ver categorías activas:**
   - Abrir "Gestión de Categorías"
   - Tab "Activas" muestra las categorías activadas
   - Usar búsqueda para encontrar rápido

2. **Activar una categoría del catálogo:**
   - Ir a tab "Disponibles"
   - Buscar la categoría deseada
   - Clic en "Activar"
   - (Opcional) Personalizar nombre y orden
   - Confirmar

3. **Crear categoría personalizada:**
   - Clic en botón flotante "Crear Personalizada"
   - Ingresar nombre y descripción
   - Confirmar

4. **Desactivar categoría:**
   - En tab "Activas"
   - Menú (3 puntos) → "Desactivar"
   - Confirmar
   - Si hay productos asociados, mostrará error

---

### 7.2. Personalización de UI

#### **Cambiar Colores:**

```dart
// En categoria_card.dart
final color = categoria.categoriaMaestraId == null
    ? Colors.purple // Personalizada
    : Colors.blue;  // Maestra

// Puedes cambiar a los colores de tu tema
final color = categoria.categoriaMaestraId == null
    ? Theme.of(context).colorScheme.secondary
    : Theme.of(context).colorScheme.primary;
```

#### **Agregar Más Íconos:**

```dart
// En _getIconData()
final iconMap = <String, IconData>{
  'devices': Icons.devices,
  // ... existentes
  'nuevo_icono': Icons.star, // Agregar aquí
};
```

---

### 7.3. Extender Funcionalidad

#### **Agregar Edición de Categorías:**

```dart
// 1. Crear usecase
class EditarCategoriaUseCase { ... }

// 2. Agregar método al cubit
Future<Resource<void>> editarCategoria({...}) async { ... }

// 3. Crear diálogo
class EditarCategoriaDialog extends StatefulWidget { ... }

// 4. Agregar opción al menú en CategoriaCard
PopupMenuItem(
  value: 'editar',
  child: Text('Editar'),
),
```

---

## 8. Siguientes Pasos

### 8.1. **Alta Prioridad** 🔴

#### **A. Implementar Marcas (Similar a Categorías)**

Ya tienes los UseCases creados (`activar_marca_usecase.dart`, `desactivar_marca_usecase.dart`). Solo necesitas:

1. Actualizar `MarcasEmpresaCubit` (similar al update que hicimos en categorías)
2. Crear `MarcasMaestrasCubit`
3. Copiar `GestionCategoriasPage` y adaptar para marcas
4. Copiar los widgets y adaptar

**Estimación:** 2-3 horas

---

#### **B. Implementar Unidades de Medida**

Necesitas crear desde cero (no existe aún):

**Backend (ya está completo):**
- ✅ Endpoints listos
- ✅ DTOs listos

**Flutter (por hacer):**

1. **Entities y Models:**
```dart
// lib/features/catalogo/domain/entities/unidad_medida_maestra.dart
class UnidadMedidaMaestra {
  final String id;
  final String codigo;      // SUNAT: "NIU", "KGM"
  final String nombre;      // "Unidad", "Kilogramo"
  final String simbolo;     // "und", "kg"
  final String descripcion;
  final String categoria;   // "CANTIDAD", "MASA", etc.
  final bool esPopular;
  // ...
}

// lib/features/catalogo/domain/entities/empresa_unidad_medida.dart
class EmpresaUnidadMedida {
  final String id;
  final String empresaId;
  final String? unidadMaestraId;
  final String? nombrePersonalizado;
  final String? simboloPersonalizado;
  // ...

  String get nombreDisplay => nombreLocal ??
      nombrePersonalizado ??
      unidadMaestra?.nombre ??
      'Sin nombre';
}
```

2. **DataSource (agregar a `catalogo_remote_datasource.dart`):**
```dart
Future<List<UnidadMedidaMaestraModel>> getUnidadesMaestras({
  String? categoria,
  bool soloPopulares = false,
}) async {
  final queryParams = <String, dynamic>{};
  if (categoria != null) queryParams['categoria'] = categoria;
  if (soloPopulares) queryParams['soloPopulares'] = 'true';

  final response = await _dioClient.get(
    '${ApiConstants.catalogos}/unidades-maestras',
    queryParameters: queryParams.isNotEmpty ? queryParams : null,
  );

  return (response.data as List)
      .map((json) => UnidadMedidaMaestraModel.fromJson(json))
      .toList();
}

Future<List<EmpresaUnidadMedidaModel>> getUnidadesEmpresa(
  String empresaId,
) async {
  final response = await _dioClient.get(
    '${ApiConstants.catalogos}/unidades/empresa/$empresaId',
  );

  return (response.data as List)
      .map((json) => EmpresaUnidadMedidaModel.fromJson(json))
      .toList();
}

Future<EmpresaUnidadMedidaModel> activarUnidad(
  Map<String, dynamic> data,
) async {
  final response = await _dioClient.post(
    '${ApiConstants.catalogos}/unidades/activar',
    data: data,
  );

  return EmpresaUnidadMedidaModel.fromJson(response.data);
}

Future<void> desactivarUnidad({
  required String empresaId,
  required String unidadId,
}) async {
  await _dioClient.delete(
    '${ApiConstants.catalogos}/unidades/empresa/$empresaId/$unidadId',
  );
}
```

3. **Repository, UseCases, Cubits** (siguiendo el mismo patrón)

4. **UI:**
   - Copiar `GestionCategoriasPage` → `GestionUnidadesPage`
   - Adaptar para unidades
   - Agregar filtro por categoría (CANTIDAD, MASA, LONGITUD, etc.)

**Estimación:** 4-6 horas

---

### 8.2. **Media Prioridad** 🟡

#### **C. Implementar Búsqueda Avanzada**

```dart
// Agregar filtros múltiples
class FiltrosAvanzados {
  final String? categoria;
  final bool? soloPopulares;
  final int? nivel;
  final List<String>? slugs;
}
```

#### **D. Implementar Ordenamiento Manual**

```dart
// Drag & drop para reordenar
class ReordenarCategoriasPage extends StatefulWidget { ... }
```

#### **E. Agregar Estadísticas**

```dart
// Widget de estadísticas
class CatalogoStats extends StatelessWidget {
  final int totalActivas;
  final int totalDisponibles;
  final int personalizadas;
  // ...
}
```

---

### 8.3. **Baja Prioridad** 🟢

#### **F. Modo Offline**

```dart
// Cachear categorías maestras en SQLite
class CatalogoLocalDataSource {
  Future<void> cachearMaestras(List<CategoriaMaestra> maestras);
  Future<List<CategoriaMaestra>> obtenerMaestrasCacheadas();
}
```

#### **G. Sincronización en Background**

```dart
// Worker para sincronizar cambios
class CatalogoSyncWorker {
  Future<void> syncCambiosPendientes();
}
```

---

## 9. Testing

### 9.1. Tests Unitarios (Recomendado)

```dart
// test/features/catalogo/domain/usecases/activar_categoria_usecase_test.dart
void main() {
  late ActivarCategoriaUseCase useCase;
  late MockCatalogoRepository mockRepository;

  setUp(() {
    mockRepository = MockCatalogoRepository();
    useCase = ActivarCategoriaUseCase(mockRepository);
  });

  test('debe activar categoría maestra correctamente', () async {
    // Arrange
    when(() => mockRepository.activarCategoria(any()))
        .thenAnswer((_) async => Resource.success(mockEmpresaCategoria));

    // Act
    final result = await useCase(
      empresaId: 'empresa-1',
      categoriaMaestraId: 'maestra-1',
    );

    // Assert
    expect(result, isA<Success>());
    verify(() => mockRepository.activarCategoria(any())).called(1);
  });
}
```

### 9.2. Tests de Widget

```dart
// test/features/catalogo/presentation/widgets/categoria_card_test.dart
void main() {
  testWidgets('debe mostrar badge "Personalizada" si no tiene maestra',
      (tester) async {
    final categoria = EmpresaCategoria(
      id: '1',
      empresaId: 'emp-1',
      categoriaMaestraId: null, // Personalizada
      nombrePersonalizado: 'Mi Categoría',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoriaCard(
            categoria: categoria,
            onDesactivar: () {},
          ),
        ),
      ),
    );

    expect(find.text('Personalizada'), findsOneWidget);
  });
}
```

---

## 10. Troubleshooting

### Problema 1: "No se encuentra el método activarCategoria en el Cubit"

**Solución:** Regenera el código de injectable:
```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

---

### Problema 2: "Cannot access state of disposed Cubit"

**Solución:** Asegúrate de que los Cubits están provistos correctamente en el árbol de widgets y no se disponen prematuramente.

---

### Problema 3: "API retorna 401 Unauthorized"

**Solución:** Verifica que:
1. El token JWT está siendo enviado en los headers
2. El usuario tiene los permisos necesarios (`MANAGE_PRODUCTS`)
3. La sesión no ha expirado

---

### Problema 4: "No se muestran las categorías maestras"

**Solución:** Verifica que:
1. El seed de categorías se ejecutó en el backend
2. La URL del API es correcta en `ApiConstants.catalogos`
3. No hay errores de CORS

---

## 11. Checklist de Implementación

Usa este checklist para verificar que todo está configurado:

### Backend ✅
- [x] Seed de categorías maestras ejecutado
- [x] Endpoints de catálogos funcionando
- [x] DTOs implementados
- [x] Validaciones activas

### Flutter
- [ ] Dependencias instaladas
- [ ] Injectable configurado y generado
- [ ] Cubits provistos en el árbol de widgets
- [ ] Rutas configuradas
- [ ] ApiConstants.catalogos apunta a URL correcta
- [ ] Tests ejecutados (opcional)

### UI
- [ ] Página de gestión accesible desde menú
- [ ] Tab "Activas" funciona
- [ ] Tab "Disponibles" funciona
- [ ] Diálogo de activación funciona
- [ ] Diálogo de crear personalizada funciona
- [ ] Desactivación funciona (con validación)
- [ ] Búsqueda funciona
- [ ] Filtros funcionan

---

## 12. Capturas de Pantalla (Concepto)

### Pantalla Principal
```
┌─────────────────────────────────────────┐
│ Gestión de Categorías            [🔄]  │
├─────────────────────────────────────────┤
│ [Activas] [Disponibles]                 │
├─────────────────────────────────────────┤
│ 🔍 Buscar categorías...           [x]  │
├─────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐│
│ │ 📱 Smartphones                      ││
│ │ Teléfonos inteligentes              ││
│ │ [Popular] [Orden: 1]          [•••]││
│ └─────────────────────────────────────┘│
│ ┌─────────────────────────────────────┐│
│ │ 💻 Laptops                          ││
│ │ Computadoras portátiles             ││
│ │ [Popular] [Orden: 2]          [•••]││
│ └─────────────────────────────────────┘│
│ ┌─────────────────────────────────────┐│
│ │ 🔧 Productos Refurbished            ││
│ │ Restaurados con garantía            ││
│ │ [Personalizada] [Orden: 10]   [•••]││
│ └─────────────────────────────────────┘│
└─────────────────────────────────────────┘
                [+ Crear Personalizada]
```

---

## 13. Resumen Ejecutivo

### ✅ Lo que Está Listo

1. **Categorías:** ✅ Completo
   - Activar maestras
   - Crear personalizadas
   - Desactivar con validación
   - Búsqueda y filtros
   - UI completa con tabs

2. **Marcas:** ⚠️ Backend listo, UI pendiente
   - UseCases creados
   - Solo falta copiar UI de categorías y adaptar

3. **Unidades:** ⚠️ Backend listo, Flutter pendiente
   - Crear entities, models, datasources
   - Crear UseCases, Cubits
   - Crear UI (similar a categorías)

### 🎯 Próximos Pasos Inmediatos

1. Configurar Injectable y regenerar código
2. Probar la página de categorías
3. Implementar UI de Marcas (2-3 horas)
4. Implementar completo Unidades (4-6 horas)

### 🎉 Resultado Final Esperado

Una vez completado todo:
- ✅ Gestión completa de catálogos desde la app
- ✅ Sin necesidad de postman/insomnia para activar
- ✅ UX intuitiva para usuarios finales
- ✅ Validaciones robustas
- ✅ Arquitectura limpia y escalable

---

**Documentado:** 2026-01-13
**Versión:** 1.0
**Estado:** ✅ Categorías completas, Marcas y Unidades pendientes
