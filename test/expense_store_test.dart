import 'package:flutter_test/flutter_test.dart';
import 'package:final_year_project/presentation/state/expense_store.dart';

void main() {
  test(
    'add, edit and delete keep monthly totals and categories consistent',
    () async {
      final store = ExpenseStore();
      addTearDown(store.dispose);
      final baseline = store.expense;
      await store.save(
        description: 'Lunch',
        amount: 20,
        date: store.month,
        category: 'Food',
        income: false,
      );
      final id = store.entries.last.id;
      expect(store.expense, baseline + 20);
      await store.save(
        id: id,
        description: 'Train',
        amount: 5,
        date: store.month,
        category: 'Transport',
        income: false,
      );
      expect(store.expense, baseline + 5);
      expect(store.categoryTotals['Transport'], 17);
      await store.delete(id);
      expect(store.expense, baseline);
      expect(store.balance, store.income - baseline);
    },
  );
  test('transactions and budget are scoped to the selected month', () async {
    final store = ExpenseStore();
    addTearDown(store.dispose);
    await store.setBudget(800);
    store.changeMonth(1);
    expect(store.monthly, isEmpty);
    expect(store.budget, 1500);
    await store.setBudget(2000);
    store.changeMonth(-1);
    expect(store.budget, 800);
    expect(store.income, 2500);
    await expectLater(store.setBudget(0), throwsArgumentError);
    await expectLater(
      store.save(
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
    expect(store.suggestCategory('Petron fuel'), 'Fuel');
    expect(store.suggestCategory('BHP Petrol'), 'Fuel');
    expect(store.suggestCategory('toys and a movie'), 'Entertainment');
    expect(store.suggestCategory('food court'), 'Food');
    expect(store.suggestCategory('etc'), 'Others');
    expect(store.suggestCategory('unknown'), 'Others');
  });
}
