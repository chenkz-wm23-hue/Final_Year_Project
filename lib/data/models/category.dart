const expenseCategories = [
  'Food',
  'Shopping',
  'Transport',
  'Fuel',
  'Healthcare',
  'Entertainment',
  'Others',
];
const incomeCategories = [
  'Salary',
  'Allowance',
  'Scholarship',
  'Freelance',
  'Others',
];

class Category {
  final String name;
  final bool income;
  const Category(this.name, {this.income = false});
}
