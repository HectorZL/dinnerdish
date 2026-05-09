import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dinnerhome/models/audit_entry.dart';
import 'package:dinnerhome/models/user.dart';
import 'package:dinnerhome/providers/providers.dart';
import 'package:dinnerhome/services/audit_service.dart';
import 'package:dinnerhome/services/in_memory/in_memory_auth_service.dart';
import 'package:dinnerhome/services/in_memory/in_memory_menu_service.dart';
import 'package:dinnerhome/services/in_memory/in_memory_order_service.dart';
import 'package:dinnerhome/services/in_memory/in_memory_payment_service.dart';
import 'package:dinnerhome/services/in_memory/in_memory_socket_service.dart';
import 'package:dinnerhome/router/app_router.dart';

// ──────────────────────────────────────────────────────────────
// InMemoryAuditService — avoids Hive dependency in tests
// ──────────────────────────────────────────────────────────────

class InMemoryAuditService implements AuditService {
  final List<AuditEntry> _entries = [];
  int _counter = 0;

  @override
  Future<void> record({
    required String action,
    required String userId,
    required Map<String, dynamic> metadata,
    DateTime? timestamp,
  }) async {
    _counter++;
    _entries.add(AuditEntry(
      id: 'audit-$_counter',
      action: action,
      userId: userId,
      timestamp: timestamp ?? DateTime.now(),
      metadata: metadata,
    ));
  }

  @override
  Future<List<AuditEntry>> list({int limit = 100, int offset = 0}) async {
    final sorted = List<AuditEntry>.from(_entries)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted.skip(offset).take(limit).toList();
  }

  List<AuditEntry> get allEntries => List.unmodifiable(_entries);
  void clear() => _entries.clear();
  List<AuditEntry> entriesByAction(String action) =>
      _entries.where((e) => e.action == action).toList();
}

// ──────────────────────────────────────────────────────────────
// Test user constants matching the app's test users
// ──────────────────────────────────────────────────────────────

const meseroUser = User(
  id: 'user-mesero-1',
  username: 'mesero',
  name: 'Juan Pérez',
  role: Role.mesero,
  token: 'mock-token-mesero',
);

const cajeroUser = User(
  id: 'user-cajero-1',
  username: 'cajero',
  name: 'María García',
  role: Role.cajero,
  token: 'mock-token-cajero',
);

const cocineroUser = User(
  id: 'user-cocinero-1',
  username: 'cocinero',
  name: 'Carlos López',
  role: Role.cocinero,
  token: 'mock-token-cocinero',
);

const adminUser = User(
  id: 'user-admin-1',
  username: 'admin',
  name: 'Ana Martínez',
  role: Role.admin,
  token: 'mock-token-admin',
);

// ──────────────────────────────────────────────────────────────
// Test service container
// ──────────────────────────────────────────────────────────────

class TestServices {
  final InMemoryAuditService audit;
  final InMemorySocketService socket;
  final InMemoryMenuService menu;
  final InMemoryAuthService auth;
  final InMemoryOrderService order;
  final InMemoryPaymentService payment;

  TestServices({
    InMemoryAuditService? audit,
    InMemorySocketService? socket,
    InMemoryMenuService? menu,
    InMemoryAuthService? auth,
    InMemoryOrderService? order,
    InMemoryPaymentService? payment,
  })  : audit = audit ?? InMemoryAuditService(),
        socket = socket ?? InMemorySocketService(),
        menu = menu ?? InMemoryMenuService(),
        auth = auth ?? InMemoryAuthService(),
        order = order ??
            InMemoryOrderService(
                socket ?? InMemorySocketService(),
                auditService: audit ?? InMemoryAuditService()),
        payment = payment ??
            InMemoryPaymentService(auditService: audit ?? InMemoryAuditService());

  /// Builds a ProviderScope with all services overridden.
  ProviderScope buildApp() {
    GoogleFonts.config.allowRuntimeFetching = false;

    return ProviderScope(
      overrides: [
        authServiceProvider.overrideWith((ref) => auth),
        menuServiceProvider.overrideWith((ref) => menu),
        socketServiceProvider.overrideWith((ref) => socket),
        auditServiceProvider.overrideWith((ref) => audit),
        orderServiceProvider.overrideWith((ref) => order),
        paymentServiceProvider.overrideWith((ref) => payment),
      ],
      child: const IntegrationTestApp(),
    );
  }
}

class IntegrationTestApp extends ConsumerWidget {
  const IntegrationTestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: 'Dinnerhome Integration Test',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFEA2A33)),
        useMaterial3: true,
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Login helper — uses the ProviderContainer to login
// ──────────────────────────────────────────────────────────────

/// Logs into the app by updating the provider via the notifier.
/// Call this after [pumpWidget] when the app is already showing the login screen.
Future<void> loginViaProvider(WidgetTester tester, User user) async {
  final ctx = tester.element(find.byType(MaterialApp));
  final container = ProviderScope.containerOf(ctx, listen: false);
  await container.read(currentUserProvider.notifier).loginWithTestUser(user);
  await tester.pumpAndSettle();
}

// ──────────────────────────────────────────────────────────────
// Navigation helper — tap a dashboard card by title
// ──────────────────────────────────────────────────────────────

Future<void> tapDashboardCard(WidgetTester tester, String title) async {
  await tester.tap(find.text(title));
  await tester.pump();
}
