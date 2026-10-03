import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:syncronize/features/marketplace/domain/entities/producto_marketplace.dart';
import 'package:syncronize/features/marketplace/presentation/widgets/producto_marketplace_card.dart';

/// 🔴 Test de MONTAJE: el carrusel del marketplace le da a la card compacta
/// una celda FIJA de 126 x 158 y el contenido pedía 2.5 px de más.
void main() {
  testWidgets('la card compacta entra en 126 x 158 con rating, vendidos y nombre largo',
      (tester) async {
    const producto = ProductoMarketplace(
      id: 'p1',
      nombre: 'EDREDON 2 PLAZAS TELA CRISTAL CON DISEÑO DE COLECCIÓN MUY LARGO',
      precio: 120,
      precioOferta: 95,
      enOferta: true,
      hayStock: true,
      calificacion: 4.8,
      totalOpiniones: 23,
      vendidos: 1250,
      tieneVariantes: true,
      empresa: EmpresaMarketplace(id: 'e1', nombre: 'JAYLI'),
    );
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 126,
            height: 158,
            child: ProductoMarketplaceCard(producto: producto, compact: true),
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(find.textContaining('S/ 95.00'), findsOneWidget);
  });
}
