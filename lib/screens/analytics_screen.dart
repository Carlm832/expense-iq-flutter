import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../services/translations.dart';
import '../services/report_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _timeRange = 'month'; // 'week', 'month', 'custom'
  DateTimeRange? _customRange;

  // Calendar tab state
  String _activeTab = 'overview'; // 'overview' or 'calendar'
  DateTime _calendarMonth =
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime? _selectedDay;

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
        return d.isAfter(
                _customRange!.start.subtract(const Duration(days: 1))) &&
            d.isBefore(_customRange!.end.add(const Duration(days: 1)));
      } else {
        // 'month' or default: show last 6 months in chart, but filter actual data to current month for stats?
        // Let's stick to the 6 month logic for the overview stats if range is 'month'
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

    final lang = state.language;
    final expenses = _getFilteredExpenses(state.expenses);
    final totalSpending = expenses.fold(0.0, (s, e) => s + state.convertToCurrent(e.amount, e.currency));

    final Map<String, double> categoryMap = {};
    for (final e in expenses) {
      final amount = state.convertToCurrent(e.amount, e.currency);
      categoryMap[e.category] = (categoryMap[e.category] ?? 0) + amount;
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
        final amount = state.convertToCurrent(e.amount, e.currency);
        dayTotals[d.weekday] = (dayTotals[d.weekday] ?? 0) + amount;
      }
      final days = [
        Translations.t('day_mon', lang).substring(0, 3),
        Translations.t('day_tue', lang).substring(0, 3),
        Translations.t('day_wed', lang).substring(0, 3),
        Translations.t('day_thu', lang).substring(0, 3),
        Translations.t('day_fri', lang).substring(0, 3),
        Translations.t('day_sat', lang).substring(0, 3),
        Translations.t('day_sun', lang).substring(0, 3),
      ];
      chartData = List.generate(7, (i) => (days[i], dayTotals[i + 1] ?? 0.0));
    } else if (_timeRange == 'custom' && _customRange != null) {
      final duration = _customRange!.end.difference(_customRange!.start).inDays;
      if (duration <= 14) {
        final Map<String, double> dayTotals = {};
        for (final e in expenses) {
          final d = DateTime.parse(e.date);
          final label = DateFormat('MM/dd').format(d);
          dayTotals[label] = (dayTotals[label] ?? 0) + e.amount;
        }
        for (int i = 0; i <= duration; i++) {
          final d = _customRange!.start.add(Duration(days: i));
          final label = DateFormat('MM/dd').format(d);
          chartData.add((label, dayTotals[label] ?? 0.0));
        }
      } else {
        final Map<String, double> monthTotals = {};
        for (final e in expenses) {
          final d = DateTime.parse(e.date);
          final label = DateFormat('MMM yyyy').format(d);
          final amount = state.convertToCurrent(e.amount, e.currency);
          monthTotals[label] = (monthTotals[label] ?? 0) + amount;
        }
        chartData = monthTotals.entries.map((e) => (e.key, e.value)).toList();
      }
    } else {
      final monthNames = [
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
      final Map<int, double> monthTotals = {};
      for (final e in state.expenses) {
        final d = DateTime.parse(e.date);
        final amount = state.convertToCurrent(e.amount, e.currency);
        monthTotals[d.month - 1] = (monthTotals[d.month - 1] ?? 0) + amount;
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

    int mostActiveDayIdx = -1;
    if (expenses.isNotEmpty) {
      final Map<int, int> countPerDay = {};
      for (var e in expenses) {
        final d = DateTime.parse(e.date);
        countPerDay[d.weekday] = (countPerDay[d.weekday] ?? 0) + 1;
      }
      mostActiveDayIdx =
          countPerDay.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }
    final daysArr = [
      Translations.t('day_mon', lang),
      Translations.t('day_tue', lang),
      Translations.t('day_wed', lang),
      Translations.t('day_thu', lang),
      Translations.t('day_fri', lang),
      Translations.t('day_sat', lang),
      Translations.t('day_sun', lang),
    ];

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(Translations.t('analytics_title', lang),
                style: GoogleFonts.dmSans(
                    fontSize: 20, fontWeight: FontWeight.w700, color: fgColor)),
            Text(Translations.t('analytics_subtitle', lang),
                style: GoogleFonts.inter(fontSize: 13, color: mutedColor)),
            const SizedBox(height: 20),

            // Master tab: Overview | Calendar
            Container(
              height: 40,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                  color: mutedBg, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                _TimeTab(
                    label: Translations.t('overview', lang),
                    isSelected: _activeTab == 'overview',
                    onTap: () => setState(() => _activeTab = 'overview'),
                    cardColor: cardColor,
                    fgColor: fgColor,
                    mutedColor: mutedColor),
                _TimeTab(
                    label: Translations.t('calendar', lang),
                    isSelected: _activeTab == 'calendar',
                    onTap: () => setState(() => _activeTab = 'calendar'),
                    cardColor: cardColor,
                    fgColor: fgColor,
                    mutedColor: mutedColor),
              ]),
            ),
            const SizedBox(height: 16),

            if (_activeTab == 'calendar') ...[
              _CalendarView(
                expenses: state.expenses,
                calendarMonth: _calendarMonth,
                selectedDay: _selectedDay,
                fgColor: fgColor,
                mutedColor: mutedColor,
                cardColor: cardColor,
                borderColor: borderColor,
                mutedBg: mutedBg,
                formatCurrency: state.formatCurrency,
                onMonthChanged: (m) => setState(() => _calendarMonth = m),
                onDayTapped: (day) {
                  setState(() => _selectedDay = day);
                  final dayExpenses = state.expenses.where((e) {
                    final d = DateTime.parse(e.date);
                    return d.year == day.year &&
                        d.month == day.month &&
                        d.day == day.day;
                  }).toList();
                  if (dayExpenses.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(Translations.t('no_data', state.language)),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20))),
                    builder: (_) => _DayDetailSheet(
                      day: day,
                      expenses: dayExpenses,
                      fgColor: fgColor,
                      mutedColor: mutedColor,
                      borderColor: borderColor,
                      cardColor: cardColor,
                      formatCurrency: state.formatCurrency,
                    ),
                  );
                },
              ),
            ] else ...[
              Container(
                height: 40,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    color: mutedBg, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  _TimeTab(
                      label: Translations.t('week', lang),
                      isSelected: _timeRange == 'week',
                      onTap: () => setState(() => _timeRange = 'week'),
                      cardColor: cardColor,
                      fgColor: fgColor,
                      mutedColor: mutedColor),
                  _TimeTab(
                      label: Translations.t('month', lang),
                      isSelected: _timeRange == 'month',
                      onTap: () => setState(() => _timeRange = 'month'),
                      cardColor: cardColor,
                      fgColor: fgColor,
                      mutedColor: mutedColor),
                  _TimeTab(
                      label: Translations.t('custom', lang),
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
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500),
                )),
              ],
              const SizedBox(height: 16),

              // Stats row
              Row(children: [
                _StatCard(
                    label: Translations.t('total', lang),
                    value: state.formatCurrency(totalSpending),
                    isDark: isDark,
                    fgColor: fgColor,
                    mutedColor: mutedColor,
                    borderColor: borderColor,
                    cardColor: cardColor),
                const SizedBox(width: 8),
                _StatCard(
                    label: Translations.t('avg_per_item', lang),
                    value: expenses.isEmpty
                        ? '${state.currencySymbol}0'
                        : state.formatCurrency(totalSpending / expenses.length),
                    isDark: isDark,
                    fgColor: fgColor,
                    mutedColor: mutedColor,
                    borderColor: borderColor,
                    cardColor: cardColor),
                const SizedBox(width: 8),
                _StatCard(
                    label: Translations.t('count', lang),
                    value: '${expenses.length}',
                    isDark: isDark,
                    fgColor: fgColor,
                    mutedColor: mutedColor,
                    borderColor: borderColor,
                    cardColor: cardColor,
                    isGreen: true),
              ]),
              const SizedBox(height: 16),

              // Export Buttons
              Row(children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => ReportService.generateAndPrintPDF(
                      expenses, 
                      state.currency, 
                      totalSpending, 
                      state.userName
                    ),
                    icon: const Icon(Icons.picture_as_pdf, size: 16),
                    label: Text(Translations.t('export_pdf', lang), style: GoogleFonts.inter(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ReportService.generateCSV(expenses, state.currency),
                    icon: const Icon(Icons.table_chart, size: 16),
                    label: Text(Translations.t('export_csv', lang), style: GoogleFonts.inter(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
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
                            child: Text(Translations.t('spending_trend', lang),
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: fgColor))),
                        Icon(Icons.calendar_today, size: 12, color: mutedColor),
                        const SizedBox(width: 4),
                        Text(
                            _timeRange == 'week'
                                ? Translations.t('week', lang)
                                : _timeRange == 'custom'
                                    ? Translations.t('custom_range', lang)
                                    : Translations.t('last_six_months', lang),
                            style: GoogleFonts.inter(
                                fontSize: 11, color: mutedColor)),
                      ]),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 180,
                        child: LineChart(LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) => FlLine(
                                color: borderColor.withValues(alpha: 0.1),
                                strokeWidth: 1),
                          ),
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
                                if (chartData.length > 7 &&
                                    idx % ((chartData.length ~/ 5) + 1) != 0) {
                                  return const SizedBox();
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(chartData[idx].$1,
                                      style: GoogleFonts.inter(
                                          fontSize: 10, color: mutedColor)),
                                );
                              },
                            )),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: List.generate(
                                  chartData.length,
                                  (i) => FlSpot(i.toDouble(), chartData[i].$2)),
                              isCurved: true,
                              color: AppColors.primary,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0.3),
                                    AppColors.primary.withValues(alpha: 0.0),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
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
                      Text(Translations.t('category_breakdown', lang),
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: fgColor)),
                      const SizedBox(height: 16),
                      categorySummary.isEmpty
                          ? Center(
                              child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(Translations.t('no_data', lang),
                                  style: GoogleFonts.inter(color: mutedColor)),
                            ))
                          : Row(children: [
                              SizedBox(
                                width: 140,
                                height: 140,
                                child: PieChart(PieChartData(
                                  sections: categorySummary
                                      .map((c) => PieChartSectionData(
                                            value: c.value,
                                            color: c.color,
                                            radius: 40,
                                            showTitle: false,
                                          ))
                                      .toList(),
                                  centerSpaceRadius: 25,
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
                                          child: Text(
                                              Translations.t(cat.name, lang),
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  color: mutedColor))),
                                      const SizedBox(width: 4),
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
                      Text(Translations.t('detailed_insights', lang),
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: fgColor)),
                      const SizedBox(height: 16),
                      if (maxExpense != null) ...[
                        _InsightRow(
                          icon: Icons.receipt_long,
                          color: AppColors.secondary,
                          title: Translations.t('largest_expense', lang),
                          description:
                              '${maxExpense.merchant} ${DateFormat('MMM d, yyyy', lang == 'Turkish' ? 'tr' : 'en').format(DateTime.parse(maxExpense.date))} (${state.formatCurrency(maxExpense.amount)})',
                          fgColor: fgColor,
                          mutedColor: mutedColor,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (mostActiveDayIdx != -1) ...[
                        _InsightRow(
                          icon: Icons.calendar_month,
                          color: AppColors.primary,
                          title: Translations.t('most_active_day', lang),
                          description:
                              Translations.t('most_active_day_desc', lang) +
                                  daysArr[mostActiveDayIdx - 1] +
                                  (lang == 'Turkish' ? ' günleridir.' : '.'),
                          fgColor: fgColor,
                          mutedColor: mutedColor,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (categorySummary.isNotEmpty) ...[
                        Builder(builder: (ctx) {
                          final sorted = [...categorySummary]
                            ..sort((a, b) => b.value.compareTo(a.value));
                          return _InsightRow(
                            icon: Icons.pie_chart,
                            color: AppColors.chartAmber,
                            title: Translations.t('top_category', lang),
                            description: Translations.t(sorted[0].name, lang) +
                                Translations.t('top_category_desc', lang) +
                                ((sorted[0].value / totalSpending) * 100)
                                    .toStringAsFixed(1) +
                                Translations.t('percent_of_spending', lang),
                            fgColor: fgColor,
                            mutedColor: mutedColor,
                          );
                        }),
                      ] else ...[
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(Translations.t('not_enough_data', lang),
                                style: GoogleFonts.inter(
                                    fontSize: 12, color: mutedColor)),
                          ),
                        )
                      ],
                    ]),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

class _CalendarView extends StatelessWidget {
  final List<Expense> expenses;
  final DateTime calendarMonth;
  final DateTime? selectedDay;
  final Color fgColor;
  final Color mutedColor;
  final Color cardColor;
  final Color borderColor;
  final Color mutedBg;
  final String Function(double) formatCurrency;
  final void Function(DateTime) onMonthChanged;
  final void Function(DateTime) onDayTapped;

  const _CalendarView({
    required this.expenses,
    required this.calendarMonth,
    required this.selectedDay,
    required this.fgColor,
    required this.mutedColor,
    required this.cardColor,
    required this.borderColor,
    required this.mutedBg,
    required this.formatCurrency,
    required this.onMonthChanged,
    required this.onDayTapped,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final lang = state.language;
    final firstDay = calendarMonth;
    final daysInMonth = DateTime(firstDay.year, firstDay.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7;

    final Map<int, double> dayTotals = {};
    final Map<int, List<Color>> dayCategoryColors = {};
    final monthExpenses = expenses.where((e) {
      final d = DateTime.parse(e.date);
      return d.year == firstDay.year && d.month == firstDay.month;
    }).toList();

    final totalMonthSpend = monthExpenses.fold(0.0, (s, e) => s + e.amount);
    final busyDay = monthExpenses.isEmpty
        ? '-'
        : () {
            final counts = <int, int>{};
            for (final e in monthExpenses) {
              final d = DateTime.parse(e.date).day;
              counts[d] = (counts[d] ?? 0) + 1;
            }
            return '${counts.entries.reduce((a, b) => a.value > b.value ? a : b).key}';
          }();

    for (final e in monthExpenses) {
      final day = DateTime.parse(e.date).day;
      dayTotals[day] = (dayTotals[day] ?? 0) + e.amount;
    }

    final categoryCols = <String, Color>{};
    for (final cat in kCategories) {
      categoryCols[cat.name] = Color(cat.color);
    }
    for (final e in monthExpenses) {
      final day = DateTime.parse(e.date).day;
      final col = categoryCols[e.category] ?? AppColors.primary;
      dayCategoryColors[day] = [...(dayCategoryColors[day] ?? []), col];
    }

    final monthLabel = DateFormat('MMMM yyyy', lang == 'Turkish' ? 'tr' : 'en')
        .format(calendarMonth);
    final cells = startWeekday + daysInMonth;
    final rows = (cells / 7).ceil();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        IconButton(
          icon: Icon(Icons.chevron_left, color: fgColor),
          onPressed: () => onMonthChanged(
              DateTime(calendarMonth.year, calendarMonth.month - 1, 1)),
        ),
        Expanded(
          child: Text(monthLabel,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                  fontSize: 15, fontWeight: FontWeight.w700, color: fgColor)),
        ),
        IconButton(
          icon: Icon(Icons.chevron_right, color: fgColor),
          onPressed: () => onMonthChanged(
              DateTime(calendarMonth.year, calendarMonth.month + 1, 1)),
        ),
      ]),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor)),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Row(children: [
          _CalStat(
              label: Translations.t('expenses_label', lang),
              value: formatCurrency(totalMonthSpend),
              fgColor: fgColor,
              mutedColor: mutedColor),
          Container(
              width: 1,
              height: 28,
              color: borderColor,
              margin: const EdgeInsets.symmetric(horizontal: 12)),
          _CalStat(
              label: Translations.t('avg_day', lang),
              value: daysInMonth > 0
                  ? formatCurrency(totalMonthSpend / daysInMonth)
                  : '-',
              fgColor: fgColor,
              mutedColor: mutedColor),
          Container(
              width: 1,
              height: 28,
              color: borderColor,
              margin: const EdgeInsets.symmetric(horizontal: 12)),
          _CalStat(
              label: Translations.t('busiest', lang),
              value: busyDay == '-'
                  ? '-'
                  : '${Translations.t('day_suffix', lang)} $busyDay',
              fgColor: fgColor,
              mutedColor: mutedColor),
        ]),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Translations.t('sun_short', lang),
          Translations.t('mon_short', lang),
          Translations.t('tue_short', lang),
          Translations.t('wed_short', lang),
          Translations.t('thu_short', lang),
          Translations.t('fri_short', lang),
          Translations.t('sat_short', lang)
        ]
            .map((d) => Expanded(
                child: Center(
                    child: Text(d,
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: mutedColor)))))
            .toList(),
      ),
      const SizedBox(height: 4),
      Container(
        decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor)),
        child: Column(
          children: List.generate(rows, (row) {
            return Row(
              children: List.generate(7, (col) {
                final cellIndex = row * 7 + col;
                final day = cellIndex - startWeekday + 1;
                if (day < 1 || day > daysInMonth) {
                  return const Expanded(child: SizedBox(height: 64));
                }
                final date =
                    DateTime(calendarMonth.year, calendarMonth.month, day);
                final total = dayTotals[day];
                final colors = (dayCategoryColors[day] ?? []).take(3).toList();
                final isSelected = selectedDay != null &&
                    selectedDay!.year == date.year &&
                    selectedDay!.month == date.month &&
                    selectedDay!.day == date.day;
                final isToday = date.year == DateTime.now().year &&
                    date.month == DateTime.now().month &&
                    date.day == DateTime.now().day;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onDayTapped(date),
                    child: Container(
                      height: 64,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : Colors.transparent,
                        border: Border(
                          right: col < 6
                              ? BorderSide(color: borderColor, width: 0.5)
                              : BorderSide.none,
                          bottom: row < rows - 1
                              ? BorderSide(color: borderColor, width: 0.5)
                              : BorderSide.none,
                          top: isSelected
                              ? const BorderSide(
                                  color: AppColors.primary, width: 1.5)
                              : BorderSide.none,
                          left: isSelected
                              ? const BorderSide(
                                  color: AppColors.primary, width: 1.5)
                              : BorderSide.none,
                        ),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$day',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight:
                                  isToday ? FontWeight.w700 : FontWeight.w500,
                              color: isToday ? AppColors.primary : fgColor,
                            ),
                          ),
                          if (total != null)
                            Flexible(
                              child: Text(
                                state.formatCurrency(total),
                                style: GoogleFonts.inter(
                                    fontSize: 8,
                                    color: AppColors.destructive,
                                    fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          const Spacer(),
                          if (colors.isNotEmpty)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: colors
                                  .map((c) => Container(
                                        width: 5,
                                        height: 5,
                                        margin: const EdgeInsets.only(right: 2),
                                        decoration: BoxDecoration(
                                            color: c, shape: BoxShape.circle),
                                      ))
                                  .toList(),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ),
      ),
    ]);
  }
}

class _CalStat extends StatelessWidget {
  final String label;
  final String value;
  final Color fgColor;
  final Color mutedColor;
  const _CalStat(
      {required this.label,
      required this.value,
      required this.fgColor,
      required this.mutedColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Text(value,
            style: GoogleFonts.dmSans(
                fontSize: 13, fontWeight: FontWeight.w700, color: fgColor)),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: mutedColor)),
      ]),
    );
  }
}

