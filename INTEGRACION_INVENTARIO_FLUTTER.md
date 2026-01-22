# 📱 Integración de Sistema de Inventario en Flutter

## 📊 Resumen de Cambios

El backend migró del sistema de inventario legacy a **ProductoStock** (inventario por sede). Este documento explica cómo integrar estos cambios en Flutter.

---

## 🔴 BREAKING CHANGES

### 1. Endpoint de Stock Actualizado

**ANTES:**
```dart
// ❌ DEPRECADO
await productoRemoteDataSource.actualizarStock(
  productoId: 'prod-123',
  empresaId: 'emp-456',
  cantidad: 50,
  operacion: 'agregar',
);
// Retornaba: ProductoModel
```

**AHORA:**
```dart
// ✅ NUEVO - Requiere sedeId
final result = await productoRemoteDataSource.actualizarStock(
  productoId: 'prod-123',
  empresaId: 'emp-456',
  sedeId: 'sede-789', // 🆕 NUEVO - REQUERIDO
  cantidad: 50,
  operacion: 'agregar',
);
// Retorna: { stock: 150, stockTotal: 380 }
```

---

## 📦 Nuevos Modelos Creados

### 1. ProductoStock (producto_stock_model.dart)

```dart
class ProductoStockModel {
  final String id;
  final String sedeId;
  final String? productoId;
  final String? varianteId;
  final String empresaId;
  final int stockActual;
  final int? stockMinimo;
  final int? stockMaximo;
  final String? ubicacion;
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  // Relaciones
  final SedeStock? sede;
  final ProductoStockInfo? producto;
  final VarianteStockInfo? variante;
}
```

**Métodos útiles:**
```dart
stock.nombreProducto  // Nombre del producto/variante
stock.esBajoMinimo    // true si stock <= stockMinimo
stock.esCritico       // true si stock == 0
stock.porcentajeStock // % de stock respecto al máximo
```

### 2. MovimientoStock (movimiento_stock_model.dart)

```dart
class MovimientoStockModel {
  final String id;
  final String sedeId;
  final String productoStockId;
  final TipoMovimientoStock tipo;
  final int cantidadAnterior;
  final int cantidad;        // Positivo = entrada, Negativo = salida
  final int cantidadNueva;
  final String? motivo;
  final String? observaciones;
  final DateTime creadoEn;
}

enum TipoMovimientoStock {
  entradaCompra,
  entradaTransferencia,
  entradaAjuste,
  entradaDevolucion,
  salidaVenta,
  salidaTransferencia,
  salidaAjuste,
  salidaMerma,
  salidaRobo,
  salidaDonacion,
}
```

### 3. Modelos de Respuesta

```dart
class StockTodasSedesModel {
  final List<ProductoStockModel> stocks;
  final ResumenStockModel resumen;
}

class ResumenStockModel {
  final int totalSedes;
  final int stockTotal;
  final int sedesConStock;
  final int sedesSinStock;
}
```

---

## 🆕 Nuevo DataSource: ProductoStockRemoteDataSource

```dart
@lazySingleton
class ProductoStockRemoteDataSource {
  // 1. Crear stock inicial en sede
  Future<ProductoStockModel> crearStock({
    required String empresaId,
    required String sedeId,
    String? productoId,
    String? varianteId,
    required int stockActual,
    int? stockMinimo,
    int? stockMaximo,
    String? ubicacion,
  });

  // 2. Listar stock de una sede
  Future<Map<String, dynamic>> getStockPorSede({
    required String sedeId,
    required String empresaId,
    int page = 1,
    int limit = 50,
  });

  // 3. Stock de producto en sede específica
  Future<ProductoStockModel> getStockProductoEnSede({
    required String productoId,
    required String sedeId,
  });

  // 4. Stock de producto en TODAS las sedes
  Future<StockTodasSedesModel> getStockTodasSedes({
    required String productoId,
    required String empresaId,
    String? varianteId,
  });

  // 5. Ajustar stock (entrada/salida)
  Future<ProductoStockModel> ajustarStock({
    required String stockId,
    required String empresaId,
    required TipoMovimientoStock tipo,
    required int cantidad,
    String? motivo,
    String? observaciones,
    String? tipoDocumento,
    String? numeroDocumento,
  });

  // 6. Historial de movimientos
  Future<List<MovimientoStockModel>> getHistorialMovimientos({
    required String stockId,
    int limit = 50,
  });

  // 7. Alertas de stock bajo
  Future<Map<String, dynamic>> getAlertasStockBajo({
    required String empresaId,
    String? sedeId,
  });

  // 8. Validar stock de combo
  Future<Map<String, dynamic>> validarStockCombo({
    required String empresaId,
    required String comboId,
    required String sedeId,
    required int cantidad,
  });

  // 9. Descontar stock de combo
  Future<List<MovimientoStockModel>> descontarStockCombo({
    required String empresaId,
    required String comboId,
    required String sedeId,
    required int cantidad,
    String? tipoDocumento,
    String? numeroDocumento,
  });
}
```

