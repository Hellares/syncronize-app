# 📦 Sistema de Stock - Flutter

## Resumen de Cambios

Se han agregado nuevos campos al modelo `ProductoStock` para preparar el sistema para módulos futuros de compras, ventas y devoluciones.

---

## 🆕 Nuevos Campos

### ProductoStock Entity

```dart
class ProductoStock {
  // ========== STOCK FÍSICO ==========
  final int stockActual;              // Stock físico total

  // ========== RESERVAS ==========
  final int stockReservado;           // Transferencias aprobadas
  final int stockReservadoVenta;      // 🆕 Apartados de clientes

  // ========== MERMA Y ESTADO ==========
  final int stockDanado;              // 🆕 Productos defectuosos
  final int stockEnGarantia;          // 🆕 En garantía/reparación
}
```

---

## 🧮 Getters Calculados

### Stock Disponible para Transferir
```dart
int get stockDisponible => stockActual - stockReservado;
```
> Se usa para validar transferencias entre sedes.

### Stock Disponible para Venta ⭐
```dart
int get stockDisponibleVenta =>
    stockActual - stockReservado - stockReservadoVenta - stockDanado - stockEnGarantia;
```
> **Principal métrica** para POS y eCommerce.

### Stock Comprometido
```dart
int get stockComprometido => stockReservado + stockReservadoVenta;
```

### Stock No Vendible
```dart
int get stockNoVendible => stockDanado + stockEnGarantia;
```

### Validaciones
```dart
bool get tieneStockReservado => stockReservado > 0;
bool get tieneStockReservadoVenta => stockReservadoVenta > 0;
bool get tieneStockDanado => stockDanado > 0;
bool get tieneStockEnGarantia => stockEnGarantia > 0;
bool get tieneIncidencias => tieneStockReservado || tieneStockReservadoVenta ||
                             tieneStockDanado || tieneStockEnGarantia;
```

---

## 🎨 UI Actualizada

### StockCard Widget

La tarjeta de stock ahora muestra:

#### Fila 1: Principales
- **Stock Físico Total** (azul)
- **Stock Disponible para Venta** (verde/rojo)

#### Fila 2: Incidencias (solo si hay)
- **Transfer.** - Stock reservado para transferencias (naranja)
- **Apartado** - Stock apartado para clientes (morado)
- **Dañado** - Productos defectuosos (rojo)
- **Garantía** - En proceso de garantía (ámbar)

#### Fila 3: Configuración (si existe)
- **Mínimo** - Stock mínimo configurado
- **Máximo** - Stock máximo configurado

### Ejemplo Visual
```
┌──────────────────────────────────────────┐
│ Laptop HP 15                       [OK]  │
│                                          │
│ ┌─────────────┐  ┌──────────────────┐   │
│ │ Físico Total│  │ Disponible       │   │
│ │    100      │  │      85          │   │
│ └─────────────┘  └──────────────────┘   │
│                                          │
│ Transfer: 5  Apartado: 8  Dañado: 2      │
│                                          │
│ ┌──────────┐  ┌──────────┐              │
│ │ Mínimo   │  │ Máximo   │              │
│ │    10    │  │   200    │              │
│ └──────────┘  └──────────┘              │
└──────────────────────────────────────────┘
```

---

## 📝 Formularios Actualizados

### Crear Transferencia

Antes:
```dart
'Stock: ${stock.stockActual}'
```

Ahora:
```dart
'Disponible: ${stock.stockDisponible}'
```

**Validación:**
```dart
if (cantidad > stock.stockDisponible) {
  return 'Stock disponible insuficiente';
}
```

### Diálogo de Agregar Producto (Transferencia Múltiple)

```dart
// Muestra información completa
if (stock.tieneStockReservado) {
  Text('Stock físico: ${stock.stockActual} | Reservado: ${stock.stockReservado}');
}
Text('Disponible para transferir: ${stock.stockDisponible} unidades');
```

---

## 🔄 Compatibilidad hacia Atrás

### Valores por Defecto
Todos los nuevos campos tienen valores por defecto de `0`:
```dart
stockReservadoVenta: 0,
stockDanado: 0,
stockEnGarantia: 0,
```

### Migración Automática
- El backend retorna los nuevos campos con valor `0` si no existen
- El frontend parsea correctamente con fallback a `0`
- Stock existente no se ve afectado

