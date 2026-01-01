# 🔍 Diagnóstico: "No veo las plantillas"

## Problema Reportado
Las plantillas no aparecen cuando intentas usarlas.

## ✅ Verificación Rápida

### Paso 1: Verificar que el archivo existe

```bash
ls -la lib/features/producto/domain/entities/atributo_plantilla.dart
```

**Resultado esperado:** Archivo de ~18KB existe ✅

---

### Paso 2: Hot Restart (MUY IMPORTANTE)

```bash
# En tu terminal de Flutter donde corre la app
R  # Presiona R (mayúscula) para Hot Restart
```

**⚠️ IMPORTANTE:** Hot Reload (r minúscula) NO es suficiente.
Necesitas Hot Restart (R mayúscula) o reiniciar completamente la app.

---

### Paso 3: Prueba Directa en Consola

Agrega este código temporal en cualquier parte de tu app:

```dart
import 'package:syncronize/features/producto/domain/entities/atributo_plantilla.dart';

// En cualquier función o initState
void probarPlantillas() {
  final plantillas = PlantillasPredefinidas.todas;
  print('Total plantillas: ${plantillas.length}'); // Debería imprimir: 4
  print('Plantillas: ${plantillas.keys}'); // Debería imprimir: [Motherboard, Procesador, Memoria RAM, Tarjeta Gráfica]
}
```

**Resultado esperado:**
```
Total plantillas: 4
Plantillas: [Motherboard, Procesador, Memoria RAM, Tarjeta Gráfica]
```

---

### Paso 4: Usar Widget de Prueba

Creé un widget de prueba simple. Úsalo así:

```dart
// En tu app
import 'package:syncronize/features/producto/presentation/TEST_PLANTILLAS.dart';

// Navegar al widget de prueba
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const TestPlantillasWidget()),
);
```

**O ejecuta la función de test:**

```dart
import 'package:syncronize/features/producto/presentation/TEST_PLANTILLAS.dart';

// En initState o en un botón
testPlantillas(); // Imprime en consola
```

**Resultado esperado en consola:**
```
=== TEST DE PLANTILLAS ===
Total de plantillas: 4

📋 Plantilla: Motherboard
   Atributos: 11
   Lista de atributos:
   1. Socket CPU (SELECT)
      Valores: AM4, AM5, LGA1200, LGA1700, LGA1851, sTRX4, sWRX8
   2. Chipset (SELECT)
      Valores: B550, B650, X570, X670, Z690, Z790, H610, H670, B660
   ... (y así hasta 11 atributos)

📋 Plantilla: Procesador
   Atributos: 9
   ...

📋 Plantilla: Memoria RAM
   Atributos: 5
   ...

📋 Plantilla: Tarjeta Gráfica
   Atributos: 5
   ...

=== FIN DEL TEST ===
```

---

## 🐛 Posibles Problemas y Soluciones

### Problema 1: "No hice Hot Restart"
**Síntoma:** El código nuevo no se carga
**Solución:**
```bash
# En terminal de Flutter
R  # Hot Restart (R mayúscula)
```

---

### Problema 2: "Error de compilación"
**Síntoma:** La app no compila o da error
**Solución:**
```bash
# Verificar errores
flutter analyze lib/features/producto/domain/entities/atributo_plantilla.dart

# Si hay errores, ejecutar
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

---

### Problema 3: "El cubit no encuentra PlantillasPredefinidas"
**Síntoma:** Error de import
**Solución:**

Verifica que en `atributo_plantilla_cubit.dart` línea 4 esté:
```dart
import '../../../domain/entities/atributo_plantilla.dart';
```

---

### Problema 4: "El dialog no se abre"
**Síntoma:** Al presionar el botón no pasa nada
**Solución:**

Verifica que estés usando el código correcto:
```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/features/producto/presentation/widgets/plantilla_selector_dialog.dart';
import 'package:syncronize/features/producto/presentation/bloc/atributo_plantilla/atributo_plantilla_cubit.dart';

// El BlocProvider ya está registrado globalmente, solo usa:
showDialog(
  context: context,
  builder: (context) => PlantillaSelectorDialog(
    empresaId: 'tu-empresa-id',
    onPlantillaAplicada: () {
      print('¡Plantilla aplicada!');
    },
  ),
);
```

---

### Problema 5: "El estado del cubit no cambia"
**Síntoma:** El cubit se queda en Initial o Loading
**Solución:**

Usa BlocBuilder para ver el estado:
```dart
BlocBuilder<AtributoPlantillaCubit, AtributoPlantillaState>(
  builder: (context, state) {
    print('Estado actual: $state'); // Ver en consola

    if (state is AtributoPlantillaLoaded) {
      print('Plantillas cargadas: ${state.plantillasPredefinidas.length}');
    }

    return Container();
  },
)
```

---

## 📝 Checklist de Diagnóstico

Completa este checklist:

- [ ] ✅ Archivo atributo_plantilla.dart existe (18KB)
- [ ] ✅ Build runner ejecutado sin errores
- [ ] ✅ Hot Restart realizado (R mayúscula)
- [ ] ✅ Test en consola imprime "Total plantillas: 4"
- [ ] ✅ Widget de prueba muestra 4 plantillas
- [ ] ✅ Cubit está en BlocProvider global
- [ ] ✅ PlantillaSelectorDialog importado correctamente

---

## 🚀 Solución Definitiva

Si nada funciona, ejecuta estos comandos en orden:

```bash
# 1. Limpiar todo
flutter clean

# 2. Reinstalar dependencias
flutter pub get

# 3. Regenerar código
flutter pub run build_runner build --delete-conflicting-outputs

# 4. Reiniciar app completamente (cerrar y abrir de nuevo)
# No solo hot restart, sino cerrar la app y ejecutar de nuevo:
flutter run
```

---

## 📞 Información de Depuración

Si sigues sin ver las plantillas, ejecuta esto y comparte el resultado:

```dart
// En cualquier lugar de tu código
import 'package:syncronize/features/producto/domain/entities/atributo_plantilla.dart';

void debugPlantillas() {
  try {
    final plantillas = PlantillasPredefinidas.todas;
    print('✅ PlantillasPredefinidas.todas funciona');
    print('   Total: ${plantillas.length}');
    print('   Keys: ${plantillas.keys.toList()}');

    plantillas.forEach((nombre, defs) {
      print('   - $nombre: ${defs.length} atributos');
    });
  } catch (e) {
    print('❌ Error: $e');
  }
}
```

**Ejecuta `debugPlantillas()` y comparte el resultado.**

---

## ✅ Resultado Esperado Final

Cuando todo funcione correctamente:

1. El widget de prueba muestra 4 cards con plantillas
2. La consola imprime el test completo
3. PlantillaSelectorDialog se abre y muestra las 4 plantillas
4. Puedes seleccionar y aplicar cualquier plantilla

---

**¿Sigues teniendo problemas?** Comparte:
1. El resultado de `debugPlantillas()`
2. Errores en consola
3. Qué paso del checklist falla
