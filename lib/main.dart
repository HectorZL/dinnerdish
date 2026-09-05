import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dinnerhome/models/menu_item.dart';
import 'package:dinnerhome/models/menu_item_variation.dart';
import 'package:dinnerhome/models/modifier.dart';
import 'package:dinnerhome/models/order_item.dart' as order_item;
import 'package:dinnerhome/models/selected_additional.dart';
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
import 'package:dinnerhome/providers/providers.dart';
import 'package:dinnerhome/services/hive/hive_menu_service.dart';

Future<void> main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  await initHive();
  runApp(const ProviderScope(child: MainApp()));
}

Future<void> initHive() async {
  await Hive.initFlutter();

  Hive.registerAdapter(MenuItemAdapter());
  Hive.registerAdapter(MenuItemVariationAdapter());
  Hive.registerAdapter(ModifierAdapter());
  Hive.registerAdapter(order_item.OrderItemAdapter());
  Hive.registerAdapter(order_item.OrderStatusAdapter());
  Hive.registerAdapter(SelectedAdditionalAdapter());
  Hive.registerAdapter(AdditionalSourceAdapter());
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
  await Hive.openBox('settings');
  final menuBox = await Hive.openBox<MenuItem>(HiveMenuService.boxName);
  if (menuBox.isEmpty) {
    await menuBox.putAll({
      for (final item in HiveMenuService.defaultMenu()) item.id: item,
    });
  }
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isAdmin = currentUser != null && currentUser.role == Role.admin;

    return MaterialApp.router(
      title: 'Dinnerhome',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFEA2A33)),
        useMaterial3: true,
        snackBarTheme: SnackBarThemeData(
          behavior: isAdmin
              ? SnackBarBehavior.floating
              : SnackBarBehavior.fixed,
        ),
      ),
      routerConfig: router,
      builder: (context, child) {
        return SafeArea(
          top: false,
          left: false,
          right: false,
          bottom: true,
          child: child!,
        );
      },
    );
  }
}
