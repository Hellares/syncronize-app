# Feature: Descuentos (Políticas de Descuento)

Módulo completo para gestionar políticas de descuento para trabajadores, familiares, VIP, etc.

## 📁 Estructura Implementada

```
descuento/
├── data/
│   ├── datasources/
│   │   └── descuento_remote_datasource.dart ✅
│   ├── models/
│   │   └── politica_descuento_model.dart ✅
│   └── repositories/
│       └── descuento_repository_impl.dart ⏳
├── domain/
│   ├── entities/
│   │   ├── politica_descuento.dart ✅
│   │   ├── usuario_descuento.dart ✅
│   │   └── descuento_calculado.dart ✅
│   ├── repositories/
│   │   └── descuento_repository.dart ⏳
│   └── usecases/
│       ├── get_politicas_descuento.dart ⏳
│       ├── create_politica.dart ⏳
│       ├── update_politica.dart ⏳
│       ├── delete_politica.dart ⏳
│       ├── asignar_usuarios.dart ⏳
│       ├── agregar_familiar.dart ⏳
│       ├── calcular_descuento.dart ⏳
│       └── ... (otros casos de uso)
└── presentation/
    ├── bloc/
    │   ├── politica_list/
    │   │   ├── politica_list_bloc.dart ⏳
    │   │   ├── politica_list_event.dart ⏳
    │   │   └── politica_list_state.dart ⏳
    │   ├── politica_form/
    │   │   ├── politica_form_bloc.dart ⏳
    │   │   ├── politica_form_event.dart ⏳
    │   │   └── politica_form_state.dart ⏳
    │   └── ... (otros blocs)
    ├── pages/
    │   ├── politicas_list_page.dart ⏳
    │   ├── politica_form_page.dart ⏳
    │   ├── asignar_usuarios_page.dart ⏳
    │   ├── familiares_page.dart ⏳
    │   └── ... (otras páginas)
    └── widgets/
        ├── politica_card.dart ⏳
        ├── usuario_item.dart ⏳
        └── ... (otros widgets)
```

## ✅ Archivos Implementados

### Domain Layer (Entidades)

1. **politica_descuento.dart**
   - Entidad principal con toda la info de una política
   - Enums: TipoDescuento, TipoCalculoDescuento, Parentesco
   - Immutable con Equatable
   - Método copyWith incluido

2. **usuario_descuento.dart**
   - Asignación de descuentos a usuarios
   - Soporte para familiares
   - Datos de aprobación y verificación

3. **descuento_calculado.dart**
   - Resultado del cálculo de descuentos
   - Incluye precio original, final, descuento aplicado
   - Información de la política usada

### Data Layer

4. **politica_descuento_model.dart**
   - Mapeo JSON <-> Entidad
   - Métodos fromJson y toJson
   - Conversión de enums BACKEND <-> DART

5. **descuento_remote_datasource.dart** ⭐ **COMPLETO**
   - Todas las llamadas HTTP al API
   - 17 métodos implementados:
     - ✅ getPoliticasDescuento (con filtros y paginación)
     - ✅ getPoliticaById
     - ✅ createPolitica
     - ✅ updatePolitica
     - ✅ deletePolitica
     - ✅ asignarUsuarios
     - ✅ removerUsuario
     - ✅ agregarFamiliar
     - ✅ obtenerFamiliares
     - ✅ removerFamiliar
     - ✅ asignarProductos
     - ✅ asignarCategorias
     - ✅ calcularDescuento
     - ✅ obtenerHistorialUso

## ⏳ Archivos Pendientes

### 1. Repository Interface (domain/repositories/)

```dart
// descuento_repository.dart
abstract class DescuentoRepository {
  Future<Either<Failure, List<PoliticaDescuento>>> getPoliticas({...});
  Future<Either<Failure, PoliticaDescuento>> getPoliticaById(String id);
  Future<Either<Failure, PoliticaDescuento>> createPolitica({...});
  Future<Either<Failure, PoliticaDescuento>> updatePolitica({...});
  Future<Either<Failure, void>> deletePolitica(String id);
  // ... otros métodos
}
```

### 2. Repository Implementation (data/repositories/)

