/// La ficha técnica agrupada por secciones —las plantillas con las que se
/// cargaron los atributos— y dibujada como tabla `nombre | valor`.
///
/// Vive acá y no dentro de una pantalla porque la usan el detalle del producto
/// y el diálogo de detalle de una VARIANTE: dos implementaciones de la misma
/// tabla se desincronizan a la primera de cambio.
///
/// Los valores se reciben como `List<dynamic>`: producto y variante usan la
/// misma forma (`atributoId`, `valor`, `atributo.nombre`) pero no comparten un
/// tipo común.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/atributo_plantilla.dart';

/// Los atributos SUELTOS, cada uno como su propia sección titulada con su
/// nombre.
///
/// 🔴 Antes iban todos juntos bajo un rótulo inventado ("Otras", después "Sin
/// sección"). Dos problemas: no decía nada, y en el catálogo hay una plantilla
/// de VERDAD llamada **OTROS**, así que la ficha mostraba "OTROS" (sección del
/// usuario) y justo debajo "Otras" (invento del app) sin forma de distinguirlas.
/// Titulando con el nombre del atributo el rótulo dice algo y el choque
/// desaparece.
///
/// La fila va sin la columna del nombre: ya está en el título.
List<Widget> seccionesDeAtributosSueltos(List sueltos) {
  return [
    for (final av in sueltos) ...[
      const SizedBox(height: 4),
      TituloSeccionAtributos('${av.atributo.nombre}'),
      const SizedBox(height: 5),
      TablaAtributos([av], soloValor: true),
    ],
  ];
}

/// Reparte los valores en las secciones con las que se cargaron.
///
/// Devuelve los pares (nombre de sección, valores) más los SUELTOS: atributos
/// que existen pero que ninguna plantilla aplicada reclama —cargados a mano, o
/// de una plantilla que después se borró—. Esos no se pueden esconder: son
/// datos igual.
///
/// [plantillasIds] es el orden guardado en el producto y manda. Si viene vacío
/// —el caso de una variante, que no guarda secciones propias— se recorre
/// [plantillas] en su propio orden y cada sección se queda con los atributos
/// que le pertenecen. Un atributo que está en dos plantillas cae en la primera
/// que lo reclama; por eso el orden guardado es preferible cuando se tiene.
(List<(String, List<dynamic>)>, List<dynamic>) agruparAtributosPorSeccion({
  required List atributosValores,
  required List<String> plantillasIds,
  required List<AtributoPlantilla> plantillas,
}) {
  final porAtributo = <String, dynamic>{
    for (final av in atributosValores) av.atributoId as String: av,
  };
  final usados = <String>{};
  final secciones = <(String, List<dynamic>)>[];

  final ordenadas = plantillasIds.isEmpty
      ? plantillas
      : [
          for (final id in plantillasIds)
            ...plantillas.where((p) => p.id == id),
        ];

  for (final plantilla in ordenadas) {
    final propios = <dynamic>[];
    for (final pa in plantilla.atributos) {
      final av = porAtributo[pa.atributo.id];
      // `usados` evita repetir un atributo que está en dos plantillas.
      if (av != null && usados.add(pa.atributo.id)) propios.add(av);
    }
    if (propios.isNotEmpty) secciones.add((plantilla.nombre, propios));
  }

  final sueltos = [
    for (final av in atributosValores)
      if (!usados.contains(av.atributoId)) av,
  ];
  return (secciones, sueltos);
}

/// El encabezado de una sección de la ficha.
class TituloSeccionAtributos extends StatelessWidget {
  final String nombre;

  const TituloSeccionAtributos(this.nombre, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.folder_outlined, size: 12, color: AppColors.blue1),
        const SizedBox(width: 4),
        Text(
          nombre.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: AppColors.blue1,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

/// Ficha técnica en filas `nombre | valor`, igual que el detalle del
/// marketplace: cebra en las pares y un divisor fino entre filas.
///
/// Reemplazó a los chips sueltos, que con muchas características se leían como
/// una bolsa: el fabricante del procesador al lado del color de la carcasa, sin
/// alineación entre nombre y valor.
class TablaAtributos extends StatelessWidget {
  final List atributosValores;

  /// Sin la columna del nombre: la usan los atributos sueltos, que llevan su
  /// nombre en el título de la sección y repetirlo abajo sobra.
  final bool soloValor;

  const TablaAtributos(
    this.atributosValores, {
    super.key,
    this.soloValor = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < atributosValores.length; i++)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: i.isEven ? Colors.grey.shade50 : Colors.white,
                border: i == 0
                    ? null
                    : Border(
                        top: BorderSide(
                            color: Colors.grey.shade200, width: 0.5),
                      ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dos tercios para el valor, como en el marketplace: los
                  // nombres son cortos y los valores se van largos.
                  if (!soloValor) ...[
                    Expanded(
                      flex: 2,
                      child: Text(
                        atributosValores[i].atributo.nombre,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    flex: 3,
                    child: Text(
                      '${atributosValores[i].valor}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