class _DayDetailSheet extends StatelessWidget {
  final DateTime day;
  final List<Expense> expenses;
  final Color fgColor;
  final Color mutedColor;
  final Color borderColor;
  final Color cardColor;
  final String Function(double) formatCurrency;

  const _DayDetailSheet({
    required this.day,
    required this.expenses,
    required this.fgColor,
    required this.mutedColor,
    required this.borderColor,
    required this.cardColor,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final total = expenses.fold(0.0, (s, e) => s + e.amount);
    final lang = context.read<AppState>().language;
    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollCtrl) => ListView(
        controller: scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Center(
            child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4))),
          ),
          Text(
              DateFormat('EEEE, MMMM d', lang == 'Turkish' ? 'tr' : 'en')
                  .format(day),
              style: GoogleFonts.dmSans(
                  fontSize: 16, fontWeight: FontWeight.w700, color: fgColor)),
          Text(
              '${expenses.length} ${expenses.length == 1 ? Translations.t('transactions_singular', lang) : Translations.t('transactions_plural', lang)} · ${formatCurrency(total)}',
              style: GoogleFonts.inter(fontSize: 12, color: mutedColor)),
          const SizedBox(height: 16),
          ...expenses.map((e) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor)),
                child: Row(children: [
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(e.merchant,
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: fgColor)),
                        Text(Translations.t(e.category, lang),
                            style: GoogleFonts.inter(
                                fontSize: 11, color: mutedColor)),
                      ])),
                  Text(formatCurrency(e.amount),
                      style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.destructive)),
                ]),
              )),
        ],
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
                      fontSize: 11, height: 1.4, color: mutedColor)),
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
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4)
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
