import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/responsive_builder.dart';
import '../../../ingredients/presentation/pages/kitchen_page.dart';
import '../../../insights/presentation/pages/insights_page.dart';
import '../../../recipes/presentation/pages/recipes_page.dart';
import '../../../settings/presentation/pages/profile_page.dart';
import '../cubit/navigation_cubit.dart';
import 'home_page.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  static const List<Widget> _pages = <Widget>[
    HomePage(),
    KitchenPage(),
    RecipesPage(),
    InsightsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationCubit, NavTab>(
      builder: (context, tab) {
        void onSelect(int index) {
          HapticFeedback.selectionClick();
          context.read<NavigationCubit>().selectIndex(index);
        }

        // Keep every page alive but pause animations on hidden ones.
        final Widget body = IndexedStack(
          index: tab.index,
          children: [
            for (int i = 0; i < _pages.length; i++)
              TickerMode(enabled: i == tab.index, child: _pages[i]),
          ],
        );

        return ResponsiveBuilder(
          builder: (context, size, _) {
            if (size.isCompact) {
              return Scaffold(
                body: body,
                bottomNavigationBar: NavigationBar(
                  selectedIndex: tab.index,
                  onDestinationSelected: onSelect,
                  destinations: [
                    for (final NavTab t in NavTab.values)
                      NavigationDestination(
                        icon: Icon(t.icon),
                        selectedIcon: Icon(t.selectedIcon),
                        label: t.shortLabel,
                        tooltip: t.label,
                      ),
                  ],
                ),
              );
            }

            return Scaffold(
              body: Row(
                children: [
                  SafeArea(
                    right: false,
                    child: _Rail(
                      selectedIndex: tab.index,
                      onSelect: onSelect,
                      extended: size.isExpanded,
                    ),
                  ),
                  const VerticalDivider(width: AppSizes.divider),
                  Expanded(child: body),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({
    required this.selectedIndex,
    required this.onSelect,
    required this.extended,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelect,
      extended: extended,
      labelType: extended ? null : NavigationRailLabelType.all,
      destinations: [
        for (final NavTab t in NavTab.values)
          NavigationRailDestination(
            icon: Icon(t.icon),
            selectedIcon: Icon(t.selectedIcon),
            label: Text(t.shortLabel),
          ),
      ],
    );
  }
}
