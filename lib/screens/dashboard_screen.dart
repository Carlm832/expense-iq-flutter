import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../app_state.dart';
import '../theme.dart';
import '../models.dart';
import '../services/translations.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  void _checkAndShowAlert() {
    final state = context.read<AppState>();
    final isCurrentMonth =
        state.selectedMonth == DateTime.now().toIso8601String().substring(0, 7);

    if (state.overallBudget > 0 && isCurrentMonth) {
      final total = state.expenses
          .where((e) => e.date.startsWith(state.selectedMonth))
          .fold(0.0, (s, e) => s + e.amount);

      final percent = (total / state.overallBudget) * 100;

      int? highestCrossed;
      for (var threshold in state.budgetWarningIntervals) {
        if (percent >= threshold && threshold > state.lastWarningThreshold) {
          highestCrossed = threshold;
        }
      }

      if (highestCrossed != null) {
        final thresholdValue = highestCrossed;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          state.setLastWarningThreshold(thresholdValue);
          _showBudgetWarning(thresholdValue);
          state.pushNotification(
            title: Translations.t('budget_alert', state.language),
            message:
                '${Translations.t('budget_warning_msg_part1', state.language)} $highestCrossed% ${Translations.t('budget_warning_msg_part2', state.language)}',
            type: 'warning',
          );
        });
      }
    }
  }

  void _showBudgetWarning(int percent) {
    final state = context.read<AppState>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(Translations.t('budget_alert', state.language)),
        content: Text(
            '${Translations.t('budget_warning_msg_part1', state.language)} $percent% ${Translations.t('budget_warning_msg_part2', state.language)}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(Translations.t('ok', state.language))),
        ],
      ),
    );
  }

  List<(String, String)> _getAvailableMonths(List<Expense> expenses) {
    final state = context.read<AppState>();
    final months = <String>{};
    for (var e in expenses) {
      if (e.date.length >= 7) {
        months.add(e.date.substring(0, 7));
      }
    }
    // Add current month if not present
    months.add(DateTime.now().toIso8601String().substring(0, 7));

    final sorted = months.toList()..sort((a, b) => b.compareTo(a));
    return sorted.map((m) {
      final date = DateTime.parse('$m-01');
      final monthNames = [
        Translations.t('m_jan', state.language),
        Translations.t('m_feb', state.language),
        Translations.t('m_mar', state.language),
        Translations.t('m_apr', state.language),
        Translations.t('m_may', state.language),
        Translations.t('m_jun', state.language),
        Translations.t('m_jul', state.language),
        Translations.t('m_aug', state.language),
        Translations.t('m_sep', state.language),
        Translations.t('m_oct', state.language),
        Translations.t('m_nov', state.language),
        Translations.t('m_dec', state.language)
      ];
      return (m, "${monthNames[date.month - 1]} ${date.year}");
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _checkAndShowAlert();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final fgColor = isDark ? AppColors.darkForeground : AppColors.foreground;
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final mutedColor =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final mutedBg = isDark ? AppColors.darkMuted : AppColors.muted;

    final lang = state.language;
    final selectedMonthStr = state.selectedMonth;
    final allExpenses = state.expenses;
    final expenses =
        allExpenses.where((e) => e.date.startsWith(selectedMonthStr)).toList();

    final totalSpending = expenses.fold(0.0, (s, e) => s + e.amount);
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? Translations.t('greeting_morning', lang)
        : hour < 18
            ? Translations.t('greeting_afternoon', lang)
            : Translations.t('greeting_evening', lang);

    // Category summary
    final Map<String, double> categoryMap = {};
    for (final e in expenses) {
      categoryMap[e.category] = (categoryMap[e.category] ?? 0) + e.amount;
    }

    final categorySummary = kCategories
        .map((cat) => (
              name: cat.name,
              value: categoryMap[cat.name] ?? 0.0,
              color: Color(cat.color)
            ))
        .where((c) => c.value > 0)
        .toList();

    // Budget progress
    final overallBudget = state.overallBudget;
    final isCurrentMonth =
        selectedMonthStr == DateTime.now().toIso8601String().substring(0, 7);
    final budgetPercent = (overallBudget > 0)
        ? (totalSpending / overallBudget).clamp(0.0, 1.0)
        : 0.0;

    final maxExpense = expenses.isEmpty
        ? 0.0
        : expenses.map((e) => e.amount).reduce((a, b) => a > b ? a : b);

    int daysInMonth =
        DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day;
    int daysPassed = isCurrentMonth ? DateTime.now().day : daysInMonth;
    final dailyAvg = totalSpending / (daysPassed > 0 ? daysPassed : 1);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('$greeting,',
                              style: GoogleFonts.inter(
                                  fontSize: 13, color: mutedColor)),
                          Text(
                              state.userName.isEmpty
                                  ? Translations.t('welcome', lang)
                                  : state.userName,
                              style: GoogleFonts.dmSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: fgColor)),
                        ])),
                    GestureDetector(
                      onTap: () => state.setCurrentScreen('notifications'),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: borderColor)),
                        child: Stack(children: [
                          Center(
                              child: Icon(Icons.notifications_outlined,
                                  size: 20, color: fgColor)),
                          if (state.unreadCount > 0)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                    color: AppColors.destructive,
                                    shape: BoxShape.circle),
                                child: Center(
                                    child: Text('${state.unreadCount}',
                                        style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white))),
                              ),
                            ),
                        ]),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // Total spending card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6))
                      ],
                    ),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(Translations.t('total_spending', lang),
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: Colors.white
                                            .withValues(alpha: 0.75))),
                                const SizedBox(height: 4),
                                Text(state.formatCurrency(totalSpending),
                                    style: GoogleFonts.dmSans(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(100)),
                                  child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.trending_down,
                                            size: 12, color: Colors.white),
                                        const SizedBox(width: 4),
                                        Text(
                                            '${expenses.length} ${Translations.t('expenses', lang)}',
                                            style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500)),
                                      ]),
                                ),
                              ])),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(100)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedMonthStr,
                                icon: const Icon(Icons.arrow_drop_down,
                                    color: Colors.white, size: 16),
                                isDense: true,
                                dropdownColor: cardColor,
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500),
                                onChanged: (newValue) {
                                  if (newValue != null) {
                                    state.setSelectedMonth(newValue);
                                    if (newValue ==
                                        DateTime.now()
                                            .toIso8601String()
                                            .substring(0, 7)) {
                                      _checkAndShowAlert();
                                    }
                                  }
                                },
                                items: _getAvailableMonths(allExpenses)
                                    .map((month) {
                                  return DropdownMenuItem<String>(
                                    value: month.$1,
                                    child: Text(month.$2,
                                        style: TextStyle(
                                          color: selectedMonthStr == month.$1
                                              ? AppColors.primary
                                              : fgColor,
                                        )),
                                  );
                                }).toList(),
                                selectedItemBuilder: (BuildContext context) {
                                  return _getAvailableMonths(allExpenses)
                                      .map((month) {
                                    return Text(month.$2,
                                        style: const TextStyle(
                                            color: Colors.white));
                                  }).toList();
                                },
                              ),
                            ),
                          ),
                        ]),
                  ),
                  const SizedBox(height: 16),

                  // Budget progress
                  if (overallBudget > 0) ...[
                    _AppCard(
                        isDark: isDark,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(
                                    child: Text(
                                        Translations.t(
                                            'overall_monthly_budget', lang),
                                        style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: fgColor))),
                                Container(width: 8),
                                GestureDetector(
                                  onTap: () => state.setCurrentScreen('budget'),
                                  child: Text(Translations.t('manage', lang),
                                      style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.primary)),
                                ),
                              ]),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: budgetPercent,
                                  minHeight: 8,
                                  backgroundColor: mutedBg,
                                  valueColor: AlwaysStoppedAnimation(
                                      budgetPercent >= 0.9
                                          ? AppColors.destructive
                                          : AppColors.primary),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(children: [
                                Text(
                                    '${state.formatCurrency(totalSpending)} ${Translations.t('spent', lang)}',
                                    style: GoogleFonts.inter(
                                        fontSize: 10, color: mutedColor)),
                                const Spacer(),
                                Text(
                                    '${state.formatCurrency(overallBudget)} ${Translations.t('limit', lang)}',
                                    style: GoogleFonts.inter(
                                        fontSize: 10, color: mutedColor)),
                              ]),
                            ])),
                    const SizedBox(height: 16),
                  ],

                  // Spending by category
                  Row(children: [
                    Expanded(
                        child: Text(
                            Translations.t('spending_by_category', lang),
                            style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: fgColor))),
                    GestureDetector(
                      onTap: () => state.setCurrentScreen('analytics'),
                      child: Text(Translations.t('see_all', lang),
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary)),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  _AppCard(
                    isDark: isDark,
                    child: categorySummary.isEmpty
                        ? Center(
                            child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(Translations.t('no_data', lang),
                                    style:
                                        GoogleFonts.inter(color: mutedColor))))
                        : Row(children: [
                            SizedBox(
                              width: 130,
                              height: 130,
                              child: PieChart(PieChartData(
                                sections: categorySummary
                                    .map((c) => PieChartSectionData(
                                          value: c.value,
                                          color: c.color,
                                          radius: 38,
                                          showTitle: false,
                                        ))
                                    .toList(),
                                centerSpaceRadius: 28,
                                sectionsSpace: 2,
                              )),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                                child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: categorySummary
                                  .take(4)
                                  .map((cat) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 3),
                                        child: Row(children: [
                                          Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                  color: cat.color,
                                                  shape: BoxShape.circle)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                              child: Text(cat.name,
                                                  style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      color: mutedColor))),
                                          Text(state.formatCurrency(cat.value),
                                              style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: fgColor)),
                                        ]),
                                      ))
                                  .toList(),
                            )),
                          ]),
                  ),
                  const SizedBox(height: 24),

                  // Quick stats
                  Row(children: [
                    Expanded(
                        child: _AppCard(
                            isDark: isDark,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                        color: AppColors.secondary
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: const Icon(Icons.trending_up,
                                        size: 16, color: AppColors.secondary),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(Translations.t('highest_expense', lang),
                                      style: GoogleFonts.inter(
                                          fontSize: 11, color: mutedColor)),
                                  Text(state.formatCurrency(maxExpense),
                                      style: GoogleFonts.dmSans(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: fgColor)),
                                ]))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _AppCard(
                            isDark: isDark,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: const Icon(Icons.trending_down,
                                        size: 16, color: AppColors.primary),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(Translations.t('daily_average', lang),
                                      style: GoogleFonts.inter(
                                          fontSize: 11, color: mutedColor)),
                                  Text(state.formatCurrency(dailyAvg),
                                      style: GoogleFonts.dmSans(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: fgColor)),
                                ]))),
                  ]),
                  const SizedBox(height: 24),

                  // Recent expenses section
                  Row(children: [
                    Expanded(
                        child: Text(Translations.t('recent_expenses', lang),
                            style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: fgColor))),
                    GestureDetector(
                      onTap: () => state.setCurrentScreen('history'),
                      child: Text(Translations.t('see_all', lang),
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary)),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  if (expenses.isEmpty)
                    Center(
                        child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(Translations.t('no_data', lang),
                                style: GoogleFonts.inter(color: mutedColor))))
                  else
                    ...expenses.take(5).map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _ExpenseItem(
                              expense: e,
                              isDark: isDark,
                              onTap: () => _showExpenseDetail(context, e)),
                        )),
                ],
              ),
            ),

            // Bottom action
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: FloatingActionButton.extended(
                onPressed: () => state.setCurrentScreen('scan'),
                backgroundColor: AppColors.primary,
                elevation: 4,
                label: Text(Translations.t('scan_receipt', lang),
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                icon: const Icon(Icons.document_scanner, color: Colors.white),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExpenseDetail(BuildContext context, Expense e) {
    final state = context.read<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = isDark ? AppColors.darkForeground : AppColors.foreground;
    final mutedColor =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final lang = state.language;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: borderColor)),
        padding: const EdgeInsets.all(24),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(Translations.t('expense_details', lang),
                    style: GoogleFonts.dmSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: fgColor)),
                const Spacer(),
                IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: Icon(Icons.close, size: 20, color: mutedColor)),
              ]),
              const SizedBox(height: 16),
              _DetailRow(
                  label: Translations.t('merchant', lang),
                  value: e.merchant,
                  fgColor: fgColor,
                  mutedColor: mutedColor),
              _DetailRow(
                  label: Translations.t('date', lang),
                  value: formatDate(e.date, lang),
                  fgColor: fgColor,
                  mutedColor: mutedColor),
              _DetailRow(
                  label: Translations.t('category', lang),
                  value: e.category,
                  fgColor: fgColor,
                  mutedColor: mutedColor),
              _DetailRow(
                  label: Translations.t('amount', lang),
                  value: state.formatCurrency(e.amount, e.currency),
                  fgColor: fgColor,
                  mutedColor: mutedColor,
                  isAmount: true),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    state.setScreenArgs({
                      'editExpense': true,
                      'id': e.id,
                      'merchant': e.merchant,
                      'amount': e.amount.toString(),
                      'date': e.date,
                      'category': e.category,
                      'notes': '',
                    });
                    state.setCurrentScreen('addExpense');
                  },
                  icon: const Icon(Icons.edit_outlined,
                      size: 16, color: AppColors.primary),
                  label: Text(Translations.t('edit_expense_title', lang),
                      style: GoogleFonts.inter(color: AppColors.primary)),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)))),
                )),
                const SizedBox(width: 12),
                Expanded(
                    child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(Translations.t('cancel', lang)),
                )),
              ]),
              const SizedBox(height: 8),
            ]),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color fgColor;
  final Color mutedColor;
  final bool isAmount;

  const _DetailRow(
      {required this.label,
      required this.value,
      required this.fgColor,
      required this.mutedColor,
      this.isAmount = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: mutedColor)),
        const Spacer(),
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isAmount ? AppColors.destructive : fgColor)),
      ]),
    );
  }
}

class _AppCard extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _AppCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

class _ExpenseItem extends StatelessWidget {
  final Expense expense;
  final bool isDark;
  final VoidCallback onTap;

  const _ExpenseItem(
      {required this.expense, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final fgColor = isDark ? AppColors.darkForeground : AppColors.foreground;
    final mutedColor =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    final lang = context.read<AppState>().language;
    final catColor = _categoryColor(expense.category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                color: catColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(_categoryIcon(expense.icon), size: 18, color: catColor),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(expense.merchant,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: fgColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(formatDate(expense.date, lang),
                    style: GoogleFonts.inter(fontSize: 11, color: mutedColor)),
              ])),
          const SizedBox(width: 8),
          Flexible(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                  '-${context.read<AppState>().formatCurrency(expense.amount, expense.currency)}',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: fgColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(expense.category,
                  style: GoogleFonts.inter(fontSize: 11, color: mutedColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ]),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, size: 16, color: mutedColor),
        ]),
      ),
    );
  }
}

Color _categoryColor(String category) {
  final cat = kCategories.firstWhere((c) => c.name == category,
      orElse: () => const Category(name: '', icon: '', color: 0xFF6B7280));
  return Color(cat.color);
}

IconData _categoryIcon(String icon) {
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
