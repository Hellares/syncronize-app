# 📍 Dónde Ver las Plantillas de Atributos

## ✅ UBICACIÓN DE LAS PLANTILLAS

Las plantillas están integradas en la página de **Atributos de Productos**.

### 🗺️ Ruta de Navegación

```
App → [Menú/Drawer] → Productos → Atributos de Productos
```

O directamente:
```
ProductoAtributosPage
```

---

## 🎯 CÓMO ACCEDER A LAS PLANTILLAS

### Opción 1: Botón en el AppBar

Cuando estés en la página **"Atributos de Productos"**, verás en la esquina superior derecha:

```
┌─────────────────────────────────────────┐
│ ← Atributos de Productos    🔲  ❓      │  ← AppBar
└─────────────────────────────────────────┘
                               ↑
                   Nuevo botón: Icono de cuadrícula
                   Tooltip: "Aplicar Plantilla"
```

**Pasos:**
1. Ve a "Atributos de Productos"
2. Presiona el icono **🔲** (dashboard_customize) en el AppBar
3. Se abre el **Selector de Plantillas**
4. Selecciona una plantilla (Motherboard, Procesador, etc.)
5. Presiona "Aplicar Plantilla"
6. ¡Listo! Atributos creados automáticamente

---

### Opción 2: Cuando No Hay Atributos (Empty State)

Si aún no tienes atributos creados, verás una pantalla con dos botones:

```
┌─────────────────────────────────────────┐
│                                         │
│            🎛️                          │
│                                         │
│    No hay atributos configurados        │
│                                         │
│  [🔲 Usar Plantilla] [➕ Crear Manual]  │
│                                         │
│  💡 Tip: Usa plantillas para agregar   │
│     múltiples atributos rápidamente    │
│                                         │
└─────────────────────────────────────────┘
```

**Pasos:**
1. Presiona **"Usar Plantilla"**
2. Selecciona plantilla
3. Aplicar
4. ¡Listo!

---

## 🎨 QUÉ VERÁS EN EL SELECTOR DE PLANTILLAS

Al abrir el selector, verás un dialog con **4 plantillas disponibles**:

```
┌──────────────────────────────────────────────────────┐
│  Plantillas de Atributos                        ✕   │
├──────────────────────────────────────────────────────┤
│                                                      │
│  ┌────────────────────────────────────────────────┐ │
│  │ 🖥️  Motherboard                               │ │
│  │  11 atributos (8 requeridos, 3 opcionales)     │ │
│  │  • Socket CPU  • Chipset  • Factor de Forma   │ │
│  │  • Tipo RAM  • Slots RAM  + 6 más             │ │
│  └────────────────────────────────────────────────┘ │
│                                                      │
│  ┌────────────────────────────────────────────────┐ │
│  │ 🔧  Procesador                                 │ │
│  │  9 atributos (6 requeridos, 3 opcionales)      │ │
│  │  • Marca  • Socket  • Núcleos  + 6 más        │ │
│  └────────────────────────────────────────────────┘ │
│                                                      │
│  ┌────────────────────────────────────────────────┐ │
│  │ 💾  Memoria RAM                                │ │
│  │  5 atributos (3 requeridos, 2 opcionales)      │ │
│  │  • Tipo  • Capacidad  • Frecuencia  + 2 más   │ │
│  └────────────────────────────────────────────────┘ │
│                                                      │
│  ┌────────────────────────────────────────────────┐ │
│  │ 🎮  Tarjeta Gráfica                           │ │
│  │  5 atributos (2 requeridos, 3 opcionales)      │ │
│  │  • Chipset  • VRAM  • Tipo Memoria  + 2 más   │ │
│  └────────────────────────────────────────────────┘ │
│                                                      │
├──────────────────────────────────────────────────────┤
│                          [Cancelar] [Aplicar Plantilla]│
└──────────────────────────────────────────────────────┘
```

---

## 📸 EJEMPLO VISUAL PASO A PASO

### Paso 1: Navega a Atributos
```
Tu App
  └─ Menú
      └─ Productos
          └─ Gestión de Atributos ← AQUÍ
```

### Paso 2: Presiona el Botón
```
AppBar: [...   🔲   ❓]
                ↑
         Presiona aquí
```

### Paso 3: Selecciona Plantilla
```
Dialog aparece
  → Haz clic en "Motherboard" (por ejemplo)
  → Presiona "Aplicar Plantilla"
```

### Paso 4: Progreso
```
┌──────────────────────────────────────┐
│  Aplicando plantilla "Motherboard"  │
│  ▓▓▓▓▓▓▓▓▓▓▓░░░░░  7 de 11         │
│  Creados 7 de 11 atributos          │
└──────────────────────────────────────┘
```

### Paso 5: ¡Listo!
```
✅ Plantilla "Motherboard" aplicada: 11 atributos creados

Atributos creados:
1. Socket CPU (SELECT)
2. Chipset (SELECT)
3. Factor de Forma (SELECT)
4. Tipo RAM (SELECT)
5. Slots RAM (SELECT)
6. Capacidad Max RAM (NUMERO)
7. Slots PCIe x16 (NUMERO)
8. Slots M.2 (NUMERO)
9. Puertos SATA (NUMERO)
10. WiFi Integrado (BOOLEAN)
11. Bluetooth Integrado (BOOLEAN)
```

---

## 🔍 TROUBLESHOOTING

### "No veo el botón 🔲 en el AppBar"
**Solución:** Haz Hot Restart (R mayúscula)
```bash
# En terminal de Flutter
R  # Presiona R mayúscula
```

### "El botón está pero no pasa nada al presionarlo"
**Solución:** Verifica la consola de errores
```bash
# Si hay error de import, ejecuta:
flutter clean
flutter pub get
flutter run
```

### "El dialog se abre pero no muestra plantillas"
**Solución:** Verifica que `PlantillasPredefinidas.todas` funciona:
```dart
import 'package:syncronize/features/producto/domain/entities/atributo_plantilla.dart';

void test() {
  print(PlantillasPredefinidas.todas.length); // Debería imprimir: 4
}
```

---

## 📝 CHECKLIST VISUAL

Completa esto para verificar que todo funciona:

- [ ] ✅ Puedo navegar a "Atributos de Productos"
- [ ] ✅ Veo el icono 🔲 en el AppBar (al lado del ❓)
- [ ] ✅ Al presionar 🔲 se abre el dialog
- [ ] ✅ Veo 4 plantillas en el dialog
- [ ] ✅ Puedo seleccionar una plantilla
- [ ] ✅ Al aplicar, veo barra de progreso
- [ ] ✅ Los atributos se crean correctamente
- [ ] ✅ Veo mensaje de éxito

---

## 🎯 RESUMEN

**Dónde:** Página "Atributos de Productos"
**Cómo:** Botón 🔲 en AppBar O botón "Usar Plantilla" en empty state
**Qué:** Dialog con 4 plantillas predefinidas
**Resultado:** Atributos creados automáticamente

---

## 🚀 PRÓXIMO PASO

1. Haz **Hot Restart** (R)
2. Ve a **Atributos de Productos**
3. Presiona **🔲** en el AppBar
4. ¡Disfruta de las plantillas!

---

**¿Sigues sin verlo?** Comparte un screenshot de tu página de Atributos y te ayudo a identificar el problema.
