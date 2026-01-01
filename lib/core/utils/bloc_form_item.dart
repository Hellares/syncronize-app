// / Helper para manejo de items de formulario en BLoC
// / Mantiene el valor y el error de cada campo
// class BlocFormItem {
//   final String value;
//   final String? error;

//   const BlocFormItem({
//     this.value = '',
//     this.error,
//   });

//   /// Crea una copia con valores actualizados
//   BlocFormItem copyWith({
//     String? value,
//     String? error,
//     bool clearError = false, // Parámetro explícito para limpiar el error
//   }) {
//     return BlocFormItem(
//       value: value ?? this.value,
//       error: clearError ? null : (error ?? this.error),
//     );
//   }
  
// }

import 'package:equatable/equatable.dart';

class BlocFormItem extends Equatable {
  final String value;
  final String? error;

  const BlocFormItem({
    this.value = '',
    this.error,
  });

  BlocFormItem copyWith({
    String? value,
    String? error,
    bool clearError = false,
  }) {
    return BlocFormItem(
      value: value ?? this.value,
      error: clearError ? null : error,
    );
  }

  bool get isValid => error == null;

  @override
  List<Object?> get props => [value, error];
}