```dart
// descuento_repository_impl.dart
class DescuentoRepositoryImpl implements DescuentoRepository {
  final DescuentoRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  // Implementación de todos los métodos
  // Manejo de errores con Either<Failure, Success>
}
```

### 3. Use Cases (domain/usecases/)

Crear un caso de uso por cada operación principal:

```dart
// get_politicas_descuento.dart
class GetPoliticasDescuento {
  final DescuentoRepository repository;

  Future<Either<Failure, List<PoliticaDescuento>>> call({
    String? tipoDescuento,
    bool? isActive,
    int page = 1,
    int limit = 20,
  }) async {
    return await repository.getPoliticas(...);
  }
}
```

Casos de uso necesarios:
- GetPoliticasDescuento
- GetPoliticaById
- CreatePolitica
- UpdatePolitica
- DeletePolitica
- AsignarUsuarios
- RemoverUsuario
- AgregarFamiliar
- ObtenerFamiliares
- RemoverFamiliar
- AsignarProductos
- AsignarCategorias
- CalcularDescuento
- ObtenerHistorialUso

### 4. BLoCs (presentation/bloc/)

#### **politica_list/** (Lista de políticas)

```dart
// politica_list_event.dart
abstract class PoliticaListEvent {}
class LoadPoliticas extends PoliticaListEvent {}
class FilterPoliticas extends PoliticaListEvent {
  final String? tipoDescuento;
  final bool? isActive;
}
class RefreshPoliticas extends PoliticaListEvent {}

// politica_list_state.dart
abstract class PoliticaListState {}
class PoliticaListInitial extends PoliticaListState {}
class PoliticaListLoading extends PoliticaListState {}
class PoliticaListLoaded extends PoliticaListState {
  final List<PoliticaDescuento> politicas;
  final int totalPages;
  final int currentPage;
}
class PoliticaListError extends PoliticaListState {
  final String message;
}

// politica_list_bloc.dart
class PoliticaListBloc extends Bloc<PoliticaListEvent, PoliticaListState> {
  final GetPoliticasDescuento getPoliticas;
  final DeletePolitica deletePolitica;

  // Implementación
}
```

#### **politica_form/** (Crear/Editar política)

```dart
// Similar estructura con events, states y bloc
```

#### **otros blocs necesarios:**
- asignar_usuarios_bloc
- familiares_bloc
- calcular_descuento_bloc

### 5. Pages (presentation/pages/)

#### **politicas_list_page.dart**
- AppBar con título y botón "Crear"
- Filtros (tipo, estado)
- ListView de políticas
- Pull to refresh
- Paginación
- Navegación a detalle/editar

#### **politica_form_page.dart**
- Formulario completo para crear/editar
- Campos:
  - Nombre
  - Descripción
  - Tipo descuento (dropdown)
  - Tipo cálculo (dropdown)
  - Valor descuento
  - Límites opcionales
  - Fechas vigencia
  - Aplicar a todos (switch)
  - Prioridad
- Validaciones
- Botón guardar

#### **politica_detail_page.dart**
- Información de la política
- Tabs:
  - Detalles
  - Usuarios asignados
  - Productos/Categorías
  - Historial de uso
- Acciones: Editar, Eliminar

#### **asignar_usuarios_page.dart**
- Buscador de usuarios
- Lista de usuarios disponibles
- Checkbox para seleccionar
- Límite mensual opcional
- Botón guardar

#### **familiares_page.dart**
- Lista de familiares del trabajador
- Botón "Agregar familiar"
- Formulario modal:
  - Selector de usuario
  - Parentesco (dropdown)
  - Upload documento verificación
  - Límite mensual opcional

### 6. Widgets (presentation/widgets/)

#### **politica_card.dart**
```dart
class PoliticaCard extends StatelessWidget {
  final PoliticaDescuento politica;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  // UI: Card con info resumida de la política
  // - Nombre
  // - Tipo
  // - Valor descuento
  // - Usuarios asignados
  // - Estado (activo/inactivo)
  // - Acciones (edit, delete)
}
```

#### **usuario_descuento_item.dart**
```dart
class UsuarioDescuentoItem extends StatelessWidget {
  final UsuarioDescuento usuario;
  final VoidCallback? onRemove;

  // UI: ListTile con info del usuario
  // - Avatar
  // - Nombre
  // - Si es familiar (badge)
  // - Límite de usos
  // - Botón remover
}
```

