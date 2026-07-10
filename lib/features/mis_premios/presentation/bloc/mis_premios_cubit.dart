import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/resource.dart';
import '../../domain/entities/premio_cliente.dart';
import '../../domain/repositories/mis_premios_repository.dart';

part 'mis_premios_state.dart';

@injectable
class MisPremiosCubit extends Cubit<MisPremiosState> {
  final MisPremiosRepository _repository;

  MisPremiosCubit(this._repository) : super(const MisPremiosLoading());

  Future<void> load() async {
    emit(const MisPremiosLoading());
    final result = await _repository.getMisPremios();
    if (isClosed) return;
    if (result is Success<List<PremioCliente>>) {
      emit(MisPremiosLoaded(result.data));
    } else if (result is Error<List<PremioCliente>>) {
      emit(MisPremiosError(result.message));
    }
  }
}
