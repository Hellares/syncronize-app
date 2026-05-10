# PDF Service

Núcleo compartido para generar documentos PDF (cotizaciones, ventas, compras).
Reemplaza la duplicación que vivía en cada `pdf_*_generator.dart` de los features.

## Arquitectura

```
PdfDocumentService.build(...)  ← orquestador (página A4 vs ticket)
       │
       ├─ PdfDocumentStyle.fromConfig(...)     ← config + flags + colores + márgenes
       │
       ├─ Builders compuestos (en builders/):
       │     • PdfHeaderBuilder.build(...)
       │     • PdfPartyBuilder.build(...)       (cliente / proveedor)
       │     • PdfTotalesBuilder.simple(...)
       │     • PdfFooterBuilder.build(...)
       │
       └─ PdfRowBuilders (helpers atómicos):
             • totalRow / infoRow / tableCell
```

## Cómo agregar un nuevo tipo de documento

```dart
final style = PdfDocumentStyle.fromConfig(
  documentConfig: documentConfig,
  empresaNombre: empresaNombre,
  empresaRuc: empresaRuc,
  defaultMarginMm: 10.0,
);

final bodyWidgets = <pw.Widget>[
  PdfHeaderBuilder.build(
    empresaNombre: style.empresaNombre,
    empresaRuc: style.empresaRuc,
    sedeNombre: style.sedeNombre,
    logo: style.showLogo ? logoEmpresa : null,
    tipoDocumento: 'RECIBO',
    codigo: 'R-2026-00001',
    documentLines: ['Fecha: ...', 'Moneda: PEN'],
    primaryColor: style.colorPrimario,
    isTicket: style.formatoPapel.isTicket,
  ),
  pw.SizedBox(height: 20),
  PdfPartyBuilder.build(
    title: 'DATOS DEL CLIENTE',
    fields: [
      PdfPartyField('Cliente', '...'),
      PdfPartyField('Documento', '...'),
    ],
    primaryColor: style.colorPrimario,
  ),
  // ... tabla items propia + observaciones + ...
  PdfTotalesBuilder.simple(
    moneda: 'PEN',
    subtotal: 100.00,
    descuento: 0,
    impuestos: 18.00,
    total: 118.00,
  ),
];

return PdfDocumentService.build(
  style: style,
  bodyWidgets: bodyWidgets,
  footerText: style.textoPiePagina ?? 'Gracias por su preferencia',
);
```

## Defaults por tipo de documento

| Generator | `defaultMarginMm` | `defaultPrimaryColor` | `defaultBodyColor` |
|---|---|---|---|
| Cotización | 10 | `kDefaultPdfPrimary` (#1565C0) | `PdfColors.black` |
| Compra | 10 | `kDefaultPdfPrimary` | `PdfColors.black` |
| Venta (ticket) | 4 | `PdfColors.black` | `PdfColors.black` |

## Tests

`test/pdf/` contiene golden tests que verifican el contenido textual del PDF
(no el layout pixel-perfect). El golden filtra timestamps volátiles del footer
(`Generado: DD/MM/YYYY HH:MM`) para que el hash sea reproducible.

```bash
flutter test test/pdf/
```

Cuando refactores algo y un golden falla:
1. Verifica visualmente que el PDF nuevo sigue siendo correcto.
2. Si está bien, actualiza `expected.textHash` en el test correspondiente.
3. Commitea explícitamente el cambio del golden.

## Generators legacy pendientes de migración

Estos no usan `ConfiguracionDocumentoCompleta` y mantienen su propia lógica:

- `features/producto/presentation/services/pdf_transferencia_generator.dart`
- `features/servicio/presentation/services/pdf_orden_servicio_generator.dart`
- `features/guia_remision/presentation/services/pdf_guia_remision_generator.dart`

Marcados con `TODO(pdf-refactor)`. Migrarlos cuando adopten el config central.
