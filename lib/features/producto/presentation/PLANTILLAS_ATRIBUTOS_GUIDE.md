# Guía de Uso: Sistema de Plantillas de Atributos

## Descripción General

El sistema de plantillas de atributos te permite crear grupos predefinidos de atributos para productos específicos (motherboards, procesadores, RAM, etc.) de manera rápida y consistente.

## Características Principales

### 1. **Plantillas Predefinidas del Sistema**
- ✅ Motherboard (11 atributos)
- ✅ Procesador/CPU (9 atributos)
- ✅ Memoria RAM (5 atributos)
- ✅ Tarjeta Gráfica/GPU (5 atributos)

### 2. **Tipos de Atributos Soportados**
- `COLOR`: Selector de color
- `TALLA`: Tallas predefinidas
- `MATERIAL`: Material del producto
- `CAPACIDAD`: Capacidad/volumen
- `SELECT`: Dropdown de selección única
- `MULTI_SELECT`: Selección múltiple
- `BOOLEAN`: Sí/No
- `NUMERO`: Valor numérico
- `TEXTO`: Campo de texto libre

## Uso Básico

### 1. Aplicar una Plantilla Predefinida

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/plantilla_selector_dialog.dart';
import '../bloc/atributo_plantilla/atributo_plantilla_cubit.dart';

// En tu página de gestión de atributos
class AtributosPage extends StatelessWidget {
  final String empresaId;
  final String? categoriaId;

  const AtributosPage({
    required this.empresaId,
    this.categoriaId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Atributos'),
      ),
      body: Column(
        children: [
          // Botón para abrir selector de plantillas
          ElevatedButton.icon(
            icon: const Icon(Icons.dashboard_customize),
            label: const Text('Aplicar Plantilla'),
            onPressed: () => _mostrarSelectorPlantillas(context),
          ),
          // ... resto del contenido
        ],
      ),
    );
  }

  void _mostrarSelectorPlantillas(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => BlocProvider(
        create: (context) => getIt<AtributoPlantillaCubit>(),
        child: PlantillaSelectorDialog(
          empresaId: empresaId,
          categoriaId: categoriaId,
          onPlantillaAplicada: () {
            // Recargar lista de atributos
            context.read<ProductoAtributoCubit>().loadAtributos(empresaId);
          },
        ),
      ),
    );
  }
}
```

### 2. Aplicar Plantilla Programáticamente

```dart
// En tu cubit o servicio
final cubit = AtributoPlantillaCubit(remoteDataSource);

// Aplicar plantilla de Motherboard
await cubit.aplicarPlantillaPredefinida(
  empresaId: 'empresa-123',
  nombrePlantilla: 'Motherboard',
  categoriaId: 'categoria-placas-madre',
);

// Escuchar el estado
cubit.stream.listen((state) {
  if (state is AtributoPlantillaAplicando) {
    print('Progreso: ${state.progreso * 100}%');
    print('Creados: ${state.atributosCreados} de ${state.totalAtributos}');
  } else if (state is AtributoPlantillaAplicada) {
    print('¡Plantilla aplicada! ${state.atributosCreados} atributos creados');
  }
});
```

### 3. Verificar si una Plantilla ya fue Aplicada

```dart
final cubit = AtributoPlantillaCubit(remoteDataSource);

final yaAplicada = await cubit.plantillaYaAplicada(
  empresaId: 'empresa-123',
  nombrePlantilla: 'Procesador',
);

if (yaAplicada) {
  print('La plantilla de Procesador ya fue aplicada');
} else {
  print('Puedes aplicar la plantilla de Procesador');
}
```

### 4. Obtener Atributos Faltantes de una Plantilla

```dart
// Útil para aplicar solo los atributos que faltan
final atributosFaltantes = await cubit.getAtributosFaltantes(
  empresaId: 'empresa-123',
  nombrePlantilla: 'Motherboard',
);

