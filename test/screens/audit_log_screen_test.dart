import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dinnerhome/models/audit_entry.dart';
import 'package:dinnerhome/presentation/screens/audit_log_screen.dart';
import 'package:dinnerhome/providers/providers.dart';
import 'package:dinnerhome/services/audit_service.dart';

// ── Mock Services ──────────────────────────────────────────────

class MockAuditLogService implements AuditService {
  final List<AuditEntry> entries;
  final bool shouldThrow;
  int callCount = 0;

  /// When [failThenSucceed] is true, the first call throws and
  /// subsequent calls return [entries]. This is useful for testing
  /// the retry flow without rebuilding the widget.
  final bool failThenSucceed;

  MockAuditLogService({
    this.entries = const [],
    this.shouldThrow = false,
    this.failThenSucceed = false,
  });

  @override
  Future<List<AuditEntry>> list({int limit = 100, int offset = 0}) async {
    callCount++;
    if (shouldThrow) {
      throw Exception('Simulated audit error');
    }
    if (failThenSucceed && callCount == 1) {
      throw Exception('Simulated audit error');
    }
    return entries;
  }

  @override
  Future<void> record({
    required String action,
    required String userId,
    required Map<String, dynamic> metadata,
    DateTime? timestamp,
  }) async {
    // Not used in the screen; only list() is read
  }
}

// ── Helpers ────────────────────────────────────────────────────

AuditEntry makeEntry({
  required String id,
  required String action,
  required String userId,
}) {
  return AuditEntry(
    id: id,
    action: action,
    userId: userId,
    timestamp: DateTime(2026, 5, 8, 14, 30),
  );
}

Widget buildAuditApp(MockAuditLogService auditService) {
  return ProviderScope(
    overrides: [
      auditServiceProvider.overrideWith((ref) => auditService),
    ],
    child: const MaterialApp(home: AuditLogScreen()),
  );
}

// ── Tests ──────────────────────────────────────────────────────

void main() {
  late MockAuditLogService auditService;

  group('AuditLogScreen', () {
    testWidgets('shows loading state initially', (tester) async {
      auditService = MockAuditLogService();

      await tester.pumpWidget(buildAuditApp(auditService));

      // _isLoading starts as true
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no entries returned', (tester) async {
      auditService = MockAuditLogService(entries: []);

      await tester.pumpWidget(buildAuditApp(auditService));
      await tester.pump();
      await tester.pump();

      expect(find.text('No hay registros de auditoría'), findsOneWidget);
    });

    testWidgets('renders list of audit entries', (tester) async {
      auditService = MockAuditLogService(
        entries: [
          makeEntry(id: '1', action: 'send_to_kitchen', userId: 'user-1'),
          makeEntry(id: '2', action: 'request_payment', userId: 'user-2'),
        ],
      );

      await tester.pumpWidget(buildAuditApp(auditService));
      await tester.pump();
      await tester.pump();

      // Actions transformed to upper case and underscores replaced
      expect(find.text('SEND TO KITCHEN'), findsOneWidget);
      expect(find.text('REQUEST PAYMENT'), findsOneWidget);

      // User IDs displayed in subtitle
      expect(find.textContaining('user-1'), findsOneWidget);
      expect(find.textContaining('user-2'), findsOneWidget);
    });

    testWidgets('shows error state when service throws', (tester) async {
      auditService = MockAuditLogService(shouldThrow: true);

      await tester.pumpWidget(buildAuditApp(auditService));
      await tester.pump();
      await tester.pump();

      // Error message is displayed
      expect(find.text('Error: Exception: Simulated audit error'),
          findsOneWidget);

      // Retry button is present
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('retry button triggers reload after error', (tester) async {
      auditService = MockAuditLogService(
        failThenSucceed: true,
        entries: [
          makeEntry(id: '3', action: 'add_item', userId: 'user-3'),
        ],
      );

      await tester.pumpWidget(buildAuditApp(auditService));
      await tester.pump();
      await tester.pump();

      // First call throws → error state with retry button
      expect(find.text('Reintentar'), findsOneWidget);

      // Tap retry → triggers _loadEntries again (second call succeeds)
      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      await tester.pump();

      // Now the entry should appear
      expect(find.text('ADD ITEM'), findsOneWidget);
      expect(find.text('No hay registros de auditoría'), findsNothing);
    });

    testWidgets('shows icons for different action types', (tester) async {
      auditService = MockAuditLogService(
        entries: [
          makeEntry(id: '1', action: 'send_to_kitchen', userId: 'u1'),
          makeEntry(id: '2', action: 'request_payment', userId: 'u2'),
          makeEntry(id: '3', action: 'add_item', userId: 'u3'),
          makeEntry(id: '4', action: 'remove_item', userId: 'u4'),
          makeEntry(id: '5', action: 'create_order', userId: 'u5'),
          makeEntry(id: '6', action: 'unknown_action', userId: 'u6'),
        ],
      );

      await tester.pumpWidget(buildAuditApp(auditService));
      await tester.pump();
      await tester.pump();

      // All actions should be rendered
      expect(find.text('SEND TO KITCHEN'), findsOneWidget);
      expect(find.text('REQUEST PAYMENT'), findsOneWidget);
      expect(find.text('ADD ITEM'), findsOneWidget);
      expect(find.text('REMOVE ITEM'), findsOneWidget);
      expect(find.text('CREATE ORDER'), findsOneWidget);
      expect(find.text('UNKNOWN ACTION'), findsOneWidget);

      // Icons for specific actions
      expect(find.byIcon(Icons.kitchen), findsOneWidget);
      expect(find.byIcon(Icons.payments), findsOneWidget);
      expect(find.byIcon(Icons.add_circle), findsOneWidget);
      expect(find.byIcon(Icons.remove_circle), findsOneWidget);
    });
  });
}
