import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _timeRange = 'month';

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

    final expenses = state.expenses;
    final totalSpending = expenses.fold(0.0, (s, e) => s + e.amount);

    final Map<String, double> categoryMap = {};
    for (final e in expenses) {
      categoryMap[e.category] = (categoryMap[e.category] ?? 0) + e.amount;
    }
    final categorySummary = kCategories
        .map((cat) => (name: cat.name, value: categoryMap[cat.name] ?? 0.0, color: Color(cat.color)))
        .where((c) => c.value > 0)
        .toList();

    // Chart data
    final now = DateTime.now();
    List<(String, double)> chartData = [];
    if (_timeRange == 'week') {
      final Map<int, double> dayTotals = {};
      for (final e in expenses) {
        final d = DateTime.parse(e.date);
        final diff = now.difference(d).inDays;
        if (diff < 7) {
          dayTotals[d.weekday] = (dayTotals[d.weekday] ?? 0) + e.amount;
        }
      }
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      chartData = List.generate(7, (i) => (days[i], dayTotals[i + 1] ?? 0.0));
    } else {
      const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
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

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Analytics', style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w700, color: fgColor)),
            Text('Understand your spending patterns', style: GoogleFonts.inter(fontSize: 13, color: mutedColor)),
            const SizedBox(height: 20),

            // Time range toggle
            Container(
              height: 40, padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: mutedBg, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                _TimeTab(label: 'This Week', isSelected: _timeRange == 'week', onTap: () => setState(() => _timeRange = 'week'), cardColor: cardColor, fgColor: fgColor, mutedColor: mutedColor),
                _TimeTab(label: 'Monthly', isSelected: _timeRange == 'month', onTap: () => setState(() => _timeRange = 'month'), cardColor: cardColor, fgColor: fgColor, mutedColor: mutedColor),
              ]),
            ),
            const SizedBox(height: 16),

            // Stats row
            Row(children: [
              _StatCard(label: 'Total', value: formatCurrency(totalSpending), isDark: isDark, fgColor: fgColor, mutedColor: mutedColor, borderColor: borderColor, cardColor: cardColor),
              const SizedBox(width: 8),
              _StatCard(label: 'Avg/Day', value: formatCurrency(totalSpending / 28), isDark: isDark, fgColor: fgColor, mutedColor: mutedColor, borderColor: borderColor, cardColor: cardColor),
              const SizedBox(width: 8),
              _StatCard(label: 'Items', value: '${expenses.length}', isDark: isDark, fgColor: fgColor, mutedColor: mutedColor, borderColor: borderColor, cardColor: cardColor, isGreen: true),
            ]),
            const SizedBox(height: 16),

            // Bar chart
            Container(
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text('Spending Trend', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: fgColor))),
                  Icon(Icons.calendar_today, size: 12, color: mutedColor),
                  const SizedBox(width: 4),
                  Text(_timeRange == 'week' ? 'This Week' : 'Last 6 Months', style: GoogleFonts.inter(fontSize: 11, color: mutedColor)),
                ]),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: BarChart(BarChartData(
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(
                        showTitles: true, reservedSize: 28,
                        getTitlesWidget: (v, m) {
                          final idx = v.toInt();
                          if (idx < 0 || idx >= chartData.length) return const SizedBox();
                          return Text(chartData[idx].$1, style: GoogleFonts.inter(fontSize: 10, color: mutedColor));
                        },
                      )),
                    ),
                    barGroups: List.generate(chartData.length, (i) => BarChartGroupData(
                      x: i,
                      barRods: [BarChartRodData(
                        toY: chartData[i].$2,
                        color: AppColors.primary,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      )],
                    )),
                  )),
                ),
              ]),
            ),
            const SizedBox(height: 16),

            // Pie chart category breakdown
            Container(
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Category Breakdown', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: fgColor)),
                const SizedBox(height: 16),
                categorySummary.isEmpty
                  ? Center(child: Text('No data', style: GoogleFonts.inter(color: mutedColor)))
                  : Row(children: [
                      SizedBox(
                        width: 150, height: 150,
                        child: PieChart(PieChartData(
                          sections: categorySummary.map((c) => PieChartSectionData(
                            value: c.value, color: c.color, radius: 45, showTitle: false,
                          )).toList(),
                          centerSpaceRadius: 30, sectionsSpace: 2,
                        )),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: Column(
                        children: categorySummary.map((cat) {
                          final pct = totalSpending > 0 ? ((cat.value / totalSpending) * 100).toStringAsFixed(0) : '0';
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(children: [
                              Container(width: 8, height: 8, decoration: BoxDecoration(color: cat.color, shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Expanded(child: Text(cat.name, style: GoogleFonts.inter(fontSize: 11, color: mutedColor))),
                              Text('$pct%', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: fgColor)),
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
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Insights', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: fgColor)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Icon(Icons.trending_down, size: 16, color: AppColors.secondary),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Total expenses tracked', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: fgColor)),
                      Text('You have ${expenses.length} expenses totaling ${formatCurrency(totalSpending)}.', style: GoogleFonts.inter(fontSize: 11, color: mutedColor)),
                    ])),
                  ]),
                ),
                if (categorySummary.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.chartAmber.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      Icon(Icons.trending_up, size: 16, color: AppColors.chartAmber),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Top spending category', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: fgColor)),
                        Builder(builder: (ctx) {
                          final sorted = [...categorySummary]..sort((a, b) => b.value.compareTo(a.value));
                          return Text('${sorted[0].name} is your highest category at ${formatCurrency(sorted[0].value)}.', style: GoogleFonts.inter(fontSize: 11, color: mutedColor));
                        }),
                      ])),
                    ]),
                  ),
                ],
              ]),
            ),
          ]),
        ),
      ),
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
  const _TimeTab({required this.label, required this.isSelected, required this.onTap, required this.cardColor, required this.fgColor, required this.mutedColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? cardColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
        ),
        alignment: Alignment.center,
        child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: isSelected ? fgColor : mutedColor)),
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
  const _StatCard({required this.label, required this.value, required this.isDark, required this.fgColor, required this.mutedColor, required this.borderColor, required this.cardColor, this.isGreen = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
      child: Column(children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: mutedColor)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: isGreen ? AppColors.secondary : fgColor)),
      ]),
    ));
  }
}
