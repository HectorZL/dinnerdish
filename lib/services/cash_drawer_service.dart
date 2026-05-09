import 'package:dinnerhome/models/cash_drawer_session.dart';

abstract class CashDrawerService {
  Future<CashDrawerSession> openDrawer({required String cashierId});

  Future<CashDrawerSession> closeDrawer({
    required String sessionId,
    required int actualBalanceCents,
  });

  Future<CashDrawerSession?> getCurrentSession();

  Future<CashDrawerSession> reconcile({
    required String sessionId,
    required int actualBalanceCents,
  });

  Future<List<CashDrawerSession>> getSessionHistory({int limit = 10});
}
