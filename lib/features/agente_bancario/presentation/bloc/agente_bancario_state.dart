import 'package:equatable/equatable.dart';
import '../../domain/entities/agente_bancario.dart';

abstract class AgenteBancarioState extends Equatable {
  const AgenteBancarioState();
  @override
  List<Object?> get props => [];
}

class AgenteBancarioInitial extends AgenteBancarioState {
  const AgenteBancarioInitial();
}

class AgenteBancarioLoading extends AgenteBancarioState {
  const AgenteBancarioLoading();
}

class AgenteBancarioLoaded extends AgenteBancarioState {
  final ResumenAgentes resumen;
  final List<AgenteBancario> agentes;

  const AgenteBancarioLoaded({
    required this.resumen,
    required this.agentes,
  });

  @override
  List<Object?> get props => [resumen, agentes];
}

class AgenteBancarioDetalleLoaded extends AgenteBancarioState {
  final AgenteBancario agente;
  final List<OperacionAgente> operaciones;

  const AgenteBancarioDetalleLoaded({
    required this.agente,
    required this.operaciones,
  });

  @override
  List<Object?> get props => [agente, operaciones];
}

class AgenteBancarioError extends AgenteBancarioState {
  final String message;
  const AgenteBancarioError(this.message);
  @override
  List<Object?> get props => [message];
}
