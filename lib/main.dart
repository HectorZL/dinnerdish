import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'login_screen.dart';

Future<void> main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dinnerhome',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFEA2A33)),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
