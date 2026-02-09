# 🚀 SuperCustomButton - Guía Completa

## ✨ Fusión Exitosa

Este CustomButton es la **fusión completa** de:
- ✅ **Base**: `core/widgets/custom_button.dart` (4 estados, gradientes, animaciones)
- ✅ **Nuevas características**: `auth/widgets/custom_button.dart` (SVG/PNG, outlined, glow)

---

## 📦 Características Completas

### 🎯 Estados Avanzados
- **4 Estados**: idle, loading, success, error
- **Compatibilidad simple**: `isLoading: true` (sin usar buttonState)
- **Textos personalizables**: loadingText, successText, errorText

### 🎨 Estilos
- **Gradientes**: Fondos degradados completos
- **Colores sólidos**: backgroundColor
- **Variante Outlined**: `isOutlined: true`
- **Bordes animados**: Color y grosor cambian al presionar

### 🖼️ Íconos Multimedia
- **Widget custom**: `icon: Icon(Icons.check)`
- **SVG**: `iconPath: 'assets/icons/logo.svg'`
- **PNG/JPG**: `iconPath: 'assets/images/google.png'`
- **Tamaño**: `iconSize: 24`

### ✨ Efectos Visuales
- **Glow (Neón)**: `enableGlow: true`
- **Glow al presionar**: `glowOnPressOnly: true`
- **Color del glow**: `glowColor: Colors.purple`
- **Intensidad**: `glowIntensity: 0.8` (0.0 - 1.0)
- **Sombras**: `enableShadows: true`

### 🎬 Animaciones
- Escala al presionar
- Flash effect
- Animaciones de borde
- Sombras animadas

---

## 📚 Ejemplos de Uso

### 1️⃣ Botón Simple (Compatibilidad con código existente)
```dart
CustomButton(
  text: 'Guardar',
  onPressed: () => print('Guardado!'),
  backgroundColor: Colors.blue,
  borderColor: Colors.blue,
)
```

### 2️⃣ Botón con Loading Simple
```dart
CustomButton(
  text: 'Procesando...',
  onPressed: isLoading ? null : _handleSubmit,
  isLoading: isLoading, // ✅ Forma simple
  backgroundColor: Colors.green,
)
```

### 3️⃣ Botón con 4 Estados (Avanzado)
```dart
CustomButton(
  text: 'Enviar',
  onPressed: _handleSubmit,
  buttonState: _currentState, // idle, loading, success, error
  loadingText: 'Enviando...',
  successText: '¡Enviado!',
  errorText: 'Error',
  backgroundColor: Colors.blue,
  borderColor: Colors.blue,
)
```

### 4️⃣ Botón con Ícono Widget
```dart
CustomButton(
  text: 'Agregar',
  onPressed: _addItem,
  icon: Icon(Icons.add, size: 16, color: Colors.white),
  backgroundColor: Colors.purple,
  borderColor: Colors.purple,
)
```

### 5️⃣ Botón con Ícono SVG
```dart
CustomButton(
  text: 'Login con Google',
  onPressed: _loginWithGoogle,
  iconPath: 'assets/logos/google_logo.svg', // ✅ SVG
  iconSize: 20,
  backgroundColor: Colors.white,
  textColor: Colors.black87,
  borderColor: Colors.grey,
)
```

### 6️⃣ Botón con Ícono PNG
```dart
CustomButton(
  text: 'Login con Facebook',
  onPressed: _loginWithFacebook,
  iconPath: 'assets/logos/facebook_logo.png', // ✅ PNG
  iconSize: 20,
  backgroundColor: Color(0xFF1877F2),
)
```

### 7️⃣ Botón Outlined
```dart
CustomButton(
  text: 'Cancelar',
  onPressed: _cancel,
  isOutlined: true, // ✅ Variante outlined
  borderColor: Colors.red,
  textColor: Colors.red,
  borderWidth: 2.0,
)
```

### 8️⃣ Botón con Glow Effect (Neón)
```dart
CustomButton(
  text: 'Premium',
  onPressed: _upgradeToPremium,
  backgroundColor: Colors.black,
  borderColor: Colors.purple,
  enableGlow: true, // ✅ Glow activado
  glowColor: Colors.purple,
  glowIntensity: 0.8,
  textColor: Colors.white,
)
```

### 9️⃣ Botón con Glow solo al presionar
```dart
CustomButton(
  text: 'Activar',
  onPressed: _activate,
  backgroundColor: Colors.blue,
  borderColor: Colors.cyan,
  enableGlow: true,
  glowOnPressOnly: true, // ✅ Glow solo al presionar
  glowColor: Colors.cyan,
)
```

### 🔟 Botón con Gradiente
```dart
CustomButton(
  text: 'Siguiente',
  onPressed: _next,
  gradient: LinearGradient(
    colors: [Colors.blue, Colors.purple],
  ),
  borderColor: Colors.purple,
  enableGlow: true,
  glowColor: Colors.purple,
)
```

### 1️⃣1️⃣ Botón Outlined + Glow
```dart
CustomButton(
  text: 'VIP Access',
  onPressed: _vipAccess,
  isOutlined: true, // ✅ Outlined
  borderColor: Colors.amber,
  textColor: Colors.amber,
  borderWidth: 2.5,
  enableGlow: true, // ✅ + Glow
  glowColor: Colors.amber,
  glowIntensity: 1.0,
)
```

