# Flujo de Marketplace Público - Documentación

## 📋 Resumen de Cambios

Se implementó un flujo de navegación tipo "Mercado Libre" donde el Marketplace es público y accesible sin autenticación. Los usuarios pueden explorar productos y solo necesitan iniciar sesión para realizar acciones específicas.

## 🎯 Objetivo

Reducir la fricción inicial permitiendo que los usuarios exploren el marketplace antes de crear una cuenta, mejorando así la tasa de conversión y retención.

## 🔧 Cambios Implementados

### 1. **AppRouter Modificado**
`lib/config/routes/app_router.dart`

**Cambios:**
- ✅ `initialLocation` cambiado de `/login` a `/marketplace`
- ✅ Marketplace agregado a rutas públicas
- ✅ Lógica de redirect actualizada para permitir acceso público
- ✅ Soporte para parámetro `returnTo` en la ruta de login

**Rutas públicas:**
- `/marketplace` - Página principal (no requiere auth)
- `/login` - Inicio de sesión
- `/register` - Registro
- `/verify-email` - Verificación de email

**Rutas protegidas:**
- `/home` - Página de usuario
- `/create-empresa` - Crear empresa
- `/empresa/*` - Dashboard y gestión de empresa
- Todas las demás rutas requieren autenticación

### 2. **Drawer Adaptable**
`lib/features/marketplace/presentation/widgets/marketplace_drawer.dart`

**Componentes creados:**
- `MarketplaceDrawer` - Drawer principal que se adapta al estado de autenticación
- `_GuestDrawerContent` - Contenido para usuarios NO autenticados
- `_AuthenticatedDrawerContent` - Contenido para usuarios autenticados

**Funcionalidades:**

#### Para usuarios Guest (NO autenticados):
- Header con avatar genérico
- Botones de "Iniciar Sesión" y "Crear Cuenta"
- Menú de exploración:
  - Marketplace
  - Categorías
  - Ofertas
- Sección de información:
  - Ayuda
  - Acerca de

#### Para usuarios Autenticados:
- Header con datos del usuario (nombre, email, avatar)
- Mi Cuenta:
  - Mis Compras
  - Favoritos
  - Mi Perfil
- Mi Negocio:
  - Mi Empresa
  - Crear Empresa
- Explorar:
  - Marketplace
  - Categorías
- Configuración:
  - Configuración
  - Ayuda
- Cerrar Sesión

### 3. **MarketplacePage Actualizado**
`lib/features/marketplace/presentation/pages/marketplace_page.dart`

**Cambios:**
- ✅ Drawer agregado: `drawer: const MarketplaceDrawer()`
- ✅ Protección del botón "Crear Empresa" usando `AuthHelper`
- ✅ Diálogo de autenticación con deep linking

### 4. **AuthHelper Utility**
`lib/core/utils/auth_helper.dart`

**Clase utilitaria para:**
- Verificar estado de autenticación
- Proteger acciones que requieren login
- Mostrar diálogos de autenticación requerida
- Manejar deep linking (returnTo)

**Métodos principales:**

```dart
// Verificar si está autenticado
AuthHelper.isAuthenticated(context)

// Ejecutar acción solo si está autenticado
AuthHelper.requireAuth(
  context,
  returnTo: '/ruta-destino',
  title: 'Título del diálogo',
  message: 'Mensaje personalizado',
  onAuthenticated: () {
    // Código a ejecutar si está autenticado
  },
)

// Navegar a ruta protegida
AuthHelper.navigateToProtectedRoute(
  context,
  '/ruta-protegida',
)

// Mostrar snackbar de auth requerida
AuthHelper.showAuthRequiredSnackBar(context)
```

### 5. **LoginPage con Deep Linking**
`lib/features/auth/presentation/pages/login_page.dart`

**Cambios:**
- ✅ Acepta parámetro `returnTo` en el constructor
- ✅ Después del login exitoso, redirige a `returnTo` si existe
- ✅ Si no hay `returnTo`, redirige al marketplace por defecto

**Uso:**
```dart
// Login normal
context.push('/login')

// Login con retorno a ruta específica
context.push('/login?returnTo=/create-empresa')
```

## 🔄 Flujo de Usuario

### Usuario NO Autenticado (Guest)

