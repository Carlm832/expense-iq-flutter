import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _search = '';
  String _selectedCategory = 'All';
  String _sortBy = 'date-desc';
  bool _showSortMenu = false;

  final _sortLabels = {
    'date-desc': 'Newest First',
    'date-asc': 'Oldest First',
    'amount-desc': 'Highest Amount',
    'amount-asc': 'Lowest Amount',
  };

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final fgColor = isDark ? AppColors.darkForeground : AppColors.foreground;
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final mutedColor = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final mutedBg = isDark ? AppColors.darkMuted : AppColors.muted;

    var expenses = state.expenses.where((e) {
      final matchSearch = e.merchant.toLowerCase().contains(_search.toLowerCase());
      final matchCat = _selectedCategory == 'All' || e.category == _selectedCategory;
      return matchSearch && matchCat;
    }).toList();

    expenses.sort((a, b) {
      switch (_sortBy) {
        case 'date-asc': return DateTime.parse(a.date).compareTo(DateTime.parse(b.date));
        case 'amount-desc': return b.amount.compareTo(a.amount);
        case 'amount-asc': return a.amount.compareTo(b.amount);
        default: return DateTime.parse(b.date).compareTo(DateTime.parse(a.date));
      }
    });

    final total = expenses.fold(0.0, (s, e) => s + e.amount);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Column(children: [
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Expense History', style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w700, color: fgColor)),
                    Text('${expenses.length} transactions totaling ${state.formatCurrency(total)}', style: GoogleFonts.inter(fontSize: 12, color: mutedColor)),
                  ])),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download, size: 14),
                    label: Text('CSV', style: GoogleFonts.inter(fontSize: 12)),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ]),
                const SizedBox(height: 12),
                // Search
                Container(
                  height: 44,
                  decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
                  child: Row(children: [
                    const SizedBox(width: 12),
                    Icon(Icons.search, size: 18, color: mutedColor),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(
                      onChanged: (v) => setState(() => _search = v),
                      decoration: const InputDecoration(
                        hintText: 'Search transactions...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      style: GoogleFonts.inter(fontSize: 13),
                    )),
                    GestureDetector(
                      onTap: () => setState(() => _showSortMenu = !_showSortMenu),
                      child: Padding(padding: const EdgeInsets.all(12), child: Icon(Icons.sort, size: 18, color: mutedColor)),
                    ),
                  ]),
                ),
                if (_showSortMenu)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
                    child: Column(
                      children: _sortLabels.entries.map((entry) => GestureDetector(
                        onTap: () => setState(() { _sortBy = entry.key; _showSortMenu = false; }),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: _sortBy == entry.key ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(entry.value, style: GoogleFonts.inter(fontSize: 12, color: _sortBy == entry.key ? AppColors.primary : fgColor, fontWeight: _sortBy == entry.key ? FontWeight.w500 : FontWeight.normal)),
                        ),
                      )).toList(),
                    ),
                  ),
                const SizedBox(height: 8),
                // Category filter
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChip(label: 'All', isSelected: _selectedCategory == 'All', onTap: () => setState(() => _selectedCategory = 'All'), mutedBg: mutedBg, mutedColor: mutedColor),
                      ...kCategories.map((cat) => _FilterChip(label: cat.name, isSelected: _selectedCategory == cat.name, onTap: () => setState(() => _selectedCategory = cat.name), mutedBg: mutedBg, mutedColor: mutedColor)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ]),
            ),
            Expanded(
              child: expenses.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.search_off, size: 40, color: mutedColor.withValues(alpha: 0.5)),
                    const SizedBox(height: 8),
                    Text('No transactions found', style: GoogleFonts.inter(fontSize: 13, color: mutedColor)),
                  ]))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: expenses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final e = expenses[i];
                      return GestureDetector(
                        onTap: () {
                          state.setSelectedExpense(e);
                          state.setShowExpenseDetail(true);
                        },
                        child: _HistoryItem(expense: e, isDark: isDark, fgColor: fgColor, mutedColor: mutedColor, cardColor: cardColor, borderColor: borderColor),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color mutedBg;
  final Color mutedColor;
  const _FilterChip({required this.label, required this.isSelected, required this.onTap, required this.mutedBg, required this.mutedColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : mutedBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : mutedColor)),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final Expense expense;
  final bool isDark;
  final Color fgColor;
  final Color mutedColor;
  final Color cardColor;
  final Color borderColor;
  const _HistoryItem({required this.expense, required this.isDark, required this.fgColor, required this.mutedColor, required this.cardColor, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    final catColor = _categoryColor(expense.category);
    return Container(
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: catColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(_categoryIcon(expense.icon), size: 18, color: catColor),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(expense.merchant, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: fgColor)),
          Text('${formatDate(expense.date)} · ${expense.category}', style: GoogleFonts.inter(fontSize: 11, color: mutedColor)),
        ])),
        Text('-${context.read<AppState>().formatCurrency(expense.amount)}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: fgColor)),
      ]),
    );
  }
}

Color _categoryColor(String category) {
  final cat = kCategories.firstWhere((c) => c.name == category, orElse: () => const Category(name: '', icon: '', color: 0xFF6B7280));
  return Color(cat.color);
}

IconData _categoryIcon(String icon) {
  switch (icon) {
    case 'car': return Icons.directions_car;
    case 'home': return Icons.home;
    case 'film': return Icons.movie;
    case 'zap': return Icons.flash_on;
    case 'shopping-bag': return Icons.shopping_bag;
    default: return Icons.restaurant;
  }
}