---

## 📱 Casos de Uso en UI

### Caso 1: Stock Normal (Sin Incidencias)
```dart
stockActual: 100
stockReservado: 0
stockReservadoVenta: 0
stockDanado: 0
stockEnGarantia: 0

// UI muestra solo:
┌─────────────────────────┐
│ Físico: 100             │
│ Disponible: 100         │
└─────────────────────────┘
```

### Caso 2: Con Transferencia Aprobada
```dart
stockActual: 100
stockReservado: 10
stockDisponible: 90

// UI muestra:
┌─────────────────────────┐
│ Físico: 100             │
│ Disponible: 90          │
│ Transfer: 10            │
└─────────────────────────┘
```

### Caso 3: Stock Comprometido Múltiple
```dart
stockActual: 100
stockReservado: 10        // Transferencia pendiente
stockReservadoVenta: 15   // Apartados de clientes
stockDanado: 5            // Productos defectuosos
stockDisponibleVenta: 70  // 100 - 10 - 15 - 5

// UI muestra:
┌─────────────────────────────────────┐
│ Físico: 100                         │
│ Disponible: 70                      │
│ Transfer: 10 | Apartado: 15 | Dañado: 5 │
└─────────────────────────────────────┘
```

---

## ⚠️ Importante

### Al Crear Transferencia
```dart
// ❌ INCORRECTO
if (cantidad > stock.stockActual) { ... }

// ✅ CORRECTO
if (cantidad > stock.stockDisponible) { ... }
```

### Para Ventas (Futuro)
```dart
// Usa stockDisponibleVenta (el más restrictivo)
if (cantidad > stock.stockDisponibleVenta) {
  throw 'Stock insuficiente para venta';
}
```

---

## 🎨 Colores Recomendados

```dart
// Estado del stock
Colors.green    // Stock OK
Colors.orange   // Stock bajo
Colors.red      // Sin stock / Crítico

// Tipos de reserva/merma
Colors.orange   // Transferencias (stockReservado)
Colors.purple   // Apartados de clientes (stockReservadoVenta)
Colors.red      // Productos dañados (stockDanado)
Colors.amber    // En garantía (stockEnGarantia)
```

---

## 🧪 Testing

### Casos de Prueba Sugeridos

```dart
testWidgets('Muestra stock disponible correctamente', (tester) async {
  final stock = ProductoStock(
    stockActual: 100,
    stockReservado: 10,
    stockReservadoVenta: 5,
    stockDanado: 2,
  );

  expect(stock.stockDisponible, 90);       // 100 - 10
  expect(stock.stockDisponibleVenta, 83);  // 100 - 10 - 5 - 2
});

testWidgets('Valida stock insuficiente en formulario', (tester) async {
  // Simular intentar transferir más de lo disponible
  // Debe mostrar error de validación
});
```

---

## 📚 Archivos Modificados

### Domain Layer
- ✅ `producto_stock.dart` - Entity actualizada con nuevos campos y getters

### Data Layer
- ✅ `producto_stock_model.dart` - Model con fromJson/toJson actualizado

### Presentation Layer
- ✅ `stock_card.dart` - Widget actualizado con visualización mejorada
- ✅ `crear_transferencia_page.dart` - Validaciones actualizadas
- ✅ `crear_transferencia_multiple_page.dart` - Validaciones actualizadas

---

## 🚀 Próximos Pasos

Cuando se implementen los módulos futuros:

### Módulo de Ventas
```dart
// Usar stockDisponibleVenta
if (producto.stockDisponibleVenta < cantidad) {
  mostrarError('Stock insuficiente');
}

// Al apartar producto
productoStock.stockReservadoVenta += cantidad;
```

### Módulo de Devoluciones
```dart
// Según estado del producto
if (producto.estadoProducto == EstadoProductoDevolucion.DANADO) {
  productoStock.stockDanado += cantidad;
} else {
  // Vuelve a stock disponible
}
```

---

## 📞 Soporte

Si encuentras algún problema con el sistema de stock:

1. Verifica que estés usando los getters correctos (`stockDisponible` vs `stockDisponibleVenta`)
2. Revisa que las validaciones usen stock disponible, no stock físico
3. Consulta la documentación del backend: `backend/docs/SISTEMA_STOCK.md`

---

**Última actualización:** 2026-01-25
**Versión:** 2.0.0
