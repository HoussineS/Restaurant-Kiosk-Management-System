import 'package:flutter/material.dart';

import '../../../../core/utils/responsive_layout.dart';
import '../screens/categories_screen.dart';
import '../screens/products_screen.dart';
import '../../../orders/presentation/screens/orders_screen.dart';

class AdminScaffold extends StatefulWidget {
  const AdminScaffold({super.key});

  @override
  State<AdminScaffold> createState() => _AdminScaffoldState();
}

class _AdminScaffoldState extends State<AdminScaffold> {
  int _selectedIndex = 0;

  static const _screens = [
    OrdersScreen(),
    CategoriesScreen(),
    ProductsScreen(),
  ];

  static const _destinations = [
    (icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long, label: 'Orders'),
    (icon: Icons.category_outlined, selectedIcon: Icons.category, label: 'Categories'),
    (icon: Icons.fastfood_outlined, selectedIcon: Icons.fastfood, label: 'Products'),
  ];

  void _onDestinationSelected(int index) =>
      setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    final body = IndexedStack(index: _selectedIndex, children: _screens);

    if (isMobile) {
      return Scaffold(
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onDestinationSelected,
          destinations: [
            for (final d in _destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            minWidth: 88,
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Icon(
                Icons.restaurant_menu,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: Text(d.label),
                ),
            ],
            onDestinationSelected: _onDestinationSelected,
          ),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class AdminPageLayout extends StatelessWidget {
  const AdminPageLayout({
    super.key,
    required this.title,
    required this.child,
    this.floatingActionButton,
  });

  final String title;
  final Widget child;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final padding = isMobile ? 16.0 : 24.0;
    final bannerHeight = isMobile ? 80.0 : 120.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: bannerHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: const DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800&q=80'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (!isMobile)
                Text(
                  'Manage the restaurant menu used by the kiosk.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              SizedBox(height: isMobile ? 12 : 24),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