if (atributosFaltantes.isNotEmpty) {
  print('Faltan ${atributosFaltantes.length} atributos:');
  for (var attr in atributosFaltantes) {
    print('- ${attr.nombre} (${attr.tipo.value})');
  }
}
```

## Ejemplo Completo: Página de Productos

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CrearProductoPage extends StatefulWidget {
  const CrearProductoPage({Key? key}) : super(key: key);

  @override
  State<CrearProductoPage> createState() => _CrearProductoPageState();
}

class _CrearProductoPageState extends State<CrearProductoPage> {
  String? _categoriaSeleccionada;
  final _atributosCubit = getIt<ProductoAtributoCubit>();

  @override
  void initState() {
    super.initState();
    _atributosCubit.loadAtributos(empresaId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Producto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard_customize),
            tooltip: 'Aplicar plantilla de atributos',
            onPressed: _mostrarPlantillas,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Campos básicos del producto
            TextField(
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 16),

            // Selector de categoría
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Categoría'),
              value: _categoriaSeleccionada,
              items: const [
                DropdownMenuItem(
                  value: 'cat-motherboard',
                  child: Text('Motherboards'),
                ),
                DropdownMenuItem(
                  value: 'cat-cpu',
                  child: Text('Procesadores'),
                ),
                DropdownMenuItem(
                  value: 'cat-ram',
                  child: Text('Memoria RAM'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _categoriaSeleccionada = value;
                });
              },
            ),
            const SizedBox(height: 24),

            // Sección de atributos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Atributos del Producto',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Usar Plantilla'),
                  onPressed: _mostrarPlantillas,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Lista de atributos (usando ProductoAtributosCubit)
            BlocBuilder<ProductoAtributosCubit, ProductoAtributosState>(
              builder: (context, state) {
                if (state is ProductoAtributosLoaded) {
                  return Column(
                    children: state.atributosDisponibles.map((atributo) {
                      return ListTile(
                        title: Text(atributo.nombre),
                        subtitle: Text(atributo.tipo.value),
                        trailing: atributo.requerido
                            ? const Chip(label: Text('Requerido'))
                            : null,
                      );
                    }).toList(),
                  );
                }
                return const CircularProgressIndicator();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarPlantillas() {
    showDialog(
      context: context,
      builder: (context) => BlocProvider(
        create: (context) => getIt<AtributoPlantillaCubit>(),
        child: PlantillaSelectorDialog(
          empresaId: empresaId,
          categoriaId: _categoriaSeleccionada,
          onPlantillaAplicada: () {
            // Recargar atributos después de aplicar plantilla
            _atributosCubit.loadAtributos(empresaId);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Plantilla aplicada exitosamente'),
              ),
            );
          },
        ),
      ),
    );
  }
}
```

## Crear Plantilla Personalizada

Si quieres crear tu propia plantilla (por ejemplo, para "Laptops"):

```dart
// En atributo_plantilla.dart
static List<AtributoPlantillaDefinicion> get laptop => [
  const AtributoPlantillaDefinicion(
    nombre: 'Tamaño de Pantalla',
    clave: 'pantalla_pulgadas',
    tipo: AtributoTipo.select,
    requerido: true,
    descripcion: 'Tamaño de pantalla en pulgadas',
    valores: ['13.3', '14', '15.6', '16', '17.3'],
    orden: 1,
    mostrarEnListado: true,
    usarParaFiltros: true,
    mostrarEnMarketplace: true,
  ),
  const AtributoPlantillaDefinicion(
    nombre: 'Resolución',
    clave: 'resolucion',
    tipo: AtributoTipo.select,
    requerido: true,
    valores: ['1920x1080', '2560x1440', '3840x2160'],
    orden: 2,
    mostrarEnListado: true,
    usarParaFiltros: true,
    mostrarEnMarketplace: true,
  ),
  const AtributoPlantillaDefinicion(
    nombre: 'Procesador',
    clave: 'procesador',
    tipo: AtributoTipo.texto,
    requerido: true,
    descripcion: 'Modelo del procesador',
    valores: [],
    orden: 3,
    mostrarEnListado: true,
    usarParaFiltros: false,
    mostrarEnMarketplace: true,
  ),
  const AtributoPlantillaDefinicion(
    nombre: 'RAM',
    clave: 'ram_gb',
    tipo: AtributoTipo.select,
    requerido: true,
    unidad: 'GB',
    valores: ['8', '16', '32', '64'],
    orden: 4,
    mostrarEnListado: true,
    usarParaFiltros: true,
    mostrarEnMarketplace: true,
  ),
  const AtributoPlantillaDefinicion(
    nombre: 'Almacenamiento',
    clave: 'almacenamiento',
    tipo: AtributoTipo.select,
    requerido: true,
    unidad: 'GB',
    valores: ['256', '512', '1024', '2048'],
    orden: 5,
    mostrarEnListado: true,
    usarParaFiltros: true,
    mostrarEnMarketplace: true,
  ),
  const AtributoPlantillaDefinicion(
    nombre: 'Tarjeta Gráfica',
    clave: 'gpu',
    tipo: AtributoTipo.texto,
    requerido: false,
    descripcion: 'GPU dedicada (opcional)',
    valores: [],
    orden: 6,
    mostrarEnListado: false,
    usarParaFiltros: false,
    mostrarEnMarketplace: true,
  ),
  const AtributoPlantillaDefinicion(
    nombre: 'Peso',
    clave: 'peso_kg',
    tipo: AtributoTipo.numero,
    requerido: false,
    unidad: 'kg',
    valores: [],
    orden: 7,
    mostrarEnListado: false,
    usarParaFiltros: false,
    mostrarEnMarketplace: true,
  ),
  const AtributoPlantillaDefinicion(
    nombre: 'Batería',
    clave: 'bateria_wh',
    tipo: AtributoTipo.numero,
    requerido: false,
    descripcion: 'Capacidad de batería',
    unidad: 'Wh',
    valores: [],
    orden: 8,
    mostrarEnListado: false,
    usarParaFiltros: false,
    mostrarEnMarketplace: false,
  ),
];

// Agregar a PlantillasPredefinidas.todas
static Map<String, List<AtributoPlantillaDefinicion>> get todas => {
  'Motherboard': motherboard,
  'Procesador': procesador,
  'Memoria RAM': memoriaRAM,
  'Tarjeta Gráfica': tarjetaGrafica,
  'Laptop': laptop, // Nueva plantilla
};
```

