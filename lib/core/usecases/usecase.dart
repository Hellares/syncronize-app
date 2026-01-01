import '../utils/resource.dart';

/// Clase base abstracta para todos los casos de uso
///
/// [T] es el tipo de dato que retorna el caso de uso
/// [Params] son los parámetros que recibe el caso de uso
abstract class UseCase<T, Params> {
  Future<Resource<T>> call(Params params);
}

/// Caso de uso sin parámetros
class NoParams {
  const NoParams();
}
