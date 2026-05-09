import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dinnerhome/models/menu_item.dart';
import 'package:dinnerhome/models/modifier.dart';
import 'package:dinnerhome/models/order_item.dart' as order_item;
import 'package:dinnerhome/models/order.dart';
import 'package:dinnerhome/models/table.dart';
import 'package:dinnerhome/models/user.dart';
import 'package:dinnerhome/models/payment_request.dart';
import 'package:dinnerhome/models/payment_method.dart';
import 'package:dinnerhome/models/payment_status.dart';
import 'package:dinnerhome/models/payment_transaction.dart';
import 'package:dinnerhome/models/cash_drawer_session.dart';
import 'package:dinnerhome/models/payment_summary.dart';
import 'package:dinnerhome/models/audit_entry.dart';
import 'package:dinnerhome/router/app_router.dart';

Future<void> main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  await initHive();
  runApp(const ProviderScope(child: MainApp()));
}

Future<void> initHive() async {
  await Hive.initFlutter();

  Hive.registerAdapter(MenuItemAdapter());
  Hive.registerAdapter(ModifierAdapter());
  Hive.registerAdapter(order_item.OrderItemAdapter());
  Hive.registerAdapter(order_item.OrderStatusAdapter());
  Hive.registerAdapter(OrderAdapter());
  Hive.registerAdapter(OrderStatusAdapter());
  Hive.registerAdapter(TableAdapter());
  Hive.registerAdapter(TableStatusAdapter());
  Hive.registerAdapter(UserAdapter());
  Hive.registerAdapter(RoleAdapter());
  Hive.registerAdapter(PaymentRequestAdapter());
  Hive.registerAdapter(PaymentMethodAdapter());
  Hive.registerAdapter(PaymentStatusAdapter());
  Hive.registerAdapter(PaymentTransactionAdapter());
  Hive.registerAdapter(CashDrawerStatusAdapter());
  Hive.registerAdapter(CashDrawerSessionAdapter());
  Hive.registerAdapter(PaymentSummaryAdapter());
  Hive.registerAdapter(AuditEntryAdapter());

  await Hive.openBox<AuditEntry>('audit');
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: 'Dinnerhome',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFEA2A33)),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
