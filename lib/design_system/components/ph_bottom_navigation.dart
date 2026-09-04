import 'package:flutter/material.dart';
import 'package:packagehub/design_system/tokens/ph_color_scheme.dart';
import 'package:packagehub/design_system/tokens/ph_typography.dart';

class PHBottomNavigationItem {
  final Widget icon;
  final Widget? selectedIcon;
  final String label;

  const PHBottomNavigationItem({
    required this.icon,
    required this.label,
    this.selectedIcon,
  });
}

class PHBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<PHBottomNavigationItem> items;

  const PHBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final colors = PHColorScheme.of(context);
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: colors.bgSurface,
        indicatorColor: colors.bgAccentSubtle,
        labelTextStyle: WidgetStatePropertyAll(
          PHTypography.caption1.copyWith(color: colors.textSecondary),
        ),
        iconTheme: WidgetStatePropertyAll(
          IconThemeData(color: colors.iconSecondary),
        ),
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: [
          for (final item in items)
            NavigationDestination(
              icon: item.icon,
              selectedIcon: item.selectedIcon,
              label: item.label,
            ),
        ],
      ),
    );
  }
}
