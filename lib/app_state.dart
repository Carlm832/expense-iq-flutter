import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart';
import 'services/currency_service.dart';
import 'services/bio_service.dart';

class AppState extends ChangeNotifier with WidgetsBindingObserver {
  // Auth
  bool _isLoggedIn = false;
  String _userName = '';
  String _userEmail = '';
  String _profileImage = '';

  // Navigation stack
  List<String> _screenHistory = ['login'];

  // Expenses
  List<Expense> _expenses = List.from(kDefaultExpenses);

  // Notifications
  List<AppNotification> _notifications = List.from(kDefaultNotifications);

  // Budgets
  List<Budget> _budgets = List.from(kDefaultBudgets);

  // Theme
  bool _isDarkMode = false;

  // Expense detail
  Expense? _selectedExpense;
  bool _showExpenseDetail = false;

  // Settings & Localization
  String _language = 'English';
  String _currency = 'TRY (₺)';
  bool _pushNotificationsEnabled = true;

  // OCR args
  Map<String, dynamic>? _screenArgs;

  // Overall Budget
  double _overallBudget = 2500.0;
  List<int> _budgetWarningIntervals = [50, 75, 90, 100];
  int _lastWarningThreshold = 0;
  bool _hasSeenBudgetWarningThisMonth = false;

  // Syncing logic for Dashboard month selection (added by collaborator)
  String _selectedMonth = DateTime.now().toString().substring(0, 7);

  // PIN & Biometric Security
  String _pin = '';      // empty = no PIN set
  bool _isPinLocked = false; // true after app resumes if PIN is set
  bool _isBiometricEnabled = false;
  DateTime? _lastPausedTime;

  // Services
  final CurrencyService _currencyService = CurrencyService();
  final BioService _bioService = BioService();

  // Initializing flag — true until Firebase auth state has resolved
  bool _isInitializing = true;

  // Firestore DB
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
  bool get hasSeenBudgetWarningThisMonth => _hasSeenBudgetWarningThisMonth;
  List<int> get budgetWarningIntervals => _budgetWarningIntervals;
  int get lastWarningThreshold => _lastWarningThreshold;
  String get selectedMonth => _selectedMonth;

  String get language => _language;
  String get currency => _currency;
  bool get pushNotificationsEnabled => _pushNotificationsEnabled;
  Map<String, dynamic>? get screenArgs => _screenArgs;
  double get overallBudget => _overallBudget;
  String get currencySymbol =>
      _currency.contains('(') ? _currency.split('(')[1].split(')')[0] : '₺';
  bool get isInitializing => _isInitializing;
  bool get isPinLocked => _isPinLocked;
  bool get hasPin => _pin.isNotEmpty;
  String get pin => _pin;
  bool get isBiometricEnabled => _isBiometricEnabled;
  CurrencyService get currencyService => _currencyService;

  AppState() {
    WidgetsBinding.instance.addObserver(this);
    _initApp();
  }

