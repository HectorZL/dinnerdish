import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dinnerhome/models/menu_item.dart';
import 'package:dinnerhome/models/modifier.dart';
import 'package:dinnerhome/presentation/screens/menu_management_screen.dart';
import 'package:dinnerhome/providers/providers.dart';
import 'package:dinnerhome/services/menu_service.dart';

// ── Mock Service ──────────────────────────────────────────────

class MockMenuService implements MenuService {
  final List<MenuItem> _items;
  final bool shouldThrow;
  final bool failThenSucceed;
  final List<String>? _customCategories;
  int callCount = 0;

  MockMenuService({
    List<MenuItem>? items,
    this.shouldThrow = false,
    this.failThenSucceed = false,
    List<String>? categories,
  })  : _items = items ?? [],
        _customCategories = categories;

  @override
  Future<List<MenuItem>> fetchMenu() async {
    callCount++;
    if (shouldThrow) {
      throw Exception('Simulated menu error');
    }
    if (failThenSucceed && callCount == 1) {
      throw Exception('Simulated menu error');
    }
    return _items;
  }

  @override
  Future<MenuItem?> getMenuItem(String id) async {
    try {
      return _items.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<MenuItem> createMenuItem(MenuItem item) async => item;

  @override
  Future<MenuItem> updateMenuItem(String id, MenuItem item) async => item;

  @override
  Future<void> deleteMenuItem(String id) async {}

  @override
  Future<List<String>> getCategories() async {
    if (_customCategories case final cats?) return cats;
    final categories = _items.map((i) => i.category).toSet().toList();
    categories.sort();
    return categories;
  }
}

// ── Helpers ────────────────────────────────────────────────────

MenuItem makeMenuItem({
  required String id,
  required String name,
  required String category,
  int priceCents = 1000,
  bool available = true,
  List<Modifier> modifiers = const [],
}) {
  return MenuItem(
    id: id,
    name: name,
    priceCents: priceCents,
    modifiers: modifiers,
    available: available,
    category: category,
  );
}

Widget buildMenuApp(MockMenuService menuService) {
  GoogleFonts.config.allowRuntimeFetching = false;
  return ProviderScope(
    overrides: [
      menuServiceProvider.overrideWith((ref) => menuService),
    ],
    child: const MaterialApp(home: MenuManagementScreen()),
  );
}

// ── Tests ──────────────────────────────────────────────────────

void main() {
  late MockMenuService menuService;

  group('MenuManagementScreen', () {
    testWidgets('shows loading state initially', (tester) async {
      menuService = MockMenuService();

      await tester.pumpWidget(buildMenuApp(menuService));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no items', (tester) async {
      menuService = MockMenuService(items: []);

      await tester.pumpWidget(buildMenuApp(menuService));
      await tester.pumpAndSettle();

      expect(find.text('No hay platos en el menú'), findsOneWidget);
      expect(find.text('Nuevo Item'), findsWidgets);
    });

    testWidgets('renders item grid with menu items', (tester) async {
      menuService = MockMenuService(
        items: [
          makeMenuItem(
              id: '1', name: 'Pizza', category: 'Platos Principales'),
          makeMenuItem(
              id: '2', name: 'Ensalada', category: 'Entrantes'),
        ],
      );

      await tester.pumpWidget(buildMenuApp(menuService));
      await tester.pumpAndSettle();

      // Both items should appear
      expect(find.text('Pizza'), findsOneWidget);
      expect(find.text('Ensalada'), findsOneWidget);
    });

    testWidgets('shows category tabs', (tester) async {
      menuService = MockMenuService(
        items: [
          makeMenuItem(
              id: '1', name: 'Pizza', category: 'Platos Principales'),
          makeMenuItem(
              id: '2', name: 'Ensalada', category: 'Entrantes'),
        ],
      );

      await tester.pumpWidget(buildMenuApp(menuService));
      await tester.pumpAndSettle();

      // "Todos" tab should be present
      expect(find.text('Todos'), findsOneWidget);
      // Category names appear as tabs and as badges on cards
      expect(find.text('Entrantes'), findsWidgets);
      expect(find.text('Platos Principales'), findsWidgets);
    });

    testWidgets('filters items by category when tab tapped', (tester) async {
      menuService = MockMenuService(
        items: [
          makeMenuItem(
              id: '1', name: 'Pizza', category: 'Platos Principales'),
          makeMenuItem(
              id: '2', name: 'Ensalada', category: 'Entrantes'),
        ],
      );

      await tester.pumpWidget(buildMenuApp(menuService));
      await tester.pumpAndSettle();

      // Both visible initially
      expect(find.text('Pizza'), findsOneWidget);
      expect(find.text('Ensalada'), findsOneWidget);

      // Tap "Entrantes" tab (first occurrence is the tab, second is the badge)
      await tester.tap(find.text('Entrantes').first);
      await tester.pumpAndSettle();

      // Only Ensalada should show
      expect(find.text('Ensalada'), findsOneWidget);
      expect(find.text('Pizza'), findsNothing);
    });

    testWidgets('shows error state and retry button', (tester) async {
      menuService = MockMenuService(shouldThrow: true);

      await tester.pumpWidget(buildMenuApp(menuService));
      await tester.pumpAndSettle();

      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.textContaining('Exception: Simulated menu error'),
          findsOneWidget);
    });

    testWidgets('retry button reloads after error', (tester) async {
      menuService = MockMenuService(
        failThenSucceed: true,
        items: [
          makeMenuItem(
              id: '1', name: 'Pizza', category: 'Platos Principales'),
        ],
      );

      await tester.pumpWidget(buildMenuApp(menuService));
      await tester.pumpAndSettle();

      // Error state with retry
      expect(find.text('Reintentar'), findsOneWidget);

      // Tap retry
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      // Now items should appear
      expect(find.text('Pizza'), findsOneWidget);
      expect(find.text('No hay platos en el menú'), findsNothing);
    });

    testWidgets('create dialog opens and closes', (tester) async {
      menuService = MockMenuService(
        items: [
          makeMenuItem(
              id: '1', name: 'Pizza', category: 'Platos Principales'),
        ],
      );

      await tester.pumpWidget(buildMenuApp(menuService));
      await tester.pumpAndSettle();

      // Tap "Nuevo Item" button (in AppBar)
      await tester.tap(find.text('Nuevo Item').first);
      await tester.pumpAndSettle();

      // Dialog should appear
      expect(find.text('Nuevo Plato'), findsOneWidget);
      expect(find.text('Nombre del plato'), findsOneWidget);

      // Cancel closes dialog
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Nuevo Plato'), findsNothing);
    });

    testWidgets('edit dialog opens and closes', (tester) async {
      menuService = MockMenuService(
        items: [
          makeMenuItem(
              id: '1', name: 'Pizza', category: 'Platos Principales'),
        ],
      );

      await tester.pumpWidget(buildMenuApp(menuService));
      await tester.pumpAndSettle();

      // Find the edit icon button
      expect(find.byIcon(Icons.edit), findsOneWidget);

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // Edit dialog should appear
      expect(find.text('Editar Plato'), findsOneWidget);

      // Cancel closes dialog
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Editar Plato'), findsNothing);
    });

    testWidgets('delete confirmation dialog', (tester) async {
      menuService = MockMenuService(
        items: [
          makeMenuItem(
              id: '1', name: 'Pizza', category: 'Platos Principales'),
        ],
      );

      await tester.pumpWidget(buildMenuApp(menuService));
      await tester.pumpAndSettle();

      // Find delete icon
      expect(find.byIcon(Icons.delete), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      // Confirmation dialog
      expect(find.text('Eliminar Plato'), findsOneWidget);
      // Pizza appears both in the card title and the dialog content
      expect(find.textContaining('Pizza'), findsWidgets);

      // Cancel closes dialog
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Eliminar Plato'), findsNothing);
    });

    testWidgets('availability toggle checkbox', (tester) async {
      menuService = MockMenuService(
        items: [
          makeMenuItem(
              id: '1', name: 'Pizza', category: 'Platos Principales'),
        ],
      );

      await tester.pumpWidget(buildMenuApp(menuService));
      await tester.pumpAndSettle();

      // Find the checkbox. It should be checked by default (available: true).
      expect(find.byType(Checkbox), findsOneWidget);

      // Toggle it
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // Checkbox should still be present
      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('category badge shown on item card', (tester) async {
      menuService = MockMenuService(
        items: [
          makeMenuItem(
              id: '1', name: 'Pizza', category: 'Platos Principales'),
        ],
      );

      await tester.pumpWidget(buildMenuApp(menuService));
      await tester.pumpAndSettle();

      // Category shown as badge at bottom of card
      expect(find.text('Platos Principales'), findsWidgets);
    });

    testWidgets('modifier count shown for items with modifiers', (tester) async {
      menuService = MockMenuService(
        items: [
          makeMenuItem(
            id: '1',
            name: 'Pizza',
            category: 'Platos Principales',
            modifiers: [
              Modifier(id: 'm1', name: 'Extra cheese', priceCents: 200),
            ],
          ),
        ],
      );

      await tester.pumpWidget(buildMenuApp(menuService));
      await tester.pumpAndSettle();

      expect(find.textContaining('modificador'), findsOneWidget);
    });

    testWidgets('no hay platos text when category has no items',
        (tester) async {
      // Provide explicit categories including one with no items
      menuService = MockMenuService(
        items: [
          makeMenuItem(
              id: '1', name: 'Pizza', category: 'Platos Principales'),
        ],
        categories: ['Entrantes', 'Platos Principales'],
      );

      await tester.pumpWidget(buildMenuApp(menuService));
      await tester.pumpAndSettle();

      // Tap "Entrantes" category which has no items
      await tester.tap(find.text('Entrantes'));
      await tester.pumpAndSettle();

      expect(find.text('No hay platos en esta categoría'), findsOneWidget);
    });
  });
}
