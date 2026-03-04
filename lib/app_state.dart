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
  List<Budget> _budgets = List.from(kDefaultBudgets);

  // Theme
  bool _isDarkMode = false;

  // Expense detail
  Expense? _selectedExpense;
  bool _showExpenseDetail = false;

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get profileImage => _profileImage;
  String get currentScreen => _screenHistory.last;
  List<Expense> get expenses => _expenses;
  List<AppNotification> get notifications => _notifications;
  List<Budget> get budgets => _budgets;
  bool get isDarkMode => _isDarkMode;
  Expense? get selectedExpense => _selectedExpense;
  bool get showExpenseDetail => _showExpenseDetail;
  int get unreadCount => _notifications.where((n) => !n.read).length;

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

    final expensesJson = prefs.getString('expenses');
    if (expensesJson != null) {
      final List<dynamic> decoded = jsonDecode(expensesJson);
      _expenses = decoded.map((e) => Expense.fromJson(e)).toList();
    }

    final budgetsJson = prefs.getString('budgets');
    if (budgetsJson != null) {
      final List<dynamic> decoded = jsonDecode(budgetsJson);
      _budgets = decoded.map((b) => Budget.fromJson(b)).toList();
    }

    notifyListeners();
  }

  Future<void> _saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('expenses', jsonEncode(_expenses.map((e) => e.toJson()).toList()));
  }

  Future<void> _saveBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('budgets', jsonEncode(_budgets.map((b) => b.toJson()).toList()));
  }

  void setCurrentScreen(String screen) {
    _screenHistory = [..._screenHistory, screen];
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
    SharedPreferences.getInstance().then((p) => p.setString('userEmail', email));
  }

  void setProfileImage(String img) {
    _profileImage = img;
    notifyListeners();
    SharedPreferences.getInstance().then((p) => p.setString('profileImage', img));
  }

  void addExpense(Expense expense) {
    _expenses = [expense, ..._expenses];
    _saveExpenses();
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
    notifyListeners();
  }

  void markNotificationRead(String id) {
    for (var n in _notifications) {
      if (n.id == id) n.read = true;
    }
    notifyListeners();
  }

  void setBudget(String category, double limit) {
    final idx = _budgets.indexWhere((b) => b.category == category);
    if (idx >= 0) {
      _budgets[idx].limit = limit;
    } else {
      _budgets = [..._budgets, Budget(category: category, limit: limit)];
    }
    _saveBudgets();
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
    _registeredUsers = [..._registeredUsers, {'name': name, 'email': email, 'password': password}];
  }

  bool validateLogin(String email, String password) {
    return _registeredUsers.any(
      (u) => u['email']!.toLowerCase() == email.toLowerCase() && u['password'] == password,
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
    return _registeredUsers.any((u) => u['email']!.toLowerCase() == email.toLowerCase());
  }
}
