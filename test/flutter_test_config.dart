import 'dart:async';
import 'package:dinnerhome/services/api/api_config.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  ApiConfig.isTestEnvironment = true;
  await testMain();
}
