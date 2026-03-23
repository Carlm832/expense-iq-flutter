import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../services/translations.dart';

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
  bool _prefilledFromScan = false;
  Map<String, String> _errors = {};

  // Edit mode state
  String? _editingId; // non-null = edit mode

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = context.read<AppState>().screenArgs;
      if (args != null && args['editExpense'] == true) {
        // Edit mode: pre-fill from the passed expense fields
        setState(() {
          _editingId = args['id'] as String?;
          _merchantCtrl.text = args['merchant'] as String? ?? '';
          _amountCtrl.text = args['amount'] as String? ?? '';
          _category = args['category'] as String? ?? 'Food & Dining';
          _notesCtrl.text = args['notes'] as String? ?? '';
          if (args['date'] != null) {
            try {
              _date = DateTime.parse(args['date'] as String);
            } catch (_) {}
          }
        });
      } else if (args != null && args['fromScan'] == true) {
        setState(() {
          _prefilledFromScan = true;
          if (args['merchant'] != null) {
            _merchantCtrl.text = args['merchant'] as String;
          }
          if (args['amount'] != null) {
            _amountCtrl.text = args['amount'] as String;
          }
          if (args['date'] != null) {
            try {
              _date = DateTime.parse(args['date'] as String);
            } catch (_) {}
          }
        });
      }
    });
  }

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
    if (_merchantCtrl.text.trim().isEmpty) {
      errors['merchant'] = Translations.t(
          'merchant_required', context.read<AppState>().language);
    }
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (amount <= 0) {
      errors['amount'] = Translations.t(
          'valid_amount_required', context.read<AppState>().language);
    }
    setState(() => _errors = errors);
    return errors.isEmpty;
  }

  void _handleSave(AppState state) {
    if (!_validate()) return;

    final dateStr =
        '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

    if (_editingId != null) {
      // Edit mode: update existing expense, keep the same ID
      // Retrieve original currency if available, or fall back to user's current currency
      final originalExpense = state.expenses.firstWhere((e) => e.id == _editingId);
      final currencyToUse = originalExpense.currency;

      final updated = Expense(
        id: _editingId!,
        merchant: _merchantCtrl.text.trim(),
        date: dateStr,
        amount: double.parse(_amountCtrl.text),
        currency: currencyToUse,
        category: _category,
        icon: _iconForCategory[_category] ?? 'utensils',
      );
      state.editExpense(_editingId!, updated);
    } else {
      // Add mode: create a new expense
      // Use clean currency code like 'USD' or 'TRY' based on settings
      String currencyToUse = state.currencyService.cleanCurrencyCode(state.currency);
      if (_prefilledFromScan && context.read<AppState>().screenArgs?['currency'] != null) {
        currencyToUse = context.read<AppState>().screenArgs!['currency'] as String;
      }

      final expense = Expense(
        id: 'exp_${DateTime.now().millisecondsSinceEpoch}',
        merchant: _merchantCtrl.text.trim(),
        date: dateStr,
        amount: double.parse(_amountCtrl.text),
        currency: currencyToUse,
        category: _category,
        icon: _iconForCategory[_category] ?? 'utensils',
      );
      state.addExpense(expense);
    }

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
    final lang = state.language;
    final isEditMode = _editingId != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final fgColor = isDark ? AppColors.darkForeground : AppColors.foreground;
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final mutedColor =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final mutedBg = isDark ? AppColors.darkMuted : AppColors.muted;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              GestureDetector(
                onTap: () => context.read<AppState>().goBack(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor)),
                  child: Icon(Icons.arrow_back, size: 18, color: fgColor),
                ),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                    isEditMode
                        ? Translations.t('edit_expense_title', lang)
                        : Translations.t('add_expense_title', lang),
                    style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: fgColor)),
                Text(
                    isEditMode
                        ? Translations.t('review_scanned_details', lang)
                        : _prefilledFromScan
                            ? Translations.t('review_scanned_details', lang)
                            : Translations.t('enter_details_manual', lang),
                    style: GoogleFonts.inter(fontSize: 12, color: mutedColor)),
              ]),
            ]),
            const SizedBox(height: 24),
            if (_saved)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor)),
                padding: const EdgeInsets.all(32),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(18)),
                        child: const Icon(Icons.check,
                            size: 32, color: AppColors.secondary),
                      ),
                      const SizedBox(height: 16),
                      Text(
                          isEditMode
                              ? Translations.t('expense_saved', lang)
                              : Translations.t('expense_added', lang),
                          style: GoogleFonts.dmSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: fgColor)),
                      Text(Translations.t('redirecting_to_dashboard', lang),
                          style: GoogleFonts.inter(
                              fontSize: 13, color: mutedColor)),
                    ]),
              )
            else ...[
              if (_prefilledFromScan && !isEditMode)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.secondary.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.auto_awesome,
                        size: 16, color: AppColors.secondary),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(
                            Translations.t('prefilled_from_scan_banner', lang),
                            style: GoogleFonts.inter(
                                fontSize: 12, color: AppColors.secondary))),
                  ]),
                ),
              Container(
                decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor)),
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel(
                          icon: Icons.store_outlined,
                          label: Translations.t('merchant_name', lang),
                          mutedColor: mutedColor,
                          fgColor: fgColor),
                      TextField(
                          controller: _merchantCtrl,
                          style:
                              GoogleFonts.inter(fontSize: 14, color: fgColor),
                          decoration: InputDecoration(
                              hintText: Translations.t('merchant_hint', lang),
                              errorText: _errors['merchant'])),
                      const SizedBox(height: 16),
                      _FieldLabel(
                          icon: Icons.calendar_today_outlined,
                          label: Translations.t('date', lang),
                          mutedColor: mutedColor,
                          fgColor: fgColor),
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor)),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(children: [
                            Icon(Icons.calendar_today,
                                size: 16, color: mutedColor),
                            const SizedBox(width: 8),
                            Text(
                                '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                                style: GoogleFonts.inter(
                                    fontSize: 14, color: fgColor)),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _FieldLabel(
                          icon: Icons.attach_money,
                          label: Translations.t('amount_label', lang),
                          mutedColor: mutedColor,
                          fgColor: fgColor),
                      TextField(
                        controller: _amountCtrl,
                        style: GoogleFonts.inter(fontSize: 14, color: fgColor),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          prefixText: '${state.currencySymbol} ',
                          errorText: _errors['amount'],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _FieldLabel(
                          icon: Icons.label_outline,
                          label: Translations.t('category_label', lang),
                          mutedColor: mutedColor,
                          fgColor: fgColor),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: kCategories
                            .map((cat) => GestureDetector(
                                  onTap: () =>
                                      setState(() => _category = cat.name),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _category == cat.name
                                          ? AppColors.primary
                                          : mutedBg,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(Translations.t(cat.name, lang),
                                        style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: _category == cat.name
                                                ? Colors.white
                                                : mutedColor)),
                                  ),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      _FieldLabel(
                          icon: Icons.notes,
                          label: Translations.t('notes_label', lang),
                          mutedColor: mutedColor,
                          fgColor: fgColor),
                      TextField(
                          controller: _notesCtrl,
                          maxLines: 2,
                          style:
                              GoogleFonts.inter(fontSize: 14, color: fgColor),
                          decoration: InputDecoration(
                              hintText: Translations.t('notes_hint', lang))),
                    ]),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _handleSave(state),
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(isEditMode
                      ? Translations.t('save_changes', lang)
                      : Translations.t('save_expense', lang)),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => context.read<AppState>().goBack(),
                  child: Text(Translations.t('cancel', lang),
                      style: GoogleFonts.inter(color: mutedColor)),
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
  const _FieldLabel(
      {required this.icon,
      required this.label,
      required this.mutedColor,
      required this.fgColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Icon(icon, size: 14, color: mutedColor),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w500, color: fgColor)),
      ]),
    );
  }
}
