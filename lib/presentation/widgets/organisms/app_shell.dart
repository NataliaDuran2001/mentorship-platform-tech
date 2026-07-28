// Atomic Design (Organism): Responsive navigation shell. It changes shape
// according to the AppConstants breakpoints: fixed 260px sidebar above 768,
// drawer + bottom nav in the middle range (481–768) and bottom nav with
// margins of 16 at ≤480. It knows nothing about routes, state or DI: it takes
// the destinations, the selected index and a callback; the wiring lives in the
// router.

import 'package:flutter/material.dart';

import '../molecules/nav_item.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';

/// Descriptor of a navigation destination of the shell.
class AppDestination {
  final String label;
  final IconData icon;

  /// Whether it takes one of the 4 bottom nav slots. Profile does not: at ≤768
  /// it is reached through the AppBar icon (decision noted in §9 of the
  /// handoff).
  final bool inBottomNav;

  const AppDestination({
    required this.label,
    required this.icon,
    this.inBottomNav = true,
  });
}

class AppShell extends StatelessWidget {
  /// Product title for the sidebar and drawer header.
  final String title;
  final List<AppDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  /// Signs out. If it is `null` the action is not shown, so that the shell
  /// keeps working in tests or on screens without authentication.
  final VoidCallback? onLogout;

  final Widget child;

  const AppShell({
    super.key,
    required this.title,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width <= AppConstants.breakpointMobile;
    final isDesktop = width > AppConstants.breakpointTablet;

    // Central content: capped at containerMax; on mobile the side margins drop
    // to 16 (spacingMd), as DESIGN.md requires.
    final margin = isMobile ? AppConstants.spacingMd : AppConstants.spacingLg;
    final content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppConstants.containerMax),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: margin),
          child: child,
        ),
      ),
    );

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            _buildSidebar(context),
            Expanded(child: content),
          ],
        ),
      );
    }

    // Middle range and mobile: AppBar + bottom nav with the destinations
    // flagged for it; the drawer with the full list only exists in the middle
    // range.
    final bottomDestinations =
        destinations.where((d) => d.inBottomNav).toList();
    final selected = destinations[selectedIndex];
    final bottomIndex = bottomDestinations.indexOf(selected);

    return Scaffold(
      appBar: AppBar(
        title: Text(selected.label),
        leading: bottomIndex < 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back',
                onPressed: () => onDestinationSelected(0), // Default to first tab (My path)
              )
            : null,
        actions: [
          for (final destination in destinations)
            if (!destination.inBottomNav)
              IconButton(
                icon: Icon(destination.icon),
                tooltip: destination.label,
                color: destination == selected ? AppColors.primary : null,
                onPressed: () =>
                    onDestinationSelected(destinations.indexOf(destination)),
              ),
        ],
      ),
      drawer: isMobile ? null : _buildDrawer(context),
      body: content,
      // The destination outside the 4 slots (Profile) is shown without bottom
      // nav, as a full view; you come back through the AppBar or the drawer.
      bottomNavigationBar: bottomIndex < 0
          ? null
          : NavigationBar(
              selectedIndex: bottomIndex,
              destinations: [
                for (final destination in bottomDestinations)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    label: destination.label,
                  ),
              ],
              onDestinationSelected: (i) => onDestinationSelected(
                destinations.indexOf(bottomDestinations[i]),
              ),
            ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    // Its own Material: ListTile paints its background and ink on the nearest
    // Material, so the color cannot live in an intermediate Container.
    return Material(
      color: AppColors.surfaceContainerLow,
      child: Container(
        width: AppConstants.sidebarWidth,
        decoration: const BoxDecoration(
          border: Border(right: BorderSide(color: AppColors.outlineVariant)),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppConstants.spacingMd),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: AppConstants.spacingSm),
              for (final (i, destination) in destinations.indexed)
                NavItem(
                  label: destination.label,
                  icon: destination.icon,
                  selected: i == selectedIndex,
                  onTap: () => onDestinationSelected(i),
                ),
              if (onLogout != null) ...[
                const Spacer(),
                const Divider(),
                NavItem(
                  label: 'Sign out',
                  icon: Icons.logout,
                  selected: false,
                  onTap: onLogout!,
                ),
                const SizedBox(height: AppConstants.spacingSm),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: AppConstants.spacingSm),
            for (final (i, destination) in destinations.indexed)
              NavItem(
                label: destination.label,
                icon: destination.icon,
                selected: i == selectedIndex,
                onTap: () {
                  Navigator.pop(context);
                  onDestinationSelected(i);
                },
              ),
            if (onLogout != null) ...[
              const Spacer(),
              const Divider(),
              NavItem(
                label: 'Sign out',
                icon: Icons.logout,
                selected: false,
                onTap: () {
                  Navigator.pop(context);
                  onLogout!();
                },
              ),
              const SizedBox(height: AppConstants.spacingSm),
            ],
          ],
        ),
      ),
    );
  }
}
