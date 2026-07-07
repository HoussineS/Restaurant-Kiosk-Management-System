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
    (icon: Icons.category_outlined,     selectedIcon: Icons.category,      label: 'Categories'),
    (icon: Icons.fastfood_outlined,     selectedIcon: Icons.fastfood,      label: 'Products'),
  ];

  void _onDestinationSelected(int index) =>
      setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final body = IndexedStack(index: _selectedIndex, children: _screens);

    // Use LayoutBuilder so the nav style adapts the instant the window is
    // dragged — no hot-restart needed.
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // ── Mobile: bottom navigation bar ──────────────────────────────────
        if (width < AppBreakpoints.mobile) {
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

        // ── Tablet / narrow desktop: compact rail (icons + labels below) ───
        if (width < AppBreakpoints.wideDesktop) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  minWidth: 80,
                  labelType: NavigationRailLabelType.all,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Icon(
                      Icons.restaurant_menu,
                      size: 28,
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

        // ── Wide desktop: extended rail (icons + labels inline) ─────────────
        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: _selectedIndex,
                extended: true,
                minExtendedWidth: 200,
                leading: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        size: 28,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Kiosk Admin',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AdminPageLayout
// ─────────────────────────────────────────────────────────────────────────────

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < AppBreakpoints.mobile;
        final isTablet = width < AppBreakpoints.tablet;

        final double padding = isMobile ? 12.0 : isTablet ? 20.0 : 28.0;
        final double bannerHeight = isMobile ? 72.0 : isTablet ? 100.0 : 130.0;

        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: floatingActionButton,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Banner ───────────────────────────────────────────────
                  Container(
                    height: bannerHeight,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: const DecorationImage(
                        image: NetworkImage(
                          'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800&q=80',
                        ),
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
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 20 : isTablet ? 24 : 28,
                            ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ── Subtitle (hidden on mobile to save space) ────────────
                  if (!isMobile)
                    Text(
                      'Manage the restaurant menu used by the kiosk.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),

                  SizedBox(height: isMobile ? 8 : 16),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
