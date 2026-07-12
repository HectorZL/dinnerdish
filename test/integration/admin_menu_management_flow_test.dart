import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'integration_test_helpers.dart';

void main() {
  late TestServices services;

  setUp(() {
    services = TestServices();
  });

  tearDown(() {
    services.socket.dispose();
  });

  group('Admin Menu Management Flow', () {
    testWidgets('displays menu items grid', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(services.buildApp());
      await tester.pump();
      await loginViaProvider(tester, adminUser);

      // Admin sees Menú nav link
      expect(find.text('Menú'), findsOneWidget);

      // Navigate to menu management
      await tester.tap(find.text('Menú').first);
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // All 5 menu items should be visible
      expect(find.text('Pasta Carbonara'), findsOneWidget);
      expect(find.text('Ensalada César'), findsOneWidget);
      expect(find.text('Lomo Saltado'), findsOneWidget);
      expect(find.text('Ceviche Mixto'), findsOneWidget);
      expect(find.text('Sopa del Día'), findsOneWidget);
    });

    testWidgets('creates a new menu item', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(services.buildApp());
      await tester.pump();
      await loginViaProvider(tester, adminUser);

      await tester.tap(find.text('Menú').first);
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // Tap "Nuevo Item" button
      await tester.tap(find.text('Nuevo Item').first);
      await tester.pumpAndSettle();

      // Dialog appears
      expect(find.text('Nuevo Plato'), findsOneWidget);

      // Enter name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre del plato'),
        'Nuevo Plato Test',
      );
      await tester.pump();

      // Enter price
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Precio (€)'),
        '12.50',
      );
      await tester.pump();

      // Save
      await tester.tap(find.text('Crear'));
      await tester.pumpAndSettle();

      // New item appears in the grid
      expect(find.text('Nuevo Plato Test'), findsOneWidget);
    });

    testWidgets('allows category filtering', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(services.buildApp());
      await tester.pump();
      await loginViaProvider(tester, adminUser);

      await tester.tap(find.text('Menú').first);
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // All visible initially
      expect(find.text('Pasta Carbonara'), findsOneWidget);

      // Tap "Entrantes" category
      await tester.tap(find.byKey(const Key('category_chip_Entrantes')));
      await tester.pumpAndSettle();

      // Only Entrantes items visible
      expect(find.text('Sopa del Día'), findsOneWidget);
      expect(find.text('Ensalada César'), findsOneWidget);
      expect(find.text('Pasta Carbonara'), findsNothing);
      expect(find.text('Lomo Saltado'), findsNothing);
    });

    testWidgets('deletes a menu item', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(services.buildApp());
      await tester.pump();
      await loginViaProvider(tester, adminUser);

      await tester.tap(find.text('Menú').first);
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // Verify item exists
      expect(find.text('Sopa del Día'), findsOneWidget);

      // Tap the delete button for Sopa del Día (last item card)
      await tester.tap(find.byIcon(Icons.delete_outline).last);
      await tester.pumpAndSettle();

      // Confirmation dialog
      expect(find.text('Eliminar Plato'), findsOneWidget);

      // Confirm delete
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      // Item removed from grid
      expect(find.text('Sopa del Día'), findsNothing);

      // Verify via service
      final menu = await services.menu.fetchMenu();
      expect(menu.where((m) => m.name == 'Sopa del Día'), isEmpty);
    });

    testWidgets('cancels delete when user cancels', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(services.buildApp());
      await tester.pump();
      await loginViaProvider(tester, adminUser);

      await tester.tap(find.text('Menú').first);
      await tester.pump();
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();

      // Cancel
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      // Item still exists
      expect(find.text('Pasta Carbonara'), findsOneWidget);
    });

    testWidgets('admin sees all dashboard cards', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(services.buildApp());
      await tester.pump();
      await loginViaProvider(tester, adminUser);

      expect(find.text('Administración'), findsNWidgets(3));
      expect(find.text('Gestión de Pedidos'), findsOneWidget);
      expect(find.text('Pantalla KDS - Cocina'), findsOneWidget);
      expect(find.text('Caja y Cobros'), findsOneWidget);
      expect(find.text('Menú'), findsOneWidget);
    });
  });
}
