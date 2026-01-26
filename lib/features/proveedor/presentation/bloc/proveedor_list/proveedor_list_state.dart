import 'package:equatable/equatable.dart';
import '../../../domain/entities/proveedor.dart';

/// Estados para la lista de proveedores
abstract class ProveedorListState extends Equatable {
  const ProveedorListState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class ProveedorListInitial extends ProveedorListState {
  const ProveedorListInitial();
}

/// Estado de carga
class ProveedorListLoading extends ProveedorListState {
  const ProveedorListLoading();
}

/// Estado con datos cargados
class ProveedorListLoaded extends ProveedorListState {
  final List<Proveedor> proveedores;
  final bool includeInactive;
  final String? searchQuery;

  const ProveedorListLoaded({
    required this.proveedores,
    this.includeInactive = false,
    this.searchQuery,
  });

  /// Filtra proveedores localmente por búsqueda
  List<Proveedor> get filteredProveedores {
    if (searchQuery == null || searchQuery!.isEmpty) {
      return proveedores;
    }

    final query = searchQuery!.toLowerCase();
    return proveedores.where((p) {
      return p.nombre.toLowerCase().contains(query) ||
          p.codigo.toLowerCase().contains(query) ||
          p.numeroDocumento.contains(query) ||
          (p.nombreComercial?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  /// Proveedores activos
  List<Proveedor> get proveedoresActivos {
    return filteredProveedores.where((p) => p.isActive).toList();
  }

  /// Proveedores inactivos
  List<Proveedor> get proveedoresInactivos {
    return filteredProveedores.where((p) => !p.isActive).toList();
  }

  /// Proveedores con buena calificación (4-5 estrellas)
  List<Proveedor> get proveedoresBienCalificados {
    return filteredProveedores.where((p) => p.buenaCalificacion).toList();
  }

  @override
  List<Object?> get props => [
        proveedores,
        includeInactive,
        searchQuery,
      ];

  ProveedorListLoaded copyWith({
    List<Proveedor>? proveedores,
    bool? includeInactive,
    String? searchQuery,
  }) {
    return ProveedorListLoaded(
      proveedores: proveedores ?? this.proveedores,
      includeInactive: includeInactive ?? this.includeInactive,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Estado de error
class ProveedorListError extends ProveedorListState {
  final String message;

  const ProveedorListError(this.message);

  @override
  List<Object?> get props => [message];
}