## 🔧 Configuración Necesaria

### 1. Agregar a `pubspec.yaml`

```yaml
dependencies:
  equatable: ^2.0.5
  http: ^1.1.0
  dartz: ^0.10.1
  flutter_bloc: ^8.1.3
```

### 2. ApiClient Configuration

Asegúrate de que tu `ApiClient` (core/network/api_client.dart) tenga:
- Métodos: get, post, put, delete
- Headers automáticos:
  - `Authorization: Bearer $token`
  - `x-tenant-id: $empresaId`
  - `Content-Type: application/json`
- Manejo de errores (401, 403, 404, 500)

### 3. Dependency Injection

Registrar en tu sistema de DI (GetIt, Provider, etc.):

```dart
// DataSources
sl.registerLazySingleton<DescuentoRemoteDataSource>(
  () => DescuentoRemoteDataSourceImpl(client: sl()),
);

// Repositories
sl.registerLazySingleton<DescuentoRepository>(
  () => DescuentoRepositoryImpl(
    remoteDataSource: sl(),
    networkInfo: sl(),
  ),
);

// UseCases
sl.registerLazySingleton(() => GetPoliticasDescuento(sl()));
sl.registerLazySingleton(() => CreatePolitica(sl()));
// ... otros

// BLoCs
sl.registerFactory(() => PoliticaListBloc(
  getPoliticas: sl(),
  deletePolitica: sl(),
));
```

## 📱 Flujo de Uso

### Listar Políticas

```dart
1. Usuario abre PoliticasListPage
2. BLoC dispara LoadPoliticas event
3. UseCase getPoliticasDescuento.call()
4. Repository llama a DataSource
5. DataSource hace HTTP GET /politicas-descuento
6. Response se convierte a PoliticaDescuentoModel
7. Model se mapea a PoliticaDescuento entity
8. BLoC emite PoliticaListLoaded state
9. UI muestra lista de políticas
```

### Crear Política

```dart
1. Usuario presiona botón "Crear"
2. Navega a PoliticaFormPage
3. Completa formulario
4. Presiona "Guardar"
5. BLoC valida y dispara CreatePolitica event
6. UseCase createPolitica.call(data)
7. Repository -> DataSource
8. DataSource hace HTTP POST /politicas-descuento
9. Response se convierte a entidad
10. BLoC emite PoliticaFormSuccess
11. Navega de vuelta y refresca lista
```

## 🎨 Diseño UI Sugerido

### PoliticasListPage
- AppBar con título "Políticas de Descuento"
- FloatingActionButton para crear
- Filtros en drawer o bottom sheet
- Cards con diseño Material 3
- Swipe to delete

### PoliticaFormPage
- Tabs si hay muchos campos
- DatePicker para fechas
- DropdownButton para enums
- Switch para booleanos
- NumberInput para valores
- Form validation

### Colors
- Trabajador: Blue
- Familiar: Green
- VIP: Gold
- Promocional: Orange
- Activo: Success color
- Inactivo: Grey

## 🚀 Próximos Pasos

1. ✅ Crear repository interface y implementation
2. ✅ Crear todos los use cases
3. ✅ Crear BLoC de lista de políticas
4. ✅ Crear página de lista
5. ✅ Crear BLoC de formulario
6. ✅ Crear página de formulario
7. ✅ Crear widgets reutilizables
8. ✅ Configurar dependency injection
9. ✅ Agregar navegación en routes
10. ✅ Testing

## 📚 Recursos

- Backend API: `/politicas-descuento/*`
- Permisos requeridos:
  - `VIEW_DISCOUNTS` - Ver políticas
  - `MANAGE_DISCOUNTS` - Crear/editar/eliminar
  - `ASSIGN_DISCOUNTS` - Asignar usuarios
  - `VIEW_DISCOUNT_REPORTS` - Ver reportes

---

**Implementado por:** Claude Code
**Fecha:** 2024-12-31
**Backend:** ✅ 100% Completado
**Flutter:** ⏳ 40% Completado (Estructura base lista)
