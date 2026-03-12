import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app_state.dart';
import 'theme.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/pin_screen.dart';
import 'screens/main_scaffold.dart';
import 'screens/add_expense_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/appearance_screen.dart';
import 'screens/budget_screen.dart';
import 'screens/help_screen.dart';
import 'screens/contact_us_screen.dart';
import 'screens/privacy_screen.dart';
import 'screens/payment_methods_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/pin_setup_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting();

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

    // Show the animated splash screen while Firebase auth is resolving
    if (state.isInitializing) return const SplashScreen();

    // If user has a PIN set and the app just launched, show PIN entry
    if (state.isLoggedIn && state.isPinLocked) return const PinEntryScreen();

    if (!state.isLoggedIn) {
      if (screen == 'register') return const RegisterScreen();
      if (screen == 'forgot_password') return const ForgotPasswordScreen();
      return const LoginScreen();
    }

    if (screen == 'email_verification') return const EmailVerificationScreen();

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
      case 'contact_us':
        child = const ContactUsScreen();
      case 'privacy':
        child = const PrivacyScreen();
      case 'payment-methods':
        child = const PaymentMethodsScreen();
      case 'editProfile':
        child = const EditProfileScreen();
      case 'setup_pin':
        child = const PinSetupScreen();
      default:
        child = MainScaffold(currentScreen: screen);
    }

    return child;
  }
}