---

## 💡 Ejemplos de Uso

### 1. Crear Stock Inicial en Sede

```dart
// Cuando un producto llega a una nueva sede
final stock = await productoStockDataSource.crearStock(
  empresaId: empresaId,
  sedeId: sedeActualId,
  productoId: producto.id,
  stockActual: 100,
  stockMinimo: 10,
  stockMaximo: 500,
  ubicacion: 'Pasillo 3, Estante B',
);

print('Stock creado: ${stock.stockActual} unidades en ${stock.sede?.nombre}');
```

### 2. Ver Stock en Todas las Sedes

```dart
final stockGlobal = await productoStockDataSource.getStockTodasSedes(
  productoId: producto.id,
  empresaId: empresaId,
);

print('Stock total: ${stockGlobal.resumen.stockTotal} unidades');
print('Distribuido en ${stockGlobal.resumen.totalSedes} sedes');

// Mostrar por sede
for (final stock in stockGlobal.stocks) {
  print('${stock.sede?.nombre}: ${stock.stockActual} unidades');
}
```

### 3. Ajustar Stock (Entrada/Salida)

```dart
// Entrada por compra
final stockActualizado = await productoStockDataSource.ajustarStock(
  stockId: stock.id,
  empresaId: empresaId,
  tipo: TipoMovimientoStock.entradaCompra,
  cantidad: 50, // Positivo = entrada
  motivo: 'Compra a proveedor XYZ',
  tipoDocumento: 'FACTURA',
  numeroDocumento: 'FC-2026-001',
);

// Salida por venta
final stockVenta = await productoStockDataSource.ajustarStock(
  stockId: stock.id,
  empresaId: empresaId,
  tipo: TipoMovimientoStock.salidaVenta,
  cantidad: -5, // Negativo = salida
  motivo: 'Venta al cliente',
  tipoDocumento: 'VENTA',
  numeroDocumento: 'VT-2026-001',
);
```

### 4. Alertas de Stock Bajo

```dart
final alertas = await productoStockDataSource.getAlertasStockBajo(
  empresaId: empresaId,
  sedeId: sedeActualId, // Opcional
);

final productos = alertas['productos'] as List;
final total = alertas['total'] as int;
final criticos = alertas['criticos'] as int;

// Mostrar alerta
if (total > 0) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('⚠️ Stock Bajo'),
      content: Text(
        '$total productos bajo mínimo\n'
        '$criticos productos sin stock',
      ),
    ),
  );
}
```

### 5. Validar y Vender Combo

```dart
// 1. Validar stock antes de vender
final validacion = await productoStockDataSource.validarStockCombo(
  empresaId: empresaId,
  comboId: combo.id,
  sedeId: sedeActualId,
  cantidad: 2,
);

final valido = validacion['valido'] as bool;
final faltantes = validacion['faltantes'] as List;

if (!valido) {
  // Mostrar componentes faltantes
  for (final faltante in faltantes) {
    print('${faltante['componenteNombre']}: '
          'necesita ${faltante['cantidadNecesaria']}, '
          'disponible ${faltante['cantidadDisponible']}');
  }
  throw Exception('Stock insuficiente para combo');
}

// 2. Descontar stock de todos los componentes
final movimientos = await productoStockDataSource.descontarStockCombo(
  empresaId: empresaId,
  comboId: combo.id,
  sedeId: sedeActualId,
  cantidad: 2,
  tipoDocumento: 'VENTA',
  numeroDocumento: 'VT-2026-001',
);

print('Se descontó stock de ${movimientos.length} componentes');
```

### 6. Historial de Movimientos

```dart
final movimientos = await productoStockDataSource.getHistorialMovimientos(
  stockId: stock.id,
  limit: 50,
);

// Mostrar historial
ListView.builder(
  itemCount: movimientos.length,
  itemBuilder: (context, index) {
    final mov = movimientos[index];
    return ListTile(
      leading: Icon(
        mov.esEntrada ? Icons.arrow_downward : Icons.arrow_upward,
        color: mov.esEntrada ? Colors.green : Colors.red,
      ),
      title: Text(mov.tipo.descripcion),
      subtitle: Text(mov.motivo ?? 'Sin motivo'),
      trailing: Text(
        '${mov.cantidad > 0 ? '+' : ''}${mov.cantidad}',
        style: TextStyle(
          color: mov.esEntrada ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  },
);
```

