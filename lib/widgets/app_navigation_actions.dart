import 'package:flutter/material.dart';
import 'package:keystone/features/calendar/calendar_screen.dart';
import 'package:keystone/features/lists/lists_screen.dart';
import 'package:keystone/features/projects/projects_screen.dart';
import 'package:keystone/features/search/search_screen.dart';
import 'package:keystone/features/settings/settings_screen.dart';

/// Reusable navigation actions for consistent navigation across all screens
class AppNavigationActions extends StatelessWidget {
  /// The current route name to avoid navigating to the same screen
  final String? currentRoute;

  const AppNavigationActions({
    super.key,
    this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Show Home button on Calendar, Lists, Projects, Search, Settings, and detail pages
        if (currentRoute == '/calendar' || 
            currentRoute == '/lists' ||
            currentRoute == '/projects' || 
            currentRoute == '/search' || 
            currentRoute == '/settings' ||
            currentRoute == '/project-detail')
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Home',
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        if (currentRoute != '/calendar')
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Calendar',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CalendarScreen()),
              );
            },
          ),
        if (currentRoute != '/lists')
          IconButton(
            icon: const Icon(Icons.check_box),
            tooltip: 'Lists',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ListsScreen()),
              );
            },
          ),
        if (currentRoute != '/projects')
          IconButton(
            icon: const Icon(Icons.account_tree),
            tooltip: 'Projects',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProjectsScreen()),
              );
            },
          ),
        if (currentRoute != '/search')
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
        if (currentRoute != '/settings')
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
      ],
    );
  }
}