### 1️⃣2️⃣ Botón Full Custom (Todo combinado)
```dart
CustomButton(
  text: 'Super Botón',
  onPressed: _superAction,

  // Estado
  buttonState: ButtonState.idle,
  loadingText: 'Cargando...',
  successText: '¡Éxito!',
  errorText: 'Error',

  // Ícono SVG
  iconPath: 'assets/icons/star.svg',
  iconSize: 22,

  // Estilo
  gradient: LinearGradient(
    colors: [Colors.orange, Colors.red],
  ),
  borderColor: Colors.red,
  borderWidth: 2.0,
  borderRadius: 25,
  width: 200,
  height: 50,

  // Glow
  enableGlow: true,
  glowColor: Colors.red,
  glowIntensity: 0.7,

  // Texto
  fontSize: 14,
  fontWeight: FontWeight.bold,
  fontFamily: 'Roboto',

  // Animación
  showHapticFeedback: true,
)
```

---

## 🎨 Casos de Uso Reales

### Login con Redes Sociales
```dart
// Google
CustomButton(
  text: 'Continuar con Google',
  onPressed: _loginGoogle,
  iconPath: 'assets/logos/google.svg',
  iconSize: 20,
  backgroundColor: Colors.white,
  textColor: Colors.black87,
  borderColor: Colors.grey.shade300,
  borderWidth: 1.5,
)

// Facebook
CustomButton(
  text: 'Continuar con Facebook',
  onPressed: _loginFacebook,
  iconPath: 'assets/logos/facebook.png',
  backgroundColor: Color(0xFF1877F2),
)
```

### Botones de Acción
```dart
// Guardar (con estados)
CustomButton(
  text: 'Guardar',
  onPressed: _save,
  buttonState: _saveState,
  loadingText: 'Guardando...',
  successText: '¡Guardado!',
  errorText: 'Error al guardar',
  backgroundColor: Colors.green,
)

// Cancelar (outlined)
CustomButton(
  text: 'Cancelar',
  onPressed: _cancel,
  isOutlined: true,
  borderColor: Colors.red,
  textColor: Colors.red,
)
```

### Botones Premium con Glow
```dart
CustomButton(
  text: 'Upgrade a Premium',
  onPressed: _upgrade,
  gradient: LinearGradient(
    colors: [Colors.purple, Colors.deepPurple],
  ),
  borderColor: Colors.purple,
  enableGlow: true,
  glowColor: Colors.purple,
  glowIntensity: 0.9,
  icon: Icon(Icons.star, color: Colors.amber, size: 18),
)
```

---

## 🔧 Propiedades Completas

### Básicas
- `text` (String, required)
- `onPressed` (VoidCallback?)
- `enabled` (bool = true)

### Estados
- `buttonState` (ButtonState = idle)
- `isLoading` (bool = false) - Forma simple
- `loadingText` (String?)
- `successText` (String?)
- `errorText` (String?)

### Estilo
- `backgroundColor` (Color?)
- `gradient` (Gradient?)
- `borderColor` (Color?)
- `borderWidth` (double = 1.0)
- `width` (double?)
- `height` (double?)
- `borderRadius` (double?)
- `isOutlined` (bool = false) 🆕

### Íconos
- `icon` (Widget?) - Prioridad 1
- `iconPath` (String?) - SVG/PNG 🆕
- `iconSize` (double = 18) 🆕
- `iconColor` (Color?)

### Texto
- `fontSize` (double?)
- `fontWeight` (FontWeight?)
- `fontFamily` (String?) 🆕
- `textColor` (Color?)
- `textStyle` (TextStyle?)
- `padding` (EdgeInsetsGeometry?)

### Efectos
- `enableShadows` (bool = true)
- `enableGlow` (bool = false) 🆕
- `glowOnPressOnly` (bool = false) 🆕
- `glowColor` (Color?) 🆕
- `glowIntensity` (double = 0.65) 🆕

### Animación
- `animationDuration` (Duration)
- `showHapticFeedback` (bool = true)

---

## ✅ Compatibilidad

### Código Existente
✅ **100% compatible** con código que ya usa el CustomButton anterior
```dart
// Esto sigue funcionando igual
CustomButton(
  text: 'Click',
  onPressed: () {},
  backgroundColor: Colors.blue,
)
```

### Migración del auth/widgets
Si usabas el CustomButton de auth/widgets:
```dart
// Antes (auth/widgets)
CustomButton(
  text: 'Login',
  isLoading: true,
  iconPath: 'assets/logo.svg',
  isOutlined: true,
)

// Ahora (MISMO código funciona en core/widgets)
CustomButton(
  text: 'Login',
  isLoading: true,
  iconPath: 'assets/logo.svg',
  isOutlined: true,
)
```

---

## 🎯 Consejos de Uso

1. **Para loading simple**: Usa `isLoading: true`
2. **Para flujos complejos**: Usa `buttonState` (idle, loading, success, error)
3. **Para logos**: Usa `iconPath` con SVG/PNG
4. **Para íconos custom**: Usa `icon` widget
5. **Para efectos premium**: Activa `enableGlow`
6. **Para botones secundarios**: Usa `isOutlined: true`

---

## 🚀 Resultado Final

Ahora tienes **UN SOLO** CustomButton que puede hacer **TODO**:
- ✅ 4 estados (idle, loading, success, error)
- ✅ Gradientes
- ✅ SVG/PNG como íconos
- ✅ Variante outlined
- ✅ Glow effect (neón)
- ✅ Animaciones complejas
- ✅ 100% personalizable
- ✅ Compatibilidad total con código existente

**¡Un botón para gobernarlos a todos!** 👑
