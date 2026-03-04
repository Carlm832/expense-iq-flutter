import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_state.dart';
import 'theme.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/main_scaffold.dart';
import 'screens/add_expense_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/appearance_screen.dart';
import 'screens/budget_screen.dart';
import 'screens/help_screen.dart';
import 'screens/privacy_screen.dart';
import 'screens/payment_methods_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const ExpenseIQApp(),
    ),
  );
}

class ExpenseIQApp extends StatelessWidget {
  const ExpenseIQApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return MaterialApp(
      title: 'ExpenseIQ',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const AppRouter(),
    );
  }
}

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final screen = state.currentScreen;

    if (screen == 'splash') return const SplashScreen();

    if (!state.isLoggedIn) {
      if (screen == 'register') return const RegisterScreen();
      return const LoginScreen();
    }

    // Main screens with bottom nav
    const mainScreens = ['dashboard', 'scan', 'ocr', 'history', 'analytics', 'profile'];

    Widget child;
    switch (screen) {
      case 'addExpense':
        child = const AddExpenseScreen();
      case 'notifications':
        child = const NotificationsScreen();
      case 'settings':
        child = const SettingsScreen();
      case 'appearance':
        child = const AppearanceScreen();
      case 'budget':
        child = const BudgetScreen();
      case 'help':
        child = const HelpScreen();
      case 'privacy':
        child = const PrivacyScreen();
      case 'payment-methods':
        child = const PaymentMethodsScreen();
      case 'editProfile':
        child = const EditProfileScreen();
      default:
        child = MainScaffold(currentScreen: screen);
    }

    return child;
  }
}
