# Guía de Integración - Marketplace Page

## 📋 Resumen

Se ha implementado la página principal del **Marketplace** para usuarios sin empresa. Esta página permite explorar productos y empresas de todo el marketplace.

## 🎯 Características Implementadas

### 1. **MarketplacePage** (`presentation/pages/marketplace_page.dart`)
Página principal con:
- AppBar personalizado con gradiente
- Barra de búsqueda con filtros
- Sección de categorías horizontales
- Productos destacados
- Empresas destacadas
- FAB para crear empresa

### 2. **Widgets Reutilizables**

#### `MarketplaceAppBar`
- AppBar expandible con gradiente azul
- Iconos de notificaciones y carrito
- Patrón de fondo decorativo

#### `MarketplaceSearchBar`
- Campo de búsqueda con filtros
- Bottom sheet de filtros (categoría, precio, empresa, ubicación)

#### `MarketplaceCategoriesSection`
- Lista horizontal de categorías
- 8 categorías predefinidas con iconos y colores

#### `MarketplaceFeaturedProductsSection`
- Cards de productos con:
  - Imagen, nombre, precio
  - Badge de descuento
  - Rating con estrellas
  - Botón de favoritos

#### `MarketplaceCompaniesSection`
- Cards de empresas con:
  - Logo, nombre, descripción
  - Rating y cantidad de productos
  - Botón de seguir

## 🔗 Integración con el Flujo de Autenticación

### Paso 1: Importar la página

```dart
import 'package:syncronize/features/marketplace/presentation/pages/marketplace_page.dart';
```

### Paso 2: Navegar desde Login

En tu `LoginPage` o donde manejes la respuesta del login, agrega:

```dart
// Después de un login exitoso en modo marketplace
if (authResponse.mode == 'marketplace') {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => const MarketplacePage(),
    ),
  );
}
```

### Paso 3: Integración con LoginCubit

En tu `login_page.dart`, modifica el listener del BlocListener:

```dart
BlocListener<LoginCubit, LoginState>(
  listener: (context, state) {
    if (state.response is Success) {
      final authResponse = (state.response as Success).data;
      
      if (authResponse.requiresSelection) {
        // Mostrar selector de modo
        ModeSelectionBottomSheet.show(
          context: context,
          modeOptions: authResponse.options ?? [],
          onModeSelected: (modeType, subdominioEmpresa) {
            if (modeType == 'marketplace') {
              // Login en modo marketplace
              context.read<LoginCubit>().loginWithMode(
                email: email,
                password: password,
                loginMode: 'marketplace',
              );
            } else {
              // Login en modo management
              context.read<LoginCubit>().loginWithMode(
                email: email,
                password: password,
                loginMode: 'management',
                subdominioEmpresa: subdominioEmpresa,
              );
            }
          },
        );
      } else if (authResponse.mode == 'marketplace') {
        // Navegar directamente a Marketplace
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MarketplacePage(),
          ),
        );
      } else if (authResponse.mode == 'management') {
        // Navegar a Management Dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ManagementDashboard(),
          ),
        );
      }
    }
  },
  child: // ... tu formulario de login
)
```

### Paso 4: Integración con Google Sign-In

Similar al login tradicional:

```dart
BlocListener<LoginCubit, LoginState>(
  listener: (context, state) {
    if (state.response is Success) {
      final authResponse = (state.response as Success).data;
      
      if (authResponse.requiresSelection) {
        // Mostrar selector de modo
        ModeSelectionBottomSheet.show(
          context: context,
          modeOptions: authResponse.options ?? [],
          onModeSelected: (modeType, subdominioEmpresa) {
            if (modeType == 'marketplace') {
              context.read<LoginCubit>().signInWithGoogleAndMode(
                loginMode: 'marketplace',
              );
            } else {
              context.read<LoginCubit>().signInWithGoogleAndMode(
                loginMode: 'management',
                subdominioEmpresa: subdominioEmpresa,
              );
            }
          },
        );
      } else if (authResponse.mode == 'marketplace') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MarketplacePage(),
          ),
        );
      }
    }
  },
  child: // ... botón de Google Sign-In
)
```

## 🎨 Personalización

### Colores
Los colores principales están definidos en cada widget. Para cambiarlos globalmente:

```dart
// En tu theme
ThemeData(
  primaryColor: Colors.blue,
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
)
```

### Categorías
Para modificar las categorías, edita `marketplace_categories_section.dart`:

```dart
_CategoryCard(
  icon: Icons.tu_icono,
  label: 'Tu Categoría',
  color: Colors.tuColor,
  onTap: () {
    // Navegar a productos de esta categoría
  },
),
```

## 🔄 Próximos Pasos (TODOs)

1. **Conectar con API real**:
   - Crear `MarketplaceCubit` para gestión de estado
   - Implementar `MarketplaceRepository`
   - Crear datasources para obtener productos y empresas

2. **Implementar funcionalidades**:
   - Búsqueda de productos
   - Filtros avanzados
   - Detalle de producto
   - Perfil de empresa
   - Carrito de compras
   - Favoritos

3. **Navegación**:
   - Implementar rutas con `go_router` o `Navigator 2.0`
   - Deep linking para productos y empresas

4. **Optimizaciones**:
   - Caché de imágenes
   - Paginación infinita
   - Pull to refresh

## 📱 Ejemplo de Uso Completo

```dart
// En tu main.dart o router
MaterialApp(
  routes: {
    '/marketplace': (context) => const MarketplacePage(),
    '/management': (context) => const ManagementDashboard(),
    // ... otras rutas
  },
)

// Desde cualquier parte de la app
Navigator.pushNamed(context, '/marketplace');
```

## 🐛 Troubleshooting

### Error: "Target of URI doesn't exist"
- Asegúrate de que todos los archivos estén en las rutas correctas
- Ejecuta `flutter pub get`

### Imágenes no cargan
- Las URLs de placeholder son solo para demo
- Reemplaza con URLs reales de tu API

### Performance issues
- Implementa lazy loading para las listas
- Usa `cached_network_image` para las imágenes

## 📚 Recursos Adicionales

- [Flutter Documentation](https://flutter.dev/docs)
- [Material Design Guidelines](https://material.io/design)
- [BLoC Pattern](https://bloclibrary.dev/)