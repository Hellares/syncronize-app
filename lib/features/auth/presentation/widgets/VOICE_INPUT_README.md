# 🎤 Guía de Uso: Voice Input en CustomText

## Descripción

Esta implementación agrega funcionalidad de dictado por voz (speech-to-text) al widget `CustomText` de manera global y reutilizable en toda la aplicación.

## ✨ Características

- **Singleton Service**: Servicio global `SpeechToTextService` para gestionar el reconocimiento de voz
- **Fácil integración**: Solo activa `enableVoiceInput: true` en cualquier `CustomText`
- **Visual feedback**: Ícono del micrófono cambia a rojo cuando está escuchando
- **Soporte multiidioma**: Configurable con `voiceLocale` (por defecto español)
- **Permisos automáticos**: Solicita permisos de micrófono automáticamente
- **Compatible con todas las features**: Funciona con validación, password fields, etc.

## 📦 Paquetes instalados

```yaml
dependencies:
  speech_to_text: ^7.0.0      # Reconocimiento de voz
  permission_handler: ^11.0.1  # Manejo de permisos
```

## 🚀 Uso básico

### 1. Habilitar voice input en CustomText

```dart
CustomText(
  label: 'Nombre completo',
  hintText: 'Escribe o dicta tu nombre',
  controller: _textController,
  enableVoiceInput: true, // 👈 Esto habilita el micrófono
)
```

### 2. Configurar idioma específico (opcional)

```dart
CustomText(
  label: 'Mensaje',
  controller: _messageController,
  enableVoiceInput: true,
  voiceLocale: 'es_CO', // 👈 Español Colombia
)
```

Locales comunes:
- `es_ES` - Español (España) - **por defecto**
- `es_MX` - Español (México)
- `es_CO` - Español (Colombia)
- `es_AR` - Español (Argentina)
- `en_US` - Inglés (Estados Unidos)

### 3. Ejemplos completos

#### Campo de texto simple
```dart
final _controller = TextEditingController();

CustomText(
  label: 'Descripción del producto',
  hintText: 'Dicta o escribe la descripción',
  controller: _controller,
  enableVoiceInput: true,
  fieldType: FieldType.text,
  maxLines: 3,
)
```

#### Campo con validación
```dart
CustomText(
  label: 'Email',
  controller: _emailController,
  enableVoiceInput: true,
  fieldType: FieldType.email,
  required: true,
  validator: FieldValidators.validateEmail,
)
```

#### Campo deshabilitado (el micrófono no aparecerá)
```dart
CustomText(
  label: 'Solo lectura',
  controller: _readOnlyController,
  enableVoiceInput: true,
  enabled: false, // 👈 El micrófono se oculta automáticamente
)
```

## 🔧 Servicio SpeechToTextService

El servicio es un **Singleton** que se puede usar directamente si necesitas más control:

```dart
import 'package:syncronize/core/services/speech_to_text_service.dart';

final speechService = SpeechToTextService();

// Verificar disponibilidad
bool available = await speechService.isAvailable();

// Inicializar manualmente
bool initialized = await speechService.initialize();

// Iniciar escucha personalizada
await speechService.startListening(
  onResult: (text) {
    print('Texto reconocido: $text');
  },
  localeId: 'es_ES',
);

// Detener
await speechService.stopListening();

// Obtener idiomas disponibles
List<LocaleName> locales = await speechService.getAvailableLocales();
```

## 📱 Permisos configurados

### Android (AndroidManifest.xml)
Ya configurado:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
```

### iOS (Info.plist)
Ya configurado:
```xml
<key>NSSpeechRecognitionUsageDescription</key>
<string>Esta aplicación necesita acceso al reconocimiento de voz para transcribir texto mediante dictado.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Esta aplicación necesita acceso al micrófono para habilitar la función de dictado por voz.</string>
```

## 🎯 Comportamiento

1. **Al presionar el micrófono**:
   - Se solicitan permisos (solo la primera vez)
   - El ícono cambia a rojo indicando que está escuchando
   - El texto reconocido se va agregando al campo en tiempo real

2. **Al volver a presionar**:
   - Se detiene la escucha
   - El ícono vuelve a su estado normal
   - El texto queda en el campo

3. **Cuando hay múltiples íconos**:
   - Se muestran todos en fila (validación, micrófono, sufijo personalizado)
   - El orden es: indicador de validación → micrófono → ícono personalizado

## ⚠️ Consideraciones

- **Conexión a internet**: Algunos dispositivos Android requieren internet para speech-to-text
- **Idioma del dispositivo**: Si el locale configurado no está disponible, se usa `es_ES` por defecto
- **Resultados parciales**: El texto se actualiza en tiempo real mientras hablas
- **Password fields**: El micrófono aparece incluso en campos de contraseña (si lo habilitas)

## 🧪 Probar la implementación

1. Instalar dependencias:
```bash
flutter pub get
```

2. Ver ejemplo de uso:
```dart
import 'package:syncronize/features/auth/presentation/widgets/custom_text_voice_example.dart';

// En tu router o navegación:
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const CustomTextVoiceExample()),
);
```

## 🎨 Personalización visual

El botón del micrófono usa los mismos estilos del widget:
- Color normal: `Colors.grey[600]` o `colorIcon` si se especifica
- Color enfocado: `Color(0xFF666666)`
- Color escuchando: `Colors.red`
- Tamaño del ícono: `20px`

Para cambiar estos estilos, modifica el método `_buildVoiceButton()` en `custom_text.dart`:

```dart
Widget _buildVoiceButton() {
  return GestureDetector(
    onTap: _toggleVoiceInput,
    child: Container(
      padding: const EdgeInsets.all(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          _isListening ? Icons.mic : Icons.mic_none,
          size: 20, // 👈 Cambiar tamaño
          color: _isListening
              ? Colors.red // 👈 Color cuando escucha
              : (_isFocused ? const Color(0xFF666666) : Colors.grey[600]),
        ),
      ),
    ),
  );
}
```

## 📝 Notas importantes

- El servicio se inicializa **automáticamente** la primera vez que se presiona el micrófono
- No es necesario inicializarlo manualmente en el `initState()`
- El servicio maneja la limpieza automática cuando el widget se destruye
- Compatible con todos los `FieldType` (text, email, number, password)

## 🐛 Debugging

Si tienes problemas, revisa los logs:
```dart
// Los logs se muestran con estos emojis:
// ✅ - Inicialización exitosa
// ❌ - Errores
// 🎤 - Inicio de escucha
// 🛑 - Detención de escucha
// 📢 - Cambios de estado
```

Habilita verbose logging en el servicio si necesitas más detalles.

## 🔄 Migración de campos existentes

Si ya tienes `CustomText` en tu app y quieres agregar voice input:

**Antes:**
```dart
CustomText(
  label: 'Nombre',
  controller: _controller,
)
```

**Después:**
```dart
CustomText(
  label: 'Nombre',
  controller: _controller,
  enableVoiceInput: true, // 👈 Solo agrega esta línea
)
```

¡Eso es todo! 🎉
