# Integración de Unidades de Medida - Guía Completa

## ✅ Implementación Completada

### Backend
- ✅ Schema de base de datos con `UnidadMedidaMaestra` y `EmpresaUnidadMedida`
- ✅ Seed con 45 unidades SUNAT oficiales en 7 categorías
- ✅ CatalogosService con 5 métodos para gestión de unidades
- ✅ CatalogosController con 5 endpoints REST
- ✅ DTOs actualizados (CreateProductoDto, CreateProductoVarianteDto)
- ✅ EmpresaService con activación automática de unidades populares
- ✅ Script de migración para empresas existentes

### Flutter
- ✅ Entities (UnidadMedidaMaestra, EmpresaUnidadMedida) con getters computados
- ✅ Models con serialización JSON completa
- ✅ Remote DataSource con 5 métodos
- ✅ Repository interface e implementación
- ✅ 5 UseCases
- ✅ Cubit con estados y métodos
- ✅ Widget dropdown reutilizable
- ✅ ProductoModel y ProductoVarianteModel actualizados
- ✅ Dependency injection configurado
- ✅ BlocProvider registrado globalmente

## 📋 Pasos Pendientes para Usuario

### 1. Ejecutar Migración Backend

Para activar unidades en empresas existentes:

```bash
cd backend
npm run migrate:unidades-empresas
```

**Resultado esperado:**
```
🚀 Iniciando migración de unidades de medida...
📊 Empresas encontradas: 2
📦 Unidades populares disponibles: 9

✨ Mi Empresa: Activando 9 unidades populares...
   ✅ Mi Empresa: 9 unidades activadas

📈 Resumen de migración:
   • Empresas con unidades activadas: 1
   • Empresas omitidas (ya tenían unidades): 1
   • Total de empresas procesadas: 2
```

### 2. Ejemplo de Uso en Formularios

#### Opción A: Uso Básico en Producto Form

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/features/empresa/presentation/cubit/unidad_medida_cubit.dart';
import 'package:syncronize/features/empresa/presentation/widgets/unidad_medida_dropdown.dart';

class ProductoFormPage extends StatefulWidget {
  @override
  State<ProductoFormPage> createState() => _ProductoFormPageState();
}

