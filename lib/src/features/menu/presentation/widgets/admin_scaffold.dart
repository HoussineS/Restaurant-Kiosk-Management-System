import 'package:flutter/material.dart';

class AdminScaffold extends StatelessWidget {
  const AdminScaffold({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.title,
    required this.child,
    this.floatingActionButton,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final String title;
  final Widget child;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            minWidth: 88,
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Icon(
                Icons.restaurant_menu,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.category_outlined),
                selectedIcon: Icon(Icons.category),
                label: Text('Categories'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.fastfood_outlined),
                selectedIcon: Icon(Icons.fastfood),
                label: Text('Products'),
              ),
            ],
            onDestinationSelected: onDestinationSelected,
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage the restaurant menu used by the kiosk.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(child: child),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
