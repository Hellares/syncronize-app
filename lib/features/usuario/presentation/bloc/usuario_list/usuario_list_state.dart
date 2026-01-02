import 'package:equatable/equatable.dart';
import '../../../domain/entities/usuario.dart';

/// Estados del cubit de lista de usuarios
abstract class UsuarioListState extends Equatable {
  const UsuarioListState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class UsuarioListInitial extends UsuarioListState {
  const UsuarioListInitial();
}

/// Estado de carga
class UsuarioListLoading extends UsuarioListState {
  const UsuarioListLoading();
}

/// Estado de carga exitosa
class UsuarioListLoaded extends UsuarioListState {
  final List<Usuario> usuarios;
  final int total;
  final int currentPage;
  final int totalPages;
  final bool hasMore;

  const UsuarioListLoaded({
    required this.usuarios,
    required this.total,
    required this.currentPage,
    required this.totalPages,
    required this.hasMore,
  });

  @override
  List<Object?> get props => [usuarios, total, currentPage, totalPages, hasMore];
}

/// Estado de error
class UsuarioListError extends UsuarioListState {
  final String message;

  const UsuarioListError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Estado de carga de más usuarios (paginación)
class UsuarioListLoadingMore extends UsuarioListState {
  final List<Usuario> currentUsuarios;

  const UsuarioListLoadingMore(this.currentUsuarios);

  @override
  List<Object?> get props => [currentUsuarios];
}
