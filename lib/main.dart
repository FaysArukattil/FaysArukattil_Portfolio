import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_portfolio/config/app_config.dart';
import 'package:my_portfolio/homescreen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize config (never fails)
  await AppConfig.initialize();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fays Arukattil',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      ),
      home: const HomeScreen(),
    );
  }
}
