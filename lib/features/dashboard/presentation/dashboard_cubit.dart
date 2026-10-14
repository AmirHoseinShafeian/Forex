import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit() : super(const DashboardState());

  void selectMenu(String value) => emit(state.copyWith(selectedMenu: value));
  void selectTimeframe(String value) => emit(state.copyWith(timeframe: value));
}
