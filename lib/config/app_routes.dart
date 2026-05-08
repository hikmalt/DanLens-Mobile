// lib/config/app_routes.dart
import 'package:flutter/material.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/main_screen.dart';
import '../screens/detail/detail_screen.dart';
import '../screens/map/map_screen.dart';
import '../screens/profile/team_profile_screen.dart';
import '../models/models.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String main = '/main';
  static const String detail = '/detail';
  static const String map = '/map';
  static const String team = '/team';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case main:
        return MaterialPageRoute(builder: (_) => const MainScreen());

      case detail:
        final tempat = settings.arguments as TempatModel;
        return MaterialPageRoute(
          builder: (_) => DetailScreen(tempat: tempat),
        );

      case map:
        final tempat = settings.arguments as TempatModel?;
        return MaterialPageRoute(
          builder: (_) => MapScreen(focusedTempat: tempat),
        );

      case team:
        return MaterialPageRoute(
          builder: (_) => const TeamProfileScreen(),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('404 - Halaman tidak ditemukan: ${settings.name}',
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 16)),
            ),
          ),
        );
    }
  }
}