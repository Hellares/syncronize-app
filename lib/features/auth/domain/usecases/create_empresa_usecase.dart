import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/resource.dart';
import '../entities/empresa.dart';
import '../entities/rubro_empresa.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso para crear una nueva empresa
@injectable
class CreateEmpresaUseCase implements UseCase<Empresa, CreateEmpresaParams> {
  final AuthRepository repository;

  CreateEmpresaUseCase(this.repository);

  @override
  Future<Resource<Empresa>> call(CreateEmpresaParams params) async {
    return await repository.createEmpresa(
      nombre: params.nombre,
      rubro: params.rubro,
      ruc: params.ruc,
      descripcion: params.descripcion,
      telefono: params.telefono,
      email: params.email,
      web: params.web,
      subdominio: params.subdominio,
      logo: params.logo,
    );
  }
}

/// Parámetros para crear empresa
class CreateEmpresaParams extends Equatable {
  final String nombre;
  final RubroEmpresa rubro;
  final String? ruc;
  final String? descripcion;
  final String? telefono;
  final String? email;
  final String? web;
  final String? subdominio;
  final String? logo;
  final List<String>? categoriasMaestrasIds;
  final List<String>? marcasMaestrasIds;

  const CreateEmpresaParams({
    required this.nombre,
    required this.rubro,
    this.ruc,
    this.descripcion,
    this.telefono,
    this.email,
    this.web,
    this.subdominio,
    this.logo,
    this.categoriasMaestrasIds,
    this.marcasMaestrasIds,
  });

  @override
  List<Object?> get props => [
        nombre,
        rubro,
        ruc,
        descripcion,
        telefono,
        email,
        web,
        subdominio,
        logo,
        categoriasMaestrasIds,
        marcasMaestrasIds,
      ];
}
