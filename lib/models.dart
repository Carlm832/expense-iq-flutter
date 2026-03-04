

class Expense {
  final String id;
  final String merchant;
  final String date;
  final double amount;
  final String category;
  final String icon;

  const Expense({
    required this.id,
    required this.merchant,
    required this.date,
    required this.amount,
    required this.category,
    required this.icon,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'merchant': merchant,
        'date': date,
        'amount': amount,
        'category': category,
        'icon': icon,
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'],
        merchant: json['merchant'],
        date: json['date'],
        amount: (json['amount'] as num).toDouble(),
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

  factory Budget.fromJson(Map<String, dynamic> json) =>
      Budget(category: json['category'], limit: (json['limit'] as num).toDouble());
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
  Expense(id: '1', merchant: 'Whole Foods Market', date: '2026-02-10', amount: 67.43, category: 'Food & Dining', icon: 'utensils'),
];

final List<Expense> kRecentExpenses = [
  Expense(id: '1', merchant: 'Whole Foods Market', date: '2026-02-10', amount: 67.43, category: 'Food & Dining', icon: 'utensils'),
  Expense(id: '2', merchant: 'Uber Ride', date: '2026-02-09', amount: 24.50, category: 'Transport', icon: 'car'),
  Expense(id: '3', merchant: 'Amazon', date: '2026-02-08', amount: 129.99, category: 'Shopping', icon: 'shopping-bag'),
  Expense(id: '4', merchant: 'Netflix', date: '2026-02-07', amount: 15.99, category: 'Entertainment', icon: 'film'),
  Expense(id: '5', merchant: 'Electric Bill', date: '2026-02-06', amount: 89.00, category: 'Utilities', icon: 'zap'),
  Expense(id: '6', merchant: 'Starbucks', date: '2026-02-05', amount: 6.75, category: 'Food & Dining', icon: 'utensils'),
  Expense(id: '7', merchant: 'Gas Station', date: '2026-02-04', amount: 45.20, category: 'Transport', icon: 'car'),
  Expense(id: '8', merchant: 'Target', date: '2026-02-03', amount: 82.30, category: 'Shopping', icon: 'shopping-bag'),
  Expense(id: '9', merchant: 'Apartment Rent', date: '2026-02-01', amount: 1200.00, category: 'Rent', icon: 'home'),
  Expense(id: '10', merchant: 'Chipotle', date: '2026-01-31', amount: 12.85, category: 'Food & Dining', icon: 'utensils'),
  Expense(id: '11', merchant: 'Lyft', date: '2026-01-30', amount: 18.75, category: 'Transport', icon: 'car'),
  Expense(id: '12', merchant: 'H&M', date: '2026-01-29', amount: 54.99, category: 'Shopping', icon: 'shopping-bag'),
];

final List<AppNotification> kDefaultNotifications = [
  AppNotification(id: 'n1', title: 'Budget Alert', message: "You've used 85% of your Food & Dining budget this month.", time: '2 hours ago', read: false, type: 'warning'),
  AppNotification(id: 'n2', title: 'Weekly Summary', message: 'Your total spending last week was ₺615. That\'s 8% less than the previous week.', time: '1 day ago', read: false, type: 'info'),
  AppNotification(id: 'n3', title: 'Expense Saved', message: 'Your receipt from Whole Foods Market (₺67.43) was saved successfully.', time: '2 days ago', read: true, type: 'success'),
  AppNotification(id: 'n4', title: 'Savings Tip', message: 'Try setting a weekly spending limit to stay on track with your goals.', time: '3 days ago', read: true, type: 'info'),
  AppNotification(id: 'n5', title: 'Shopping Alert', message: 'Your Shopping category spending is 23% higher than last month.', time: '4 days ago', read: false, type: 'warning'),
];

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

String formatDate(String dateStr) {
  final date = DateTime.parse(dateStr);
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[date.month - 1]} ${date.day}';
}
