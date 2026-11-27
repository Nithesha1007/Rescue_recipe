import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum NavTab {
  home('Home', 'Home', Icons.home_outlined, Icons.home),
  kitchen('Kitchen', 'My Kitchen', Icons.kitchen_outlined, Icons.kitchen),
  recipes(
    'Recipes',
    'Recipes',
    Icons.restaurant_menu_outlined,
    Icons.restaurant_menu,
  ),
  insights('Insights', 'Insights', Icons.insights_outlined, Icons.insights),
  profile('Profile', 'Profile', Icons.person_outline, Icons.person);

  const NavTab(this.shortLabel, this.label, this.icon, this.selectedIcon);

  /// Short label for the bottom bar (fits at 320dp).
  final String shortLabel;

  /// Full label for the rail, tooltips and screen titles.
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class NavigationCubit extends Cubit<NavTab> {
  NavigationCubit() : super(NavTab.home);

  void select(NavTab tab) => emit(tab);

  void selectIndex(int index) => emit(NavTab.values[index]);
}
