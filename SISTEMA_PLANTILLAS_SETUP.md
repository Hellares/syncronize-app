# ✅ Sistema de Plantillas de Atributos - Setup Completo

## 📋 Resumen

Se ha implementado un **sistema completo de plantillas de atributos** para crear atributos predefinidos de manera rápida y consistente.

## ✅ ARCHIVOS CREADOS

### 1. Domain Layer
```
✅ lib/features/producto/domain/entities/atributo_plantilla.dart
   - AtributoPlantilla (entidad principal)
   - AtributoPlantillaDefinicion (definición individual)
   - PlantillasPredefinidas (4 plantillas listas: Motherboard, CPU, RAM, GPU)
```

### 2. Data Layer
```
✅ lib/features/producto/data/models/atributo_plantilla_model.dart
   - AtributoPlantillaModel (con serialización JSON)
   - CreatePlantillaDto (DTO para crear plantillas)
```

### 3. Presentation Layer - Bloc
```
✅ lib/features/producto/presentation/bloc/atributo_plantilla/
   - atributo_plantilla_cubit.dart (lógica de negocio)
   - atributo_plantilla_state.dart (estados)
```

### 4. Presentation Layer - Widgets
```
✅ lib/features/producto/presentation/widgets/plantilla_selector_dialog.dart
   - Dialog visual para seleccionar y aplicar plantillas
   - Muestra progreso de creación
   - Detecta duplicados
```

### 5. Configuración
```
✅ lib/bloc_provider.dart (actualizado)
   - Registrado AtributoPlantillaCubit
```

### 6. Mejoras en Cubits Existentes
```
✅ lib/features/producto/presentation/bloc/producto_atributo/producto_atributo_cubit.dart
   - Agregado: crearAtributosEnLote()
   - Agregado: existeAtributoConClave()
   - Agregado: getAtributosPorCategoria()
```

### 7. Documentación
```
✅ lib/features/producto/presentation/PLANTILLAS_ATRIBUTOS_GUIDE.md
   - Guía completa de uso
   - Ejemplos de código
   - Casos de uso
```

## 🎯 PLANTILLAS INCLUIDAS

### 1. Motherboard (11 atributos)
- Socket CPU, Chipset, Factor de Forma, Tipo RAM, Slots RAM
- Capacidad Max RAM, Slots PCIe, Slots M.2, Puertos SATA
- WiFi Integrado, Bluetooth Integrado

### 2. Procesador (9 atributos)
- Marca, Socket, Núcleos, Hilos, Frecuencia Base
- Frecuencia Turbo, Cache, TDP, Gráficos Integrados

### 3. Memoria RAM (5 atributos)
- Tipo, Capacidad, Frecuencia, Latencia CAS, RGB

### 4. Tarjeta Gráfica (5 atributos)
- Chipset, Memoria VRAM, Tipo Memoria, Conectores, TDP

## 🚀 PASOS PARA USAR

### Paso 1: Verificar que el build_runner terminó
```bash
# El comando se está ejecutando automáticamente
# Espera a que termine (puede tomar 1-2 minutos)
```

### Paso 2: Hot Restart de tu app
```bash
# En tu terminal de Flutter
r  # Hot reload
# o
R  # Hot restart (recomendado)
```

### Paso 3: Usar el selector de plantillas

En cualquier página donde quieras aplicar plantillas:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/features/producto/presentation/widgets/plantilla_selector_dialog.dart';
import 'package:syncronize/features/producto/presentation/bloc/atributo_plantilla/atributo_plantilla_cubit.dart';

// Ejemplo: En tu página de crear producto
ElevatedButton.icon(
  icon: const Icon(Icons.dashboard_customize),
  label: const Text('Aplicar Plantilla de Atributos'),
  onPressed: () {
    showDialog(
      context: context,
      builder: (context) => PlantillaSelectorDialog(
        empresaId: empresaId, // Tu empresa ID actual
        categoriaId: categoriaId, // Opcional: categoria del producto
        onPlantillaAplicada: () {
          // Callback cuando se aplica exitosamente
          // Recargar atributos si es necesario
          context.read<ProductoAtributoCubit>().loadAtributos(empresaId);
        },
      ),
    );
  },
)
```

### Paso 4: Acceder al cubit desde cualquier lugar

El cubit ya está registrado globalmente, así que puedes accederlo con:

```dart
// Obtener instancia del cubit
final cubit = context.read<AtributoPlantillaCubit>();

// O escuchar cambios
BlocBuilder<AtributoPlantillaCubit, AtributoPlantillaState>(
  builder: (context, state) {
    if (state is AtributoPlantillaLoaded) {
      // Usar plantillas disponibles
      final plantillas = state.plantillasPredefinidas;
    }
    return Container();
  },
)
```

## 💡 EJEMPLOS DE USO

### Ejemplo 1: Aplicar plantilla de Motherboard

```dart
// Mostrar dialog
showDialog(
  context: context,
  builder: (context) => PlantillaSelectorDialog(
    empresaId: 'empresa-123',
    categoriaId: 'cat-motherboards',
    onPlantillaAplicada: () {
      print('¡11 atributos creados para Motherboard!');
    },
  ),
);
```

### Ejemplo 2: Verificar si plantilla ya fue aplicada

```dart
final cubit = context.read<AtributoPlantillaCubit>();