  Future<void> _initApp() async {
    await _loadFromPrefs();
    _initAuthListener();
    await _currencyService.init();
    // Ensure splash screen is visible for at least 3 seconds
    await Future.delayed(const Duration(seconds: 3));
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _lastPausedTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_lastPausedTime != null) {
        final now = DateTime.now();
        final diff = now.difference(_lastPausedTime!);
        if (diff.inSeconds >= 90) {
          if (_isLoggedIn && (_pin.isNotEmpty || _isBiometricEnabled) && !_isPinLocked) {
            _isPinLocked = true;
            notifyListeners();
          }
        }
        _lastPausedTime = null;
      }
    }
  }

  void _initAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _isLoggedIn = true;
        _userName = user.displayName ?? '';
        _userEmail = user.email ?? '';
        _profileImage = user.photoURL ?? '';

        _syncDataFromFirestore(user.uid);

        // Handle Email Verification for password provider
        bool isPasswordProvider = user.providerData.any((p) => p.providerId == 'password');
        if (isPasswordProvider && !user.emailVerified) {
          if (_screenHistory.last != 'email_verification') {
            _screenHistory = ['email_verification'];
          }
        } else {
          // If PIN is set, lock the app for PIN entry on every fresh start
          if (_isInitializing && _pin.isNotEmpty) {
            _isPinLocked = true;
          } else if (_screenHistory.last == 'login' ||
              _screenHistory.last == 'register' ||
              _screenHistory.last == 'email_verification') {
            _screenHistory = ['dashboard'];
          }
        }
      } else {
        _isLoggedIn = false;
        _userName = '';
        _userEmail = '';
        _profileImage = '';
        _expenses = [];
        _budgets = [];
        if (_screenHistory.last != 'login' &&
            _screenHistory.last != 'register') {
          _screenHistory = ['login'];
        }
      }
      _isInitializing = false;
      notifyListeners();
    });
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _language = prefs.getString('language') ?? 'English';
    _currency = prefs.getString('currency') ?? 'TRY (₺)';
    _pushNotificationsEnabled =
        prefs.getBool('pushNotificationsEnabled') ?? true;
    _overallBudget = prefs.getDouble('overallBudget') ?? 2500.0;
    
    final String currentMonth = DateTime.now().toIso8601String().substring(0, 7);
    final String lastMonthOpened = prefs.getString('lastMonthOpened') ?? currentMonth;
    
    if (lastMonthOpened != currentMonth) {
       _hasSeenBudgetWarningThisMonth = false;
       _lastWarningThreshold = 0;
       prefs.setString('lastMonthOpened', currentMonth);
       prefs.setBool('hasSeenBudgetWarningThisMonth', false);
       prefs.setInt('lastWarningThreshold', 0);
    } else {
       _hasSeenBudgetWarningThisMonth = prefs.getBool('hasSeenBudgetWarningThisMonth') ?? false;
       _lastWarningThreshold = prefs.getInt('lastWarningThreshold') ?? 0;
    }
    
    _budgetWarningIntervals = (prefs.getStringList('budgetWarningIntervals') ?? ['50', '75', '90', '100'])
        .map((s) => int.parse(s)).toList();
    _pin = prefs.getString('appPin') ?? '';
    // Load persisted notifications
    final notifJson = prefs.getString('notifications');
    if (notifJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(notifJson);
        _notifications = decoded.map((n) => AppNotification.fromJson(n)).toList();
      } catch (_) {}
    }
    _isBiometricEnabled = prefs.getBool('isBiometricEnabled') ?? false;
    notifyListeners();
  }

  Future<void> _saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(
        'expenses', jsonEncode(_expenses.map((e) => e.toJson()).toList()));

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _db.collection('users').doc(user.uid).set({
        'expenses': _expenses.map((e) => e.toJson()).toList(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> _saveBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(
        'budgets', jsonEncode(_budgets.map((b) => b.toJson()).toList()));

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _db.collection('users').doc(user.uid).set({
        'budgets': _budgets.map((b) => b.toJson()).toList(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> _savePreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _db.collection('users').doc(user.uid).set({
        'isDarkMode': _isDarkMode,
        'language': _language,
        'currency': _currency,
        'pushNotificationsEnabled': _pushNotificationsEnabled,
        'overallBudget': _overallBudget,
        'budgetWarningIntervals': _budgetWarningIntervals,
        'lastWarningThreshold': _lastWarningThreshold,
        'appPin': _pin,
        'isBiometricEnabled': _isBiometricEnabled,
        'displayName': _userName,
      }, SetOptions(merge: true));
    }
  }

  Future<void> _syncDataFromFirestore(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        
        // Restore Expenses & Budgets
        if (data.containsKey('expenses')) {
          final List<dynamic> exps = data['expenses'];
          _expenses = exps.map((e) => Expense.fromJson(e)).toList();
        }
        if (data.containsKey('budgets')) {
          final List<dynamic> bdgs = data['budgets'];
          _budgets = bdgs.map((b) => Budget.fromJson(b)).toList();
        }

        // Restore Preferences
        final prefs = await SharedPreferences.getInstance();
        if (data.containsKey('isDarkMode')) {
          _isDarkMode = data['isDarkMode'];
          await prefs.setBool('isDarkMode', _isDarkMode);
        }
        if (data.containsKey('language')) {
          _language = data['language'];
          await prefs.setString('language', _language);
        }
        if (data.containsKey('currency')) {
          _currency = data['currency'];
          await prefs.setString('currency', _currency);
        }
        if (data.containsKey('pushNotificationsEnabled')) {
          _pushNotificationsEnabled = data['pushNotificationsEnabled'];
          await prefs.setBool('pushNotificationsEnabled', _pushNotificationsEnabled);
        }
        if (data.containsKey('overallBudget')) {
          _overallBudget = (data['overallBudget'] as num).toDouble();
          await prefs.setDouble('overallBudget', _overallBudget);
        }
        if (data.containsKey('budgetWarningIntervals')) {
          _budgetWarningIntervals = List<int>.from(data['budgetWarningIntervals']);
          await prefs.setStringList('budgetWarningIntervals', _budgetWarningIntervals.map((i) => i.toString()).toList());
        }
        if (data.containsKey('appPin')) {
          _pin = data['appPin'];
          await prefs.setString('appPin', _pin);
        }
        if (data.containsKey('isBiometricEnabled')) {
          _isBiometricEnabled = data['isBiometricEnabled'];
          await prefs.setBool('isBiometricEnabled', _isBiometricEnabled);
        }
        if (data.containsKey('displayName')) {
          _userName = data['displayName'];
          await prefs.setString('userName', _userName);
        }
        if (data.containsKey('notifications')) {
          final List<dynamic> notifs = data['notifications'];
          _notifications = notifs.map((n) => AppNotification.fromJson(n)).toList();
          await prefs.setString('notifications', jsonEncode(notifs));
        }

        notifyListeners();
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error syncing from Firestore: $e');
    }
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

  Future<void> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // On web, use the popup-based sign-in via Firebase directly
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        // Ensure the correct client ID is used for initialization
        await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        // On Android/iOS, use the native GoogleSignIn package
        // Note: Client ID is usually picked up from google-services.json/Info.plist automatically
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        
        if (googleUser == null) {
          // User canceled the sign-in flow
          return;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      // ignore: avoid_print
      print('Firebase Google Sign-In error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      // ignore: avoid_print
      print('Google sign in error: $e');
      rethrow;
    }
  }

  Future<void> loginWithEmail(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      // ignore: avoid_print
      print('Login error: $e');
      rethrow;
    }
  }

  Future<void> registerWithEmail(
      String name, String email, String password) async {
    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (credential.user != null) {
        await credential.user!.updateDisplayName(name);
        await credential.user!.sendEmailVerification();
        // Refresh state
        _userName = name;
        notifyListeners();
      }
    } catch (e) {
      // ignore: avoid_print
      print('Registration error: $e');
      rethrow;
    }
  }

  Future<void> resendVerificationEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<void> checkEmailVerificationStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();
      final freshUser = FirebaseAuth.instance.currentUser;
      if (freshUser != null && freshUser.emailVerified) {
        _screenHistory = ['dashboard'];
        notifyListeners();
      }
    }
  }

  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
    } catch (e) {
      // ignore: avoid_print
      print('Logout error: $e');
    }
    _isLoggedIn = false;
    _screenHistory = ['login'];
    SharedPreferences.getInstance().then((p) => p.setBool('isLoggedIn', false));
    notifyListeners();
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

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _db
          .collection('users')
          .doc(user.uid)
          .set({'profileImage': img}, SetOptions(merge: true));
    }
  }

  // ---------------------------------------------------------------------------
  // Notification helpers
  // ---------------------------------------------------------------------------

  void pushNotification({
    required String title,
    required String message,
    required String type, // 'success' | 'info' | 'warning'
  }) {
    final n = AppNotification(
      id: 'n_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
      time: 'Just now',
      read: false,
      type: type,
    );
    _notifications = [n, ..._notifications];
    _saveNotifications();
    notifyListeners();
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notifData = _notifications.map((n) => n.toJson()).toList();
    prefs.setString('notifications', jsonEncode(notifData));

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _db.collection('users').doc(user.uid).set({
        'notifications': notifData,
      }, SetOptions(merge: true));
    }
  }

  // ---------------------------------------------------------------------------
  // Expense CRUD
  // ---------------------------------------------------------------------------

  void addExpense(Expense expense) {
    _expenses = [expense, ..._expenses];
    _saveExpenses();
    pushNotification(
      title: 'expense_saved',
      message:
          '${expense.merchant} (${formatCurrency(expense.amount)}) was saved successfully.',
      type: 'success',
    );
    notifyListeners();
  }

  void editExpense(String id, Expense updated) {
    _expenses = _expenses.map((e) => e.id == id ? updated : e).toList();
    _saveExpenses();
    pushNotification(
      title: 'expense_saved',
      message:
          '${updated.merchant} (${formatCurrency(updated.amount)}) was updated successfully.',
      type: 'info',
    );
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
    SharedPreferences.getInstance()
        .then((p) => p.setBool('isDarkMode', _isDarkMode));
    _savePreferences();
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

  // Stored user accounts for legacy login validation (optional, can be removed once fully migrated to Firebase)
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
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setCurrency(String curr) async {
    _currency = curr;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', curr);
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setPushNotificationsEnabled(bool enabled) async {
    _pushNotificationsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pushNotificationsEnabled', enabled);
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setOverallBudget(double amount) async {
    _overallBudget = amount;
    _hasSeenBudgetWarningThisMonth = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('overallBudget', amount);
    await prefs.setBool('hasSeenBudgetWarningThisMonth', false);

    await _savePreferences();
    notifyListeners();
  }

  Future<void> setHasSeenBudgetWarningThisMonth(bool seen) async {
    _hasSeenBudgetWarningThisMonth = seen;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenBudgetWarningThisMonth', seen);
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

    _screenHistory = ['login'];
    notifyListeners();
  }

  String formatCurrency(double amount, [String? originalCurrency]) {
    return formatCurrencyWithSymbol(amount, originalCurrency);
  }

  void setSelectedMonth(String month) {
    _selectedMonth = month;
    notifyListeners();
  }

  void setScreenArgs(Map<String, dynamic>? args) {
    _screenArgs = args;
    notifyListeners();
  }

  String formatCurrencyWithSymbol(double amount, [String? originalCurrency]) {
    final symbol = _currencyService.getCurrencySymbol(_currency);
    double convertedAmount = amount;
    
    // Make sure we only convert if the currencies differ 
    if (originalCurrency != null && originalCurrency.isNotEmpty) {
      final cleanOriginal = _currencyService.cleanCurrencyCode(originalCurrency);
      final cleanCurrent = _currencyService.cleanCurrencyCode(_currency);
      
      if (cleanOriginal != cleanCurrent) {
        convertedAmount = convertToCurrent(amount, cleanOriginal);
      }
    }
    return '$symbol${convertedAmount.toStringAsFixed(2).replaceAllMapped(RegExp(r"(\d)(?=(\d{3})+(?!\d))"), (m) => "${m[1]},")}';
  }

  double convertToCurrent(double amount, String fromCurrency) {
    if (amount == 0) return 0;
    final to = _currencyService.cleanCurrencyCode(_currency);
    final from = _currencyService.cleanCurrencyCode(fromCurrency);
    return _currencyService.convert(amount, from, to);
  }

  double getTotalInCurrentCurrency() {
    double total = 0;
    final to = _currencyService.cleanCurrencyCode(_currency);
    for (var e in _expenses) {
      total += _currencyService.convert(e.amount, e.currency, to);
    }
    return total;
  }

  /// Set or update the PIN. Persists to SharedPreferences.
  Future<void> setPin(String newPin) async {
    _pin = newPin;
    _isPinLocked = false;
    await _savePreferences();
    notifyListeners();
  }

  /// Remove the PIN.
  Future<void> clearPin() async {
    _pin = '';
    _isPinLocked = false;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    _isBiometricEnabled = enabled;
    await _savePreferences();
    notifyListeners();
  }

  /// Called when user successfully enters PIN; unlocks the app.
  void unlockPin() {
    _isPinLocked = false;
    if (_screenHistory.last == 'login' ||
        _screenHistory.last == 'register') {
      _screenHistory = ['dashboard'];
    }
    notifyListeners();
  }

  Future<void> authenticateWithBiometrics() async {
    if (!_isBiometricEnabled) return;
    final success = await _bioService.authenticate();
    if (success) {
      _isPinLocked = false;
      notifyListeners();
    }
  }

  Future<void> setBudgetWarningIntervals(List<int> intervals) async {
    _budgetWarningIntervals = intervals;
    _budgetWarningIntervals.sort();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('budgetWarningIntervals',
        _budgetWarningIntervals.map((i) => i.toString()).toList());
    
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setLastWarningThreshold(int threshold) async {
    _lastWarningThreshold = threshold;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastWarningThreshold', threshold);
    
    await _savePreferences();
    notifyListeners();
  }
}
