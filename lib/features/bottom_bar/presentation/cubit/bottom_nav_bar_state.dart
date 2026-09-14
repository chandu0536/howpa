import 'package:equatable/equatable.dart';

class BottomNavBarState extends Equatable {
  final int selectedIndex;

  const BottomNavBarState({this.selectedIndex = 0});

  @override
  List<Object?> get props => [selectedIndex];
}
