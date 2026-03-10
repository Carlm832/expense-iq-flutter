import 'package:flutter_test/flutter_test.dart';
import 'package:expense_iq_flutter/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ExpenseIQApp());
    expect(find.byType(ExpenseIQApp), findsOneWidget);
  });
}
