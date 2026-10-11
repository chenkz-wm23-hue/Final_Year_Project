import 'package:flutter_test/flutter_test.dart';
import 'package:final_year_project/presentation/state/expense_store.dart';

void main() {
  test(
    'add, edit and delete keep monthly totals and categories consistent',
    () {
      final store = ExpenseStore();
      addTearDown(store.dispose);
      final baseline = store.expense;
      store.save(
        description: 'Lunch',
        amount: 20,
        date: store.month,
        category: 'Food',
        income: false,
      );
      final id = store.entries.last.id;
      expect(store.expense, baseline + 20);
      store.save(
        id: id,
        description: 'Train',
        amount: 5,
        date: store.month,
        category: 'Transport',
        income: false,
      );
      expect(store.expense, baseline + 5);
      expect(store.categoryTotals['Transport'], 17);
      store.delete(id);
      expect(store.expense, baseline);
      expect(store.balance, store.income - baseline);
    },
  );
  test('transactions and budget are scoped to the selected month', () {
    final store = ExpenseStore();
    addTearDown(store.dispose);
    store.setBudget(800);
    store.changeMonth(1);
    expect(store.monthly, isEmpty);
    expect(store.budget, 1500);
    store.setBudget(2000);
    store.changeMonth(-1);
    expect(store.budget, 800);
    expect(store.income, 2500);
    expect(() => store.setBudget(0), throwsArgumentError);
    expect(
      () => store.save(
        description: 'Bad',
        amount: double.nan,
        date: store.month,
        category: 'Others',
        income: false,
      ),
      throwsArgumentError,
    );
  });
  test('keyword suggestion handles known and unknown merchants', () {
    final store = ExpenseStore();
    addTearDown(store.dispose);
    expect(store.suggestCategory('KFC dinner'), 'Food');
    expect(store.suggestCategory('GRAB ride'), 'Transport');
    expect(store.suggestCategory('unknown'), 'Others');
  });
}
