import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class AppState extends ChangeNotifier {
  // Auth
  bool _isLoggedIn = false;
  String _userName = '';
  String _userEmail = '';
  String _profileImage = '';

  // Navigation stack
  List<String> _screenHistory = ['splash'];

  // Expenses
  List<Expense> _expenses = List.from(kRecentExpenses);

  // Notifications
  List<AppNotification> _notifications = List.from(kDefaultNotifications);

  // Budgets
  double _overallBudget = 0.0;
  bool _hasSeenBudgetWarningThisMonth = false;
  String _selectedMonth =
      DateTime.now().toString().substring(0, 7); // YYYY-MM format

  // Theme
  bool _isDarkMode = false;

  // Expense detail
  Expense? _selectedExpense;
  bool _showExpenseDetail = false;

  // Screen navigation args
  Map<String, dynamic>? _screenArgs;

  // New Settings Fields
  String _language = 'English';
  String _currency = 'TRY (₺)';
  bool _pushNotificationsEnabled = true;

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get profileImage => _profileImage;
  String get currentScreen => _screenHistory.last;
  Map<String, dynamic>? get screenArgs => _screenArgs;
  List<Expense> get expenses => _expenses;
  List<AppNotification> get notifications => _notifications;
  double get overallBudget => _overallBudget;
  String get selectedMonth => _selectedMonth;
  bool get hasSeenBudgetWarningThisMonth => _hasSeenBudgetWarningThisMonth;
  bool get isDarkMode => _isDarkMode;
  Expense? get selectedExpense => _selectedExpense;
  bool get showExpenseDetail => _showExpenseDetail;
  int get unreadCount => _notifications.where((n) => !n.read).length;

  String get language => _language;
  String get currency => _currency;
  bool get pushNotificationsEnabled => _pushNotificationsEnabled;

  // Extract the symbol from "TRY (₺)" -> "₺"
  String get currencySymbol {
    final match = RegExp(r'\((.*?)\)').firstMatch(_currency);
    return match != null ? match.group(1) ?? '₺' : '₺';
  }

  // Currency formatter
  String formatCurrency(double amount) {
    return '$currencySymbol${amount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  AppState() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    _userName = prefs.getString('userName') ?? '';
    _userEmail = prefs.getString('userEmail') ?? '';
    _profileImage = prefs.getString('profileImage') ?? '';
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;

    // Load Settings
    _language = prefs.getString('language') ?? 'English';
    _currency = prefs.getString('currency') ?? 'TRY (₺)';
    _pushNotificationsEnabled = prefs.getBool('pushNotificationsEnabled') ?? true;

    final expensesJson = prefs.getString('expenses');
    if (expensesJson != null) {
      final List<dynamic> decoded = jsonDecode(expensesJson);
      _expenses = decoded.map((e) => Expense.fromJson(e)).toList();
    }

    final notificationsJson = prefs.getString('notifications');
    if (notificationsJson != null) {
      final List<dynamic> decoded = jsonDecode(notificationsJson);
      _notifications = decoded.map((e) => AppNotification.fromJson(e)).toList();
    }

    _overallBudget = prefs.getDouble('overallBudget') ?? 0.0;
    _hasSeenBudgetWarningThisMonth =
        prefs.getBool('budgetWarning_${DateTime.now().month}') ?? false;

    notifyListeners();
  }

  Future<void> _saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(
        'expenses', jsonEncode(_expenses.map((e) => e.toJson()).toList()));
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(
        'notifications', jsonEncode(_notifications.map((e) => e.toJson()).toList()));
  }

  Future<void> _saveBudget() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('overallBudget', _overallBudget);
  }

  Future<void> _markWarningSeen() async {
    _hasSeenBudgetWarningThisMonth = true;
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('budgetWarning_${DateTime.now().month}', true);
    notifyListeners();
  }

  void setCurrentScreen(String screen, {Map<String, dynamic>? args}) {
    _screenHistory = [..._screenHistory, screen];
    _screenArgs = args;
    notifyListeners();
  }

  void goBack() {
    if (_screenHistory.length > 1) {
      _screenHistory = _screenHistory.sublist(0, _screenHistory.length - 1);
      notifyListeners();
    }
  }

  void login(String name, String email) {
    _userName = name;
    _userEmail = email;
    _isLoggedIn = true;
    _screenHistory = ['dashboard'];
    _saveUserData();
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _screenHistory = ['login'];
    SharedPreferences.getInstance().then((p) => p.setBool('isLoggedIn', false));
    notifyListeners();
  }

  void register(String name, String email) {
    login(name, email);
  }

  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isLoggedIn', _isLoggedIn);
    prefs.setString('userName', _userName);
    prefs.setString('userEmail', _userEmail);
  }

  void setUserName(String name) {
    _userName = name;
    notifyListeners();
    SharedPreferences.getInstance().then((p) => p.setString('userName', name));
  }

  void setUserEmail(String email) {
    _userEmail = email;
    notifyListeners();
    SharedPreferences.getInstance()
        .then((p) => p.setString('userEmail', email));
  }

  void setProfileImage(String img) {
    _profileImage = img;
    notifyListeners();
    SharedPreferences.getInstance()
        .then((p) => p.setString('profileImage', img));
  }

  void addExpense(Expense expense) {
    _expenses = [expense, ..._expenses];
    _saveExpenses();
    _checkBudgetWarning();
    notifyListeners();
  }

  void editExpense(String id, Expense updated) {
    _expenses = _expenses.map((e) => e.id == id ? updated : e).toList();
    _saveExpenses();
    notifyListeners();
  }

  void deleteExpense(String id) {
    _expenses = _expenses.where((e) => e.id != id).toList();
    _saveExpenses();
    _checkBudgetWarning();
    notifyListeners();
  }

  void markNotificationRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx].read = true;
      _saveNotifications();
      notifyListeners();
    }
  }

  void markAllNotificationsRead() {
    for (var n in _notifications) {
      n.read = true;
    }
    _saveNotifications();
    notifyListeners();
  }

  void setOverallBudget(double limit) {
    _overallBudget = limit;
    _saveBudget();
    _checkBudgetWarning();
    notifyListeners();
  }

  void setSelectedMonth(String yearMonth) {
    _selectedMonth = yearMonth;
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    SharedPreferences.getInstance().then((p) => p.setBool('isDarkMode', _isDarkMode));
    notifyListeners();
  }

  void setSelectedExpense(Expense? expense) {
    _selectedExpense = expense;
    notifyListeners();
  }

  void setShowExpenseDetail(bool show) {
    _showExpenseDetail = show;
    notifyListeners();
  }

  // Stored user accounts for login validation
  List<Map<String, String>> _registeredUsers = [];

  void addRegisteredUser(String name, String email, String password) {
    _registeredUsers = [
      ..._registeredUsers,
      {'name': name, 'email': email, 'password': password}
    ];
  }

  bool validateLogin(String email, String password) {
    return _registeredUsers.any(
      (u) =>
          u['email']!.toLowerCase() == email.toLowerCase() &&
          u['password'] == password,
    );
  }

  String? getNameForEmail(String email) {
    final user = _registeredUsers.firstWhere(
      (u) => u['email']!.toLowerCase() == email.toLowerCase(),
      orElse: () => {},
    );
    return user.isEmpty ? null : user['name'];
  }

  bool isEmailRegistered(String email) {
    return _registeredUsers
        .any((u) => u['email']!.toLowerCase() == email.toLowerCase());
  }

  // New Settings Setters
  Future<void> setLanguage(String lang) async {
    _language = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    notifyListeners();
  }

  Future<void> setCurrency(String curr) async {
    _currency = curr;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', curr);
    notifyListeners();
  }

  Future<void> setPushNotificationsEnabled(bool enabled) async {
    _pushNotificationsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pushNotificationsEnabled', enabled);
    notifyListeners();
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    _expenses = [];
    _notifications = [];
    _overallBudget = 0.0;
    
    _isLoggedIn = false;
    _userName = '';
    _userEmail = '';
    _profileImage = '';
    
    _language = 'English';
    _currency = 'TRY (₺)';
    _pushNotificationsEnabled = true;
    _isDarkMode = false;
    
    _screenHistory = ['splash'];
    notifyListeners();
  }

  void _checkBudgetWarning() {
    if (_overallBudget <= 0 || _hasSeenBudgetWarningThisMonth) return;

    final currentMonthExpenses = _expenses.where(
        (e) => e.date.startsWith(DateTime.now().toString().substring(0, 7)));

    final spentThisMonth =
        currentMonthExpenses.fold(0.0, (s, e) => s + e.amount);

    if (spentThisMonth >= _overallBudget * 0.9) {
      _markWarningSeen();
      _notifications.insert(
          0,
          AppNotification(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: 'Budget Warning',
            message:
                'You have spent ${((spentThisMonth / _overallBudget) * 100).toStringAsFixed(0)}% of your monthly budget.',
            time: 'Just now',
            read: false,
            type: 'warning',
          ));
      _saveNotifications();
      notifyListeners();
    }
  }
}
