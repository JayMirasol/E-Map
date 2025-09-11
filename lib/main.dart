import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/routes.dart';
import 'core/theme.dart';
import 'providers/campus_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => CampusProvider())],
      child: const EMAPApp(),
    ),
  );
}

class EMAPApp extends StatelessWidget {
  const EMAPApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EMAP',
      debugShowCheckedModeBanner: false,
      theme: emapTheme(),
      routes: AppRoutes.build(),
      initialRoute: AppRoutes.landing, // 👈 start at the new homepage
    );
  }
}