---

## 🎨 Ejemplo de UI: Selector de Sede

```dart
class SedeStockSelector extends StatelessWidget {
  final String productoId;
  final Function(ProductoStockModel) onSedeSelected;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StockTodasSedesModel>(
      future: context.read<ProductoStockDataSource>().getStockTodasSedes(
        productoId: productoId,
        empresaId: context.read<AuthProvider>().empresaId,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();

        final stockGlobal = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen global
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Stock Total: ${stockGlobal.resumen.stockTotal}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Distribuido en ${stockGlobal.resumen.totalSedes} sedes',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Lista de sedes
            ...stockGlobal.stocks.map((stock) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: stock.esCritico
                      ? Colors.red
                      : stock.esBajoMinimo
                          ? Colors.orange
                          : Colors.green,
                  child: Text('${stock.stockActual}'),
                ),
                title: Text(stock.sede?.nombre ?? 'Sede'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (stock.ubicacion != null)
                      Text('📍 ${stock.ubicacion}'),
                    if (stock.stockMinimo != null)
                      Text('Mínimo: ${stock.stockMinimo}'),
                  ],
                ),
                trailing: stock.esBajoMinimo
                    ? Icon(Icons.warning, color: Colors.orange)
                    : null,
                onTap: () => onSedeSelected(stock),
              );
            }),
          ],
        );
      },
    );
  }
}
```

---

## 🔄 Migración de Código Existente

### Paso 1: Actualizar llamadas a `actualizarStock`

**ANTES:**
```dart
await productoRepository.actualizarStock(
  productoId: producto.id,
  cantidad: 10,
  operacion: 'agregar',
);
```

**DESPUÉS:**
```dart
// Opción A: Usar endpoint actualizado (requiere sedeId)
final result = await productoRepository.actualizarStock(
  productoId: producto.id,
  sedeId: sedeActualId, // 🆕 AGREGAR
  cantidad: 10,
  operacion: 'agregar',
);
// result = { stock: 60, stockTotal: 150 }

// Opción B: Usar nuevo sistema (recomendado)
final stock = await productoStockRepository.ajustarStock(
  stockId: stockId,
  tipo: TipoMovimientoStock.entradaCompra,
  cantidad: 10,
  motivo: 'Reposición',
);
```

### Paso 2: Agregar selector de sede en formularios

```dart
// En formularios de ajuste de stock
class AjusteStockForm extends StatefulWidget {
  final Producto producto;

  @override
  _AjusteStockFormState createState() => _AjusteStockFormState();
}

class _AjusteStockFormState extends State<AjusteStockForm> {
  String? sedeSeleccionada;
  int cantidad = 0;
  TipoMovimientoStock tipo = TipoMovimientoStock.entradaAjuste;

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        children: [
          // 🆕 NUEVO - Selector de sede
          DropdownButtonFormField<String>(
            decoration: InputDecoration(labelText: 'Sede'),
            items: sedes.map((sede) {
              return DropdownMenuItem(
                value: sede.id,
                child: Text(sede.nombre),
              );
            }).toList(),
            onChanged: (value) => setState(() => sedeSeleccionada = value),
            validator: (value) => value == null ? 'Seleccione una sede' : null,
          ),

          // Tipo de movimiento
          DropdownButtonFormField<TipoMovimientoStock>(
            decoration: InputDecoration(labelText: 'Tipo de movimiento'),
            items: TipoMovimientoStock.values.map((tipo) {
              return DropdownMenuItem(
                value: tipo,
                child: Text(tipo.descripcion),
              );
            }).toList(),
            onChanged: (value) => setState(() => this.tipo = value!),
          ),

          // Cantidad
          TextFormField(
            decoration: InputDecoration(labelText: 'Cantidad'),
            keyboardType: TextInputType.number,
            onChanged: (value) => cantidad = int.tryParse(value) ?? 0,
          ),

          // Botón guardar
          ElevatedButton(
            onPressed: _guardar,
            child: Text('Ajustar Stock'),
          ),
        ],
      ),
    );
  }

  Future<void> _guardar() async {
    if (sedeSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Seleccione una sede')),
      );
      return;
    }

    await context.read<ProductoStockDataSource>().ajustarStock(
      stockId: stockId,
      empresaId: empresaId,
      tipo: tipo,
      cantidad: tipo.esEntrada ? cantidad : -cantidad,
      motivo: 'Ajuste manual',
    );

    Navigator.pop(context);
  }
}
```

---

## 📊 Dashboard de Inventario