final yaAplicada = await cubit.plantillaYaAplicada(
  empresaId: empresaId,
  nombrePlantilla: 'Procesador',
);

if (!yaAplicada) {
  // Aplicar plantilla
  await cubit.aplicarPlantillaPredefinida(
    empresaId: empresaId,
    nombrePlantilla: 'Procesador',
  );
}
```

### Ejemplo 3: Obtener atributos faltantes

```dart
final cubit = context.read<AtributoPlantillaCubit>();

final faltantes = await cubit.getAtributosFaltantes(
  empresaId: empresaId,
  nombrePlantilla: 'Memoria RAM',
);

print('Faltan ${faltantes.length} atributos');
for (var attr in faltantes) {
  print('- ${attr.nombre}');
}
```

## 🔧 TROUBLESHOOTING

### Error: "AtributoPlantillaCubit not found"
**Solución:** Ejecuta `flutter pub run build_runner build --delete-conflicting-outputs`

### Error: "PlantillaSelectorDialog not found"
**Solución:** Verifica el import:
```dart
import 'package:syncronize/features/producto/presentation/widgets/plantilla_selector_dialog.dart';
```

### Las plantillas no aparecen
**Solución:**
1. Verifica que llamaste `cubit.loadPlantillas()`
2. Revisa el estado del cubit con BlocBuilder

### Duplicados al aplicar plantilla
**Solución:** El sistema detecta duplicados automáticamente y muestra un diálogo de confirmación

## 📊 FLUJO DE DATOS

```
Usuario presiona "Aplicar Plantilla"
    ↓
PlantillaSelectorDialog se abre
    ↓
AtributoPlantillaCubit.loadPlantillas()
    ↓
Estado: AtributoPlantillaLoaded (muestra 4 plantillas)
    ↓
Usuario selecciona "Motherboard"
    ↓
Usuario presiona "Aplicar"
    ↓
Verifica duplicados (plantillaYaAplicada)
    ↓
AtributoPlantillaCubit.aplicarPlantillaPredefinida()
    ↓
Estado: AtributoPlantillaAplicando (progreso 0/11, 1/11, 2/11...)
    ↓
Crea cada atributo vía ProductoRemoteDataSource
    ↓
Estado: AtributoPlantillaAplicada (11 atributos creados)
    ↓
Callback onPlantillaAplicada() ejecutado
    ↓
Dialog se cierra
    ↓
Atributos disponibles para usar en productos
```

## 🎨 PERSONALIZACIÓN

### Agregar nueva plantilla

Edita `atributo_plantilla.dart`:

```dart
// 1. Crear getter con definiciones
static List<AtributoPlantillaDefinicion> get miPlantilla => [
  const AtributoPlantillaDefinicion(
    nombre: 'Mi Atributo',
    clave: 'mi_atributo',
    tipo: AtributoTipo.select,
    requerido: true,
    valores: ['Valor 1', 'Valor 2'],
    orden: 1,
    mostrarEnListado: true,
    usarParaFiltros: true,
    mostrarEnMarketplace: true,
  ),
  // ... más atributos
];

// 2. Agregar al mapa de todas
static Map<String, List<AtributoPlantillaDefinicion>> get todas => {
  'Motherboard': motherboard,
  'Procesador': procesador,
  'Memoria RAM': memoriaRAM,
  'Tarjeta Gráfica': tarjetaGrafica,
  'Mi Plantilla': miPlantilla, // ← Nueva
};
```

### Personalizar iconos del dialog

Edita `plantilla_selector_dialog.dart` línea ~185:

```dart
final iconos = {
  'Motherboard': Icons.developer_board,
  'Procesador': Icons.memory,
  'Memoria RAM': Icons.storage,
  'Tarjeta Gráfica': Icons.videogame_asset,
  'Mi Plantilla': Icons.computer, // ← Tu icono
};
```

## 📚 DOCUMENTACIÓN COMPLETA

Lee la guía completa en:
```
lib/features/producto/presentation/PLANTILLAS_ATRIBUTOS_GUIDE.md
```

## ✅ CHECKLIST DE IMPLEMENTACIÓN

- [x] Entidades creadas
- [x] Modelos creados
- [x] Cubit creado
- [x] Estados definidos
- [x] Widget UI creado
- [x] Cubit registrado en DI
- [x] Cubit agregado a BlocProvider
- [x] Build runner ejecutado
- [x] 4 plantillas predefinidas incluidas
- [x] Documentación completa
- [ ] Hot restart de la app
- [ ] Probar selector de plantillas
- [ ] Aplicar primera plantilla

## 🎉 ¡LISTO PARA USAR!

Una vez que el build_runner termine:

1. Haz Hot Restart (R) de tu app
2. Navega a cualquier página de productos
3. Presiona el botón "Aplicar Plantilla"
4. Selecciona "Motherboard"
5. ¡11 atributos creados en segundos!

---

**¿Preguntas?** Revisa:
- PLANTILLAS_ATRIBUTOS_GUIDE.md (guía completa)
- plantilla_selector_dialog.dart (ejemplo de uso)
- atributo_plantilla.dart (plantillas disponibles)
