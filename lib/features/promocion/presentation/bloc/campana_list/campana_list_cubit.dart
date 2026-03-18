import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/campana.dart';
import '../../../domain/repositories/promocion_repository.dart';
import 'campana_list_state.dart';

@injectable
class CampanaListCubit extends Cubit<CampanaListState> {
  final PromocionRepository _repository;

  CampanaListCubit(this._repository) : super(const CampanaListInitial());

  int _page = 1;

  Future<void> loadCampanas({int page = 1}) async {
    _page = page;
    emit(const CampanaListLoading());

    final result = await _repository.getCampanas(page: page);
    if (isClosed) return;

    if (result is Success<CampanasPaginadas>) {
      emit(CampanaListLoaded(resultado: result.data));
    } else if (result is Error<CampanasPaginadas>) {
      emit(CampanaListError(result.message));
    }
  }

  Future<void> reload() async {
    await loadCampanas(page: _page);
  }
}