```dart
class InventarioDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Inventario')),
      body: Column(
        children: [
          // Alertas de stock bajo
          _buildAlertasCard(context),

          // Stock por sede
          Expanded(
            child: _buildStockPorSede(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertasCard(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: context.read<ProductoStockDataSource>().getAlertasStockBajo(
        empresaId: empresaId,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox.shrink();

        final total = snapshot.data!['total'] as int;
        final criticos = snapshot.data!['criticos'] as int;

        if (total == 0) return SizedBox.shrink();

        return Card(
          color: Colors.orange.shade50,
          child: ListTile(
            leading: Icon(Icons.warning, color: Colors.orange),
            title: Text('$total productos bajo mínimo'),
            subtitle: Text('$criticos sin stock'),
            trailing: ElevatedButton(
              child: Text('Ver'),
              onPressed: () => Navigator.pushNamed(context, '/alertas'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStockPorSede(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: context.read<ProductoStockDataSource>().getStockPorSede(
        sedeId: sedeActualId,
        empresaId: empresaId,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();

        final stocks = (snapshot.data!['stocks'] as List)
            .map((e) => ProductoStockModel.fromJson(e))
            .toList();

        return ListView.builder(
          itemCount: stocks.length,
          itemBuilder: (context, index) {
            final stock = stocks[index];
            return _buildStockCard(stock);
          },
        );
      },
    );
  }

  Widget _buildStockCard(ProductoStockModel stock) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: stock.esCritico
              ? Colors.red
              : stock.esBajoMinimo
                  ? Colors.orange
                  : Colors.green,
          child: Text('${stock.stockActual}'),
        ),
        title: Text(stock.nombreProducto),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (stock.ubicacion != null)
              Text('📍 ${stock.ubicacion}'),
            if (stock.stockMinimo != null)
              Text('Mínimo: ${stock.stockMinimo}'),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.history),
          onPressed: () => _verHistorial(stock),
        ),
      ),
    );
  }

  Future<void> _verHistorial(ProductoStockModel stock) async {
    final movimientos = await context.read<ProductoStockDataSource>()
        .getHistorialMovimientos(stockId: stock.id);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Historial de ${stock.nombreProducto}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: movimientos.length,
            itemBuilder: (context, index) {
              final mov = movimientos[index];
              return ListTile(
                leading: Icon(
                  mov.esEntrada ? Icons.arrow_downward : Icons.arrow_upward,
                  color: mov.esEntrada ? Colors.green : Colors.red,
                ),
                title: Text(mov.tipo.descripcion),
                subtitle: Text(
                  '${mov.motivo ?? ''}\n'
                  '${mov.creadoEn.toString().substring(0, 16)}',
                ),
                trailing: Text(
                  '${mov.cantidad > 0 ? '+' : ''}${mov.cantidad}',
                  style: TextStyle(
                    color: mov.esEntrada ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
```

---

## ✅ Checklist de Integración

- [ ] Crear modelos: `producto_stock_model.dart`, `movimiento_stock_model.dart`
- [ ] Crear entities: `producto_stock.dart`, `movimiento_stock.dart`
- [ ] Crear datasource: `producto_stock_remote_datasource.dart`
- [ ] Actualizar `producto_remote_datasource.dart` (agregar sedeId)
- [ ] Registrar datasource en inyección de dependencias
- [ ] Actualizar formularios de stock para incluir selector de sede
- [ ] Crear UI para ver stock en todas las sedes
- [ ] Implementar alertas de stock bajo
- [ ] Agregar historial de movimientos
- [ ] Probar flujo completo de combos

---

## 🐛 Problemas Comunes

### 1. Error: "Stock no encontrado en sede"

**Causa**: El producto no tiene `ProductoStock` en esa sede.

**Solución**:
```dart
try {
  final stock = await datasource.getStockProductoEnSede(...);
} catch (e) {
  // Stock no existe, crear inicial
  final stock = await datasource.crearStock(
    sedeId: sedeId,
    productoId: productoId,
    stockActual: 0,
    stockMinimo: 10,
  );
}
```

### 2. Error: "Se requiere sedeId"

**Causa**: Llamada al endpoint antiguo sin sedeId.

**Solución**: Agregar sedeId al llamado:
```dart
await productoRepository.actualizarStock(
  ...
  sedeId: sedeActualId, // AGREGAR
);
```

### 3. Stock incorrecto después de migración

**Causa**: Cache desactualizado.

**Solución**: Limpiar cache local:
```dart
await sharedPreferences.clear();
await hiveBox.clear();
```

---

**Última actualización**: 2026-01-21
**Versión**: 1.0
**Estado**: ✅ Modelos y datasources creados
