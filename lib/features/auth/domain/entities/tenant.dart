import 'package:equatable/equatable.dart';

/// Entidad de tenant/empresa
class Tenant extends Equatable {
  final String id;
  final String name;
  final String role;

  const Tenant({
    required this.id,
    required this.name,
    required this.role,
  });

  @override
  List<Object?> get props => [id, name, role];
}
