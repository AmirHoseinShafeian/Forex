import 'package:equatable/equatable.dart';

class DashboardState extends Equatable {
  const DashboardState({
    this.selectedMenu = 'Dashboard',
    this.timeframe = 'M15',
  });

  final String selectedMenu;
  final String timeframe;

  DashboardState copyWith({String? selectedMenu, String? timeframe}) {
    return DashboardState(
      selectedMenu: selectedMenu ?? this.selectedMenu,
      timeframe: timeframe ?? this.timeframe,
    );
  }

  @override
  List<Object> get props => [selectedMenu, timeframe];
}
