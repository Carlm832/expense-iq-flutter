import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _timeRange = 'month'; // 'week', 'month', 'custom'
  DateTimeRange? _customRange;

  Future<void> _selectCustomRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.primary,
                    surface: AppColors.darkCard,
                    onSurface: AppColors.darkForeground,
                  )
                : const ColorScheme.light(
                    primary: AppColors.primary,
                    surface: AppColors.card,
                    onSurface: AppColors.foreground,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _customRange) {
      setState(() {
        _customRange = picked;
        _timeRange = 'custom';
      });
    } else if (_timeRange == 'custom' && _customRange == null) {
      // Revert if cancelled and no previous custom range
      setState(() => _timeRange = 'month');
    }
  }

  List<Expense> _getFilteredExpenses(List<Expense> allExpenses) {
    final now = DateTime.now();
    return allExpenses.where((e) {
      final d = DateTime.parse(e.date);
      if (_timeRange == 'week') {
        return now.difference(d).inDays < 7;
      } else if (_timeRange == 'custom' && _customRange != null) {
        return d.isAfter(_customRange!.start.subtract(const Duration(days: 1))) &&
               d.isBefore(_customRange!.end.add(const Duration(days: 1)));
      } else { // 'month' or default
        // Get last 6 months logic from existing chart, but let's filter actual data to last 6 mos
        final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);
        return d.isAfter(sixMonthsAgo);
      }
    }).toList();
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

    final expenses = _getFilteredExpenses(state.expenses);
    final totalSpending = expenses.fold(0.0, (s, e) => s + e.amount);

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

    // Chart data
    final now = DateTime.now();
    List<(String, double)> chartData = [];
    if (_timeRange == 'week') {
      final Map<int, double> dayTotals = {};
      for (final e in expenses) {
        final d = DateTime.parse(e.date);
        dayTotals[d.weekday] = (dayTotals[d.weekday] ?? 0) + e.amount;
      }
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      chartData = List.generate(7, (i) => (days[i], dayTotals[i + 1] ?? 0.0));
    } else if (_timeRange == 'custom' && _customRange != null) {
        // Group by day if range is < 14 days, else group by month
        final duration = _customRange!.end.difference(_customRange!.start).inDays;
        if (duration <= 14) {
            final Map<String, double> dayTotals = {};
            for (final e in expenses) {
                final d = DateTime.parse(e.date);
                final label = DateFormat('MM/dd').format(d);
                dayTotals[label] = (dayTotals[label] ?? 0) + e.amount;
            }
            // Generate all days in range to ensure continuous axis
            for (int i = 0; i <= duration; i++) {
                final d = _customRange!.start.add(Duration(days: i));
                final label = DateFormat('MM/dd').format(d);
                chartData.add((label, dayTotals[label] ?? 0.0));
            }
        } else {
             // Group by month
             final Map<String, double> monthTotals = {};
             for (final e in expenses) {
                 final d = DateTime.parse(e.date);
                 final label = DateFormat('MMM yyyy').format(d);
                 monthTotals[label] = (monthTotals[label] ?? 0) + e.amount;
             }
             chartData = monthTotals.entries.map((e) => (e.key, e.value)).toList();
        }
    } else {
      const monthNames = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final Map<int, double> monthTotals = {};
      for (final e in expenses) {
        final d = DateTime.parse(e.date);
        monthTotals[d.month - 1] = (monthTotals[d.month - 1] ?? 0) + e.amount;
      }
      chartData = List.generate(6, (i) {
        final m = (now.month - 1 - 5 + i + 12) % 12;
        return (monthNames[m], monthTotals[m] ?? 0.0);
      });
    }

    // Insights Calculations
    final maxExpense = expenses.isEmpty
        ? null
        : expenses.reduce((a, b) => a.amount > b.amount ? a : b);
    
    // Most active day (day of week with most expenses over this period)
    int mostActiveDayIdx = -1;
    if (expenses.isNotEmpty) {
      final Map<int, int> countPerDay = {};
      for(var e in expenses) {
        final d = DateTime.parse(e.date);
        countPerDay[d.weekday] = (countPerDay[d.weekday] ?? 0) + 1;
      }
      mostActiveDayIdx = countPerDay.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }
    const daysArr = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];


    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Analytics',
                style: GoogleFonts.dmSans(
                    fontSize: 20, fontWeight: FontWeight.w700, color: fgColor)),
            Text('Understand your spending patterns',
                style: GoogleFonts.inter(fontSize: 13, color: mutedColor)),
            const SizedBox(height: 20),

            // Time range toggle
            Container(
              height: 40,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                  color: mutedBg, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                _TimeTab(
                    label: 'This Week',
                    isSelected: _timeRange == 'week',
                    onTap: () => setState(() => _timeRange = 'week'),
                    cardColor: cardColor,
                    fgColor: fgColor,
                    mutedColor: mutedColor),
                _TimeTab(
                    label: 'Monthly',
                    isSelected: _timeRange == 'month',
                    onTap: () => setState(() => _timeRange = 'month'),
                    cardColor: cardColor,
                    fgColor: fgColor,
                    mutedColor: mutedColor),
                _TimeTab(
                    label: 'Custom',
                    isSelected: _timeRange == 'custom',
                    onTap: _selectCustomRange,
                    cardColor: cardColor,
                    fgColor: fgColor,
                    mutedColor: mutedColor),
              ]),
            ),
            if (_timeRange == 'custom' && _customRange != null) ...[
                const SizedBox(height: 8),
                Center(
                    child: Text(
                        '${DateFormat.yMMMd().format(_customRange!.start)} - ${DateFormat.yMMMd().format(_customRange!.end)}',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                    )
                ),
            ],
            const SizedBox(height: 16),

            // Stats row
            Row(children: [
              _StatCard(
                  label: 'Total',
                  value: state.formatCurrency(totalSpending),
                  isDark: isDark,
                  fgColor: fgColor,
                  mutedColor: mutedColor,
                  borderColor: borderColor,
                  cardColor: cardColor),
              const SizedBox(width: 8),
              _StatCard(
                  label: 'Avg/Item',
                  value: expenses.isEmpty ? '${state.currencySymbol}0' : state.formatCurrency(totalSpending / expenses.length),
                  isDark: isDark,
                  fgColor: fgColor,
                  mutedColor: mutedColor,
                  borderColor: borderColor,
                  cardColor: cardColor),
              const SizedBox(width: 8),
              _StatCard(
                  label: 'Count',
                  value: '${expenses.length}',
                  isDark: isDark,
                  fgColor: fgColor,
                  mutedColor: mutedColor,
                  borderColor: borderColor,
                  cardColor: cardColor,
                  isGreen: true),
            ]),
            const SizedBox(height: 16),

            // Bar chart
            Container(
              decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor)),
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Text('Spending Trend',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: fgColor))),
                      Icon(Icons.calendar_today, size: 12, color: mutedColor),
                      const SizedBox(width: 4),
                      Text(
                          _timeRange == 'week' 
                            ? 'This Week' 
                            : _timeRange == 'custom' 
                                ? 'Custom Range'
                                : 'Last 6 Months',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: mutedColor)),
                    ]),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 180,
                      child: BarChart(BarChartData(
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (v, m) {
                              final idx = v.toInt();
                              if (idx < 0 || idx >= chartData.length) {
                                return const SizedBox();
                              }
                              // Hide some labels if there are too many (e.g. custom range)
                              if (chartData.length > 7 && idx % ((chartData.length ~/ 5) + 1) != 0) {
                                  return const SizedBox();
                              }

                              return Text(chartData[idx].$1,
                                  style: GoogleFonts.inter(
                                      fontSize: 10, color: mutedColor));
                            },
                          )),
                        ),
                        barGroups: List.generate(
                            chartData.length,
                            (i) => BarChartGroupData(
                                  x: i,
                                  barRods: [
                                    BarChartRodData(
                                      toY: chartData[i].$2,
                                      color: AppColors.primary,
                                      width: chartData.length > 7 ? 8 : 20,
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(4)),
                                    )
                                  ],
                                )),
                      )),
                    ),
                  ]),
            ),
            const SizedBox(height: 16),

            // Pie chart category breakdown
            Container(
              decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor)),
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Category Breakdown',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: fgColor)),
                    const SizedBox(height: 16),
                    categorySummary.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text('No data for this period',
                                  style: GoogleFonts.inter(color: mutedColor)),
                            ))
                        : Row(children: [
                            SizedBox(
                              width: 150,
                              height: 150,
                              child: PieChart(PieChartData(
                                sections: categorySummary
                                    .map((c) => PieChartSectionData(
                                          value: c.value,
                                          color: c.color,
                                          radius: 45,
                                          showTitle: false,
                                        ))
                                    .toList(),
                                centerSpaceRadius: 30,
                                sectionsSpace: 2,
                              )),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                                child: Column(
                              children: categorySummary.map((cat) {
                                final pct = totalSpending > 0
                                    ? ((cat.value / totalSpending) * 100)
                                        .toStringAsFixed(0)
                                    : '0';
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
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
                                    Text('$pct%',
                                        style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: fgColor)),
                                  ]),
                                );
                              }).toList(),
                            )),
                          ]),
                  ]),
            ),
            const SizedBox(height: 16),

            // Insights
            Container(
              decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor)),
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Detailed Insights',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: fgColor)),
                    const SizedBox(height: 16),
                    
                    if (maxExpense != null) ...[
                        _InsightRow(
                            icon: Icons.receipt_long,
                            color: AppColors.secondary,
                            title: 'Largest Expense',
                            description: '${maxExpense.merchant} on ${DateFormat('MMM dd').format(DateTime.parse(maxExpense.date))} (${state.formatCurrency(maxExpense.amount)})',
                            fgColor: fgColor,
                            mutedColor: mutedColor,
                        ),
                        const SizedBox(height: 12),
                    ],

                    if (mostActiveDayIdx != -1) ...[
                        _InsightRow(
                            icon: Icons.calendar_month,
                            color: AppColors.primary,
                            title: 'Most Active Day',
                            description: 'You tend to make the most purchases on ${daysArr[mostActiveDayIdx - 1]}s.',
                            fgColor: fgColor,
                            mutedColor: mutedColor,
                        ),
                        const SizedBox(height: 12),
                    ],

                    if (categorySummary.isNotEmpty) ...[
                      Builder(builder: (ctx) {
                        final sorted = [...categorySummary]..sort((a, b) => b.value.compareTo(a.value));
                        return _InsightRow(
                            icon: Icons.pie_chart,
                            color: AppColors.chartAmber,
                            title: 'Top Category',
                            description: '${sorted[0].name} accounts for ${((sorted[0].value / totalSpending) * 100).toStringAsFixed(1)}% of your spending in this period.',
                            fgColor: fgColor,
                            mutedColor: mutedColor,
                        );
                      }),
                    ] else ...[
                        Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('Not enough data to generate insights.',
                                  style: GoogleFonts.inter(fontSize: 12, color: mutedColor)),
                            ),
                        )
                    ],
                  ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
    final IconData icon;
    final Color color;
    final String title;
    final String description;
    final Color fgColor;
    final Color mutedColor;

    const _InsightRow({
        required this.icon,
        required this.color,
        required this.title,
        required this.description,
        required this.fgColor,
        required this.mutedColor,
    });

    @override
    Widget build(BuildContext context) {
        return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text(title,
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: fgColor)),
                            const SizedBox(height: 2),
                            Text(description,
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    height: 1.4,
                                    color: mutedColor)),
                        ],
                    ),
                ),
            ],
        );
    }
}

class _TimeTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color cardColor;
  final Color fgColor;
  final Color mutedColor;
  const _TimeTab(
      {required this.label,
      required this.isSelected,
      required this.onTap,
      required this.cardColor,
      required this.fgColor,
      required this.mutedColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? cardColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? fgColor : mutedColor)),
      ),
    ));
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final Color fgColor;
  final Color mutedColor;
  final Color borderColor;
  final Color cardColor;
  final bool isGreen;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.isDark,
      required this.fgColor,
      required this.mutedColor,
      required this.borderColor,
      required this.cardColor,
      this.isGreen = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor)),
      child: Column(children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: mutedColor)),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isGreen ? AppColors.secondary : fgColor)),
      ]),
    ));
  }
}
