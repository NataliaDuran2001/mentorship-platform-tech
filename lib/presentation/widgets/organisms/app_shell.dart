// Atomic Design (Organismo): Shell de navegación responsivo. Cambia de forma
// según los breakpoints de AppConstants: sidebar fija de 260px arriba de 768,
// drawer + bottom nav en el rango intermedio (481–768) y bottom nav con
// márgenes de 16 en ≤480. No conoce rutas, estado ni DI: recibe los destinos,
// el índice seleccionado y un callback; el wiring vive en el router.

import 'package:flutter/material.dart';

import '../molecules/nav_item.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';

/// Descriptor de un destino de navegación del shell.
class AppDestination {
  final String label;
  final IconData icon;

  /// Si ocupa uno de los 4 slots del bottom nav. Perfil no lo hace: en ≤768
  /// se llega por el ícono del AppBar (decisión anotada en la §9 del handoff).
  final bool enBottomNav;

  const AppDestination({
    required this.label,
    required this.icon,
    this.enBottomNav = true,
  });
}

class AppShell extends StatelessWidget {
  /// Título del producto para el encabezado de sidebar y drawer.
  final String title;
  final List<AppDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  const AppShell({
    super.key,
    required this.title,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final esMovil = ancho <= AppConstants.breakpointMobile;
    final esEscritorio = ancho > AppConstants.breakpointTablet;

    // Contenido central: limitado a containerMax; en móvil los márgenes
    // laterales bajan a 16 (spacingMd), como manda DESIGN.md.
    final margen = esMovil ? AppConstants.spacingMd : AppConstants.spacingLg;
    final contenido = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppConstants.containerMax),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: margen),
          child: child,
        ),
      ),
    );

    if (esEscritorio) {
      return Scaffold(
        body: Row(
          children: [
            _buildSidebar(context),
            Expanded(child: contenido),
          ],
        ),
      );
    }

    // Rango intermedio y móvil: AppBar + bottom nav de 4 slots; el drawer con
    // la lista completa solo existe en el rango intermedio.
    final bottomDestinations =
        destinations.where((d) => d.enBottomNav).toList();
    final seleccionado = destinations[selectedIndex];
    final indiceBottom = bottomDestinations.indexOf(seleccionado);

    return Scaffold(
      appBar: AppBar(
        title: Text(seleccionado.label),
        actions: [
          for (final destino in destinations)
            if (!destino.enBottomNav)
              IconButton(
                icon: Icon(destino.icon),
                tooltip: destino.label,
                color: destino == seleccionado ? AppColors.primary : null,
                onPressed: () =>
                    onDestinationSelected(destinations.indexOf(destino)),
              ),
        ],
      ),
      drawer: esMovil ? null : _buildDrawer(context),
      body: contenido,
      // El destino fuera de los 4 slots (Perfil) se muestra sin bottom nav,
      // como una vista plena; se vuelve por el AppBar o el drawer.
      bottomNavigationBar: indiceBottom < 0
          ? null
          : NavigationBar(
              selectedIndex: indiceBottom,
              destinations: [
                for (final destino in bottomDestinations)
                  NavigationDestination(
                    icon: Icon(destino.icon),
                    label: destino.label,
                  ),
              ],
              onDestinationSelected: (i) => onDestinationSelected(
                destinations.indexOf(bottomDestinations[i]),
              ),
            ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    // Material propio: los ListTile pintan su fondo e ink en el Material más
    // cercano, así que el color no puede vivir en un Container intermedio.
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
              for (final (i, destino) in destinations.indexed)
                NavItem(
                  label: destino.label,
                  icon: destino.icon,
                  selected: i == selectedIndex,
                  onTap: () => onDestinationSelected(i),
                ),
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
            for (final (i, destino) in destinations.indexed)
              NavItem(
                label: destino.label,
                icon: destino.icon,
                selected: i == selectedIndex,
                onTap: () {
                  Navigator.pop(context);
                  onDestinationSelected(i);
                },
              ),
          ],
        ),
      ),
    );
  }
}
