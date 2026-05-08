import 'package:flutter/material.dart';
import 'config/app_theme.dart';
import 'screens/splash/splash_screen.dart';

// lib/app.dart
class DanLensApp extends StatelessWidget {
  const DanLensApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DanLens',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}
 