## Flujo de Trabajo Recomendado

### Para un Producto de Tipo Motherboard:

1. **Crear/seleccionar la categoría** "Motherboards"
2. **Aplicar plantilla** "Motherboard" (crea 11 atributos)
3. **Crear producto** y asignar valores a los atributos
4. **Crear variantes** si es necesario (ej: diferentes colores)

### Ejemplo Práctico:

```dart
// 1. Aplicar plantilla de Motherboard
await cubit.aplicarPlantillaPredefinida(
  empresaId: empresaId,
  nombrePlantilla: 'Motherboard',
  categoriaId: categoriaMotherbaordsId,
);

// Ahora tienes 11 atributos creados:
// - Socket CPU (SELECT: AM4, AM5, LGA1200, etc.)
// - Chipset (SELECT: B550, B650, X570, etc.)
// - Factor de Forma (SELECT: ATX, Micro-ATX, Mini-ITX)
// - Tipo de RAM (SELECT: DDR4, DDR5)
// - Slots de RAM (SELECT: 2, 4, 8)
// - Capacidad Máxima RAM (NUMERO en GB)
// - Slots PCIe x16 (NUMERO)
// - Slots M.2 (NUMERO)
// - Puertos SATA (NUMERO)
// - WiFi Integrado (BOOLEAN)
// - Bluetooth Integrado (BOOLEAN)

// 2. Crear producto motherboard
final producto = await crearProducto({
  'nombre': 'ASUS ROG Strix B550-F Gaming',
  'categoriaId': categoriaMotherbaordsId,
  // ... otros campos
});

// 3. Asignar valores a atributos
await setProductoAtributos(
  productoId: producto.id,
  atributos: [
    {'atributoId': socketCpuId, 'valor': 'AM4'},
    {'atributoId': chipsetId, 'valor': 'B550'},
    {'atributoId': factorFormaId, 'valor': 'ATX'},
    {'atributoId': tipoRamId, 'valor': 'DDR4'},
    {'atributoId': slotsRamId, 'valor': '4'},
    {'atributoId': capacidadMaxRamId, 'valor': '128'},
    {'atributoId': slotsPcieId, 'valor': '2'},
    {'atributoId': slotsM2Id, 'valor': '2'},
    {'atributoId': puertosSataId, 'valor': '6'},
    {'atributoId': wifiId, 'valor': 'true'},
    {'atributoId': bluetoothId, 'valor': 'true'},
  ],
);
```

## Ventajas del Sistema de Plantillas

✅ **Consistencia**: Todos los productos de un tipo tienen los mismos atributos
✅ **Rapidez**: Crea 10+ atributos en segundos en lugar de uno por uno
✅ **Estandarización**: Valores predefinidos evitan inconsistencias
✅ **Filtros**: Atributos configurados para filtros automáticamente
✅ **Marketplace**: Control de qué atributos se muestran al cliente
✅ **Escalabilidad**: Fácil agregar nuevas plantillas

## Estructura de Datos

### AtributoPlantillaDefinicion
```dart
{
  nombre: 'Socket CPU',           // Nombre visible
  clave: 'socket_cpu',            // Identificador único
  tipo: AtributoTipo.select,      // Tipo de input
  requerido: true,                // ¿Es obligatorio?
  descripcion: '...',             // Ayuda para el usuario
  unidad: null,                   // Ej: 'GB', 'MHz', 'W'
  valores: ['AM4', 'AM5', ...],   // Opciones predefinidas
  orden: 1,                       // Orden de visualización
  mostrarEnListado: true,         // ¿Mostrar en listados?
  usarParaFiltros: true,          // ¿Usar para filtros?
  mostrarEnMarketplace: true,     // ¿Mostrar al cliente?
}
```

## Integración con Dependency Injection

Registra el cubit en tu `injection_container.dart`:

```dart
// En injection_container.dart
@module
abstract class ProductoModule {
  @injectable
  AtributoPlantillaCubit get atributoPlantillaCubit =>
      AtributoPlantillaCubit(getIt<ProductoRemoteDataSource>());
}
```

## Notas Importantes

⚠️ **Duplicados**: El sistema no evita duplicados automáticamente. Usa `plantillaYaAplicada()` antes de aplicar.
⚠️ **Categorías**: Puedes vincular plantillas a categorías específicas para mejor organización.
⚠️ **Claves únicas**: Cada atributo debe tener una clave única por empresa.
⚠️ **Backend**: Asegúrate que el backend soporta creación masiva de atributos.

## Próximas Mejoras

- [ ] Plantillas personalizadas guardadas en backend
- [ ] Importar/exportar plantillas como JSON
- [ ] Editor visual de plantillas
- [ ] Sugerencias de valores basadas en productos existentes
- [ ] Validaciones cruzadas entre atributos

---

**¿Preguntas o problemas?** Revisa los ejemplos en `/presentation/widgets/plantilla_selector_dialog.dart`
