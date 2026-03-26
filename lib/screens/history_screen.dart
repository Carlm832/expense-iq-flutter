import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../services/translations.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _search = '';
  String _selectedCategory = 'All';
  final String _sortBy = 'date-desc';



  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final lang = state.language;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final fgColor = isDark ? AppColors.darkForeground : AppColors.foreground;
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final mutedColor =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    var expenses = state.expenses.where((e) {
      final matchSearch =
          e.merchant.toLowerCase().contains(_search.toLowerCase());
      final matchCat =
          _selectedCategory == 'All' || e.category == _selectedCategory;
      return matchSearch && matchCat;
    }).toList();

    expenses.sort((a, b) {
      switch (_sortBy) {
        case 'date-asc':
          return DateTime.parse(a.date).compareTo(DateTime.parse(b.date));
        case 'amount-desc':
          return b.amount.compareTo(a.amount);
        case 'amount-asc':
          return a.amount.compareTo(b.amount);
        default:
          return DateTime.parse(b.date).compareTo(DateTime.parse(a.date));
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
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(Translations.t('expense_history', lang),
                            style: GoogleFonts.dmSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: fgColor)),
                        Text(
                            '${expenses.length} ${Translations.t('transactions', lang).toLowerCase()} ${Translations.t('totaling', lang)} ${state.formatCurrency(total)}',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: mutedColor)),
                      ])),
                ]),
                const SizedBox(height: 12),
                // Search
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor)),
                  child: Row(children: [
                    const SizedBox(width: 12),
                    Icon(Icons.search, size: 18, color: mutedColor),
                    const SizedBox(width: 8),
                    Expanded(
                        child: TextField(
                      onChanged: (v) => setState(() => _search = v),
                      style: GoogleFonts.inter(fontSize: 14, color: fgColor),
                      decoration: InputDecoration(
                        hintText: Translations.t('search_history', lang),
                        hintStyle:
                            GoogleFonts.inter(fontSize: 14, color: mutedColor),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                      ),
                    )),
                  ]),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        isSelected: _selectedCategory == 'All',
                        onTap: () => setState(() => _selectedCategory = 'All'),
                      ),
                      ...kCategories.map((c) => _FilterChip(
                            label: c.name,
                            isSelected: _selectedCategory == c.name,
                            onTap: () =>
                                setState(() => _selectedCategory = c.name),
                          )),
                    ],
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: expenses.isEmpty
                  ? Center(
                      child: Text(Translations.t('no_transactions', lang),
                          style: GoogleFonts.inter(color: mutedColor)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: expenses.length,
                      itemBuilder: (ctx, idx) => _HistoryItem(
                            expense: expenses[idx],
                            isDark: isDark,
                            lang: lang,
                            formatCurrency: (a, [c]) => state.formatCurrency(a, c),
                          )),
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

  const _FilterChip(
      {required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: GoogleFonts.inter(fontSize: 12)),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.mutedForeground),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final Expense expense;
  final bool isDark;
  final String lang;
  final String Function(double, [String?]) formatCurrency;

  const _HistoryItem(
      {required this.expense,
      required this.isDark,
      required this.lang,
      required this.formatCurrency});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final fgColor = isDark ? AppColors.darkForeground : AppColors.foreground;
    final mutedColor =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor)),
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: Color(_getCatColor(expense.category)).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(_getCatIcon(expense.icon),
              size: 18, color: Color(_getCatColor(expense.category))),
        ),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(expense.merchant,
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w500, color: fgColor)),
          Text(formatDate(expense.date, lang),
              style: GoogleFonts.inter(fontSize: 11, color: mutedColor)),
        ])),
        Text('-${formatCurrency(expense.amount, expense.currency)}',
            style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600, color: fgColor)),
      ]),
    );
  }

  int _getCatColor(String category) {
    return kCategories
        .firstWhere((c) => c.name == category,
            orElse: () => const Category(name: '', icon: '', color: 0xFF6B7280))
        .color;
  }

  IconData _getCatIcon(String icon) {
    switch (icon) {
      case 'car':
        return Icons.directions_car;
      case 'home':
        return Icons.home;
      case 'film':
        return Icons.movie;
      case 'zap':
        return Icons.flash_on;
      case 'shopping-bag':
        return Icons.shopping_bag;
      default:
        return Icons.restaurant;
    }
  }
}