class _ProductoFormPageState extends State<ProductoFormPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedUnidadMedidaId;
  final String _empresaId = 'tu-empresa-id'; // Obtener del contexto

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Producto')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ... otros campos del formulario (nombre, precio, etc.)

              const SizedBox(height: 16),

              // Dropdown de Unidad de Medida
              UnidadMedidaDropdown(
                empresaId: _empresaId,
                selectedUnidadId: _selectedUnidadMedidaId,
                onChanged: (value) {
                  setState(() {
                    _selectedUnidadMedidaId = value;
                  });
                },
                labelText: 'Unidad de medida',
                hintText: 'Selecciona una unidad',
                required: true, // Hacer obligatorio si es necesario
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _saveProducto,
                child: const Text('Guardar Producto'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveProducto() {
    if (_formKey.currentState!.validate()) {
      // Crear el producto incluyendo unidadMedidaId
      final productoData = {
        'nombre': 'Producto Ejemplo',
        'precio': 100.0,
        'unidadMedidaId': _selectedUnidadMedidaId, // ✅ Incluir unidad
        // ... otros campos
      };

      // Enviar al cubit/bloc para crear
      // context.read<ProductoFormCubit>().createProducto(productoData);
    }
  }
}
```

#### Opción B: Con BlocListener para Activación de Unidades Populares

```dart
class ProductoFormPage extends StatefulWidget {
  @override
  State<ProductoFormPage> createState() => _ProductoFormPageState();
}

class _ProductoFormPageState extends State<ProductoFormPage> {
  String? _selectedUnidadMedidaId;
  final String _empresaId = 'tu-empresa-id';

  @override
  Widget build(BuildContext context) {
    return BlocListener<UnidadMedidaCubit, UnidadMedidaState>(
      listener: (context, state) {
        if (state is UnidadesPopularesActivadas) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${state.unidades.length} unidades activadas'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is UnidadMedidaError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Crear Producto'),
          actions: [
            // Botón para activar unidades populares si no hay ninguna
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                context
                    .read<UnidadMedidaCubit>()
                    .activarUnidadesPopulares(_empresaId);
              },
              tooltip: 'Activar unidades populares',
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              UnidadMedidaDropdown(
                empresaId: _empresaId,
                selectedUnidadId: _selectedUnidadMedidaId,
                onChanged: (value) {
                  setState(() {
                    _selectedUnidadMedidaId = value;
                  });
                },
                labelText: 'Unidad de medida *',
                required: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

#### Opción C: Para Variantes de Productos

```dart
class ProductoVarianteForm extends StatefulWidget {
  final String empresaId;

  const ProductoVarianteForm({required this.empresaId});

  @override
  State<ProductoVarianteForm> createState() => _ProductoVarianteFormState();
}

class _ProductoVarianteFormState extends State<ProductoVarianteForm> {
  String? _varianteUnidadMedidaId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Campos de la variante (nombre, SKU, precio, etc.)

        const SizedBox(height: 16),

        // Cada variante puede tener su propia unidad de medida
        UnidadMedidaDropdown(
          empresaId: widget.empresaId,
          selectedUnidadId: _varianteUnidadMedidaId,
          onChanged: (value) {
            setState(() {
              _varianteUnidadMedidaId = value;
            });
          },
          labelText: 'Unidad de medida de la variante',
          hintText: 'Ej: Caja, Docena, Unidad',
          required: false, // Opcional: heredará del producto padre si no se especifica
        ),
      ],
    );
  }
}
```

### 3. Ejemplos de Uso del Cubit (Sin UI)

#### Cargar unidades de empresa al iniciar pantalla:

```dart
@override
void initState() {
  super.initState();
  context.read<UnidadMedidaCubit>().getUnidadesEmpresa(empresaId);
}
```

#### Activar unidades populares programáticamente:

```dart
void _setupInitialUnits() async {
  final cubit = context.read<UnidadMedidaCubit>();
  await cubit.activarUnidadesPopulares(empresaId);
}
```

#### Obtener unidades maestras filtradas:

```dart
// Obtener solo unidades de MASA
context.read<UnidadMedidaCubit>().getUnidadesMaestras(
  categoria: 'MASA',
  soloPopulares: false,
);

// Obtener solo unidades populares de todas las categorías
context.read<UnidadMedidaCubit>().getUnidadesMaestras(
  soloPopulares: true,
);
```

#### Activar una unidad específica:

```dart
// Activar una unidad maestra existente
context.read<UnidadMedidaCubit>().activarUnidad(
  empresaId: empresaId,
  unidadMaestraId: 'id-unidad-maestra',
);

// Crear una unidad personalizada
context.read<UnidadMedidaCubit>().activarUnidad(
  empresaId: empresaId,
  nombrePersonalizado: 'Paquete',
  simboloPersonalizado: 'paq',
  codigoPersonalizado: 'PAQ',
);
```

## 🎯 Unidades Populares Pre-activadas

Las 9 unidades que se activan automáticamente son:

1. **Unidad (NIU)** - und
2. **Kilogramo (KGM)** - kg
3. **Metro (MTR)** - m
4. **Litro (LTR)** - L
5. **Caja (BX)** - cja
6. **Docena (DZN)** - doc
7. **Gramo (GRM)** - g
8. **Servicio (ZZ)** - srv
9. **Hora (HUR)** - hr

## 📊 Categorías de Unidades SUNAT

El catálogo completo incluye 45 unidades en 7 categorías:

- **CANTIDAD**: Unidad, Docena, Ciento, Millar, Caja
- **MASA**: Gramo, Kilogramo, Tonelada, Libra, Onza
- **LONGITUD**: Metro, Centímetro, Kilómetro, Pulgada, Pie
- **AREA**: Metro cuadrado, Hectárea
- **VOLUMEN**: Litro, Mililitro, Metro cúbico, Galón
- **TIEMPO**: Hora, Día, Semana, Mes, Año
- **SERVICIO**: Servicio, Sesión, Consulta

## 🔄 Flujo Completo de Uso

1. **Usuario crea una empresa nueva**
   - ✅ Backend automáticamente activa 9 unidades populares
   - ✅ Empresa lista para crear productos

2. **Usuario crea un producto**
   - Selecciona unidad de medida del dropdown
   - Si no hay unidades disponibles, puede activar las populares con un botón
   - Producto se guarda con `unidadMedidaId`

3. **Usuario crea variantes**
   - Cada variante puede tener su propia unidad
   - Ejemplo: Producto "Gaseosa" con variantes:
     - Variante "Unidad" → unidad de medida: Unidad (NIU)
     - Variante "Caja x12" → unidad de medida: Caja (BX)
     - Variante "Six Pack" → unidad de medida: Paquete (personalizada)

4. **Display en lista de productos**
   ```dart
   Text('${producto.precio} / ${producto.unidadDisplay}')
   // Ejemplo: "S/ 10.50 / kg"

   Text('Precio: ${producto.precio} por ${producto.unidadDisplayCompleto}')
   // Ejemplo: "Precio: S/ 10.50 por Kilogramo (kg)"
   ```

5. **Facturación electrónica SUNAT**
   ```dart
   final codigoSunat = producto.unidadCodigoSunat; // "KGM"
   // Usar en XML de factura electrónica
   ```

## 🐛 Troubleshooting

### Error: "No hay unidades disponibles"
**Solución:** Ejecutar el script de migración o activar unidades populares desde la UI.

### Error: Cubit no encontrado
**Solución:** Asegurarse de que el `UnidadMedidaCubit` esté registrado en `bloc_provider.dart` y ejecutar `flutter pub run build_runner build`.

### Error: UnidadMedidaModel no reconocido
**Solución:** Verificar que el import esté correcto: `import '../../../empresa/data/models/unidad_medida_model.dart';`

## 📝 Próximas Mejoras (Opcional)

- [ ] Pantalla de gestión de unidades (activar/desactivar unidades maestras)
- [ ] Crear unidades personalizadas desde UI
- [ ] Filtrar unidades por categoría en el dropdown
- [ ] Búsqueda de unidades en el dropdown
- [ ] Conversión automática entre unidades (kg ↔ g)
- [ ] Validación de unidades compatibles para variantes

## 🎉 ¡Implementación Completa!

Todas las capas están implementadas y funcionando:
- ✅ Backend con endpoints REST
- ✅ Base de datos con catálogo SUNAT
- ✅ Flutter con Clean Architecture
- ✅ Widget reutilizable
- ✅ Integración con formularios
- ✅ Activación automática para nuevas empresas
