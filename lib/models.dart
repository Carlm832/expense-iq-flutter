import 'services/translations.dart';

class Expense {
  final String id;
  final String merchant;
  final String date;
  final double amount;
  final String currency;
  final String category;
  final String icon;

  const Expense({
    required this.id,
    required this.merchant,
    required this.date,
    required this.amount,
    required this.currency,
    required this.category,
    required this.icon,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'merchant': merchant,
        'date': date,
        'amount': amount,
        'currency': currency,
        'category': category,
        'icon': icon,
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'],
        merchant: json['merchant'],
        date: json['date'],
        amount: (json['amount'] as num).toDouble(),
        currency: json['currency'] ?? 'TRY', // fallback for old data without currency
        category: json['category'],
        icon: json['icon'],
      );
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String time;
  bool read;
  final String type; // "warning" | "info" | "success"

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.read,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'time': time,
        'read': read,
        'type': type,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'],
        title: json['title'],
        message: json['message'],
        time: json['time'],
        read: json['read'],
        type: json['type'],
      );
}

class Budget {
  final String category;
  double limit;

  Budget({required this.category, required this.limit});

  Map<String, dynamic> toJson() => {'category': category, 'limit': limit};

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
      category: json['category'], limit: (json['limit'] as num).toDouble());
}

class Category {
  final String name;
  final String icon;
  final int color; // ARGB

  const Category({required this.name, required this.icon, required this.color});
}

const List<Category> kCategories = [
  Category(name: 'Food & Dining', icon: 'utensils', color: 0xFF4F8EF7),
  Category(name: 'Transport', icon: 'car', color: 0xFF33C17A),
  Category(name: 'Shopping', icon: 'shopping-bag', color: 0xFFF5A623),
  Category(name: 'Rent', icon: 'home', color: 0xFFEF4444),
  Category(name: 'Entertainment', icon: 'film', color: 0xFF8B5CF6),
  Category(name: 'Utilities', icon: 'zap', color: 0xFF0EA5E9),
];

const List<Expense> kDefaultExpenses = [
  Expense(
      id: '1',
      merchant: 'Whole Foods Market',
      date: '2026-02-10',
      amount: 67.43,
      currency: 'USD',
      category: 'Food & Dining',
      icon: 'utensils'),
];

final List<AppNotification> kDefaultNotifications = [];


final List<Budget> kDefaultBudgets = [
  Budget(category: 'Food & Dining', limit: 500),
  Budget(category: 'Transport', limit: 350),
  Budget(category: 'Shopping', limit: 400),
  Budget(category: 'Rent', limit: 1300),
  Budget(category: 'Entertainment', limit: 150),
  Budget(category: 'Utilities', limit: 200),
];

String formatCurrency(double amount) {
  return '₺${amount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
}

String formatDate(String dateStr, String lang) {
  final date = DateTime.parse(dateStr);
  final months = [
    Translations.t('m_jan', lang),
    Translations.t('m_feb', lang),
    Translations.t('m_mar', lang),
    Translations.t('m_apr', lang),
    Translations.t('m_may', lang),
    Translations.t('m_jun', lang),
    Translations.t('m_jul', lang),
    Translations.t('m_aug', lang),
    Translations.t('m_sep', lang),
    Translations.t('m_oct', lang),
    Translations.t('m_nov', lang),
    Translations.t('m_dec', lang)
  ];
  return '${months[date.month - 1]} ${date.day}';
}
