import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/features/servicio/domain/entities/orden_servicio.dart';

/// Lo que se le nombra al cliente cuando se le escribe: "la orden OS-000123"
/// no le dice nada, "su LAPTOP HP PAVILION" sí.
void main() {
  OrdenServicio orden({
    String? tipo,
    String? marca,
    OrdenModeloEquipo? modelo,
  }) {
    final ahora = DateTime(2026, 8, 26);
    return OrdenServicio(
      id: 'os_1',
      empresaId: 'emp_1',
      codigo: 'OS-000123',
      tipoServicio: 'REPARACION',
      tipoEquipo: tipo,
      marcaEquipo: marca,
      modeloEquipo: modelo,
      estado: 'RECIBIDO',
      creadoEn: ahora,
      actualizadoEn: ahora,
    );
  }

  const modeloCatalogo =
      OrdenModeloEquipo(id: 'm_1', marca: 'HP', modelo: 'Pavilion 15');

  group('OrdenServicio.descripcionEquipo', () {
    test('tipo + modelo del catálogo', () {
      expect(
        orden(tipo: 'LAPTOP', modelo: modeloCatalogo).descripcionEquipo,
        'LAPTOP HP Pavilion 15',
      );
    });

    test('🔴 el modelo del catálogo le gana a la marca tecleada a mano', () {
      // Mismo orden de prioridad que la sección EQUIPO de la pantalla.
      expect(
        orden(tipo: 'LAPTOP', marca: 'HP', modelo: modeloCatalogo)
            .descripcionEquipo,
        'LAPTOP HP Pavilion 15',
      );
    });

    test('sin modelo cae a la marca suelta', () {
      expect(orden(tipo: 'LAPTOP', marca: 'HP').descripcionEquipo, 'LAPTOP HP');
    });

    test('con una sola parte no deja espacios colgando', () {
      expect(orden(tipo: 'LAPTOP').descripcionEquipo, 'LAPTOP');
      expect(orden(marca: 'HP').descripcionEquipo, 'HP');
      expect(orden(modelo: modeloCatalogo).descripcionEquipo, 'HP Pavilion 15');
    });

    test('sin equipo registrado devuelve null', () {
      expect(orden().descripcionEquipo, isNull);
      // Cadenas vacías cuentan como sin equipo, igual que en el resto del
      // sistema los textos opcionales llegan como '' y no como null.
      expect(orden(tipo: '', marca: '   ').descripcionEquipo, isNull);
    });
  });
}