```
1. App inicia → Marketplace (público)
   ↓
2. Usuario explora productos
   ↓
3. Usuario intenta acción protegida (ej: crear empresa)
   ↓
4. Aparece diálogo: "Necesitas iniciar sesión"
   ↓
5. Usuario toca "Iniciar Sesión"
   ↓
6. Navega a /login?returnTo=/create-empresa
   ↓
7. Completa login
   ↓
8. Redirige automáticamente a /create-empresa
```

### Usuario Autenticado

```
1. App inicia → Marketplace (completo)
   ↓
2. Drawer muestra info del usuario
   ↓
3. Todas las acciones disponibles
   ↓
4. Puede navegar a Mi Empresa, Mi Perfil, etc.
```

## 🎨 Ejemplo de Uso

### Proteger una acción cualquiera

```dart
// En cualquier widget
ElevatedButton(
  onPressed: () {
    AuthHelper.requireAuth(
      context,
      returnTo: '/ruta-despues-del-login',
      title: 'Inicia Sesión',
      message: 'Necesitas una cuenta para realizar esta acción',
      onAuthenticated: () {
        // Código que se ejecuta solo si está autenticado
        print('Usuario autenticado, ejecutando acción...');
      },
    );
  },
  child: Text('Acción Protegida'),
)
```

### Navegar a ruta protegida

```dart
// Forma simple
AuthHelper.navigateToProtectedRoute(
  context,
  '/mi-perfil',
  title: 'Perfil Privado',
  message: 'Inicia sesión para ver tu perfil',
);

// Si está autenticado: navega a /mi-perfil
// Si NO está autenticado: muestra diálogo y guarda returnTo
```

## ✅ Ventajas de este Enfoque

1. **Menor fricción inicial** - Los usuarios ven valor antes de registrarse
2. **Mayor conversión** - Exploran → Se interesan → Se registran
3. **UX familiar** - Patrón usado por apps exitosas (Mercado Libre, Amazon)
4. **Deep linking automático** - Los usuarios vuelven a donde estaban
5. **Código reutilizable** - `AuthHelper` centraliza la lógica de protección
6. **Fácil mantenimiento** - Un solo lugar para modificar comportamiento de auth

## 📱 Pantallas Afectadas

### Páginas Públicas
- ✅ MarketplacePage - Totalmente pública
- ✅ LoginPage - Accesible sin auth
- ✅ RegisterPage - Accesible sin auth

### Páginas Protegidas (requieren auth)
- 🔒 HomePage - Perfil del usuario
- 🔒 CreateEmpresaPage - Crear empresa
- 🔒 EmpresaDashboardPage - Dashboard de empresa
- 🔒 ProductosPage - Gestión de productos
- 🔒 Todas las rutas bajo `/empresa/*`

## 🔐 Seguridad

- ✅ El backend debe validar SIEMPRE la autenticación en endpoints protegidos
- ✅ El frontend solo oculta UI, no depende de él para seguridad
- ✅ Los tokens se manejan de forma segura en `SecureStorage`
- ✅ El `AuthInterceptor` agrega automáticamente el token a peticiones protegidas

## 🚀 Próximos Pasos Sugeridos

1. **Implementar página de Favoritos** - Para usuarios autenticados
2. **Agregar Mis Compras** - Historial de compras del usuario
3. **Sistema de Carrito** - Que persista entre sesiones para usuarios auth
4. **Deep linking para productos** - `/producto/:id` público
5. **Sistema de reseñas** - Requiere autenticación para escribir
6. **Notificaciones** - Solo para usuarios autenticados

## 📝 Notas Importantes

- El `AppInitializer` NO redirige según estado de auth
- Todas las redirecciones están en `AppRouter.redirect`
- El Drawer se actualiza automáticamente con `BlocBuilder<AuthBloc>`
- El parámetro `returnTo` se pasa como query parameter: `?returnTo=/ruta`

## 🐛 Debugging

Si algo no funciona:

1. Verificar que el `AuthBloc` esté emitiendo estados correctamente
2. Revisar logs de navegación en `AppRouter`
3. Confirmar que `returnTo` se esté pasando correctamente
4. Verificar que las rutas estén definidas en `AppRouter.routes`

## 📞 Soporte

Para más información sobre:
- **AuthHelper**: Ver `lib/core/utils/auth_helper.dart`
- **Drawer**: Ver `lib/features/marketplace/presentation/widgets/marketplace_drawer.dart`
- **Rutas**: Ver `lib/config/routes/app_router.dart`
- **Login con returnTo**: Ver `lib/features/auth/presentation/pages/login_page.dart`
