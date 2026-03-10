import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _merchantCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  String _category = 'Food & Dining';
  bool _saved = false;
  Map<String, String> _errors = {};

  static const Map<String, String> _iconForCategory = {
    'Food & Dining': 'utensils',
    'Transport': 'car',
    'Shopping': 'shopping-bag',
    'Rent': 'home',
    'Entertainment': 'film',
    'Utilities': 'zap',
  };

  bool _validate() {
    final errors = <String, String>{};
    if (_merchantCtrl.text.trim().isEmpty) errors['merchant'] = 'Merchant name is required';
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (amount <= 0) errors['amount'] = 'Enter a valid amount';
    setState(() => _errors = errors);
    return errors.isEmpty;
  }

  void _handleSave(AppState state) {
    if (!_validate()) return;
    final expense = Expense(
      id: 'exp_${DateTime.now().millisecondsSinceEpoch}',
      merchant: _merchantCtrl.text.trim(),
      date: '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
      amount: double.parse(_amountCtrl.text),
      category: _category,
      icon: _iconForCategory[_category] ?? 'utensils',
    );
    state.addExpense(expense);
    setState(() => _saved = true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) state.setCurrentScreen('dashboard');
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final fgColor = isDark ? AppColors.darkForeground : AppColors.foreground;
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final mutedColor = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final mutedBg = isDark ? AppColors.darkMuted : AppColors.muted;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header
            Row(children: [
              GestureDetector(
                onTap: () => context.read<AppState>().goBack(),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: borderColor)),
                  child: Icon(Icons.arrow_back, size: 18, color: fgColor),
                ),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Add Expense', style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w700, color: fgColor)),
                Text('Enter expense details manually', style: GoogleFonts.inter(fontSize: 12, color: mutedColor)),
              ]),
            ]),
            const SizedBox(height: 24),

            if (_saved)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(18)),
                    child: const Icon(Icons.check, size: 32, color: AppColors.secondary),
                  ),
                  const SizedBox(height: 16),
                  Text('Expense Added!', style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w600, color: fgColor)),
                  Text('Redirecting to dashboard...', style: GoogleFonts.inter(fontSize: 13, color: mutedColor)),
                ]),
              )
            else ...[
              Container(
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Merchant
                  _FieldLabel(icon: Icons.store_outlined, label: 'Merchant Name', mutedColor: mutedColor, fgColor: fgColor),
                  TextField(controller: _merchantCtrl, decoration: InputDecoration(hintText: 'e.g. Starbucks, Amazon', errorText: _errors['merchant'])),
                  const SizedBox(height: 16),
                  // Date
                  _FieldLabel(icon: Icons.calendar_today_outlined, label: 'Date', mutedColor: mutedColor, fgColor: fgColor),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(color: isDark ? AppColors.darkCard : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(children: [
                        Icon(Icons.calendar_today, size: 16, color: mutedColor),
                        const SizedBox(width: 8),
                        Text('${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}', style: GoogleFonts.inter(fontSize: 14, color: fgColor)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Amount
                  _FieldLabel(icon: Icons.attach_money, label: 'Amount', mutedColor: mutedColor, fgColor: fgColor),
                  TextField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      prefixText: '${context.read<AppState>().currencySymbol} ',
                      errorText: _errors['amount'],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Category
                  _FieldLabel(icon: Icons.label_outline, label: 'Category', mutedColor: mutedColor, fgColor: fgColor),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: kCategories.map((cat) => GestureDetector(
                      onTap: () => setState(() => _category = cat.name),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _category == cat.name ? AppColors.primary : mutedBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(cat.name, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: _category == cat.name ? Colors.white : mutedColor)),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Notes
                  _FieldLabel(icon: Icons.notes, label: 'Notes (Optional)', mutedColor: mutedColor, fgColor: fgColor),
                  TextField(controller: _notesCtrl, decoration: const InputDecoration(hintText: 'Add any additional notes...')),
                ]),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _handleSave(state),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Save Expense'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => context.read<AppState>().goBack(),
                  child: Text('Cancel', style: GoogleFonts.inter(color: mutedColor)),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color mutedColor;
  final Color fgColor;
  const _FieldLabel({required this.icon, required this.label, required this.mutedColor, required this.fgColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Icon(icon, size: 14, color: mutedColor),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: fgColor)),
      ]),
    );
  }
}
